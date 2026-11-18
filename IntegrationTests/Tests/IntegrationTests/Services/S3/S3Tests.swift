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
import Testing

@testable import SotoCore

@Suite(.awsClient())
struct S3Tests {
    var randomBytes: ByteBuffer {
        self.createRandomBuffer(size: 11 * 1024 * 1024)
    }
    func createRandomBuffer(size: Int) -> ByteBuffer {
        // create buffer
        var data = [UInt8](repeating: 0, count: size)
        for i in 0..<size {
            data[i] = UInt8.random(in: 0...255)
        }
        return ByteBuffer(bytes: data)
    }

    static func createBucket(name: String, createBucketConfiguration: S3.CreateBucketConfiguration? = nil, s3: S3) async throws {
        do {
            _ = try await s3.createBucket(bucket: name, createBucketConfiguration: createBucketConfiguration, logger: TestEnvironment.logger)
            try await s3.waitUntilBucketExists(.init(bucket: name), logger: TestEnvironment.logger)
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

    /// create S3 bucket with supplied name and run supplied closure
    func testBucket(
        _ name: String,
        createBucketConfiguration: S3.CreateBucketConfiguration? = nil,
        s3: S3,
        test: @escaping (String) async throws -> Void
    )
        async throws
    {
        try await testAsset {
            try await Self.createBucket(name: name, createBucketConfiguration: createBucketConfiguration, s3: s3)
            return name
        } test: {
            try await test($0)
        } delete: { (name: String) in
            try await Self.deleteBucket(name: name, s3: s3)
        }
    }

    /// Test putObject to S3 and that getObject returns the same object
    func testPutGetObject(
        bucket: String,
        filename: String,
        contents: AWSHTTPBody,
        s3: S3
    ) async throws {
        try await self.testBucket(bucket, s3: s3) { name in
            let putRequest = S3.PutObjectRequest(
                body: contents,
                bucket: name,
                key: filename
            )
            let putResponse = try await s3.putObject(putRequest)
            #expect(putResponse.eTag != nil)
            let getResponse = try await s3.getObject(
                .init(bucket: name, key: filename, responseExpires: Date())
            )
            let requestContents = try await contents.collect(upTo: .max)
            let responseContents = try await getResponse.body.collect(upTo: .max)
            #expect(responseContents == requestContents)
            #expect(getResponse.lastModified != nil)
        }
    }

    // MARK: TESTS

    @Test func testPutGetObject() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let name = TestEnvironment.generateResourceName()
        try await self.testPutGetObject(
            bucket: name,
            filename: "testfile.txt",
            contents: .init(string: "testing S3.PutObject and S3.GetObject"),
            s3: s3
        )
    }

    @Test func testPutGetObjectWithSpecialName() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let name = TestEnvironment.generateResourceName()
        let filename =
            if TestEnvironment.isUsingLocalstack {
                "test $filé+!@£$%^&*()_=-[]{}\\|';:\",./?><~`.txt"
            } else {
                "test $filé+!@£$%2F%^&*()_=-[]{}\\|';:\",./?><~`.txt"
            }
        try await self.testPutGetObject(
            bucket: name,
            filename: filename,
            contents: .init(string: "testing S3.PutObject and S3.GetObject"),
            s3: s3
        )
    }

    @Test func testCopy() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let name = TestEnvironment.generateResourceName()
        try await self.testBucket(name, s3: s3) { name in
            let keyName = "file1"
            let newKeyName = "file2"
            let contents = "testing S3.PutObject and S3.GetObject"
            let putRequest = S3.PutObjectRequest(
                body: .init(string: contents),
                bucket: name,
                key: keyName
            )
            let putResponse = try await s3.putObject(putRequest)
            #expect(putResponse.eTag != nil)
            let copyRequest = S3.CopyObjectRequest(
                bucket: name,
                copySource: "\(name)/\(keyName)",
                key: newKeyName
            )
            _ = try await s3.copyObject(copyRequest)
            let getResponse = try await s3.getObject(
                .init(bucket: name, key: newKeyName, responseExpires: Date())
            )
            let responseContents = try await getResponse.body.collect(upTo: .max)
            #expect(String(buffer: responseContents) == contents)
            #expect(getResponse.lastModified != nil)
        }
    }

    @Test func testPutObjectChecksum() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let name = TestEnvironment.generateResourceName()
        try await self.testBucket(name, s3: s3) { name in
            let filename = "testfile.txt"
            let contents = "testing S3.PutObject and S3.GetObject"
            var response = try await s3.putObject(
                .init(
                    body: .init(string: contents),
                    bucket: name,
                    checksumAlgorithm: .crc32,
                    key: filename
                )
            )
            #expect(response.checksumCRC32 == "Myi+ng==")
            response = try await s3.putObject(
                .init(
                    body: .init(string: contents),
                    bucket: name,
                    checksumAlgorithm: .crc32c,
                    key: filename
                )
            )
            #expect(response.checksumCRC32C == "iHPfLQ==")
            response = try await s3.putObject(
                .init(
                    body: .init(string: contents),
                    bucket: name,
                    checksumAlgorithm: .sha256,
                    key: filename
                )
            )
            #expect(response.checksumSHA256 == "KdsWZ5GWPwkbVNJptXFitMEbmWdL0ukIyJLCUo3lQ8w=")
            response = try await s3.putObject(
                .init(
                    body: .init(string: contents),
                    bucket: name,
                    checksumAlgorithm: .sha1,
                    key: filename
                )
            )
            #expect(response.checksumSHA1 == "Ai2xMkIfITUzJLRnKXnoHFPhcSo=")
        }
    }

    /// test uploaded objects are returned in ListObjects
    @Test func testListObjects() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let name = TestEnvironment.generateResourceName()
        let contents = "testing S3.ListObjectsV2"
        try await self.testBucket(name, s3: s3) { name in
            let putRequest = S3.PutObjectRequest(
                body: .init(string: contents),
                bucket: name,
                key: name
            )
            let putResponse = try await s3.putObject(putRequest)
            let eTag = putResponse.eTag
            let listResponse = try await s3.listObjectsV2(.init(bucket: name))
            #expect(listResponse.contents?.first?.key == name)
            #expect(listResponse.contents?.first?.size == Int64(contents.utf8.count))
            #expect(listResponse.contents?.first?.eTag == eTag)
            #expect(listResponse.contents?.first?.lastModified != nil)
            #expect(listResponse.contents?.first?.storageClass == .standard)
        }
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
        let byteBuffer = self.createRandomBuffer(size: 1 * 1024 * 1024)
        let count = ManagedAtomic(byteBuffer.readableBytes)
        // try await self.testBucket(name, s3: s3) { name in
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
    @Test func testDisable100Complete() async throws {
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
        let byteBuffer = self.createRandomBuffer(size: 8 * 1024)

        do {
            let filename = "testfile.txt"
            let putRequest = S3.PutObjectRequest(
                body: .init(buffer: byteBuffer),
                bucket: name,
                key: filename
            )
            _ = try await s3.putObject(putRequest)
        } catch let error as Disable100CompleteError {
            #expect(error.header == nil)
        }
    }

    /// test lifecycle rules are uploaded and downloaded ok
    @Test func testLifecycleRule() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let name = TestEnvironment.generateResourceName()
        try await self.testBucket(name, s3: s3) { name in
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
                bucket: name,
                lifecycleConfiguration: .init(rules: [lifecycleRules])
            )
            _ = try await s3.putBucketLifecycleConfiguration(request)

            let getResponse = try await s3.getBucketLifecycleConfiguration(.init(bucket: name))
            #expect(getResponse.rules?[0].transitions?[0].storageClass == .glacier)
            #expect(getResponse.rules?[0].transitions?[0].days == 14)
            #expect(
                getResponse.rules?[0].abortIncompleteMultipartUpload?.daysAfterInitiation == 7
            )
        }
    }

    @Test func testMultipleUpload() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1, timeout: .seconds(120))
        let name = TestEnvironment.generateResourceName()
        try await self.testBucket(name, s3: s3) { name in
            _ = try await (0..<32).concurrentMap(maxConcurrentTasks: 8) {
                let body = "testMultipleUpload - " + $0.description
                let filename = "file" + $0.description
                _ = try await s3.putObject(
                    .init(
                        body: .init(string: body),
                        bucket: name,
                        key: filename
                    )
                )
                let getResponse = try await s3.getObject(.init(bucket: name, key: filename))
                let buffer = try await getResponse.body.collect(upTo: .max)
                #expect(String(buffer: buffer) == body)
            }
        }
    }

    /// testing decoding of values in xml attributes
    @Test func testGetAclRequestPayer() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let name = TestEnvironment.generateResourceName()
        let contents = "testing xml attributes header"

        try await self.testBucket(name, s3: s3) { name in
            let putRequest = S3.PutObjectRequest(
                body: .init(string: contents),
                bucket: name,
                key: name
            )
            _ = try await s3.putObject(putRequest)
            let getACLResponse = try await s3.getObjectAcl(
                .init(bucket: name, key: name, requestPayer: .requester)
            )
            print(getACLResponse)
        }
    }

    @Test func testListPaginator() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let name = TestEnvironment.generateResourceName()
        try await self.testBucket(name, s3: s3) { name in
            try await _ = (0..<16).concurrentMap {
                let body = "testMultipleUpload - " + $0.description
                let filename = "file" + $0.description
                _ = try await s3.putObject(
                    .init(body: .init(string: body), bucket: name, key: filename)
                )
            }

            let paginator = s3.listObjectsV2Paginator(.init(bucket: name, maxKeys: 5))
            let contents =
                try await paginator
                .reduce([]) { ($1.contents ?? []) + $0 }
                .compactMap { $0.key != nil ? $0 : nil }
                .sorted { $0.key! < $1.key! }
            let listResponse = try await s3.listObjectsV2(.init(bucket: name))
            let listContents = try #require(listResponse.contents)
                .compactMap { $0.key != nil ? $0 : nil }
                .sorted { $0.key! < $1.key! }

            #expect(contents.count == listContents.count)
            for i in 0..<contents.count {
                #expect(contents[i].key == listContents[i].key)
                #expect(contents[i].key == listContents[i].key)
            }
        }
    }

    @Test func testStreamPutObject() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1, timeout: .seconds(120))
        let name = TestEnvironment.generateResourceName()
        let chunkSize = 64 * 1024
        let byteBuffer = self.createRandomBuffer(size: 240 * 1024)

        try await self.testPutGetObject(
            bucket: name,
            filename: "testfile.txt",
            contents: .init(
                asyncSequence: byteBuffer.asyncSequence(chunkSize: chunkSize),
                length: byteBuffer.readableBytes
            ),
            s3: s3
        )
    }

    /// testing Date format in response headers
    @Test func testMultipartAbortDate() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let name = TestEnvironment.generateResourceName()

        try await self.testBucket(name, s3: s3) { name in
            let rule = S3.LifecycleRule(
                abortIncompleteMultipartUpload: .init(daysAfterInitiation: 7),
                filter: .init(prefix: ""),
                id: "multipart-upload",
                status: .enabled
            )
            let request = S3.PutBucketLifecycleConfigurationRequest(
                bucket: name,
                lifecycleConfiguration: .init(rules: [rule])
            )
            _ = try await s3.putBucketLifecycleConfiguration(request)

            let response = try await s3.createMultipartUpload(.init(bucket: name, key: "test"))

            guard let uploadId = response.uploadId else { throw AWSResponseError.missingParameter }
            _ = try await s3.abortMultipartUpload(
                .init(bucket: name, key: "test", uploadId: uploadId)
            )
        }
    }

    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Cannot test signing using localstack"))
    func testSignedURL() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let name = TestEnvironment.generateResourceName()
        let s3Url = URL(
            string: "https://\(name).s3.us-east-1.amazonaws.com/\(name)!=%+/(*)_.txt"
        )!

        try await self.testBucket(name, s3: s3) { _ in
            let byteBuffer = self.createRandomBuffer(size: 186)
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

            let listResponse = try await s3.listObjectsV2(.init(bucket: name))
            #expect(listResponse.contents?.first?.key == "\(name)!=%+/(*)_.txt")

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
    }

    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Cannot test dual stack endoints using localstack"))
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
        let name = TestEnvironment.generateResourceName()

        try await self.testPutGetObject(
            bucket: name,
            filename: "testfile.txt",
            contents: .init(string: "testing S3.PutObject and S3.GetObject"),
            s3: s3
        )
    }

    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Cannot test fips endoints using localstack"))
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
        let name = TestEnvironment.generateResourceName()

        try await self.testPutGetObject(
            bucket: name,
            filename: "testfile.txt",
            contents: .init(string: "testing S3.PutObject and S3.GetObject"),
            s3: s3
        )
    }

    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Cannot test transfer accelerated endoints using localstack"))
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
        let name = TestEnvironment.generateResourceName()
        try await self.testBucket(name, s3: s3) { name in
            let filename = "testfile.txt"
            let contents = "testing S3.PutObject and S3.GetObject"
            // set acceleration configuration
            let request = S3.PutBucketAccelerateConfigurationRequest(
                accelerateConfiguration: .init(status: .enabled),
                bucket: name
            )
            _ = try await s3.putBucketAccelerateConfiguration(request)

            let putRequest = S3.PutObjectRequest(
                body: .init(string: contents),
                bucket: name,
                key: filename
            )
            let putResponse = try await s3Accelerated.putObject(putRequest)
            #expect(putResponse.eTag != nil)
            let getResponse = try await s3Accelerated.getObject(
                .init(bucket: name, key: filename, responseExpires: Date())
            )
            let responseContents = try await getResponse.body.collect(upTo: .max)
            #expect(String(buffer: responseContents) == contents)
            #expect(getResponse.lastModified != nil)
        }
    }

    @Test func testWaiters() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let name = TestEnvironment.generateResourceName()
        try await self.testBucket(name, s3: s3) { _ in
            let filename = "testfile.txt"
            let contents = "testing S3.PutObject and S3.GetObject"

            _ = try await s3.putObject(
                .init(body: .init(string: contents), bucket: name, key: filename)
            )
            try await s3.waitUntilObjectExists(.init(bucket: name, key: filename))

            _ = try await s3.deleteObject(.init(bucket: name, key: filename))
            try await s3.waitUntilObjectNotExists(.init(bucket: name, key: filename))
        }
    }

    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Localstack returns the wrong error"))
    func testError() async {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        let error = await XCTAsyncExpectError(S3ErrorType.self) {
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
    @Test func testS3ControlPrefix() async throws {
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
        do {
            _ = try await s3Control.listJobs(request)
        } catch is CancelError {}
    }

    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Cannot test s3 express with localstack"))
    func testS3Express() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        // doesnt work with LocalStack
        let bucket = "soto-test-directory-bucket--use1-az6--x-s3"
        try await testBucket(
            bucket,
            createBucketConfiguration: .init(
                bucket: .init(dataRedundancy: .singleAvailabilityZone, type: .directory),
                location: .init(name: "use1-az6", type: .availabilityZone)
            ),
            s3: s3
        ) { bucket in
            let (client, _expressS3) = s3.createS3ExpressClientAndService(bucket: bucket)
            let expressS3 = _expressS3.with(middleware: TestEnvironment.middlewares)
            try await withTeardown {
                let putResponse = try await expressS3.putObject(
                    body: .init(buffer: ByteBuffer(string: "Uploaded")),
                    bucket: bucket,
                    key: "test-file",
                    logger: TestEnvironment.logger
                )
                let listResponse = try await expressS3.listObjectsV2(
                    bucket: bucket,
                    logger: TestEnvironment.logger
                )
                let testFile = try #require(listResponse.contents?.first { $0.eTag == putResponse.eTag }?.key)
                let getResponse = try await expressS3.getObject(
                    bucket: bucket,
                    key: testFile,
                    logger: TestEnvironment.logger
                )
                let body = try await getResponse.body.collect(upTo: .max)
                #expect(body == ByteBuffer(string: "Uploaded"))

                _ = try await expressS3.deleteObject(bucket: bucket, key: "test-file", logger: TestEnvironment.logger)
            } teardown: {
                try? await client.shutdown()
            }
        }
    }

    /// test S3 control host is prefixed with account id
    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Cannot test s3 access points with localstack"))
    func testS3AccessPoints() async throws {
        let s3 = S3(client: AWSClientTrait.client, region: .useast1)
        guard let accountId = Environment["AWS_ACCOUNT_ID"] else {
            Issue.record("Require AWS_ACCOUNT_ID environment variable", severity: .warning)
            return
        }
        let name = TestEnvironment.generateResourceName()
        try await self.testBucket(name, s3: s3) { name in
            let s3Control = S3Control(client: AWSClientTrait.client, region: s3.region)
            let response = try await s3Control.createAccessPoint(
                accountId: accountId,
                bucket: name,
                name: "test-accesspoint",
                logger: TestEnvironment.logger
            )
            return try await withTeardown {
                let accessPointArn = try #require(response.accessPointArn)
                let alias = try #require(response.alias)
                let string = "testing S3.PutObject and S3.GetObject"
                // upload using arn
                _ = try await s3.putObject(body: .init(string: string), bucket: accessPointArn, key: name, logger: TestEnvironment.logger)
                // download using alias
                let getObjectResponse = try await s3.getObject(bucket: alias, key: name, logger: TestEnvironment.logger)
                let body = try await getObjectResponse.body.collect(upTo: .max)
                #expect(String(buffer: body) == string)
            } teardown: {
                try? await s3Control.deleteAccessPoint(accountId: accountId, name: "test-accesspoint", logger: TestEnvironment.logger)
            }
        }
    }
}
