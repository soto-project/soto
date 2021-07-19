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
@testable import SotoS3Control

class S3Tests: XCTestCase {
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
            client: S3Tests.client,
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

    static func createBucket(name: String, s3: S3) -> EventLoopFuture<Void> {
        let bucketRequest = S3.CreateBucketRequest(bucket: name)
        return s3.createBucket(bucketRequest)
            .map { _ in }
            .flatMapErrorThrowing { error in
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

    static func deleteBucket(name: String, s3: S3) -> EventLoopFuture<Void> {
        let request = S3.ListObjectsV2Request(bucket: name)
        return s3.listObjectsV2(request)
            .flatMap { response -> EventLoopFuture<Void> in
                let eventLoop = s3.client.eventLoopGroup.next()
                guard let objects = response.contents else { return eventLoop.makeSucceededFuture(()) }
                let deleteFutureResults = objects.compactMap { $0.key.map { s3.deleteObject(.init(bucket: name, key: $0)) } }
                return EventLoopFuture.andAllSucceed(deleteFutureResults, on: eventLoop)
            }
            .flatMap { _ in
                let request = S3.DeleteBucketRequest(bucket: name)
                return s3.deleteBucket(request).map { _ in }
            }
            .flatMapErrorThrowing { error in
                // when using LocalStack ignore errors from deleting buckets
                guard !TestEnvironment.isUsingLocalstack else { return }
                throw error
            }
    }

    // MARK: TESTS

    func testHeadBucket() {
        let name = TestEnvironment.generateResourceName()
        let response = Self.createBucket(name: name, s3: Self.s3)
            .flatMap {
                Self.s3.headBucket(.init(bucket: name))
            }
            .flatAlways { _ in
                return Self.deleteBucket(name: name, s3: Self.s3)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testPutGetObject() {
        let name = TestEnvironment.generateResourceName()
        let filename = "testfile.txt"
        let contents = "testing S3.PutObject and S3.GetObject"
        let response = Self.createBucket(name: name, s3: Self.s3)
            .flatMap { (_) -> EventLoopFuture<S3.PutObjectOutput> in
                let putRequest = S3.PutObjectRequest(
                    acl: .publicRead,
                    body: .string(contents),
                    bucket: name,
                    contentLength: Int64(contents.utf8.count),
                    key: filename
                )
                return Self.s3.putObject(putRequest)
            }
            .map { response -> Void in
                XCTAssertNotNil(response.eTag)
            }
            .flatMap { _ -> EventLoopFuture<S3.GetObjectOutput> in
                return Self.s3.getObject(.init(bucket: name, key: filename, responseExpires: Date()))
            }
            .map { response -> Void in
                XCTAssertEqual(response.body?.asString(), contents)
                XCTAssertNotNil(response.lastModified)
            }
            .flatAlways { _ in
                return Self.deleteBucket(name: name, s3: Self.s3)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testPutGetObjectWithSpecialName() {
        let name = TestEnvironment.generateResourceName()
        let filename = "test $filé+!@£$%2F%^&*()_=-[]{}\\|';:\",./?><~`.txt"
        let contents = "testing S3.PutObject and S3.GetObject"
        let response = Self.createBucket(name: name, s3: Self.s3)
            .flatMap { (_) -> EventLoopFuture<S3.PutObjectOutput> in
                let putRequest = S3.PutObjectRequest(
                    acl: .publicRead,
                    body: .string(contents),
                    bucket: name,
                    contentLength: Int64(contents.utf8.count),
                    key: filename
                )
                return Self.s3.putObject(putRequest)
            }
            .map { response -> Void in
                XCTAssertNotNil(response.eTag)
            }
            .flatMap { _ -> EventLoopFuture<S3.GetObjectOutput> in
                return Self.s3.getObject(.init(bucket: name, key: filename))
            }
            .map { response -> Void in
                XCTAssertEqual(response.body?.asString(), contents)
                XCTAssertNotNil(response.lastModified)
            }
            .flatAlways { _ in
                return Self.deleteBucket(name: name, s3: Self.s3)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testCopy() {
        let name = TestEnvironment.generateResourceName()
        let keyName = "file1"
        let newKeyName = "file2"
        let contents = "testing S3.PutObject and S3.GetObject"
        let response = Self.createBucket(name: name, s3: Self.s3)
            .flatMap { (_) -> EventLoopFuture<S3.PutObjectOutput> in
                let putRequest = S3.PutObjectRequest(body: .string(contents), bucket: name, key: keyName)
                return Self.s3.putObject(putRequest)
            }
            .flatMap { _ -> EventLoopFuture<S3.CopyObjectOutput> in
                let copyRequest = S3.CopyObjectRequest(bucket: name, copySource: "\(name)/\(keyName)", key: newKeyName)
                return Self.s3.copyObject(copyRequest)
            }
            .flatMap { _ -> EventLoopFuture<S3.GetObjectOutput> in
                return Self.s3.getObject(.init(bucket: name, key: newKeyName))
            }
            .map { response -> Void in
                XCTAssertEqual(response.body?.asString(), contents)
            }
            .flatAlways { _ in
                return Self.deleteBucket(name: name, s3: Self.s3)
            }
        XCTAssertNoThrow(try response.wait())
    }

    /// test uploaded objects are returned in ListObjects
    func testListObjects() {
        let name = TestEnvironment.generateResourceName()
        let contents = "testing S3.ListObjectsV2"
        let response = Self.createBucket(name: name, s3: Self.s3)
            .flatMap { (_) -> EventLoopFuture<S3.PutObjectOutput> in
                let putRequest = S3.PutObjectRequest(body: .string(contents), bucket: name, key: name)
                return Self.s3.putObject(putRequest)
            }
            .flatMapThrowing { response -> String in
                return try XCTUnwrap(response.eTag)
            }
            .flatMap { eTag -> EventLoopFuture<(S3.ListObjectsV2Output, String)> in
                return Self.s3.listObjectsV2(.init(bucket: name)).map { ($0, eTag) }
            }
            .map { (response, eTag) -> Void in
                XCTAssertEqual(response.contents?.first?.key, name)
                XCTAssertEqual(response.contents?.first?.size, Int64(contents.utf8.count))
                XCTAssertEqual(response.contents?.first?.eTag, eTag)
                XCTAssertNotNil(response.contents?.first?.lastModified)
            }
            .flatAlways { _ in
                return Self.deleteBucket(name: name, s3: Self.s3)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testStreamPutObject() {
        let s3 = Self.s3.with(timeout: .minutes(2))
        let name = TestEnvironment.generateResourceName()
        let dataSize = 240 * 1024
        let blockSize = 64 * 1024
        let data = Self.createRandomBuffer(size: 240 * 1024)
        var byteBuffer = ByteBufferAllocator().buffer(capacity: dataSize)
        byteBuffer.writeBytes(data)

        let response = Self.createBucket(name: name, s3: s3)
            .flatMap { _ -> EventLoopFuture<Void> in
                let payload = AWSPayload.stream(size: dataSize) { eventLoop in
                    let size = min(blockSize, byteBuffer.readableBytes)
                    if size == 0 {
                        return eventLoop.makeSucceededFuture(.end)
                    }
                    let slice = byteBuffer.readSlice(length: size)!
                    return eventLoop.makeSucceededFuture(.byteBuffer(slice))
                }
                let request = S3.PutObjectRequest(body: payload, bucket: name, key: "tempfile")
                return s3.putObject(request).map { _ in }
            }
            .flatMap { _ -> EventLoopFuture<S3.GetObjectOutput> in
                return s3.getObject(.init(bucket: name, key: "tempfile"))
            }
            .map { response in
                XCTAssertEqual(response.body?.asData(), data)
            }
            .flatAlways { _ in
                Self.deleteBucket(name: name, s3: s3)
            }

        XCTAssertNoThrow(try response.wait())
    }

    /// test lifecycle rules are uploaded and downloaded ok
    func testLifecycleRule() {
        let name = TestEnvironment.generateResourceName()
        let response = Self.createBucket(name: name, s3: Self.s3)
            .flatMap { _ -> EventLoopFuture<Void> in
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
                return Self.s3.putBucketLifecycleConfiguration(request)
            }
            .flatMap { _ in
                return Self.s3.getBucketLifecycleConfiguration(.init(bucket: name))
            }
            .map { response -> Void in
                XCTAssertEqual(response.rules?[0].transitions?[0].storageClass, .glacier)
                XCTAssertEqual(response.rules?[0].transitions?[0].days, 14)
                XCTAssertEqual(response.rules?[0].abortIncompleteMultipartUpload?.daysAfterInitiation, 7)
            }
            .flatAlways { _ in
                return Self.deleteBucket(name: name, s3: Self.s3)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testMultipleUpload() {
        func putGet(body: String, bucket: String, key: String) -> EventLoopFuture<Void> {
            return Self.s3.putObject(.init(body: .string(body), bucket: bucket, key: key))
                .flatMap { _ in
                    return Self.s3.getObject(.init(bucket: bucket, key: key))
                }
                .flatMapThrowing { response in
                    let getBody = try XCTUnwrap(response.body)
                    XCTAssertEqual(getBody.asString(), body)
                }
        }

        let name = TestEnvironment.generateResourceName()
        let eventLoop = Self.s3.client.eventLoopGroup.next()
        let response = Self.createBucket(name: name, s3: Self.s3)
            .flatMap { (_) -> EventLoopFuture<Void> in
                let futureResults = (1...16).map { index -> EventLoopFuture<Void> in
                    let body = "testMultipleUpload - " + index.description
                    let filename = "file" + index.description
                    return putGet(body: body, bucket: name, key: filename)
                }
                return EventLoopFuture.whenAllSucceed(futureResults, on: eventLoop).map { _ in }
            }
            .flatAlways { _ in
                return Self.deleteBucket(name: name, s3: Self.s3)
            }
        XCTAssertNoThrow(try response.wait())
    }

    /// testing decoding of values in xml attributes
    func testGetAclRequestPayer() {
        let name = TestEnvironment.generateResourceName()
        let contents = "testing xml attributes header"
        let response = Self.createBucket(name: name, s3: Self.s3)
            .flatMap { (_) -> EventLoopFuture<S3.PutObjectOutput> in
                let putRequest = S3.PutObjectRequest(
                    body: .string(contents),
                    bucket: name,
                    key: name
                )
                return Self.s3.putObject(putRequest)
            }
            .flatMap { _ -> EventLoopFuture<S3.GetObjectAclOutput> in
                return Self.s3.getObjectAcl(.init(bucket: name, key: name, requestPayer: .requester))
            }
            .flatAlways { response -> EventLoopFuture<Void> in
                print(response)
                return Self.deleteBucket(name: name, s3: Self.s3)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testListPaginator() {
        let name = TestEnvironment.generateResourceName()
        let eventLoop = Self.s3.client.eventLoopGroup.next()
        var list: [S3.Object] = []
        var list2: [S3.Object] = []
        let response = Self.createBucket(name: name, s3: Self.s3)
            .flatMap { (_) -> EventLoopFuture<Void> in
                // put 16 files into bucket
                let futureResults: [EventLoopFuture<S3.PutObjectOutput>] = (1...16).map {
                    let body = "testMultipleUpload - " + $0.description
                    let filename = "file" + $0.description
                    return Self.s3.putObject(.init(body: .string(body), bucket: name, key: filename))
                }
                return EventLoopFuture.whenAllSucceed(futureResults, on: eventLoop).map { _ in }
            }
            .flatMap { _ in
                return Self.s3.listObjectsV2Paginator(.init(bucket: name, maxKeys: 5)) { result, eventLoop in
                    list.append(contentsOf: result.contents ?? [])
                    return eventLoop.makeSucceededFuture(true)
                }
            }
            .flatMap { _ in
                // test both types of paginator and both listObjects
                return Self.s3.listObjectsV2Paginator(.init(bucket: name, maxKeys: 5), []) { list, result, eventLoop in
                    return eventLoop.makeSucceededFuture((true, list + (result.contents ?? [])))
                }
            }
            .flatMap { result in
                list2 = result
                return Self.s3.listObjectsV2(.init(bucket: name))
            }
            .map { (response: S3.ListObjectsV2Output) in
                XCTAssertEqual(list.count, response.contents?.count)
                for i in 0..<list.count {
                    XCTAssertEqual(list[i].key, response.contents?[i].key)
                    XCTAssertEqual(list2[i].key, response.contents?[i].key)
                }
            }
            .flatAlways { _ in
                return Self.deleteBucket(name: name, s3: Self.s3)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testStreamRequestObject() {
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

        let response = Self.createBucket(name: name, s3: s3)
            .hop(to: runOnEventLoop)
            .flatMap { _ -> EventLoopFuture<S3.PutObjectOutput> in
                let putRequest = S3.PutObjectRequest(body: payload, bucket: name, key: "tempfile")
                return s3.putObject(putRequest, on: runOnEventLoop)
            }
            .flatMap { _ -> EventLoopFuture<S3.GetObjectOutput> in
                let getRequest = S3.GetObjectRequest(bucket: name, key: "tempfile")
                return s3.getObject(getRequest, on: runOnEventLoop)
            }
            .map { response in
                XCTAssertEqual(data, response.body?.asData())
            }
            .flatAlways { _ in
                return Self.deleteBucket(name: name, s3: s3)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testStreamResponseObject() {
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

        let response = Self.createBucket(name: name, s3: s3)
            .hop(to: runOnEventLoop)
            .flatMap { _ -> EventLoopFuture<S3.PutObjectOutput> in
                let putRequest = S3.PutObjectRequest(body: .data(data), bucket: name, key: "tempfile")
                return s3.putObject(putRequest, on: runOnEventLoop)
            }
            .flatMap { _ -> EventLoopFuture<S3.GetObjectOutput> in
                let getRequest = S3.GetObjectRequest(bucket: name, key: "tempfile")
                return s3.getObjectStreaming(getRequest, on: runOnEventLoop) { byteBuffer, eventLoop in
                    XCTAssertTrue(eventLoop === runOnEventLoop)
                    var byteBuffer = byteBuffer
                    byteBufferCollate.writeBuffer(&byteBuffer)
                    return eventLoop.makeSucceededFuture(())
                }
            }
            .map { _ in
                XCTAssertEqual(data, byteBufferCollate.getData(at: 0, length: byteBufferCollate.readableBytes))
            }
            .flatAlways { _ in
                return Self.deleteBucket(name: name, s3: s3)
            }
        XCTAssertNoThrow(try response.wait())
    }

    /// testing Date format in response headers
    func testMultipartAbortDate() {
        let name = TestEnvironment.generateResourceName()
        let response = Self.createBucket(name: name, s3: Self.s3)
            .flatMap { _ -> EventLoopFuture<Void> in
                let rule = S3.LifecycleRule(abortIncompleteMultipartUpload: .init(daysAfterInitiation: 7), filter: .init(prefix: ""), id: "multipart-upload", status: .enabled)
                let request = S3.PutBucketLifecycleConfigurationRequest(
                    bucket: name,
                    lifecycleConfiguration: .init(rules: [rule])
                )
                return Self.s3.putBucketLifecycleConfiguration(request)
            }
            .flatMap { _ -> EventLoopFuture<S3.CreateMultipartUploadOutput> in
                Self.s3.createMultipartUpload(.init(bucket: name, key: "test"))
            }
            .flatMap { response -> EventLoopFuture<S3.AbortMultipartUploadOutput> in
                guard let uploadId = response.uploadId else { return Self.s3.eventLoopGroup.next().makeFailedFuture(AWSClientError.missingParameter) }
                return Self.s3.abortMultipartUpload(.init(bucket: name, key: "test", uploadId: uploadId))
            }
            .flatAlways { _ in
                return Self.deleteBucket(name: name, s3: Self.s3)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testSignedURL() {
        // doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }

        let name = TestEnvironment.generateResourceName()
        let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
        defer { XCTAssertNoThrow(try httpClient.syncShutdown()) }
        let s3Url = URL(string: "https://\(name).s3.us-east-1.amazonaws.com/\(name)!=%25+/*()_.txt")!

        let response = Self.createBucket(name: name, s3: Self.s3)
            .flatMap { _ -> EventLoopFuture<URL> in
                Self.s3.signURL(url: s3Url, httpMethod: .PUT, expires: .minutes(5))
            }
            .flatMap { url -> EventLoopFuture<HTTPClient.Response> in
                let buffer = ByteBufferAllocator().buffer(string: "Testing upload via signed URL")
                return httpClient.put(url: url.absoluteString, body: .byteBuffer(buffer), deadline: .now() + .minutes(5))
            }
            .flatMap { response -> EventLoopFuture<S3.ListObjectsV2Output> in
                XCTAssertEqual(response.status, .ok)
                return Self.s3.listObjectsV2(.init(bucket: name))
            }
            .flatMap { response -> EventLoopFuture<URL> in
                XCTAssertEqual(response.contents?.first?.key, "\(name)!=%+/*()_.txt")
                return Self.s3.signURL(url: s3Url, httpMethod: .GET, expires: .minutes(5))
            }
            .flatMap { url -> EventLoopFuture<HTTPClient.Response> in
                httpClient.get(url: url.absoluteString)
            }
            .flatMapThrowing { response -> Void in
                XCTAssertEqual(response.status, .ok)
                var buffer = try XCTUnwrap(response.body)
                let bufferString = buffer.readString(length: buffer.readableBytes)
                XCTAssertEqual(bufferString, "Testing upload via signed URL")
            }
            .flatAlways { _ in
                return Self.deleteBucket(name: name, s3: Self.s3)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testDualStack() {
        // doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }

        let s3 = Self.s3.with(options: .s3UseDualStackEndpoint)
        let name = TestEnvironment.generateResourceName()
        let filename = "testfile.txt"
        let contents = "testing S3.PutObject and S3.GetObject"
        let response = Self.createBucket(name: name, s3: s3)
            .flatMap { (_) -> EventLoopFuture<S3.PutObjectOutput> in
                let putRequest = S3.PutObjectRequest(
                    acl: .publicRead,
                    body: .string(contents),
                    bucket: name,
                    contentLength: Int64(contents.utf8.count),
                    key: filename
                )
                return s3.putObject(putRequest)
            }
            .map { response -> Void in
                XCTAssertNotNil(response.eTag)
            }
            .flatMap { _ -> EventLoopFuture<S3.GetObjectOutput> in
                return s3.getObject(.init(bucket: name, key: filename))
            }.flatAlways { _ in
                return Self.deleteBucket(name: name, s3: s3)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testTransferAccelerated() {
        // doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }

        let s3Accelerated = Self.s3.with(options: .s3UseTransferAcceleratedEndpoint)
        let name = TestEnvironment.generateResourceName()
        let filename = "testfile.txt"
        let contents = "testing S3.PutObject and S3.GetObject"
        let response = Self.createBucket(name: name, s3: Self.s3)
            .flatMap { _ -> EventLoopFuture<Void> in
                let request = S3.PutBucketAccelerateConfigurationRequest(accelerateConfiguration: .init(status: .enabled), bucket: name)
                return Self.s3.putBucketAccelerateConfiguration(request)
            }
            .flatMap { (_) -> EventLoopFuture<S3.PutObjectOutput> in
                let putRequest = S3.PutObjectRequest(
                    acl: .publicRead,
                    body: .string(contents),
                    bucket: name,
                    contentLength: Int64(contents.utf8.count),
                    key: filename
                )
                return s3Accelerated.putObject(putRequest)
            }
            .map { response -> Void in
                XCTAssertNotNil(response.eTag)
            }
            .flatMap { _ -> EventLoopFuture<S3.GetObjectOutput> in
                return Self.s3.getObject(.init(bucket: name, key: filename))
            }.flatAlways { _ in
                return Self.deleteBucket(name: name, s3: Self.s3)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testWaiters() {
        let name = TestEnvironment.generateResourceName()
        let filename = "testfile.txt"
        let contents = "testing S3.PutObject and S3.GetObject"
        let response = Self.createBucket(name: name, s3: Self.s3)
            .flatMap { _ in
                Self.s3.putObject(.init(body: .string(contents), bucket: name, key: filename))
            }
            .flatMap { _ in
                Self.s3.waitUntilObjectExists(.init(bucket: name, key: filename))
            }
            .flatMap { _ in
                Self.s3.deleteObject(.init(bucket: name, key: filename))
            }
            .flatMap { _ in
                Self.s3.waitUntilObjectNotExists(.init(bucket: name, key: filename))
            }
            .flatAlways { _ in
                return Self.deleteBucket(name: name, s3: Self.s3)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testError() {
        // get wrong error with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }
        let response = Self.s3.deleteBucket(.init(bucket: "nosuch-bucket-name3458bjhdfgdf"))
        XCTAssertThrowsError(try response.wait()) { error in
            switch error {
            case let error as S3ErrorType where error == .noSuchBucket:
                XCTAssertNotNil(error.message)
            default:
                XCTFail("Wrong error: \(error)")
            }
        }
    }

    /// test S3 control host is prefixed with account id
    func testS3ControlPrefix() throws {
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
        let request = S3Control.ListJobsRequest(accountId: "123456780123")
        do {
            _ = try s3Control.listJobs(request).wait()
        } catch is CancelError {}
    }
}
