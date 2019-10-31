//
//  S3Tests.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/06.
//
//

import Foundation
import NIO
import XCTest
@testable import S3
@testable import AWSSDKSwiftCore

class S3Tests: XCTestCase {

    struct TestData {
        static let shared = TestData()
        let bucket = "aws-sdk-swift-test-bucket"
        let bodyData = "hello world".data(using: .utf8)!
        let key = "hello.txt"
    }

    var client: S3 {
        return S3(
            accessKeyId: "key",
            secretAccessKey: "secret",
            region: .apnortheast1,
            endpoint: "http://localhost:4569"
        )
    }

    override func setUp() {
        let bucketRequest = S3.CreateBucketRequest(bucket: TestData.shared.bucket)
        _ = try? client.createBucket(bucketRequest).wait()
    }

    override func tearDown() {
        let objects = try? client.listObjects(S3.ListObjectsRequest(bucket: TestData.shared.bucket)).wait()
        if let objects = objects?.contents {
            for object in objects {
                if let key = object.key {
                    let deleteRequest = S3.DeleteObjectRequest(bucket: TestData.shared.bucket, key: key)
                    _ = try? client.deleteObject(deleteRequest).wait()
                }
            }
        }
    }

    func testPutObject() throws {
        let putRequest = S3.PutObjectRequest(
            acl: .publicRead,
            body: TestData.shared.bodyData,
            bucket: TestData.shared.bucket,
            contentLength: Int64(TestData.shared.bodyData.count),
            key: TestData.shared.key
        )

        let output = try client.putObject(putRequest).wait()
        XCTAssertNotNil(output.eTag)
    }


    func testGetObject() throws {
        let putRequest = S3.PutObjectRequest(
            acl: .publicRead,
            body: TestData.shared.bodyData,
            bucket: TestData.shared.bucket,
            contentLength: Int64(TestData.shared.bodyData.count),
            key: TestData.shared.key
        )

        _ = try client.putObject(putRequest).wait()
        let object = try client.getObject(S3.GetObjectRequest(bucket: TestData.shared.bucket, key: "hello.txt")).wait()
        XCTAssertEqual(object.body, TestData.shared.bodyData)
    }

    func testMultiPartDownload() throws {
        let putRequest = S3.PutObjectRequest(
            acl: .publicRead,
            body: TestData.shared.bodyData,
            bucket: TestData.shared.bucket,
            contentLength: Int64(TestData.shared.bodyData.count),
            key: TestData.shared.key
        )
        _ = try client.putObject(putRequest).wait()

        let filename = TestData.shared.key
        _ = try client.multipartDownload(
            S3.GetObjectRequest(bucket: TestData.shared.bucket, key: "hello.txt"),
            partSize: 5,
            filename: filename
        ).wait()
        XCTAssert(FileManager.default.fileExists(atPath: filename))
        try FileManager.default.removeItem(atPath: filename)
    }

    func testMultiPartUpload() throws {
        let multiPartUploadRequest = S3.CreateMultipartUploadRequest(
            acl: .publicRead,
            bucket: TestData.shared.bucket,
            key: TestData.shared.key
        )

        let filename = TestData.shared.key
        FileManager.default.createFile(atPath: filename, contents: nil)
        let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: filename))
        fileHandle.write(TestData.shared.bodyData)
        fileHandle.closeFile()
        _ = try client.multipartUpload(multiPartUploadRequest, partSize: 5, filename: filename).wait()
        let object = try client.getObject(S3.GetObjectRequest(bucket: TestData.shared.bucket, key: TestData.shared.key)).wait()
        XCTAssertEqual(object.body, TestData.shared.bodyData)
        try FileManager.default.removeItem(atPath: filename)
    }

    func testListObjects() throws {
        let putRequest = S3.PutObjectRequest(
            acl: .publicRead,
            body: TestData.shared.bodyData,
            bucket: TestData.shared.bucket,
            contentLength: Int64(TestData.shared.bodyData.count),
            key: TestData.shared.key
        )

        let putResult = try client.putObject(putRequest).wait()

        let output = try client.listObjects(S3.ListObjectsRequest(bucket: TestData.shared.bucket)).wait()

        XCTAssertEqual(output.maxKeys, 1000)
        XCTAssertEqual(output.contents?.first?.key, TestData.shared.key)
        XCTAssertEqual(output.contents?.first?.size, Int64(TestData.shared.bodyData.count))
        XCTAssertEqual(output.contents?.first?.eTag, putResult.eTag)
    }

    func testMultipleUpload() throws {
        // uploads 100 files at the same time and then downloads them to check they uploaded correctly
        var responses : [Future<Void>] = []
        for i in 0..<100 {
            let objectName = "testMultiple\(i).txt"
            let text = "Testing, testing,1,2,1,\(i)"
            let data = text.data(using: .utf8)!

            let request = S3.PutObjectRequest(body: data, bucket: TestData.shared.bucket, key: objectName)
            let response = client.putObject(request)
                .flatMap { (response)->Future<S3.GetObjectOutput> in
                    let request = S3.GetObjectRequest(bucket: TestData.shared.bucket, key: objectName)
                    return self.client.getObject(request)
                }
                .flatMapThrowing { response in
                    guard let body = response.body else {throw AWSError(message: "Get \(objectName) failed", rawBody: "") }
                    guard text == String(data: body, encoding: .utf8) else {throw AWSError(message: "Get \(objectName) contents is incorrect", rawBody: "") }
                    return
            }
            responses.append(response)
        }
        
        _ = try EventLoopFuture.whenAllSucceed(responses, on: AWSClient.eventGroup.next()).wait()
    }

    static var allTests : [(String, (S3Tests) -> () throws -> Void)] {
        return [
            ("testPutObject", testPutObject),
            ("testListObjects", testListObjects),
            ("testGetObject", testGetObject),
            ("testMultiPartDownload", testMultiPartDownload),
            ("testMultiPartUpload", testMultiPartUpload)
        ]
    }
}
