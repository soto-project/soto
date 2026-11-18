//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import AsyncHTTPClient
import Atomics
import Foundation
import HTTPTypes
import NIOCore
import NIOPosix
import SotoS3
import SotoS3Control
import SotoSTS
import Testing

@testable import SotoCore

@Suite(.awsClient())
struct S3Tests {
    func testPutGetObject(
        filename: String,
        contents: AWSHTTPBody,
        s3: S3
    ) async throws {
        let putRequest = S3.PutObjectRequest(
            body: contents,
            bucket: S3BucketTrait.name,
            key: filename
        )
        let putResponse = try await s3.putObject(putRequest)
        #expect(putResponse.eTag != nil)
        let getResponse = try await s3.getObject(
            .init(bucket: S3BucketTrait.name, key: filename, responseExpires: Date())
        )
        let requestContents = try await contents.collect(upTo: .max)
        let responseContents = try await getResponse.body.collect(upTo: .max)
        #expect(responseContents == requestContents)
        #expect(getResponse.lastModified != nil)
    }

    // MARK: TESTS

    @Test(.s3Bucket)
    func testPutGetObject() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        try await self.testPutGetObject(
            filename: "testfile.txt",
            contents: .init(string: "testing S3.PutObject and S3.GetObject"),
            s3: s3
        )
    }

    @Test(.s3Bucket)
    func testPutGetObjectWithSpecialName() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let filename =
            if TestEnvironment.isUsingLocalstack {
                "test $filé+!@£$%^&*()_=-[]{}\\|';:\",./?><~`.txt"
            } else {
                "test $filé+!@£$%2F%^&*()_=-[]{}\\|';:\",./?><~`.txt"
            }
        try await self.testPutGetObject(
            filename: filename,
            contents: .init(string: "testing S3.PutObject and S3.GetObject"),
            s3: s3
        )
    }

    @Test(.s3Bucket)
    func testCopy() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let keyName = "file1"
        let newKeyName = "file2"
        let contents = "testing S3.PutObject and S3.GetObject"
        let putRequest = S3.PutObjectRequest(
            body: .init(string: contents),
            bucket: S3BucketTrait.name,
            key: keyName
        )
        let putResponse = try await s3.putObject(putRequest)
        #expect(putResponse.eTag != nil)
        let copyRequest = S3.CopyObjectRequest(
            bucket: S3BucketTrait.name,
            copySource: "\(S3BucketTrait.name)/\(keyName)",
            key: newKeyName
        )
        _ = try await s3.copyObject(copyRequest)
        let getResponse = try await s3.getObject(
            .init(bucket: S3BucketTrait.name, key: newKeyName, responseExpires: Date())
        )
        let responseContents = try await getResponse.body.collect(upTo: .max)
        #expect(String(buffer: responseContents) == contents)
        #expect(getResponse.lastModified != nil)
    }

    @Test(.s3Bucket)
    func testPutObjectChecksum() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let filename = "testfile.txt"
        let contents = "testing S3.PutObject and S3.GetObject"
        var response = try await s3.putObject(
            .init(
                body: .init(string: contents),
                bucket: S3BucketTrait.name,
                checksumAlgorithm: .crc32,
                key: filename
            )
        )
        #expect(response.checksumCRC32 == "Myi+ng==")
        response = try await s3.putObject(
            .init(
                body: .init(string: contents),
                bucket: S3BucketTrait.name,
                checksumAlgorithm: .crc32c,
                key: filename
            )
        )
        #expect(response.checksumCRC32C == "iHPfLQ==")
        response = try await s3.putObject(
            .init(
                body: .init(string: contents),
                bucket: S3BucketTrait.name,
                checksumAlgorithm: .sha256,
                key: filename
            )
        )
        #expect(response.checksumSHA256 == "KdsWZ5GWPwkbVNJptXFitMEbmWdL0ukIyJLCUo3lQ8w=")
        response = try await s3.putObject(
            .init(
                body: .init(string: contents),
                bucket: S3BucketTrait.name,
                checksumAlgorithm: .sha1,
                key: filename
            )
        )
        #expect(response.checksumSHA1 == "Ai2xMkIfITUzJLRnKXnoHFPhcSo=")
    }

    /// test uploaded objects are returned in ListObjects
    @Test(.s3Bucket)
    func testListObjects() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let contents = "testing S3.ListObjectsV2"
        let putRequest = S3.PutObjectRequest(
            body: .init(string: contents),
            bucket: S3BucketTrait.name,
            key: "objects"
        )
        let putResponse = try await s3.putObject(putRequest)
        let eTag = putResponse.eTag
        let listResponse = try await s3.listObjectsV2(.init(bucket: S3BucketTrait.name))
        #expect(listResponse.contents?.first?.key == "objects")
        #expect(listResponse.contents?.first?.size == Int64(contents.utf8.count))
        #expect(listResponse.contents?.first?.eTag == eTag)
        #expect(listResponse.contents?.first?.lastModified != nil)
        #expect(listResponse.contents?.first?.storageClass == .standard)
    }

    /// test 100-Complete header forces failed request to quit before uploading everything
    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Cannot test 100 reponses with localstack"))
    func testPut100Complete() async throws {
        struct Verify100CompleteMiddleware: AWSMiddlewareProtocol {
            func handle(
                _ request: AWSHTTPRequest,
                context: AWSMiddlewareContext,
                next: (AWSHTTPRequest, AWSMiddlewareContext) async throws -> AWSHTTPResponse
            ) async throws -> AWSHTTPResponse {
                // #expect(request.httpHeaders["Expect"].first == "100-continue")
                try await next(request, context)
            }
        }
        let s3 = S3(client: AWSClientTrait.client, region: .useast1, middleware: Verify100CompleteMiddleware())
        let name = TestEnvironment.generateResourceName()
        let chunkSize = 64 * 1024
        let byteBuffer = createRandomBuffer(size: 1 * 1024 * 1024)
        let count = ManagedAtomic(byteBuffer.readableBytes)
        // try await S3TestHelpers.testBucket(name, s3: s3) { name in
        let filename = "testfile.txt"
        let bufferSequence =
            byteBuffer
            .asyncSequence(chunkSize: chunkSize)
            .report { count.wrappingDecrement(by: $0.readableBytes, ordering: .relaxed) }

        let putRequest = S3.PutObjectRequest(
            body: .init(asyncSequence: bufferSequence, length: byteBuffer.readableBytes),
            bucket: name,
            key: filename
        )
        _ = try? await s3.putObject(putRequest)
        #expect(count.load(ordering: .relaxed) > 0)
    }

    /// test disable 100-Complete header
    @Test
    func testDisable100Complete() async throws {
        struct Disable100CompleteError: Error {
            let header: String?
        }
        struct Disable100CompleteMiddleware: AWSMiddlewareProtocol {
            func handle(
                _ request: AWSHTTPRequest,
                context: AWSMiddlewareContext,
                next: (AWSHTTPRequest, AWSMiddlewareContext) async throws -> AWSHTTPResponse
            ) async throws -> AWSHTTPResponse {
                throw Disable100CompleteError(header: request.headers[.expect])
            }
        }
        let s3 = S3(client: AWSClientTrait.client, region: .useast1, middleware: Disable100CompleteMiddleware(), options: .s3Disable100Continue)
        let name = TestEnvironment.generateResourceName()
        let byteBuffer = createRandomBuffer(size: 8 * 1024)

        let filename = "testfile.txt"
        let putRequest = S3.PutObjectRequest(
            body: .init(buffer: byteBuffer),
            bucket: name,
            key: filename
        )
        let error = await #expect(throws: Disable100CompleteError.self) { try await s3.putObject(putRequest) }
        #expect(error?.header == nil)

    }

    /// test lifecycle rules are uploaded and downloaded ok
    @Test(.s3Bucket)
    func testLifecycleRule() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        // set lifecycle rules
        // clear incomplete multipart uploads after 7 days
        let incompleteMultipartUploads = S3.AbortIncompleteMultipartUpload(daysAfterInitiation: 7)
        let filter = S3.LifecycleRuleFilter(prefix: "")  // everything
        let transitions = [S3.Transition(days: 14, storageClass: .glacier)]  // transition objects to glacier after 14 days
        let lifecycleRules = S3.LifecycleRule(
            abortIncompleteMultipartUpload: incompleteMultipartUploads,
            filter: filter,
            id: "aws-test",
            status: .enabled,
            transitions: transitions
        )
        let request = S3.PutBucketLifecycleConfigurationRequest(
            bucket: S3BucketTrait.name,
            lifecycleConfiguration: .init(rules: [lifecycleRules])
        )
        _ = try await s3.putBucketLifecycleConfiguration(request)

        let getResponse = try await s3.getBucketLifecycleConfiguration(.init(bucket: S3BucketTrait.name))
        #expect(getResponse.rules?[0].transitions?[0].storageClass == .glacier)
        #expect(getResponse.rules?[0].transitions?[0].days == 14)
        #expect(
            getResponse.rules?[0].abortIncompleteMultipartUpload?.daysAfterInitiation == 7
        )
    }

    @Test(.s3Bucket)
    func testMultipleUpload() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1, timeout: .seconds(120))
        _ = try await (0..<32).concurrentMap(maxConcurrentTasks: 8) {
            let body = "testMultipleUpload - " + $0.description
            let filename = "file" + $0.description
            _ = try await s3.putObject(
                .init(
                    body: .init(string: body),
                    bucket: S3BucketTrait.name,
                    key: filename
                )
            )
            let getResponse = try await s3.getObject(.init(bucket: S3BucketTrait.name, key: filename))
            let buffer = try await getResponse.body.collect(upTo: .max)
            #expect(String(buffer: buffer) == body)
        }
    }

    /// testing decoding of values in xml attributes
    @Test(.s3Bucket)
    func testGetAclRequestPayer() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let contents = "testing xml attributes header"

        let putRequest = S3.PutObjectRequest(
            body: .init(string: contents),
            bucket: S3BucketTrait.name,
            key: "acl-request-payer"
        )
        _ = try await s3.putObject(putRequest)
        let getACLResponse = try await s3.getObjectAcl(
            .init(bucket: S3BucketTrait.name, key: "acl-request-payer", requestPayer: .requester)
        )
        print(getACLResponse)
    }

    @Test(.s3Bucket)
    func testListPaginator() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        try await _ = (0..<16).concurrentMap {
            let body = "testMultipleUpload - " + $0.description
            let filename = "file" + $0.description
            _ = try await s3.putObject(
                .init(body: .init(string: body), bucket: S3BucketTrait.name, key: filename)
            )
        }

        let paginator = s3.listObjectsV2Paginator(.init(bucket: S3BucketTrait.name, maxKeys: 5))
        let contents =
            try await paginator
            .reduce([]) { ($1.contents ?? []) + $0 }
            .compactMap { $0.key != nil ? $0 : nil }
            .sorted { $0.key! < $1.key! }
        let listResponse = try await s3.listObjectsV2(.init(bucket: S3BucketTrait.name))
        let listContents = try #require(listResponse.contents)
            .compactMap { $0.key != nil ? $0 : nil }
            .sorted { $0.key! < $1.key! }

        #expect(contents.count == listContents.count)
        for i in 0..<contents.count {
            #expect(contents[i].key == listContents[i].key)
            #expect(contents[i].key == listContents[i].key)
        }
    }

    @Test(.s3Bucket)
    func testStreamPutObject() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1, timeout: .seconds(120))
        let chunkSize = 64 * 1024
        let byteBuffer = createRandomBuffer(size: 240 * 1024)

        try await self.testPutGetObject(
            filename: "testfile.txt",
            contents: .init(
                asyncSequence: byteBuffer.asyncSequence(chunkSize: chunkSize),
                length: byteBuffer.readableBytes
            ),
            s3: s3
        )
    }

    /// testing Date format in response headers
    @Test(.s3Bucket)
    func testMultipartAbortDate() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let rule = S3.LifecycleRule(
            abortIncompleteMultipartUpload: .init(daysAfterInitiation: 7),
            filter: .init(prefix: ""),
            id: "multipart-upload",
            status: .enabled
        )
        let request = S3.PutBucketLifecycleConfigurationRequest(
            bucket: S3BucketTrait.name,
            lifecycleConfiguration: .init(rules: [rule])
        )
        _ = try await s3.putBucketLifecycleConfiguration(request)

        let response = try await s3.createMultipartUpload(.init(bucket: S3BucketTrait.name, key: "test"))

        guard let uploadId = response.uploadId else { throw AWSResponseError.missingParameter }
        _ = try await s3.abortMultipartUpload(
            .init(bucket: S3BucketTrait.name, key: "test", uploadId: uploadId)
        )
    }

    @Test(
        .disabled(if: TestEnvironment.isUsingLocalstack, "Cannot test signing using localstack"),
        .s3Bucket
    )
    func testSignedURL() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let s3Url = URL(
            string: "https://\(S3BucketTrait.name).s3.us-east-1.amazonaws.com/\(S3BucketTrait.name)!=%+/(*)_.txt"
        )!

        let byteBuffer = createRandomBuffer(size: 186)
        let putRequest = HTTPRequest(method: .put, url: s3Url)
        let putURL = try await s3.signURL(
            request: putRequest,
            expires: .seconds(300)
        )
        var request = HTTPClientRequest(url: putURL.absoluteString)
        request.method = .PUT
        request.body = .bytes(byteBuffer)
        let response = try await HTTPClient.shared.execute(request, timeout: .minutes(1))
        #expect(response.status == .ok)

        let listResponse = try await s3.listObjectsV2(.init(bucket: S3BucketTrait.name))
        #expect(listResponse.contents?.first?.key == "\(S3BucketTrait.name)!=%+/(*)_.txt")

        let getRequest = HTTPRequest(method: .get, url: s3Url)

        let getURL = try await s3.signURL(
            request: getRequest,
            expires: .seconds(300)
        )
        let getResponse = try await HTTPClient.shared.execute(
            .init(url: getURL.absoluteString),
            timeout: .minutes(1)
        )

        let getBuffer = try await getResponse.body.collect(upTo: .max)
        #expect(response.status == .ok)
        #expect(byteBuffer == getBuffer)
    }

    @Test(
        .disabled(if: TestEnvironment.isUsingLocalstack, "Cannot test dual stack endoints using localstack"),
        .s3Bucket
    )
    func testDualStack() async throws {
        struct VerifyDualStackMiddleware: AWSMiddlewareProtocol {
            func handle(
                _ request: AWSHTTPRequest,
                context: AWSMiddlewareContext,
                next: (AWSHTTPRequest, AWSMiddlewareContext) async throws -> AWSHTTPResponse
            ) async throws -> AWSHTTPResponse {
                let url = try #require(request.request.url)
                let urlComp = url.absoluteString.split(separator: ".")[2]
                #expect(urlComp == "dualstack")
                return try await next(request, context)
            }
        }
        let s3 = S3(
            client: AWSClientTrait.client,
            region: .useast1,
            options: .useDualStackEndpoint
        ).with(middleware: VerifyDualStackMiddleware())

        try await self.testPutGetObject(
            filename: "testfile.txt",
            contents: .init(string: "testing S3.PutObject and S3.GetObject"),
            s3: s3
        )
    }

    @Test(
        .disabled(if: TestEnvironment.isUsingLocalstack, "Cannot test fips endoints using localstack"),
        .s3Bucket
    )
    func testFIPSEndpoints() async throws {
        struct VerifyFipsEndpointMiddleware: AWSMiddlewareProtocol {
            func handle(
                _ request: AWSHTTPRequest,
                context: AWSMiddlewareContext,
                next: (AWSHTTPRequest, AWSMiddlewareContext) async throws -> AWSHTTPResponse
            ) async throws -> AWSHTTPResponse {
                let url = try #require(request.request.url)
                let urlComp = url.absoluteString.split(separator: ".")[1]
                #expect(urlComp == "s3-fips")
                return try await next(request, context)
            }
        }
        let s3 = S3(
            client: AWSClientTrait.client,
            region: .useast1,
            options: .useFipsEndpoint
        ).with(middleware: VerifyFipsEndpointMiddleware())

        try await self.testPutGetObject(
            filename: "testfile.txt",
            contents: .init(string: "testing S3.PutObject and S3.GetObject"),
            s3: s3
        )
    }

    @Test(
        .disabled(if: TestEnvironment.isUsingLocalstack, "Cannot test transfer accelerated endoints using localstack"),
        .s3Bucket
    )
    func testTransferAccelerated() async throws {
        struct VerifyTransferAccelerateMiddleware: AWSMiddlewareProtocol {
            func handle(
                _ request: AWSHTTPRequest,
                context: AWSMiddlewareContext,
                next: (AWSHTTPRequest, AWSMiddlewareContext) async throws -> AWSHTTPResponse
            ) async throws -> AWSHTTPResponse {
                let url = try #require(request.request.url)
                let urlComp = url.absoluteString.split(separator: ".")[1]
                #expect(urlComp == "s3-accelerate")
                return try await next(request, context)
            }
        }
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let s3Accelerated = s3.with(middleware: VerifyTransferAccelerateMiddleware(), options: .s3UseTransferAcceleratedEndpoint)
        let filename = "testfile.txt"
        let contents = "testing S3.PutObject and S3.GetObject"
        // set acceleration configuration
        let request = S3.PutBucketAccelerateConfigurationRequest(
            accelerateConfiguration: .init(status: .enabled),
            bucket: S3BucketTrait.name
        )
        _ = try await s3.putBucketAccelerateConfiguration(request)

        let putRequest = S3.PutObjectRequest(
            body: .init(string: contents),
            bucket: S3BucketTrait.name,
            key: filename
        )
        let putResponse = try await s3Accelerated.putObject(putRequest)
        #expect(putResponse.eTag != nil)
        let getResponse = try await s3Accelerated.getObject(
            .init(bucket: S3BucketTrait.name, key: filename, responseExpires: Date())
        )
        let responseContents = try await getResponse.body.collect(upTo: .max)
        #expect(String(buffer: responseContents) == contents)
        #expect(getResponse.lastModified != nil)
    }

    @Test(.s3Bucket)
    func testWaiters() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let filename = "testfile.txt"
        let contents = "testing S3.PutObject and S3.GetObject"

        _ = try await s3.putObject(
            .init(body: .init(string: contents), bucket: S3BucketTrait.name, key: filename)
        )
        try await s3.waitUntilObjectExists(.init(bucket: S3BucketTrait.name, key: filename))

        _ = try await s3.deleteObject(.init(bucket: S3BucketTrait.name, key: filename))
        try await s3.waitUntilObjectNotExists(.init(bucket: S3BucketTrait.name, key: filename))
    }

    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Localstack returns the wrong error"))
    func testError() async {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let error = await #expect(throws: S3ErrorType.self) {
            _ = try await s3.deleteBucket(.init(bucket: "nosuch-bucket-name3458bjhdfgdf"))
        }
        switch error?.error {
        case .noSuchBucket:
            break
        default:
            Issue.record("Expected noSuchBucket, got \(String(describing: error?.error))")
        }
    }

    /// test S3 control host is prefixed with account id
    func testS3ControlPrefix() async throws {
        // don't actually want to make this API call so once I've checked the host is correct
        // I will throw an error in the request middleware
        struct CancelError: Error {}
        struct CheckHostMiddleware: AWSMiddlewareProtocol {
            func handle(
                _ request: AWSHTTPRequest,
                context: AWSMiddlewareContext,
                next: (AWSHTTPRequest, AWSMiddlewareContext) async throws -> AWSHTTPResponse
            ) async throws -> AWSHTTPResponse {
                #expect(request.request.authority?.hasPrefix("123456780123.") == true)
                throw CancelError()
            }
        }
        let s3Control = S3Control(client: AWSClientTrait.client, region: .euwest1, middleware: CheckHostMiddleware())
        let request = S3Control.ListJobsRequest(accountId: "123456780123")
        await #expect(throws: CancelError.self) {
            _ = try await s3Control.listJobs(request)
        }
    }

    @Test(
        .disabled(if: TestEnvironment.isUsingLocalstack, "Cannot test s3 express with localstack"),
        S3BucketTrait(
            name: "soto-test-directory-bucket--use1-az6--x-s3",
            createBucketConfiguration: .init(
                bucket: .init(dataRedundancy: .singleAvailabilityZone, type: .directory),
                location: .init(name: "use1-az6", type: .availabilityZone)
            )
        )
    )
    func testS3Express() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let (client, _expressS3) = s3.createS3ExpressClientAndService(bucket: S3BucketTrait.name)
        let expressS3 = _expressS3.with(middleware: TestEnvironment.middlewares)
        try await withTeardown {
            let putResponse = try await expressS3.putObject(
                body: .init(buffer: ByteBuffer(string: "Uploaded")),
                bucket: S3BucketTrait.name,
                key: "test-file",
                logger: TestEnvironment.logger
            )
            let listResponse = try await expressS3.listObjectsV2(
                bucket: S3BucketTrait.name,
                logger: TestEnvironment.logger
            )
            let testFile = try #require(listResponse.contents?.first { $0.eTag == putResponse.eTag }?.key)
            let getResponse = try await expressS3.getObject(
                bucket: S3BucketTrait.name,
                key: testFile,
                logger: TestEnvironment.logger
            )
            let body = try await getResponse.body.collect(upTo: .max)
            #expect(body == ByteBuffer(string: "Uploaded"))
        } teardown: {
            try? await client.shutdown()
        }
    }

    /// test S3 control host is prefixed with account id
    @Test(
        .disabled(if: TestEnvironment.isUsingLocalstack, "Cannot test s3 access points with localstack"),
        .s3Bucket
    )
    func testS3AccessPoints() async throws {
        let sts = STS(client: AWSClientTrait.client, region: .useast1)
        let identity = try await sts.getCallerIdentity()
        let accountId = try #require(identity.account)
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let s3Control = S3Control(client: AWSClientTrait.client, region: s3.region)
        try await testAsset {
            try await s3Control.createAccessPoint(
                accountId: accountId,
                bucket: S3BucketTrait.name,
                name: "test-accesspoint",
                logger: TestEnvironment.logger
            )
        } test: { response in
            let accessPointArn = try #require(response.accessPointArn)
            let alias = try #require(response.alias)
            let string = "testing S3.PutObject and S3.GetObject"
            // upload using arn
            _ = try await s3.putObject(body: .init(string: string), bucket: accessPointArn, key: S3BucketTrait.name, logger: TestEnvironment.logger)
            // download using alias
            let getObjectResponse = try await s3.getObject(bucket: alias, key: S3BucketTrait.name, logger: TestEnvironment.logger)
            let body = try await getObjectResponse.body.collect(upTo: .max)
            #expect(String(buffer: body) == string)
        } delete: { response in
            try await s3Control.deleteAccessPoint(accountId: accountId, name: "test-accesspoint", logger: TestEnvironment.logger)
        }
    }
}

/// Create temporary s3 bucket to be used by either a test or suite
struct S3BucketTrait: TestScoping, SuiteTrait, TestTrait {
    @TaskLocal
    static var _name: String?

    static var name: String {
        guard let _name else { fatalError("Test needs a S3BucketTrait") }
        return _name
    }

    let bucketName: String?
    let createBucketConfiguration: S3.CreateBucketConfiguration?

    init(name: String? = nil, createBucketConfiguration: S3.CreateBucketConfiguration? = nil) {
        self.bucketName = name
        self.createBucketConfiguration = createBucketConfiguration
    }

    func provideScope(for test: Test, testCase: Test.Case?, performing function: @concurrent @Sendable () async throws -> Void) async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let name = self.bucketName ?? TestEnvironment.generateResourceName(test.name)
        let input = S3.CreateBucketRequest(bucket: name, createBucketConfiguration: self.createBucketConfiguration)
        try await testAsset {
            try await Self.createBucket(input: input, s3: s3)
        } test: {
            try await S3BucketTrait.$_name.withValue(name) {
                try await function()
            }
        } delete: {
            _ = try await Self.deleteBucket(name: name, s3: s3)
        }
    }

    static func createBucket(input: S3.CreateBucketRequest, s3: S3) async throws {
        do {
            _ = try await s3.createBucket(input, logger: TestEnvironment.logger)
            try await s3.waitUntilBucketExists(.init(bucket: input.bucket), logger: TestEnvironment.logger)
        } catch let error as S3ErrorType {
            switch error.error {
            case .bucketAlreadyOwnedByYou:
                break
            default:
                throw error
            }
        }
    }

    static func deleteBucket(name: String, s3: S3) async throws {
        let response = try await s3.listObjectsV2(
            .init(bucket: name),
            logger: TestEnvironment.logger
        )
        if let contents = response.contents {
            let request = S3.DeleteObjectsRequest(
                bucket: name,
                delete: S3.Delete(objects: contents.compactMap { $0.key.map { .init(key: $0) } })
            )
            _ = try await s3.deleteObjects(request, logger: TestEnvironment.logger)
        }
        try await s3.deleteBucket(.init(bucket: name), logger: TestEnvironment.logger)
    }
}

extension TestTrait where Self == S3BucketTrait {
    /// Provide a temporary s3 bucket. Bucket name is accessible from `S3BucketTrait.name`
    static var s3Bucket: Self { S3BucketTrait() }
}
