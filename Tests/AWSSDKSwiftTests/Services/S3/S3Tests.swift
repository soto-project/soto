//
//  S3Tests.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/06.
//
//

import Foundation
import Dispatch
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
        let deleteRequest = S3.DeleteObjectRequest(bucket: TestData.shared.bucket, key: TestData.shared.key)
        _ = try? client.deleteObject(deleteRequest).wait()
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
        XCTAssertEqual(output.contents?.first?.size, Int32(TestData.shared.bodyData.count))
        XCTAssertEqual(output.contents?.first?.eTag, putResult.eTag?.replacingOccurrences(of: "\"", with: ""))
    }


    static var allTests : [(String, (S3Tests) -> () throws -> Void)] {
        return [
            ("testPutObject", testPutObject),
            ("testListObjects", testListObjects),
            ("testGetObject", testGetObject),
        ]
    }
}
