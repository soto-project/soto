//===----------------------------------------------------------------------===//
//
// This source file is part of the AWSSDKSwift open source project
//
// Copyright (c) 2017-2020 the AWSSDKSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of AWSSDKSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import AsyncHTTPClient
import NIO
import NIOHTTP1
import XCTest

@testable import AWSS3
@testable import AWSSDKSwiftCore

class S3Tests: XCTestCase {

    var s3 = S3(
        accessKeyId: TestEnvironment.accessKeyId,
        secretAccessKey: TestEnvironment.secretAccessKey,
        region: .euwest1,
        endpoint: TestEnvironment.getEndPoint(environment: "S3_ENDPOINT", default: "http://localhost:4572"),
        middlewares: TestEnvironment.middlewares,
        httpClientProvider: .createNew
    )

    override class func setUp() {
        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }
    }

    func createRandomBuffer(size: Int) -> Data {
        // create buffer
        var data = Data(count: size)
        for i in 0..<size {
            data[i] = UInt8.random(in: 0...255)
        }
        return data
    }
    
    func createBucket(name: String, s3: S3? = nil) -> EventLoopFuture<Void> {
        let s3 = s3 ?? self.s3
        let bucketRequest = S3.CreateBucketRequest(bucket: name)
        return s3.createBucket(bucketRequest)
            .map { _ in }
            .flatMapErrorThrowing { error in
                switch error {
                case S3ErrorType.bucketAlreadyOwnedByYou(_):
                    return
                case S3ErrorType.bucketAlreadyExists(_):
                    // local stack returns bucketAlreadyExists instead of bucketAlreadyOwnedByYou
                    if !TestEnvironment.isUsingLocalstack {
                        throw error
                    }
                default:
                    throw error
                }
        }
    }
    
    func deleteBucket(name: String, s3: S3? = nil) -> EventLoopFuture<Void> {
        let s3 = s3 ?? self.s3
        let request = S3.ListObjectsV2Request(bucket: name)
        return s3.listObjectsV2(request)
            .flatMap { response -> EventLoopFuture<Void> in
                let eventLoop = s3.client.eventLoopGroup.next()
                guard let objects = response.contents else { return eventLoop.makeSucceededFuture(())}
                let deleteFutureResults = objects.compactMap { $0.key.map { s3.deleteObject(.init(bucket: name, key: $0)) } }
                return EventLoopFuture.andAllSucceed(deleteFutureResults, on: eventLoop)
        }
        .flatMap { _ in
            let request = S3.DeleteBucketRequest(bucket: name)
            return s3.deleteBucket(request).map { _ in }
        }
    }
    
    //MARK: TESTS

    func testPutGetObject() {
        let name = TestEnvironment.generateResourceName()
        let contents = "testing S3.PutObject and S3.GetObject"
        let response = createBucket(name: name)
            .flatMap { (_) -> EventLoopFuture<S3.PutObjectOutput> in
                let putRequest = S3.PutObjectRequest(
                    acl: .publicRead,
                    body: .string(contents),
                    bucket: name,
                    contentLength: Int64(contents.utf8.count),
                    key: name
                )
                return self.s3.putObject(putRequest)
        }
        .map { response -> Void in
            XCTAssertNotNil(response.eTag)
        }
        .flatMap { _ -> EventLoopFuture<S3.GetObjectOutput> in
            return self.s3.getObject(.init(bucket: name, key: name))
        }
        .map { response -> Void in
            XCTAssertEqual(response.body?.asString(), contents)
        }
        .flatAlways { _ in
            return self.deleteBucket(name: name)
        }
        XCTAssertNoThrow(try response.wait())
    }

    func testMultiPartDownload() {
        let data = createRandomBuffer(size: 10 * 1024 * 1024)
        let name = TestEnvironment.generateResourceName()
        let filename = "S3MultipartDownloadTest"
        let response = createBucket(name: name)
            .flatMap { (_) -> EventLoopFuture<S3.PutObjectOutput> in
                let putRequest = S3.PutObjectRequest(body: .data(data), bucket: name, contentLength: Int64(data.count), key: filename)
                return self.s3.putObject(putRequest)
        }
        .flatMap { _ -> EventLoopFuture<Int64> in
            let request = S3.GetObjectRequest(bucket: name, key: filename)
            return self.s3.multipartDownload(request, partSize: 1024*1024, filename: filename) { print("Progress \($0*100)%")}
        }
        .flatMapThrowing { size in
            XCTAssertEqual(size, Int64(data.count))
            XCTAssert(FileManager.default.fileExists(atPath: filename))
            try FileManager.default.removeItem(atPath: filename)
        }
        .flatAlways { _ in
            return self.deleteBucket(name: name)
        }
        XCTAssertNoThrow(try response.wait())
    }

    func testMultiPartDownloadFailure() {
        let name = TestEnvironment.generateResourceName()
        let response = createBucket(name: name)
            .flatMap { _ -> EventLoopFuture<Int64> in
                let request = S3.GetObjectRequest(bucket: name, key: name)
                return self.s3.multipartDownload(request, partSize: 1024*1024, filename: name) { print("Progress \($0*100)%")}
        }
        .map { _ in
            XCTFail("testMultiPartDownloadFailure: should have failed")
        }
        .flatMapErrorThrowing { error in
            switch error {
            case let error as AWSError:
                XCTAssertEqual(error.statusCode, .notFound)
                return
            default:
                XCTFail("Unexpected error: \(error)")
            }
        }
        .flatAlways { _ in
            return self.deleteBucket(name: name)
        }
        XCTAssertNoThrow(try response.wait())
    }

    func testMultiPartUpload() {
        let data = createRandomBuffer(size: 10 * 1024 * 1024)
        let name = TestEnvironment.generateResourceName()
        let filename = "S3MultipartUploadTest"
        
        XCTAssertNoThrow(try data.write(to: URL(fileURLWithPath: filename)))
        defer {
            XCTAssertNoThrow(try FileManager.default.removeItem(atPath: filename))
        }

        let response = createBucket(name: name)
            .flatMap { (_) -> EventLoopFuture<S3.CompleteMultipartUploadOutput> in
                let request = S3.CreateMultipartUploadRequest(
                    bucket: name,
                    key: name
                )
                return self.s3.multipartUpload(request, partSize: 5 * 1024 * 1024, filename: filename) { print("Progress \($0*100)%") }
        }
        .flatMap { _ -> EventLoopFuture<S3.GetObjectOutput> in
            return self.s3.getObject(.init(bucket: name, key: name))
        }
        .map { response -> Void in
            XCTAssertEqual(response.body?.asData(), data)
        }
        .flatAlways { _ in
            return self.deleteBucket(name: name)
        }
        XCTAssertNoThrow(try response.wait())
    }

    func testMultiPartUploadFailure() {
        let data = createRandomBuffer(size: 10 * 1024 * 1024)
        let name = TestEnvironment.generateResourceName()
        let filename = "S3MultipartUploadTestFail"
        
        XCTAssertNoThrow(try data.write(to: URL(fileURLWithPath: filename)))
        defer {
            XCTAssertNoThrow(try FileManager.default.removeItem(atPath: filename))
        }

        // file doesn't exist test
        let response = createBucket(name: name)
            .flatMap { _ -> EventLoopFuture<Void> in
                let request = S3.CreateMultipartUploadRequest(bucket: name, key: name)
                return self.s3.multipartUpload(request, partSize: 5 * 1024 * 1024, filename: "doesntexist").map { _ in }
        }
        .map { _ in
            XCTFail("testMultiPartDownloadFailure: should have failed")
        }
        .flatMapErrorThrowing { error -> Void in
            return
        }
        .flatAlways { _ in
            return self.deleteBucket(name: name)
        }
        XCTAssertNoThrow(try response.wait())

        // bucket doesn't exist
        let request = S3.CreateMultipartUploadRequest(bucket: name, key: name)
        let response2 =  s3.multipartUpload(request, partSize: 5 * 1024 * 1024, filename: filename)
            .map { _ in
                XCTFail("testMultiPartDownloadFailure: should have failed")
        }
        .flatMapErrorThrowing { error -> Void in
            switch error {
            case S3ErrorType.noSuchBucket(_):
                return
            default:
                XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertNoThrow(try response2.wait())
    }

    /// test uploaded objects are returned in ListObjects
    func testListObjects() {
        let name = TestEnvironment.generateResourceName()
        let contents = "testing S3.ListObjectsV2"
        let response = createBucket(name: name)
            .flatMap { (_) -> EventLoopFuture<S3.PutObjectOutput> in
                let putRequest = S3.PutObjectRequest(body: .string(contents), bucket: name, key: name)
                return self.s3.putObject(putRequest)
        }
        .flatMapThrowing { response -> String in
            return try XCTUnwrap(response.eTag)
        }
        .flatMap { eTag -> EventLoopFuture<(S3.ListObjectsV2Output, String)> in
            return self.s3.listObjectsV2(.init(bucket: name)).map { ($0, eTag)}
        }
        .map { (response, eTag) -> Void in
            XCTAssertEqual(response.contents?.first?.key, name)
            XCTAssertEqual(response.contents?.first?.size, Int64(contents.utf8.count))
            XCTAssertEqual(response.contents?.first?.eTag, eTag)
        }
        .flatAlways { _ in
            return self.deleteBucket(name: name)
        }
        XCTAssertNoThrow(try response.wait())
    }

    func testStreamPutObject() {
        let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
        defer {
            XCTAssertNoThrow(try httpClient.syncShutdown())
        }
        let s3 = S3(
            accessKeyId: TestEnvironment.accessKeyId,
            secretAccessKey: TestEnvironment.secretAccessKey,
            region: .euwest1,
            endpoint: TestEnvironment.getEndPoint(environment: "S3_ENDPOINT", default: "http://localhost:4572"),
            middlewares: TestEnvironment.middlewares,
            httpClientProvider: .shared(httpClient)
        )
        let name = TestEnvironment.generateResourceName()
        let dataSize = 240*1024
        let blockSize = 64*1024
        let data = createRandomBuffer(size: 240*1024)
        var byteBuffer = ByteBufferAllocator().buffer(capacity: dataSize)
        byteBuffer.writeBytes(data)

        let response = createBucket(name: name, s3: s3)
            .flatMap { _ -> EventLoopFuture<Void> in
                let payload = AWSPayload.stream(size: dataSize) { eventLoop in
                    let size = min(blockSize, byteBuffer.readableBytes)
                    if size == 0 {
                        return eventLoop.makeSucceededFuture(byteBuffer)
                    }
                    let slice = byteBuffer.readSlice(length: size)!
                    return eventLoop.makeSucceededFuture(slice)
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
            self.deleteBucket(name: name, s3: s3)
        }
        
        XCTAssertNoThrow(try response.wait())
    }

    /// test bucket location is correctly returned.
    func testGetBucketLocation() {
        let name = TestEnvironment.generateResourceName()
        let response = createBucket(name: name)
            .flatMap { _ in
                return self.s3.getBucketLocation(.init(bucket: name))
        }
        .map { response in
            XCTAssertEqual(response.locationConstraint, .euWest1)
        }
        .flatAlways { _ in
            return self.deleteBucket(name: name)
        }
        XCTAssertNoThrow(try response.wait())
    }

    /// test lifecycle rules are uploaded and downloaded ok
    func testLifecycleRule() {
        let name = TestEnvironment.generateResourceName()
        let response = createBucket(name: name)
            .flatMap { _ -> EventLoopFuture<Void> in
                // set lifecycle rules
                let incompleteMultipartUploads = S3.AbortIncompleteMultipartUpload(daysAfterInitiation: 7)  // clear incomplete multipart uploads after 7 days
                let filter = S3.LifecycleRuleFilter(prefix: "")  // everything
                let transitions = [S3.Transition(days: 14, storageClass: .glacier)]  // transition objects to glacier after 14 days
                let lifecycleRules = S3.LifecycleRule(
                    abortIncompleteMultipartUpload: incompleteMultipartUploads,
                    filter: filter,
                    id: "aws-test",
                    status: .enabled,
                    transitions: transitions
                )
                let request = S3.PutBucketLifecycleConfigurationRequest(bucket: name, lifecycleConfiguration: .init(rules: [lifecycleRules]))
                return self.s3.putBucketLifecycleConfiguration(request)
        }
        .flatMap { _ in
            return self.s3.getBucketLifecycleConfiguration(.init(bucket: name))
        }
        .map { response -> Void in
            XCTAssertEqual(response.rules?[0].transitions?[0].storageClass, .glacier)
            XCTAssertEqual(response.rules?[0].transitions?[0].days, 14)
            XCTAssertEqual(response.rules?[0].abortIncompleteMultipartUpload?.daysAfterInitiation, 7)
        }
        .flatAlways { _ in
            return self.deleteBucket(name: name)
        }
        XCTAssertNoThrow(try response.wait())
    }

    /// test metadata is uploaded and downloaded ok
    func testMetaData() {
        let name = TestEnvironment.generateResourceName()
        let contents = "testing metadata header"
        let response = createBucket(name: name)
            .flatMap { (_) -> EventLoopFuture<S3.PutObjectOutput> in
                let putRequest = S3.PutObjectRequest(
                    body: .string(contents),
                    bucket: name,
                    key: name,
                    metadata: ["Test": "testing", "first": "one"]
                )
                return self.s3.putObject(putRequest)
        }
        .flatMap { _ -> EventLoopFuture<S3.GetObjectOutput> in
            return self.s3.getObject(.init(bucket: name, key: name))
        }
        .map { response -> Void in
            XCTAssertEqual(response.metadata?["test"], "testing")
            XCTAssertEqual(response.metadata?["first"], "one")
        }
        .flatAlways { _ in
            return self.deleteBucket(name: name)
        }
        XCTAssertNoThrow(try response.wait())
    }

    func testMultipleUpload() {
        func putGet(body: String, bucket: String, key: String) -> EventLoopFuture<Void> {
            return s3.putObject(.init(body: .string(body), bucket: bucket, key: key))
                .flatMap { _ in
                    return self.s3.getObject(.init(bucket: bucket, key: key))
            }
            .flatMapThrowing { response in
                let getBody = try XCTUnwrap(response.body)
                XCTAssertEqual(getBody.asString(), body)
            }
        }
        
        let name = TestEnvironment.generateResourceName()
        let eventLoop = s3.client.eventLoopGroup.next()
        let response = createBucket(name: name)
            .flatMap { (_) -> EventLoopFuture<Void> in
                let futureResults = (1...16).map { index -> EventLoopFuture<Void> in
                    let body = "testMultipleUpload - " + index.description
                    let filename = "file" + index.description
                    return putGet(body: body, bucket: name, key: filename)
                }
                return EventLoopFuture.whenAllSucceed(futureResults, on: eventLoop).map { _ in }
        }
        .flatAlways { _ in
            return self.deleteBucket(name: name)
        }
        XCTAssertNoThrow(try response.wait())
    }

    /// testing decoding of values in xml attributes
    func testGetAclRequestPayer() {
        let name = TestEnvironment.generateResourceName()
        let contents = "testing xml attributes header"
        let response = createBucket(name: name)
            .flatMap { (_) -> EventLoopFuture<S3.PutObjectOutput> in
                let putRequest = S3.PutObjectRequest(
                    body: .string(contents),
                    bucket: name,
                    key: name
                )
                return self.s3.putObject(putRequest)
        }
        .flatMap { _ -> EventLoopFuture<S3.GetObjectAclOutput> in
            return self.s3.getObjectAcl(.init(bucket: name, key: name, requestPayer: .requester))
        }
        .flatAlways { response -> EventLoopFuture<Void> in
            print(response)
            return self.deleteBucket(name: name)
        }
        XCTAssertNoThrow(try response.wait())
    }

    func testListPaginator() {
        let name = TestEnvironment.generateResourceName()
        let eventLoop = s3.client.eventLoopGroup.next()
        var list: [S3.Object] = []
        let response = createBucket(name: name)
            .flatMap { (_) -> EventLoopFuture<Void> in
                // put 16 files into bucket
                let futureResults: [EventLoopFuture<S3.PutObjectOutput>] = (1...16).map {
                    let body = "testMultipleUpload - " + $0.description
                    let filename = "file" + $0.description
                    return self.s3.putObject(.init(body: .string(body), bucket: name, key: filename))
                }
                return EventLoopFuture.whenAllSucceed(futureResults, on: eventLoop).map { _ in }
        }
        .flatMap { _ in
            return self.s3.listObjectsV2Paginator(.init(bucket: name, maxKeys: 5)) { result, eventLoop in
                list.append(contentsOf: result.contents ?? [])
                return eventLoop.makeSucceededFuture(true)
            }
        }
        .flatMap { _ in
            return self.s3.listObjectsV2(.init(bucket: name))
        }
        .map { response in
            XCTAssertEqual(list.count, response.contents?.count)
            for i in 0..<list.count {
                XCTAssertEqual(list[i].key, response.contents?[i].key)
            }
        }
        .flatAlways { _ in
            return self.deleteBucket(name: name)
        }
        XCTAssertNoThrow(try response.wait())
    }

    func testS3VirtualAddressing(_ urlString: String) throws -> String {
        let url = URL(string: urlString)!
        let request = try AWSRequest(
            region: .useast1,
            url: url,
            serviceProtocol: s3.client.serviceProtocol,
            operation: "TestOperation",
            httpMethod: "GET",
            httpHeaders: [:],
            body: .empty
        ).applyMiddlewares(s3.client.serviceConfig.middlewares)
        return request.url.relativeString
    }

    func testS3VirtualAddressing() {
        XCTAssertEqual(try testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket"), "https://bucket.s3.us-east-1.amazonaws.com/")
        XCTAssertEqual(try testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket/filename"), "https://bucket.s3.us-east-1.amazonaws.com/filename")
        XCTAssertEqual(try testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket/filename?test=test&test2=test2"), "https://bucket.s3.us-east-1.amazonaws.com/filename?test=test&test2=test2")
        XCTAssertEqual(try testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket/filename?test=%3D"), "https://bucket.s3.us-east-1.amazonaws.com/filename?test=%3D")
        XCTAssertEqual(try testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket/file%20name"), "https://bucket.s3.us-east-1.amazonaws.com/file%20name")
    }

    static var allTests: [(String, (S3Tests) -> () throws -> Void)] {
        return [
            ("testPutGetObject", testPutGetObject),
            ("testListObjects", testListObjects),
            ("testMultiPartDownload", testMultiPartDownload),
            ("testMultiPartUpload", testMultiPartUpload),
            ("testStreamPutObject", testStreamPutObject),
            ("testGetBucketLocation", testGetBucketLocation),
            ("testLifecycleRule", testLifecycleRule),
            ("testMetaData", testMetaData),
            ("testMultipleUpload", testMultipleUpload),
            ("testListPaginator", testListPaginator),
        ]
    }
}
