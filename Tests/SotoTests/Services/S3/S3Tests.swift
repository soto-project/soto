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
import NIOCore
import NIOPosix
import XCTest

@testable import SotoCore
@testable import SotoS3
@testable import SotoS3Control

class S3Tests: XCTestCase {
    static var client: AWSClient!
    static var s3: S3!
    static var randomBytes: ByteBuffer!

    override class func setUp() {
        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }

        self.client = AWSClient(
            credentialProvider: TestEnvironment.credentialProvider,
            middleware: TestEnvironment.middlewares
        )
        self.s3 = S3(
            client: self.client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
        self.randomBytes = self.createRandomBuffer(size: 11 * 1024 * 1024)
    }

    override class func tearDown() {
        XCTAssertNoThrow(try self.client.syncShutdown())
    }

    static func createRandomBuffer(size: Int) -> ByteBuffer {
        // create buffer
        var data = [UInt8](repeating: 0, count: size)
        for i in 0..<size {
            data[i] = UInt8.random(in: 0...255)
        }
        return ByteBuffer(bytes: data)
    }

    static func createBucket(name: String, s3: S3) async throws {
        let bucketRequest = S3.CreateBucketRequest(bucket: name)
        do {
            _ = try await s3.createBucket(bucketRequest, logger: TestEnvironment.logger)
            try await s3.waitUntilBucketExists(.init(bucket: name), logger: TestEnvironment.logger)
        } catch let error as S3ErrorType where error == .bucketAlreadyOwnedByYou {}
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
        s3: S3? = nil,
        test: @escaping (String) async throws -> Void
    )
        async throws
    {
        let s3 = s3 ?? Self.s3!
        try await XCTTestAsset {
            try await Self.createBucket(name: name, s3: s3)
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
        s3: S3? = nil
    )
        async throws
    {
        let s3 = s3 ?? Self.s3!
        try await self.testBucket(bucket, s3: s3) { name in
            let putRequest = S3.PutObjectRequest(
                body: contents,
                bucket: name,
                key: filename
            )
            let putResponse = try await s3.putObject(putRequest)
            XCTAssertNotNil(putResponse.eTag)
            let getResponse = try await s3.getObject(
                .init(bucket: name, key: filename, responseExpires: Date())
            )
            let requestContents = try await contents.collect(upTo: .max)
            let responseContents = try await getResponse.body.collect(upTo: .max)
            XCTAssertEqual(responseContents, requestContents)
            XCTAssertNotNil(getResponse.lastModified)
        }
    }

    // MARK: TESTS

    func testPutGetObject() async throws {
        let name = TestEnvironment.generateResourceName()
        try await self.testPutGetObject(
            bucket: name,
            filename: "testfile.txt",
            contents: .init(string: "testing S3.PutObject and S3.GetObject")
        )
    }

    func testPutGetObjectWithSpecialName() async throws {
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
            contents: .init(string: "testing S3.PutObject and S3.GetObject")
        )
    }

    func testCopy() async throws {
        let name = TestEnvironment.generateResourceName()
        try await self.testBucket(name) { name in
            let keyName = "file1"
            let newKeyName = "file2"
            let contents = "testing S3.PutObject and S3.GetObject"
            let putRequest = S3.PutObjectRequest(
                body: .init(string: contents),
                bucket: name,
                key: keyName
            )
            let putResponse = try await Self.s3.putObject(putRequest)
            XCTAssertNotNil(putResponse.eTag)
            let copyRequest = S3.CopyObjectRequest(
                bucket: name,
                copySource: "\(name)/\(keyName)",
                key: newKeyName
            )
            _ = try await Self.s3.copyObject(copyRequest)
            let getResponse = try await Self.s3.getObject(
                .init(bucket: name, key: newKeyName, responseExpires: Date())
            )
            let responseContents = try await getResponse.body.collect(upTo: .max)
            XCTAssertEqual(String(buffer: responseContents), contents)
            XCTAssertNotNil(getResponse.lastModified)
        }
    }

    func testPutObjectChecksum() async throws {
        let name = TestEnvironment.generateResourceName()
        try await self.testBucket(name) { name in
            let filename = "testfile.txt"
            let contents = "testing S3.PutObject and S3.GetObject"
            var response = try await Self.s3.putObject(
                .init(
                    body: .init(string: contents),
                    bucket: name,
                    checksumAlgorithm: .crc32,
                    key: filename
                )
            )
            XCTAssertEqual(response.checksumCRC32, "Myi+ng==")
            response = try await Self.s3.putObject(
                .init(
                    body: .init(string: contents),
                    bucket: name,
                    checksumAlgorithm: .crc32c,
                    key: filename
                )
            )
            XCTAssertEqual(response.checksumCRC32C, "iHPfLQ==")
            response = try await Self.s3.putObject(
                .init(
                    body: .init(string: contents),
                    bucket: name,
                    checksumAlgorithm: .sha256,
                    key: filename
                )
            )
            XCTAssertEqual(response.checksumSHA256, "KdsWZ5GWPwkbVNJptXFitMEbmWdL0ukIyJLCUo3lQ8w=")
            response = try await Self.s3.putObject(
                .init(
                    body: .init(string: contents),
                    bucket: name,
                    checksumAlgorithm: .sha1,
                    key: filename
                )
            )
            XCTAssertEqual(response.checksumSHA1, "Ai2xMkIfITUzJLRnKXnoHFPhcSo=")
        }
    }

    /// test uploaded objects are returned in ListObjects
    func testListObjects() async throws {
        let name = TestEnvironment.generateResourceName()
        let contents = "testing S3.ListObjectsV2"
        try await self.testBucket(name) { name in
            let putRequest = S3.PutObjectRequest(
                body: .init(string: contents),
                bucket: name,
                key: name
            )
            let putResponse = try await Self.s3.putObject(putRequest)
            let eTag = putResponse.eTag
            let listResponse = try await Self.s3.listObjectsV2(.init(bucket: name))
            XCTAssertEqual(listResponse.contents?.first?.key, name)
            XCTAssertEqual(listResponse.contents?.first?.size, Int64(contents.utf8.count))
            XCTAssertEqual(listResponse.contents?.first?.eTag, eTag)
            XCTAssertNotNil(listResponse.contents?.first?.lastModified)
        }
    }

    /// test 100-Complete header forces failed request to quit before uploading everything
    func testPut100Complete() async throws {
        // doesnt work with LocalStack
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)

        struct Verify100CompleteMiddleware: AWSMiddlewareProtocol {
            func handle(
                _ request: AWSHTTPRequest,
                context: AWSMiddlewareContext,
                next: (AWSHTTPRequest, AWSMiddlewareContext) async throws -> AWSHTTPResponse
            ) async throws -> AWSHTTPResponse {
                // XCTAssertEqual(request.httpHeaders["Expect"].first, "100-continue")
                try await next(request, context)
            }
        }
        let s3 = Self.s3.with(middleware: Verify100CompleteMiddleware())
        let name = TestEnvironment.generateResourceName()
        let chunkSize = 64 * 1024
        let byteBuffer = Self.createRandomBuffer(size: 1 * 1024 * 1024)
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
        XCTAssertGreaterThan(count.load(ordering: .relaxed), 0)
    }

    /// test disable 100-Complete header
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
                throw Disable100CompleteError(header: request.headers["Expect"].first)
            }
        }
        let s3 = Self.s3.with(
            middleware: Disable100CompleteMiddleware(),
            options: .s3Disable100Continue
        )
        let name = TestEnvironment.generateResourceName()
        let byteBuffer = Self.createRandomBuffer(size: 8 * 1024)

        do {
            let filename = "testfile.txt"
            let putRequest = S3.PutObjectRequest(
                body: .init(buffer: byteBuffer),
                bucket: name,
                key: filename
            )
            _ = try await s3.putObject(putRequest)
        } catch let error as Disable100CompleteError {
            XCTAssertNil(error.header)
        }
    }

    /// test lifecycle rules are uploaded and downloaded ok
    func testLifecycleRule() async throws {
        let name = TestEnvironment.generateResourceName()
        try await self.testBucket(name) { name in
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
            _ = try await Self.s3.putBucketLifecycleConfiguration(request)

            let getResponse = try await Self.s3.getBucketLifecycleConfiguration(.init(bucket: name))
            XCTAssertEqual(getResponse.rules?[0].transitions?[0].storageClass, .glacier)
            XCTAssertEqual(getResponse.rules?[0].transitions?[0].days, 14)
            XCTAssertEqual(
                getResponse.rules?[0].abortIncompleteMultipartUpload?.daysAfterInitiation,
                7
            )
        }
    }

    func testMultipleUpload() async throws {
        let name = TestEnvironment.generateResourceName()
        try await self.testBucket(name, s3: Self.s3.with(timeout: .minutes(2))) { name in
            _ = try await (0..<32).concurrentMap(maxConcurrentTasks: 8) {
                let body = "testMultipleUpload - " + $0.description
                let filename = "file" + $0.description
                _ = try await Self.s3.putObject(
                    .init(
                        body: .init(string: body),
                        bucket: name,
                        key: filename
                    )
                )
                let getResponse = try await Self.s3.getObject(.init(bucket: name, key: filename))
                let buffer = try await getResponse.body.collect(upTo: .max)
                XCTAssertEqual(String(buffer: buffer), body)
            }
        }
    }

    /// testing decoding of values in xml attributes
    func testGetAclRequestPayer() async throws {
        let name = TestEnvironment.generateResourceName()
        let contents = "testing xml attributes header"

        try await testBucket(name) { name in
            let putRequest = S3.PutObjectRequest(
                body: .init(string: contents),
                bucket: name,
                key: name
            )
            _ = try await Self.s3.putObject(putRequest)
            let getACLResponse = try await Self.s3.getObjectAcl(
                .init(bucket: name, key: name, requestPayer: .requester)
            )
            print(getACLResponse)
        }
    }

    func testListPaginator() async throws {
        let name = TestEnvironment.generateResourceName()
        try await self.testBucket(name) { name in
            try await _ = (0..<16).concurrentMap {
                let body = "testMultipleUpload - " + $0.description
                let filename = "file" + $0.description
                _ = try await Self.s3.putObject(
                    .init(body: .init(string: body), bucket: name, key: filename)
                )
            }

            let paginator = Self.s3.listObjectsV2Paginator(.init(bucket: name, maxKeys: 5))
            let contents =
                try await paginator
                .reduce([]) { ($1.contents ?? []) + $0 }
                .compactMap { $0.key != nil ? $0 : nil }
                .sorted { $0.key! < $1.key! }
            let listResponse = try await Self.s3.listObjectsV2(.init(bucket: name))
            let listContents = try XCTUnwrap(listResponse.contents)
                .compactMap { $0.key != nil ? $0 : nil }
                .sorted { $0.key! < $1.key! }

            XCTAssertEqual(contents.count, listContents.count)
            for i in 0..<contents.count {
                XCTAssertEqual(contents[i].key, listContents[i].key)
                XCTAssertEqual(contents[i].key, listContents[i].key)
            }
        }
    }

    func testStreamPutObject() async throws {
        let s3 = Self.s3.with(timeout: .minutes(2))
        let name = TestEnvironment.generateResourceName()
        let chunkSize = 64 * 1024
        let byteBuffer = Self.createRandomBuffer(size: 240 * 1024)

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
    func testMultipartAbortDate() async throws {
        let name = TestEnvironment.generateResourceName()

        try await self.testBucket(name) { name in
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
            _ = try await Self.s3.putBucketLifecycleConfiguration(request)

            let response = try await Self.s3.createMultipartUpload(.init(bucket: name, key: "test"))

            guard let uploadId = response.uploadId else { throw AWSClientError.missingParameter }
            _ = try await Self.s3.abortMultipartUpload(
                .init(bucket: name, key: "test", uploadId: uploadId)
            )
        }
    }

    func testSignedURL() async throws {
        // doesnt work with LocalStack
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)

        let name = TestEnvironment.generateResourceName()
        let s3Url = URL(
            string: "https://\(name).s3.us-east-1.amazonaws.com/\(name)!=%25+/(*)_.txt"
        )!

        try await testBucket(name) { _ in
            let byteBuffer = Self.createRandomBuffer(size: 186)
            let putURL = try await Self.s3.signURL(
                url: s3Url,
                httpMethod: .PUT,
                expires: .minutes(5)
            )
            var request = HTTPClientRequest(url: putURL.absoluteString)
            request.method = .PUT
            request.body = .bytes(byteBuffer)
            let response = try await HTTPClient.shared.execute(request, timeout: .minutes(1))
            XCTAssertEqual(response.status, .ok)

            let listResponse = try await Self.s3.listObjectsV2(.init(bucket: name))
            XCTAssertEqual(listResponse.contents?.first?.key, "\(name)!=%+/(*)_.txt")

            let getURL = try await Self.s3.signURL(
                url: s3Url,
                httpMethod: .GET,
                expires: .minutes(5)
            )
            let getResponse = try await HTTPClient.shared.execute(
                .init(url: getURL.absoluteString),
                timeout: .minutes(1)
            )

            let getBuffer = try await getResponse.body.collect(upTo: .max)
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(byteBuffer, getBuffer)
        }
    }

    func testDualStack() async throws {
        struct VerifyDualStackMiddleware: AWSMiddlewareProtocol {
            func handle(
                _ request: AWSHTTPRequest,
                context: AWSMiddlewareContext,
                next: (AWSHTTPRequest, AWSMiddlewareContext) async throws -> AWSHTTPResponse
            ) async throws -> AWSHTTPResponse {
                XCTAssertEqual(request.url.absoluteString.split(separator: ".")[2], "dualstack")
                return try await next(request, context)
            }
        }
        // doesnt work with LocalStack
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)

        let s3 = Self.s3.with(
            middleware: VerifyDualStackMiddleware(),
            options: .useDualStackEndpoint
        )
        let name = TestEnvironment.generateResourceName()

        try await self.testPutGetObject(
            bucket: name,
            filename: "testfile.txt",
            contents: .init(string: "testing S3.PutObject and S3.GetObject"),
            s3: s3
        )
    }

    func testFIPSEndpoints() async throws {
        struct VerifyFipsEndpointMiddleware: AWSMiddlewareProtocol {
            func handle(
                _ request: AWSHTTPRequest,
                context: AWSMiddlewareContext,
                next: (AWSHTTPRequest, AWSMiddlewareContext) async throws -> AWSHTTPResponse
            ) async throws -> AWSHTTPResponse {
                XCTAssertEqual(request.url.absoluteString.split(separator: ".")[1], "s3-fips")
                return try await next(request, context)
            }
        }
        // doesnt work with LocalStack
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)

        let s3 = Self.s3.with(
            middleware: VerifyFipsEndpointMiddleware(),
            options: .useFipsEndpoint
        )
        let name = TestEnvironment.generateResourceName()

        try await self.testPutGetObject(
            bucket: name,
            filename: "testfile.txt",
            contents: .init(string: "testing S3.PutObject and S3.GetObject"),
            s3: s3
        )
    }

    func testTransferAccelerated() async throws {
        struct VerifyTransferAccelerateMiddleware: AWSMiddlewareProtocol {
            func handle(
                _ request: AWSHTTPRequest,
                context: AWSMiddlewareContext,
                next: (AWSHTTPRequest, AWSMiddlewareContext) async throws -> AWSHTTPResponse
            ) async throws -> AWSHTTPResponse {
                XCTAssertEqual(request.url.absoluteString.split(separator: ".")[1], "s3-accelerate")
                return try await next(request, context)
            }
        }
        // doesnt work with LocalStack
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)

        let s3Accelerated = Self.s3.with(
            middleware: VerifyTransferAccelerateMiddleware(),
            options: .s3UseTransferAcceleratedEndpoint
        )
        let name = TestEnvironment.generateResourceName()
        try await self.testBucket(name, s3: Self.s3) { name in
            let filename = "testfile.txt"
            let contents = "testing S3.PutObject and S3.GetObject"
            // set acceleration configuration
            let request = S3.PutBucketAccelerateConfigurationRequest(
                accelerateConfiguration: .init(status: .enabled),
                bucket: name
            )
            _ = try await Self.s3.putBucketAccelerateConfiguration(request)

            let putRequest = S3.PutObjectRequest(
                body: .init(string: contents),
                bucket: name,
                key: filename
            )
            let putResponse = try await s3Accelerated.putObject(putRequest)
            XCTAssertNotNil(putResponse.eTag)
            let getResponse = try await s3Accelerated.getObject(
                .init(bucket: name, key: filename, responseExpires: Date())
            )
            let responseContents = try await getResponse.body.collect(upTo: .max)
            XCTAssertEqual(String(buffer: responseContents), contents)
            XCTAssertNotNil(getResponse.lastModified)
        }
    }

    func testWaiters() async throws {
        let name = TestEnvironment.generateResourceName()
        try await self.testBucket(name) { _ in
            let filename = "testfile.txt"
            let contents = "testing S3.PutObject and S3.GetObject"

            _ = try await Self.s3.putObject(
                .init(body: .init(string: contents), bucket: name, key: filename)
            )
            try await Self.s3.waitUntilObjectExists(.init(bucket: name, key: filename))

            _ = try await Self.s3.deleteObject(.init(bucket: name, key: filename))
            try await Self.s3.waitUntilObjectNotExists(.init(bucket: name, key: filename))
        }
    }

    func testError() async {
        // get wrong error with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }
        await XCTAsyncExpectError(S3ErrorType.noSuchBucket) {
            _ = try await Self.s3.deleteBucket(.init(bucket: "nosuch-bucket-name3458bjhdfgdf"))
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
                XCTAssertEqual(request.url.host, "123456780123.s3-control.eu-west-1.amazonaws.com")
                throw CancelError()
            }
        }
        let s3Control = S3Control(client: Self.client, region: .euwest1).with(
            middleware: CheckHostMiddleware()
        )
        let request = S3Control.ListJobsRequest(accountId: "123456780123")
        do {
            _ = try await s3Control.listJobs(request)
        } catch is CancelError {}
    }

    func testS3Express() async throws {
        // doesnt work with LocalStack
        let bucket = "soto-test-directory-bucket--use1-az6--x-s3"
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)
        do {
            _ = try await Self.s3.createBucket(
                bucket: bucket,
                createBucketConfiguration: .init(
                    bucket: .init(dataRedundancy: .singleAvailabilityZone, type: .directory),
                    location: .init(name: "use1-az6", type: .availabilityZone)
                ),
                logger: TestEnvironment.logger
            )
            try await Self.s3.waitUntilBucketExists(.init(bucket: bucket), logger: TestEnvironment.logger)
        } catch let error as S3ErrorType where error == .bucketAlreadyOwnedByYou {}
        try await withTeardown {
            let (client, _expressS3) = Self.s3.createS3ExpressClientAndService(bucket: bucket)
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
                let testFile = try XCTUnwrap(listResponse.contents?.first { $0.eTag == putResponse.eTag }?.key)
                let getResponse = try await expressS3.getObject(
                    bucket: bucket,
                    key: testFile,
                    logger: TestEnvironment.logger
                )
                let body = try await getResponse.body.collect(upTo: .max)
                XCTAssertEqual(body, ByteBuffer(string: "Uploaded"))

                _ = try await expressS3.deleteObject(bucket: bucket, key: "test-file", logger: TestEnvironment.logger)
            } teardown: {
                try? await client.shutdown()
            }
        } teardown: {
            do {
                _ = try await Self.s3.deleteBucket(
                    bucket: bucket
                )
            } catch {
                XCTFail("\(error)")
            }
        }
    }

    /// test S3 control host is prefixed with account id
    func testS3AccessPoints() async throws {
        // doesnt work with LocalStack
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)
        guard let accountId = Environment["AWS_ACCOUNT_ID"] else { throw XCTSkip() }
        let name = TestEnvironment.generateResourceName()
        try await self.testBucket(name) { name in
            let s3Control = S3Control(client: Self.client, region: Self.s3.region)
            let response = try await s3Control.createAccessPoint(
                accountId: accountId,
                bucket: name,
                name: "test-accesspoint",
                logger: TestEnvironment.logger
            )
            return try await withTeardown {
                let accessPointArn = try XCTUnwrap(response.accessPointArn)
                let alias = try XCTUnwrap(response.alias)
                let string = "testing S3.PutObject and S3.GetObject"
                // upload using arn
                _ = try await Self.s3.putObject(body: .init(string: string), bucket: accessPointArn, key: name, logger: TestEnvironment.logger)
                // download using alias
                let getObjectResponse = try await Self.s3.getObject(bucket: alias, key: name, logger: TestEnvironment.logger)
                let body = try await getObjectResponse.body.collect(upTo: .max)
                XCTAssertEqual(String(buffer: body), string)
            } teardown: {
                try? await s3Control.deleteAccessPoint(accountId: accountId, name: "test-accesspoint", logger: TestEnvironment.logger)
            }
        }
    }
}
