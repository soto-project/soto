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
import NIO
import NIOHTTP1
import SotoCore
import XCTest

@testable import SotoS3

#if compiler(>=5.4) && $AsyncAwait

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
class S3AsyncTests: XCTestCase {
    static var client: AWSClient!
    static var s3: S3!

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
    func s3Test(bucket name: String, s3: S3 = S3AsyncTests.s3, _ process: @escaping () async throws -> Void) {
        let dg = DispatchGroup()
        dg.enter()
        Task.detached {
            do {
                try await Self.createBucket(name: name, s3: s3)
                do {
                    try await process()
                } catch {
                    XCTFail("\(error)")
                }
                try await Self.deleteBucket(name: name, s3: s3)
            } catch {
                XCTFail("\(error)")
            }
            dg.leave()
        }
        dg.wait()
    }

    // MARK: TESTS

    func testHeadBucketAsync() throws {
        let name = TestEnvironment.generateResourceName()
        self.s3Test(bucket: name) {
            try await Self.s3.headBucket(.init(bucket: name))
        }
    }

    func testPutGetObjectAsync() {
        let name = TestEnvironment.generateResourceName()
        let filename = "testfile.txt"
        let contents = "testing S3.PutObject and S3.GetObject"
        self.s3Test(bucket: name) {
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

    func testPutGetObjectWithSpecialNameAsync() {
        let name = TestEnvironment.generateResourceName()
        let filename = "test $filé+!@£$%2F%^&*()_=-[]{}\\|';:\",./?><~`.txt"
        let contents = "testing S3.PutObject and S3.GetObject"
        self.s3Test(bucket: name) {
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

    func testCopyAsync() {
        let name = TestEnvironment.generateResourceName()
        let keyName = "file1"
        let newKeyName = "file2"
        let contents = "testing S3.PutObject and S3.GetObject"
        self.s3Test(bucket: name) {
            _ = try await Self.s3.putObject(.init(body: .string(contents), bucket: name, key: keyName))
            _ = try await Self.s3.copyObject(.init(bucket: name, copySource: "\(name)/\(keyName)", key: newKeyName))
            let getResponse = try await Self.s3.getObject(.init(bucket: name, key: newKeyName))
            XCTAssertEqual(getResponse.body?.asString(), contents)
        }
    }

    /// test uploaded objects are returned in ListObjects
    func testListObjectsAsync() {
        let name = TestEnvironment.generateResourceName()
        let contents = "testing S3.ListObjectsV2"

        self.s3Test(bucket: name) {
            let putResponse = try await Self.s3.putObject(.init(body: .string(contents), bucket: name, key: name))
            let eTag = try XCTUnwrap(putResponse.eTag)
            let listResponse = try await Self.s3.listObjectsV2(.init(bucket: name))
            XCTAssertEqual(listResponse.contents?.first?.key, name)
            XCTAssertEqual(listResponse.contents?.first?.size, Int64(contents.utf8.count))
            XCTAssertEqual(listResponse.contents?.first?.eTag, eTag)
            XCTAssertNotNil(listResponse.contents?.first?.lastModified)
        }
    }

    func testStreamPutObjectAsync() {
        let s3 = Self.s3.with(timeout: .minutes(2))
        let name = TestEnvironment.generateResourceName()
        let dataSize = 240 * 1024
        let blockSize = 64 * 1024
        let data = Self.createRandomBuffer(size: 240 * 1024)
        var byteBuffer = ByteBufferAllocator().buffer(capacity: dataSize)
        byteBuffer.writeBytes(data)

        self.s3Test(bucket: name) {
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
    func testLifecycleRuleAsync() {
        let name = TestEnvironment.generateResourceName()

        self.s3Test(bucket: name) {
            // set lifecycle rules
            let incompleteMultipartUploads = S3.AbortIncompleteMultipartUpload(daysAfterInitiation: 7) // clear incomplete multipart uploads after 7 days
            let filter = S3.LifecycleRuleFilter(prefix: "") // everything
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

    func testMultipleUploadAsync() {
        let name = TestEnvironment.generateResourceName()
        self.s3Test(bucket: name) {
            await withThrowingTaskGroup(of: String?.self) { group in
                for index in 1...16 {
                    group.async {
                        let body = "testMultipleUpload - " + index.description
                        let filename = "file" + index.description
                        _ = try await Self.s3.putObject(.init(body: .string(body), bucket: name, key: filename))
                        let bodyOutput = try await Self.s3.getObject(.init(bucket: name, key: filename)).body
                        XCTAssertEqual(bodyOutput?.asString(), body)
                        return bodyOutput?.asString()
                    }
                }
            }
        }
    }

    /// testing decoding of values in xml attributes
    func testGetAclRequestPayerAsync() {
        let name = TestEnvironment.generateResourceName()
        let contents = "testing xml attributes header"

        self.s3Test(bucket: name) {
            let putRequest = S3.PutObjectRequest(
                body: .string(contents),
                bucket: name,
                key: name
            )
            _ = try await Self.s3.putObject(putRequest)
            _ = try await Self.s3.getObjectAcl(.init(bucket: name, key: name, requestPayer: .requester))
        }
    }

    func testListPaginatorAsync() {
        let name = TestEnvironment.generateResourceName()
        self.s3Test(bucket: name) {
            await withThrowingTaskGroup(of: String?.self) { group in
                for index in 1...16 {
                    let body = "testMultipleUpload - " + index.description
                    let filename = "file" + index.description
                    group.async {
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

    func testStreamRequestObjectAsync() {
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

        self.s3Test(bucket: name, s3: s3) {
            let putRequest = S3.PutObjectRequest(body: payload, bucket: name, key: "tempfile")
            _ = try await s3.putObject(putRequest, on: runOnEventLoop)
            let getRequest = S3.GetObjectRequest(bucket: name, key: "tempfile")
            let getResponse = try await s3.getObject(getRequest, on: runOnEventLoop)
            XCTAssertEqual(data, getResponse.body?.asData())
        }
    }

    func testStreamResponseObjectAsync() {
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

        self.s3Test(bucket: name, s3: s3) {
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
    func testMultipartAbortDateAsync() {
        let name = TestEnvironment.generateResourceName()

        self.s3Test(bucket: name) {
            let rule = S3.LifecycleRule(abortIncompleteMultipartUpload: .init(daysAfterInitiation: 7), filter: .init(prefix: ""), id: "multipart-upload", status: .enabled)
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

    func testSignedURLAsync() {
        // doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }

        let name = TestEnvironment.generateResourceName()
        let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
        defer { XCTAssertNoThrow(try httpClient.syncShutdown()) }
        let s3Url = URL(string: "https://\(name).s3.us-east-1.amazonaws.com/\(name)!=%25+/*()_.txt")!

        self.s3Test(bucket: name) {
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

    func testDualStackAsync() {
        // doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }

        let s3 = Self.s3.with(options: .s3UseDualStackEndpoint)
        let name = TestEnvironment.generateResourceName()
        let filename = "testfile.txt"
        let contents = "testing S3.PutObject and S3.GetObject"
        self.s3Test(bucket: name, s3: s3) {
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

    func testTransferAcceleratedAsync() {
        // doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }

        let s3Accelerated = Self.s3.with(options: .s3UseTransferAcceleratedEndpoint)
        let name = TestEnvironment.generateResourceName()
        let filename = "testfile.txt"
        let contents = "testing S3.PutObject and S3.GetObject"
        self.s3Test(bucket: name) {
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

    func testErrorAsync() {
        // get wrong error with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }

        let dg = DispatchGroup()
        dg.enter()
        Task.detached {
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
            dg.leave()
        }
        dg.wait()
    }
}

#endif
