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
        XCTAssertEqual(output.contents?.first?.size, Int64(TestData.shared.bodyData.count))
        XCTAssertEqual(output.contents?.first?.eTag, putResult.eTag?.replacingOccurrences(of: "\"", with: ""))
    }

    func testCreateMultipartUploadXML() {
        let request = S3.CreateMultipartUploadRequest(acl: .authenticatedRead, bucket: "test-bucket", expires: TimeStamp(Date(timeIntervalSince1970: 10000000)), key:"test-object", metadata: ["test-key":"test-value"], objectLockLegalHoldStatus:.on, objectLockMode: .compliance, objectLockRetainUntilDate: TimeStamp(Date(timeIntervalSince1970: 10003600)), requestPayer: .requester, serverSideEncryption: .aes256, storageClass: .standard)
        do {
            let expectedResult = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><CreateMultipartUploadRequest><x-amz-acl>authenticated-read</x-amz-acl><Bucket>test-bucket</Bucket><Expires>1970-04-26T17:46:40.000Z</Expires><Key>test-object</Key><Metadata><entry><key>test-key</key><value>test-value</value></entry></Metadata><x-amz-object-lock-legal-hold>ON</x-amz-object-lock-legal-hold><x-amz-object-lock-mode>COMPLIANCE</x-amz-object-lock-mode><x-amz-object-lock-retain-until-date>1970-04-26T18:46:40.000Z</x-amz-object-lock-retain-until-date><x-amz-request-payer>requester</x-amz-request-payer><x-amz-server-side-encryption>AES256</x-amz-server-side-encryption><x-amz-storage-class>STANDARD</x-amz-storage-class></CreateMultipartUploadRequest>"
            let awsRequest = try client.client.debugCreateAWSRequest(operation: "CreateMultipartUpload", path: "/{Bucket}/{Key+}?uploads", httpMethod: "POST", input: request)
            
            let bodyData = try awsRequest.body.asData()
            XCTAssertNotNil(bodyData)
            let body = String(data:bodyData!, encoding: .utf8)!
            XCTAssertEqual(body, expectedResult)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    static var allTests : [(String, (S3Tests) -> () throws -> Void)] {
        return [
            ("testPutObject", testPutObject),
            ("testListObjects", testListObjects),
            ("testGetObject", testGetObject),
            ("testCreateMultipartUploadXML", testCreateMultipartUploadXML)
        ]
    }
}
