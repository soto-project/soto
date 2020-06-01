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

// testing S3 service
enum S3TestErrors: Error {
    case error(String)
}

class S3Tests: XCTestCase {

    var s3 = S3(
        region: .euwest1,
        endpoint: TestEnvironment.getEndPoint(environment: "S3_ENDPOINT", default: "http://localhost:4572"),
        middlewares: TestEnvironment.middlewares,
        httpClientProvider: .createNew
    )

    class TestData {
        let s3: S3
        let bucket: String
        let bodyData: Data
        let key: String

        init(_ testName: String, s3: S3) throws {
            let testName = testName.lowercased().filter { return $0.isLetter }
            self.s3 = s3
            self.bucket = "\(testName)-bucket"
            self.bodyData = "\(testName) hello world".data(using: .utf8)!
            self.key = "\(testName)-key.txt"

            do {
                let bucketRequest = S3.CreateBucketRequest(bucket: self.bucket)
                _ = try s3.createBucket(bucketRequest).wait()
            } catch S3ErrorType.bucketAlreadyOwnedByYou(_) {
                print("Bucket (\(self.bucket)) already owned by you")
            } catch S3ErrorType.bucketAlreadyExists(_) {
                print("Bucket (\(self.bucket)) already exists")
            }
        }

        deinit {
            attempt {
                let objects = try s3.listObjects(S3.ListObjectsRequest(bucket: self.bucket)).wait()
                if let objects = objects.contents {
                    for object in objects {
                        if let key = object.key {
                            let deleteRequest = S3.DeleteObjectRequest(bucket: self.bucket, key: key)
                            _ = try s3.deleteObject(deleteRequest).wait()
                        }
                    }
                }
                let deleteRequest = S3.DeleteBucketRequest(bucket: self.bucket)
                _ = try s3.deleteBucket(deleteRequest).wait()
            }
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
    
    func createBucket(name: String) -> EventLoopFuture<Void> {
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
    
    func deleteBucket(name: String) -> EventLoopFuture<Void> {
        let request = S3.ListObjectsV2Request(bucket: name)
        return s3.listObjectsV2(request)
            .flatMap { response -> EventLoopFuture<Void> in
                let eventLoop = self.s3.client.eventLoopGroup.next()
                guard let objects = response.contents else { return eventLoop.makeSucceededFuture(())}
                let deleteFutureResults = objects.compactMap { $0.key.map { self.s3.deleteObject(.init(bucket: name, key: $0)) } }
                return EventLoopFuture.andAllSucceed(deleteFutureResults, on: eventLoop)
        }
        .flatMap { _ in
            let request = S3.DeleteBucketRequest(bucket: name)
            return self.s3.deleteBucket(request).map { _ in }
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
            accessKeyId: "key",
            secretAccessKey: "secret",
            region: .euwest1,
            endpoint: ProcessInfo.processInfo.environment["S3_ENDPOINT"] ?? "http://localhost:4572",
            httpClientProvider: .shared(httpClient)
        )

        attempt {
            let testData = try TestData(#function, s3: s3)
            // create buffer
            let dataSize = 240*1024
            var data = Data(count: dataSize)
            for i in 0..<dataSize {
                data[i] = UInt8.random(in:0...255)
            }
            var byteBuffer = ByteBufferAllocator().buffer(capacity: dataSize)
            byteBuffer.writeBytes(data)

            let blockSize = 64*1024
            let payload = AWSPayload.stream(size: dataSize) { eventLoop in
                let size = min(blockSize, byteBuffer.readableBytes)
                if size == 0 {
                    return eventLoop.makeSucceededFuture(byteBuffer)
                }
                let slice = byteBuffer.readSlice(length: size)!
                return eventLoop.makeSucceededFuture(slice)
            }
            
            let putRequest = S3.PutObjectRequest(body: payload, bucket: testData.bucket, key: "tempfile")
            _ = try s3.putObject(putRequest).wait()

            let getRequest = S3.GetObjectRequest(bucket: testData.bucket, key: "tempfile")
            let response = try s3.getObject(getRequest).wait()

            XCTAssertEqual(data, response.body?.asData())
        }
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
        attempt {
            let testData = try TestData(#function, s3: s3)

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
            let putBucketLifecycleRequest = S3.PutBucketLifecycleConfigurationRequest(
                bucket: testData.bucket,
                lifecycleConfiguration: S3.BucketLifecycleConfiguration(rules: [lifecycleRules])
            )
            try s3.putBucketLifecycleConfiguration(putBucketLifecycleRequest).wait()

            // get lifecycle rules
            let getBucketLifecycleRequest = S3.GetBucketLifecycleConfigurationRequest(bucket: testData.bucket)
            let getBucketLifecycleResult = try s3.getBucketLifecycleConfiguration(getBucketLifecycleRequest).wait()

            XCTAssertEqual(getBucketLifecycleResult.rules?[0].transitions?[0].storageClass, .glacier)
            XCTAssertEqual(getBucketLifecycleResult.rules?[0].transitions?[0].days, 14)
            XCTAssertEqual(getBucketLifecycleResult.rules?[0].abortIncompleteMultipartUpload?.daysAfterInitiation, 7)
        }
    }

    /// test metadata is uploaded and downloaded ok
    func testMetaData() {
        attempt {
            let testData = try TestData(#function, s3: s3)

            let putObjectRequest = S3.PutObjectRequest(
                body: .data(testData.bodyData),
                bucket: testData.bucket,
                key: testData.key,
                metadata: ["Test": "testing", "first": "one"]
            )
            _ = try s3.putObject(putObjectRequest).wait()

            let getObjectRequest = S3.GetObjectRequest(bucket: testData.bucket, key: testData.key)
            let result = try s3.getObject(getObjectRequest).wait()
            XCTAssertEqual(result.metadata?["test"], "testing")
            XCTAssertEqual(result.metadata?["first"], "one")
        }
    }

    func testMultipleUpload() {
        attempt {
            let testData = try TestData(#function, s3: s3)

            // uploads 100 files at the same time and then downloads them to check they uploaded correctly
            var responses: [EventLoopFuture<Void>] = []
            for i in 0..<16 {
                let objectName = "testMultiple\(i).txt"
                let text = "Testing, testing,1,2,1,\(i)"

                let request = S3.PutObjectRequest(body: .string(text), bucket: testData.bucket, key: objectName)
                let response = s3.putObject(request)
                    .flatMap { (response) -> EventLoopFuture<S3.GetObjectOutput> in
                        let request = S3.GetObjectRequest(bucket: testData.bucket, key: objectName)
                        return self.s3.getObject(request)
                    }
                    .flatMapThrowing { response in
                        guard let body = response.body else { throw S3TestErrors.error("Get \(objectName) failed") }
                        guard text == body.asString() else { throw S3TestErrors.error("Get \(objectName) contents is incorrect") }
                        return
                    }
                responses.append(response)
            }

            let results = try EventLoopFuture.whenAllComplete(responses, on: s3.client.eventLoopGroup.next()).wait()

            for r in results {
                if case .failure(let error) = r {
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }

    func testGetAclRequestPayer() {
        attempt {
            let testData = try TestData(#function, s3: s3)
            let putRequest = S3.PutObjectRequest(
                body: .data(testData.bodyData),
                bucket: testData.bucket,
                contentLength: Int64(testData.bodyData.count),
                key: testData.key
            )
            _ = try s3.putObject(putRequest).wait()
            let request = S3.GetObjectAclRequest(bucket: testData.bucket, key: testData.key, requestPayer: .requester)
            _ = try s3.getObjectAcl(request).wait()
        }
    }

    func testListPaginator() {
        attempt {
            let testData = try TestData(#function, s3: s3)

            // uploads 16 files
            var responses: [EventLoopFuture<Void>] = []
            for i in 0..<16 {
                let objectName = "testMultiple\(i).txt"
                let text = "Testing, testing,1,2,1,\(i)"

                let request = S3.PutObjectRequest(body: .string(text), bucket: testData.bucket, key: objectName)
                let response = s3.putObject(request).map { _ in }
                responses.append(response)
            }
            _ = try EventLoopFuture.whenAllSucceed(responses, on: s3.client.eventLoopGroup.next()).wait()

            let request = S3.ListObjectsV2Request(bucket: testData.bucket, maxKeys: 5)
            var list: [S3.Object] = []
            try s3.listObjectsV2Paginator(request) { result, eventLoop in
                list.append(contentsOf: result.contents ?? [])
                return eventLoop.makeSucceededFuture(true)
            }.wait()

            let request2 = S3.ListObjectsV2Request(bucket: testData.bucket)
            let response = try s3.listObjectsV2(request2).wait()
            XCTAssertEqual(list.count, 16)
            for i in 0..<list.count {
                XCTAssertEqual(list[i].key, response.contents?[i].key)
            }
        }
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
        attempt {
            XCTAssertEqual(try testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket"), "https://bucket.s3.us-east-1.amazonaws.com/")
            XCTAssertEqual(
                try testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket/filename"),
                "https://bucket.s3.us-east-1.amazonaws.com/filename"
            )
            XCTAssertEqual(
                try testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket/filename?test=test&test2=test2"),
                "https://bucket.s3.us-east-1.amazonaws.com/filename?test=test&test2=test2"
            )
            XCTAssertEqual(
                try testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket/filename?test=%3D"),
                "https://bucket.s3.us-east-1.amazonaws.com/filename?test=%3D"
            )
            XCTAssertEqual(
                try testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket/file%20name"),
                "https://bucket.s3.us-east-1.amazonaws.com/file%20name"
            )
        }
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
