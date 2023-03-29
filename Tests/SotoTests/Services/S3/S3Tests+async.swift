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
import Foundation
import NIOCore
import NIOPosix
import SotoCore
import XCTest

import SotoS3
import SotoS3Control

#if compiler(>=5.5.2) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class S3AsyncTests: XCTestCase {
    static var client: AWSClient!
    static var s3: S3!
    static var randomBytes: Data!

    override class func setUp() {
        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }

        Self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middlewares: TestEnvironment.middlewares, httpClientProvider: .createNew)
        Self.s3 = S3(
            client: Self.client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
        Self.randomBytes = Self.createRandomBuffer(size: 23 * 1024 * 1024)
    }

    override class func tearDown() {
        XCTAssertNoThrow(try Self.client.syncShutdown())
    }

    static func createRandomBuffer(size: Int) -> Data {
        // create buffer
        var data = Data(count: size)
        for i in 0..<size {
            data[i] = UInt8.random(in: 0...255)
        }
        return data
    }

    static func createBucket(name: String, s3: S3) async throws {
        do {
            _ = try await s3.createBucket(.init(bucket: name))
            try await s3.waitUntilBucketExists(.init(bucket: name))
        } catch {
            switch error {
            case let error as S3ErrorType:
                switch error {
                case .bucketAlreadyOwnedByYou:
                    return
                case .bucketAlreadyExists:
                    // local stack returns bucketAlreadyExists instead of bucketAlreadyOwnedByYou
                    if !TestEnvironment.isUsingLocalstack {
                        throw error
                    }
                default:
                    throw error
                }
            default:
                throw error
            }
        }
    }

    static func deleteBucket(name: String, s3: S3) async throws {
        let listResponse = try await s3.listObjectsV2(.init(bucket: name))
        if let objects = listResponse.contents {
            for object in objects {
                guard let key = object.key else { continue }
                _ = try await s3.deleteObject(.init(bucket: name, key: key))
            }
        }
        do {
            _ = try await s3.deleteBucket(.init(bucket: name))
        } catch {
            // when using LocalStack ignore errors from deleting buckets
            guard !TestEnvironment.isUsingLocalstack else { return }
            throw error
        }
    }

    /// Runs test: construct bucket with supplied name, runs process and deletes bucket
    func s3Test(bucket name: String, s3: S3 = S3AsyncTests.s3, _ process: @escaping () async throws -> Void) async throws {
        try await Self.createBucket(name: name, s3: s3)
        do {
            try await process()
        } catch {
            XCTFail("\(error)")
        }
        try await Self.deleteBucket(name: name, s3: s3)
    }

    // MARK: TESTS

    func testHeadBucketAsync() async throws {
        let name = TestEnvironment.generateResourceName()
        try await self.s3Test(bucket: name) {
            try await Self.s3.headBucket(.init(bucket: name))
        }
    }

    func testPutGetObjectAsync() async throws {
        let name = TestEnvironment.generateResourceName()
        let filename = "testfile.txt"
        let contents = "testing S3.PutObject and S3.GetObject"
        try await self.s3Test(bucket: name) {
            let putRequest = S3.PutObjectRequest(
                acl: .publicRead,
                body: .string(contents),
                bucket: name,
                contentLength: Int64(contents.utf8.count),
                key: filename
            )
            let putObjectResponse = try await Self.s3.putObject(putRequest)
            XCTAssertNotNil(putObjectResponse.eTag)
            let getObjectResponse = try await Self.s3.getObject(.init(bucket: name, key: filename, responseExpires: Date()))
            XCTAssertEqual(getObjectResponse.body?.asString(), contents)
            XCTAssertNotNil(getObjectResponse.lastModified)
        }
    }

    func testPutGetObjectWithSpecialNameAsync() async throws {
        let name = TestEnvironment.generateResourceName()
        let filename = "test $filé+!@£$%2F%^&*()_=-[]{}\\|';:\",./?><~`.txt"
        let contents = "testing S3.PutObject and S3.GetObject"
        try await self.s3Test(bucket: name) {
            let putRequest = S3.PutObjectRequest(
                acl: .publicRead,
                body: .string(contents),
                bucket: name,
                contentLength: Int64(contents.utf8.count),
                key: filename
            )
            let putObjectResponse = try await Self.s3.putObject(putRequest)
            XCTAssertNotNil(putObjectResponse.eTag)
            let getObjectResponse = try await Self.s3.getObject(.init(bucket: name, key: filename, responseExpires: Date()))
            XCTAssertEqual(getObjectResponse.body?.asString(), contents)
            XCTAssertNotNil(getObjectResponse.lastModified)
        }
    }

    func testCopyAsync() async throws {
        let name = TestEnvironment.generateResourceName()
        let keyName = "file1"
        let newKeyName = "file2"
        let contents = "testing S3.PutObject and S3.GetObject"
        try await self.s3Test(bucket: name) {
            _ = try await Self.s3.putObject(.init(body: .string(contents), bucket: name, key: keyName))
            _ = try await Self.s3.copyObject(.init(bucket: name, copySource: "\(name)/\(keyName)", key: newKeyName))
            let getResponse = try await Self.s3.getObject(.init(bucket: name, key: newKeyName))
            XCTAssertEqual(getResponse.body?.asString(), contents)
        }
    }

    /// test uploaded objects are returned in ListObjects
    func testListObjectsAsync() async throws {
        let name = TestEnvironment.generateResourceName()
        let contents = "testing S3.ListObjectsV2"

        try await self.s3Test(bucket: name) {
            let putResponse = try await Self.s3.putObject(.init(body: .string(contents), bucket: name, key: name))
            let eTag = try XCTUnwrap(putResponse.eTag)
            let listResponse = try await Self.s3.listObjectsV2(.init(bucket: name))
            XCTAssertEqual(listResponse.contents?.first?.key, name)
            XCTAssertEqual(listResponse.contents?.first?.size, Int64(contents.utf8.count))
            XCTAssertEqual(listResponse.contents?.first?.eTag, eTag)
            XCTAssertNotNil(listResponse.contents?.first?.lastModified)
        }
    }

    func testStreamPutObjectAsync() async throws {
        let s3 = Self.s3.with(timeout: .minutes(2))
        let name = TestEnvironment.generateResourceName()
        let dataSize = 240 * 1024
        let blockSize = 64 * 1024
        let data = Self.createRandomBuffer(size: 240 * 1024)
        var byteBuffer = ByteBufferAllocator().buffer(capacity: dataSize)
        byteBuffer.writeBytes(data)

        try await self.s3Test(bucket: name) {
            let payload = AWSPayload.stream(size: dataSize) { eventLoop in
                let size = min(blockSize, byteBuffer.readableBytes)
                if size == 0 {
                    return eventLoop.makeSucceededFuture(.end)
                }
                let slice = byteBuffer.readSlice(length: size)!
                return eventLoop.makeSucceededFuture(.byteBuffer(slice))
            }
            let putRequest = S3.PutObjectRequest(body: payload, bucket: name, key: "tempfile")
            _ = try await s3.putObject(putRequest)
            let getResponse = try await s3.getObject(.init(bucket: name, key: "tempfile"))
            XCTAssertEqual(getResponse.body?.asData(), data)
        }
    }

    /// test lifecycle rules are uploaded and downloaded ok
    func testLifecycleRuleAsync() async throws {
        let name = TestEnvironment.generateResourceName()

        try await self.s3Test(bucket: name) {
            // set lifecycle rules
            let incompleteMultipartUploads = S3.AbortIncompleteMultipartUpload(daysAfterInitiation: 7) // clear incomplete multipart uploads after 7 days
            let filter = S3.LifecycleRuleFilter.prefix("") // everything
            let transitions = [S3.Transition(days: 14, storageClass: .glacier)] // transition objects to glacier after 14 days
            let lifecycleRules = S3.LifecycleRule(
                abortIncompleteMultipartUpload: incompleteMultipartUploads,
                filter: filter,
                id: "aws-test",
                status: .enabled,
                transitions: transitions
            )
            let request = S3.PutBucketLifecycleConfigurationRequest(bucket: name, lifecycleConfiguration: .init(rules: [lifecycleRules]))
            _ = try await Self.s3.putBucketLifecycleConfiguration(request)
            let getResponse = try await Self.s3.getBucketLifecycleConfiguration(.init(bucket: name))

            XCTAssertEqual(getResponse.rules?[0].transitions?[0].storageClass, .glacier)
            XCTAssertEqual(getResponse.rules?[0].transitions?[0].days, 14)
            XCTAssertEqual(getResponse.rules?[0].abortIncompleteMultipartUpload?.daysAfterInitiation, 7)
        }
    }

    func testMultipleUploadAsync() async throws {
        let name = TestEnvironment.generateResourceName()
        let s3 = Self.s3.with(timeout: .minutes(2))
        try await self.s3Test(bucket: name) {
            await withThrowingTaskGroup(of: String?.self) { group in
                for index in 1...16 {
                    group.addTask {
                        let body = "testMultipleUpload - " + index.description
                        let filename = "file" + index.description
                        _ = try await s3.putObject(.init(body: .string(body), bucket: name, key: filename))
                        let bodyOutput = try await s3.getObject(.init(bucket: name, key: filename)).body
                        XCTAssertEqual(bodyOutput?.asString(), body)
                        return bodyOutput?.asString()
                    }
                }
            }
        }
    }

    /// testing decoding of values in xml attributes
    func testGetAclRequestPayerAsync() async throws {
        let name = TestEnvironment.generateResourceName()
        let contents = "testing xml attributes header"

        try await self.s3Test(bucket: name) {
            let putRequest = S3.PutObjectRequest(
                body: .string(contents),
                bucket: name,
                key: name
            )
            _ = try await Self.s3.putObject(putRequest)
            _ = try await Self.s3.getObjectAcl(.init(bucket: name, key: name, requestPayer: .requester))
        }
    }

    func testListPaginatorAsync() async throws {
        let name = TestEnvironment.generateResourceName()
        try await self.s3Test(bucket: name) {
            await withThrowingTaskGroup(of: String?.self) { group in
                for index in 1...16 {
                    let body = "testMultipleUpload - " + index.description
                    let filename = "file" + index.description
                    group.addTask {
                        return try await Self.s3.putObject(.init(body: .string(body), bucket: name, key: filename)).eTag
                    }
                }
            }
            let list = try await Self.s3.listObjectsV2(.init(bucket: name)).contents
            let paginator = Self.s3.listObjectsV2Paginator(.init(bucket: name, maxKeys: 5))
            let list2 = try await paginator.reduce([]) { $0 + ($1.contents ?? []) }
            XCTAssertEqual(list?.count, list2.count)
            for i in 0..<list2.count {
                XCTAssertEqual(list2[i].key, list?[i].key)
            }
        }
    }

    func testStreamRequestObjectAsync() async throws {
        // testing eventLoop so need to use MultiThreadedEventLoopGroup
        let elg = MultiThreadedEventLoopGroup(numberOfThreads: 3)
        let httpClient = HTTPClient(eventLoopGroupProvider: .shared(elg))
        let client = AWSClient(
            credentialProvider: TestEnvironment.credentialProvider,
            middlewares: TestEnvironment.middlewares,
            httpClientProvider: .shared(httpClient)
        )
        let s3 = S3(
            client: client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
        defer {
            XCTAssertNoThrow(try client.syncShutdown())
            XCTAssertNoThrow(try httpClient.syncShutdown())
            XCTAssertNoThrow(try elg.syncShutdownGracefully())
        }

        let runOnEventLoop = s3.client.eventLoopGroup.next()

        // create buffer
        let dataSize = 457_017
        var data = Data(count: dataSize)
        for i in 0..<dataSize {
            data[i] = UInt8.random(in: 0...255)
        }
        var byteBuffer = ByteBufferAllocator().buffer(data: data)
        let payload = AWSPayload.stream(size: dataSize) { eventLoop in
            XCTAssertTrue(eventLoop === runOnEventLoop)
            let size = min(100_000, byteBuffer.readableBytes)
            let slice = byteBuffer.readSlice(length: size)!
            return eventLoop.makeSucceededFuture(.byteBuffer(slice))
        }
        let name = TestEnvironment.generateResourceName()

        try await self.s3Test(bucket: name, s3: s3) {
            let putRequest = S3.PutObjectRequest(body: payload, bucket: name, key: "tempfile")
            _ = try await s3.putObject(putRequest, on: runOnEventLoop)
            let getRequest = S3.GetObjectRequest(bucket: name, key: "tempfile")
            let getResponse = try await s3.getObject(getRequest, on: runOnEventLoop)
            XCTAssertEqual(data, getResponse.body?.asData())
        }
    }

    func testStreamResponseObjectAsync() async throws {
        // testing eventLoop so need to use MultiThreadedEventLoopGroup
        let elg = MultiThreadedEventLoopGroup(numberOfThreads: 3)
        let httpClient = HTTPClient(eventLoopGroupProvider: .shared(elg))
        let client = AWSClient(
            credentialProvider: TestEnvironment.credentialProvider,
            middlewares: TestEnvironment.middlewares,
            httpClientProvider: .shared(httpClient)
        )
        let s3 = S3(
            client: client,
            region: .euwest1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
        defer {
            XCTAssertNoThrow(try client.syncShutdown())
            XCTAssertNoThrow(try httpClient.syncShutdown())
            XCTAssertNoThrow(try elg.syncShutdownGracefully())
        }

        // create buffer
        let dataSize = 257 * 1024
        var data = Data(count: dataSize)
        for i in 0..<dataSize {
            data[i] = UInt8.random(in: 0...255)
        }

        let name = TestEnvironment.generateResourceName()
        let runOnEventLoop = s3.client.eventLoopGroup.next()
        var byteBufferCollate = ByteBufferAllocator().buffer(capacity: dataSize)

        try await self.s3Test(bucket: name, s3: s3) {
            let putRequest = S3.PutObjectRequest(body: .data(data), bucket: name, key: "tempfile")
            _ = try await s3.putObject(putRequest, on: runOnEventLoop)
            let getRequest = S3.GetObjectRequest(bucket: name, key: "tempfile")
            _ = try await s3.getObjectStreaming(getRequest, on: runOnEventLoop) { byteBuffer, eventLoop in
                XCTAssertTrue(eventLoop === runOnEventLoop)
                var byteBuffer = byteBuffer
                byteBufferCollate.writeBuffer(&byteBuffer)
                return eventLoop.makeSucceededFuture(())
            }
            XCTAssertEqual(data, byteBufferCollate.getData(at: 0, length: byteBufferCollate.readableBytes))
        }
    }

    /// testing Date format in response headers
    func testMultipartAbortDateAsync() async throws {
        let name = TestEnvironment.generateResourceName()

        try await self.s3Test(bucket: name) {
            let rule = S3.LifecycleRule(abortIncompleteMultipartUpload: .init(daysAfterInitiation: 7), filter: .prefix(""), id: "multipart-upload", status: .enabled)
            let request = S3.PutBucketLifecycleConfigurationRequest(
                bucket: name,
                lifecycleConfiguration: .init(rules: [rule])
            )
            _ = try await Self.s3.putBucketLifecycleConfiguration(request)
            let createResponse = try await Self.s3.createMultipartUpload(.init(bucket: name, key: "test"))
            guard let uploadId = createResponse.uploadId else { throw AWSClientError.missingParameter }
            _ = try await Self.s3.abortMultipartUpload(.init(bucket: name, key: "test", uploadId: uploadId))
        }
    }

    func testSignedURLAsync() async throws {
        // doesnt work with LocalStack
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)

        let name = TestEnvironment.generateResourceName()
        let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
        defer { XCTAssertNoThrow(try httpClient.syncShutdown()) }
        let s3Url = URL(string: "https://\(name).s3.us-east-1.amazonaws.com/\(name)!=%25+/*()_.txt")!

        try await self.s3Test(bucket: name) {
            let putURL = try await Self.s3.signURL(url: s3Url, httpMethod: .PUT, expires: .minutes(5)).get()
            let buffer = ByteBufferAllocator().buffer(string: "Testing upload via signed URL")

            let response = try await httpClient.put(url: putURL.absoluteString, body: .byteBuffer(buffer), deadline: .now() + .minutes(5)).get()
            XCTAssertEqual(response.status, .ok)

            let contents = try await Self.s3.listObjectsV2(.init(bucket: name)).contents
            XCTAssertEqual(contents?.first?.key, "\(name)!=%+/*()_.txt")

            let getURL = try await Self.s3.signURL(url: s3Url, httpMethod: .GET, expires: .minutes(5)).get()
            let getResponse = try await httpClient.get(url: getURL.absoluteString).get()

            XCTAssertEqual(getResponse.status, .ok)
            let buffer2 = try XCTUnwrap(getResponse.body)
            XCTAssertEqual(String(buffer: buffer2), "Testing upload via signed URL")
        }
    }

    func testDualStackAsync() async throws {
        // doesnt work with LocalStack
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)

        let s3 = Self.s3.with(options: .useDualStackEndpoint)
        let name = TestEnvironment.generateResourceName()
        let filename = "testfile.txt"
        let contents = "testing S3.PutObject and S3.GetObject"
        try await self.s3Test(bucket: name, s3: s3) {
            let putRequest = S3.PutObjectRequest(
                acl: .publicRead,
                body: .string(contents),
                bucket: name,
                contentLength: Int64(contents.utf8.count),
                key: filename
            )
            let putObjectResponse = try await s3.putObject(putRequest)
            XCTAssertNotNil(putObjectResponse.eTag)
            let getObjectResponse = try await s3.getObject(.init(bucket: name, key: filename, responseExpires: Date()))
            XCTAssertEqual(getObjectResponse.body?.asString(), contents)
            XCTAssertNotNil(getObjectResponse.lastModified)
        }
    }

    func testTransferAcceleratedAsync() async throws {
        // doesnt work with LocalStack
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)

        let s3Accelerated = Self.s3.with(options: .s3UseTransferAcceleratedEndpoint)
        let name = TestEnvironment.generateResourceName()
        let filename = "testfile.txt"
        let contents = "testing S3.PutObject and S3.GetObject"
        try await self.s3Test(bucket: name) {
            let accelerationRequest = S3.PutBucketAccelerateConfigurationRequest(accelerateConfiguration: .init(status: .enabled), bucket: name)
            _ = try await Self.s3.putBucketAccelerateConfiguration(accelerationRequest)
            let putRequest = S3.PutObjectRequest(
                acl: .publicRead,
                body: .string(contents),
                bucket: name,
                contentLength: Int64(contents.utf8.count),
                key: filename
            )
            let putObjectResponse = try await s3Accelerated.putObject(putRequest)
            XCTAssertNotNil(putObjectResponse.eTag)
            let getObjectResponse = try await Self.s3.getObject(.init(bucket: name, key: filename, responseExpires: Date()))
            XCTAssertEqual(getObjectResponse.body?.asString(), contents)
            XCTAssertNotNil(getObjectResponse.lastModified)
        }
    }

    func testWaitersAsync() async throws {
        let name = TestEnvironment.generateResourceName()
        let filename = "testfile.txt"
        let contents = "testing S3.PutObject and S3.GetObject"
        try await self.s3Test(bucket: name) {
            _ = try await Self.s3.putObject(.init(body: .string(contents), bucket: name, key: filename))
            try await Self.s3.waitUntilObjectExists(.init(bucket: name, key: filename))
            _ = try await Self.s3.deleteObject(.init(bucket: name, key: filename))
            try await Self.s3.waitUntilObjectNotExists(.init(bucket: name, key: filename))
        }
    }

    func testErrorAsync() async throws {
        // get wrong error with LocalStack
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)

        do {
            _ = try await Self.s3.deleteBucket(.init(bucket: "nosuch-bucket-name3458bjhdfgdf"))
        } catch {
            switch error {
            case let error as S3ErrorType where error == .noSuchBucket:
                XCTAssertNotNil(error.message)
            default:
                XCTFail("Wrong error: \(error)")
            }
        }
    }

    /// test S3 control host is prefixed with account id
    func testS3ControlPrefixAsync() async throws {
        // don't actually want to make this API call so once I've checked the host is correct
        // I will throw an error in the request middleware
        struct CancelError: Error {}
        struct CheckHostMiddleware: AWSServiceMiddleware {
            func chain(request: AWSRequest, context: AWSMiddlewareContext) throws -> AWSRequest {
                XCTAssertEqual(request.url.host, "123456780123.s3-control.eu-west-1.amazonaws.com")
                throw CancelError()
            }
        }
        let s3Control = S3Control(client: Self.client, region: .euwest1).with(middlewares: [CheckHostMiddleware()])
        do {
            let request = S3Control.ListJobsRequest(accountId: "123456780123")
            _ = try await s3Control.listJobs(request)
        } catch is CancelError {}
    }

    func testMultiPartDownloadAsync() async throws {
        // doesnt work with LocalStack
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)

        let s3 = Self.s3.with(timeout: .minutes(2))
        let data = S3Tests.createRandomBuffer(size: 10 * 1024 * 1028)
        let name = TestEnvironment.generateResourceName()
        let filename = "testMultiPartDownloadAsync"

        try await self.s3Test(bucket: name) {
            var buffer = ByteBuffer(data: data)
            let putRequest = S3.CreateMultipartUploadRequest(bucket: name, key: filename)
            _ = try await s3.multipartUploadFromStream(putRequest, logger: TestEnvironment.logger) { _ -> AWSPayload in
                let blockSize = min(buffer.readableBytes, 5 * 1024 * 1024)
                let slice = buffer.readSlice(length: blockSize)!
                return .byteBuffer(slice)
            }

            let request = S3.GetObjectRequest(bucket: name, key: filename)
            let size = try await s3.multipartDownload(request, partSize: 1024 * 1024, filename: filename, logger: TestEnvironment.logger) { print("Progress \($0 * 100)%") }

            XCTAssertEqual(size, Int64(data.count))
            let savedData = try Data(contentsOf: URL(fileURLWithPath: filename))
            XCTAssertEqual(savedData, data)
            try FileManager.default.removeItem(atPath: filename)
        }
    }

    func testMultiPartUploadAsync() async throws {
        let s3 = Self.s3.with(timeout: .minutes(2))
        let data = Self.randomBytes!
        let name = TestEnvironment.generateResourceName()
        let filename = "testMultiPartUploadAsync"

        XCTAssertNoThrow(try data.write(to: URL(fileURLWithPath: filename)))
        defer {
            XCTAssertNoThrow(try FileManager.default.removeItem(atPath: filename))
        }

        try await self.s3Test(bucket: name) {
            let request = S3.CreateMultipartUploadRequest(
                bucket: name,
                key: name
            )
            let date = Date()
            _ = try await s3.multipartUpload(request, partSize: 5 * 1024 * 1024, filename: filename, logger: TestEnvironment.logger) { print("Progress \($0 * 100)%") }
            print(-date.timeIntervalSinceNow)

            let download = try await s3.getObject(.init(bucket: name, key: name), logger: TestEnvironment.logger)
            XCTAssertEqual(download.body?.asData(), data)
        }
    }

    func testMultiPartUploadAsyncSequence() async throws {
        let s3 = Self.s3.with(timeout: .minutes(2))
        let name = TestEnvironment.generateResourceName()
        let buffer = ByteBufferAllocator().buffer(data: Self.randomBytes)
        let seq = TestByteBufferSequence(source: buffer, range: 32768..<65536)

        try await self.s3Test(bucket: name) {
            let request = S3.CreateMultipartUploadRequest(
                bucket: name,
                key: name
            )
            let date = Date()
            @Sendable func printProgress(_ value: Int) {
                print("Progress \(value) bytes")
            }
            _ = try await s3.multipartUpload(request, partSize: 5 * 1024 * 1024, bufferSequence: seq, logger: TestEnvironment.logger, progress: printProgress)
            print(-date.timeIntervalSinceNow)

            let download = try await s3.getObject(.init(bucket: name, key: name), logger: TestEnvironment.logger)
            XCTAssertEqual(download.body?.asByteBuffer(), buffer)
        }
    }

    func testMultiPartEmptyUploadAsync() async throws {
        let s3 = Self.s3.with(timeout: .minutes(2))
        let data = Data() // Empty
        let name = TestEnvironment.generateResourceName()
        let filename = "testMultiPartEmptyUploadAsync"

        XCTAssertNoThrow(try data.write(to: URL(fileURLWithPath: filename)))
        defer {
            XCTAssertNoThrow(try FileManager.default.removeItem(atPath: filename))
        }

        try await self.s3Test(bucket: name) {
            let request = S3.CreateMultipartUploadRequest(
                bucket: name,
                key: name
            )
            _ = try await s3.multipartUpload(request, partSize: 5 * 1024 * 1024, filename: filename, logger: TestEnvironment.logger) { print("Progress \($0 * 100)%") }

            let download = try await s3.getObject(.init(bucket: name, key: name), logger: TestEnvironment.logger)
            XCTAssert(download.body?.isEmpty != false)
        }
    }

    func testResumeMultiPartUploadAsync() async throws {
        struct CancelError: Error {}
        let s3 = Self.s3.with(timeout: .minutes(2))
        let data = S3Tests.createRandomBuffer(size: 11 * 1024 * 1024)
        let name = TestEnvironment.generateResourceName()
        let filename = "testResumeMultiPartUploadAsync"

        XCTAssertNoThrow(try data.write(to: URL(fileURLWithPath: filename)))
        defer {
            XCTAssertNoThrow(try FileManager.default.removeItem(atPath: filename))
        }

        try await self.s3Test(bucket: name) {
            var resumeRequest: S3.ResumeMultipartUploadRequest
            do {
                let request = S3.CreateMultipartUploadRequest(bucket: name, key: name)
                _ = try await s3.multipartUpload(request, partSize: 5 * 1024 * 1024, filename: filename, abortOnFail: false, logger: TestEnvironment.logger) {
                    guard $0 < 0.45 else { throw CancelError() }
                    print("Progress \($0 * 100)")
                }
                throw CancelError()
            } catch S3ErrorType.multipart.abortedUpload(let resume, _) {
                resumeRequest = resume
            }

            do {
                _ = try await s3.resumeMultipartUpload(resumeRequest, partSize: 5 * 1024 * 1024, filename: filename, abortOnFail: false, logger: TestEnvironment.logger) {
                    guard $0 < 0.95 else { throw CancelError() }
                    print("Progress \($0 * 100)")
                }
                throw CancelError()
            } catch S3ErrorType.multipart.abortedUpload(let resume, _) {
                resumeRequest = resume
            }

            _ = try await s3.resumeMultipartUpload(resumeRequest, partSize: 5 * 1024 * 1024, filename: filename, abortOnFail: false, logger: TestEnvironment.logger) {
                print("Progress \($0 * 100)")
            }

            let response = try await s3.getObject(.init(bucket: name, key: name))
            XCTAssertEqual(response.body?.asData(), data)
        }
    }

    func testMultipartCopyAsync() async throws {
        let s3 = Self.s3.with(timeout: .minutes(2))
        let data = S3Tests.createRandomBuffer(size: 6 * 1024 * 1024)
        let name = TestEnvironment.generateResourceName()
        let name2 = name + "2"
        let filename = "testMultipartCopyAsync"
        let filename2 = "testMultipartCopyAsync2"

        XCTAssertNoThrow(try data.write(to: URL(fileURLWithPath: filename)))
        defer {
            XCTAssertNoThrow(try FileManager.default.removeItem(atPath: filename))
        }

        try await self.s3Test(bucket: name) {
            let s3Euwest2 = S3(
                client: Self.client,
                region: .useast1,
                endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT"),
                timeout: .minutes(5)
            )
            try await self.s3Test(bucket: name2, s3: s3Euwest2) {
                // upload to bucket
                let uploadRequest = S3.CreateMultipartUploadRequest(
                    bucket: name,
                    key: filename
                )
                _ = try await s3.multipartUpload(uploadRequest, partSize: 5 * 1024 * 1024, filename: filename) { print("Progress \($0 * 100)%") }

                // copy
                let copyRequest = S3.CopyObjectRequest(
                    bucket: name2,
                    copySource: "/\(name)/\(filename)",
                    key: filename2
                )
                _ = try await s3Euwest2.multipartCopy(copyRequest, partSize: 5 * 1024 * 1024)

                // download
                let object = try await s3Euwest2.getObject(.init(bucket: name2, key: filename2))
                XCTAssertEqual(object.body?.asData(), data)
            }
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
struct TestByteBufferSequence: AsyncSequence {
    typealias Element = ByteBuffer
    let source: ByteBuffer
    let range: Range<Int>

    struct AsyncIterator: AsyncIteratorProtocol {
        var source: ByteBuffer
        var range: Range<Int>

        mutating func next() async throws -> ByteBuffer? {
            let size = Swift.min(Int.random(in: self.range), self.source.readableBytes)
            if size == 0 {
                return nil
            } else {
                return self.source.readSlice(length: size)
            }
        }
    }

    /// Make async iterator
    public func makeAsyncIterator() -> AsyncIterator {
        return AsyncIterator(source: self.source, range: self.range)
    }
}

#endif
