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
        let bucket : String
        let bodyData : Data
        let key : String
        
        init(_ testName: String) {
            let testName = testName.lowercased().filter { return $0.isLetter }
            self.bucket = "\(testName)-bucket"
            self.bodyData = "\(testName) hello world".data(using: .utf8)!
            self.key = "\(testName)-key.txt"
        }
    }

    var client = S3(
            accessKeyId: "key",
            secretAccessKey: "secret",
            region: .apnortheast1,
            endpoint: "http://localhost:4572"
    )

    /// setup test
    func setUp(_ testData: TestData) throws {
        do {
            let bucketRequest = S3.CreateBucketRequest(bucket: testData.bucket)
            _ = try client.createBucket(bucketRequest).wait()
        } catch S3ErrorType.bucketAlreadyOwnedByYou(_) {
            print("Bucket (\(testData.bucket)) already owned by you")
        } catch S3ErrorType.bucketAlreadyExists(_) {
            print("Bucket (\(testData.bucket)) already exists")
        }
    }

    /// teardown test
    func tearDown(_ testData: TestData) {
        attempt {
            let objects = try client.listObjects(S3.ListObjectsRequest(bucket: testData.bucket)).wait()
            if let objects = objects.contents {
                for object in objects {
                    if let key = object.key {
                        let deleteRequest = S3.DeleteObjectRequest(bucket: testData.bucket, key: key)
                        _ = try client.deleteObject(deleteRequest).wait()
                    }
                }
            }
            let deleteRequest = S3.DeleteBucketRequest(bucket: testData.bucket)
            _ = try client.deleteBucket(deleteRequest).wait()
        }
    }

    //MARK: TESTS
    
    func testPutObject() {
        attempt {
            let testData = TestData(#function)
            try setUp(testData)
            defer {
                tearDown(testData)
            }

            let putRequest = S3.PutObjectRequest(
                acl: .publicRead,
                body: testData.bodyData,
                bucket: testData.bucket,
                contentLength: Int64(testData.bodyData.count),
                key: testData.key
            )

            let output = try client.putObject(putRequest).wait()
            XCTAssertNotNil(output.eTag)
        }
    }


    func testGetObject() {
        attempt {
            let testData = TestData(#function)
            try setUp(testData)
            defer {
                tearDown(testData)
            }

            let putRequest = S3.PutObjectRequest(
                acl: .publicRead,
                body: testData.bodyData,
                bucket: testData.bucket,
                contentLength: Int64(testData.bodyData.count),
                key: testData.key
            )

            _ = try client.putObject(putRequest).wait()
            let object = try client.getObject(S3.GetObjectRequest(bucket: testData.bucket, key: testData.key)).wait()
            XCTAssertEqual(object.body, testData.bodyData)
        }
    }

    func testMultiPartDownload() {
        attempt {
            let testData = TestData(#function)
            try setUp(testData)
            defer {
                tearDown(testData)
            }

            let putRequest = S3.PutObjectRequest(
                acl: .publicRead,
                body: testData.bodyData,
                bucket: testData.bucket,
                contentLength: Int64(testData.bodyData.count),
                key: testData.key
            )
            _ = try client.putObject(putRequest).wait()

            let filename = testData.key
            _ = try client.multipartDownload(
                S3.GetObjectRequest(bucket: testData.bucket, key: testData.key),
                partSize: 5,
                filename: filename
            ).wait()
            XCTAssert(FileManager.default.fileExists(atPath: filename))
            try FileManager.default.removeItem(atPath: filename)
        }
    }

    func testMultiPartUpload() {
        attempt {
            let testData = TestData(#function)
            try setUp(testData)
            defer {
                tearDown(testData)
            }

            let multiPartUploadRequest = S3.CreateMultipartUploadRequest(
                acl: .publicRead,
                bucket: testData.bucket,
                key: testData.key
            )

            // create buffer
            let dataSize = 16*1024*1024
            var data = Data(count: dataSize)
            for i in 0..<dataSize {
                data[i] = UInt8.random(in:0...255)
            }
            
            let filename = testData.key
            try data.write(to: URL(fileURLWithPath: filename))

            _ = try client.multipartUpload(multiPartUploadRequest, partSize: 5*1024*1024, filename: filename).wait()
            let object = try client.getObject(S3.GetObjectRequest(bucket: testData.bucket, key: filename)).wait()
            
            XCTAssertEqual(object.body, data)
            try FileManager.default.removeItem(atPath: filename)
        }
    }

    /// test uploaded objects are returned in ListObjects
    func testListObjects() {
        attempt {
            let testData = TestData(#function)
            try setUp(testData)
            defer {
                tearDown(testData)
            }

            let putRequest = S3.PutObjectRequest(
                acl: .publicRead,
                body: testData.bodyData,
                bucket: testData.bucket,
                contentLength: Int64(testData.bodyData.count),
                key: testData.key
            )

            let putResult = try client.putObject(putRequest).wait()

            let output = try client.listObjects(S3.ListObjectsRequest(bucket: testData.bucket)).wait()

            XCTAssertEqual(output.contents?.first?.key, testData.key)
            XCTAssertEqual(output.contents?.first?.size, Int64(testData.bodyData.count))
            XCTAssertEqual(output.contents?.first?.eTag, putResult.eTag)
        }
    }

    /// test bucket location is correctly returned.
    func testGetBucketLocation() {
        attempt {
            let testData = TestData(#function)
            try setUp(testData)
            defer {
                tearDown(testData)
            }

            let request = S3.GetBucketLocationRequest(bucket: testData.bucket)
            let response = try client.getBucketLocation(request).wait()
            XCTAssertNotNil(response.locationConstraint)
        }
    }

    /// test lifecycle rules are uploaded and downloaded ok
    func testLifecycleRule() {
        attempt {
            let testData = TestData(#function)
            try setUp(testData)
            defer {
                tearDown(testData)
            }

            // set lifecycle rules
            let incompleteMultipartUploads = S3.AbortIncompleteMultipartUpload(daysAfterInitiation: 7) // clear incomplete multipart uploads after 7 days
            let filter = S3.LifecycleRuleFilter(prefix:"") // everything
            let transitions = [S3.Transition(days: 14, storageClass: .glacier)] // transition objects to glacier after 14 days
            let lifecycleRules = S3.LifecycleRule(abortIncompleteMultipartUpload: incompleteMultipartUploads, filter: filter, id: "aws-test", status:.enabled, transitions: transitions)
            let putBucketLifecycleRequest = S3.PutBucketLifecycleConfigurationRequest(bucket: testData.bucket, lifecycleConfiguration:S3.BucketLifecycleConfiguration(rules:[lifecycleRules]))
            try client.putBucketLifecycleConfiguration(putBucketLifecycleRequest).wait()

            // get lifecycle rules
            let getBucketLifecycleRequest = S3.GetBucketLifecycleConfigurationRequest(bucket: testData.bucket)
            let getBucketLifecycleResult = try client.getBucketLifecycleConfiguration(getBucketLifecycleRequest).wait()

            XCTAssertEqual(getBucketLifecycleResult.rules?[0].transitions?[0].storageClass, .glacier)
            XCTAssertEqual(getBucketLifecycleResult.rules?[0].transitions?[0].days, 14)
            XCTAssertEqual(getBucketLifecycleResult.rules?[0].abortIncompleteMultipartUpload?.daysAfterInitiation, 7)
        }
    }

    /// test metadata is uploaded and downloaded ok
    func testMetaData() {
        attempt {
            let testData = TestData(#function)
            try setUp(testData)
            defer {
               tearDown(testData)
            }

            let putObjectRequest = S3.PutObjectRequest(body: testData.bodyData, bucket: testData.bucket, key: testData.key, metadata: ["Test": "testing", "first" : "one"])
            _ = try client.putObject(putObjectRequest).wait()

            let getObjectRequest = S3.GetObjectRequest(bucket: testData.bucket, key: testData.key)
            let result = try client.getObject(getObjectRequest).wait()
            XCTAssertEqual(result.metadata?["test"], "testing")
            XCTAssertEqual(result.metadata?["first"], "one")
        }
    }


    static var allTests : [(String, (S3Tests) -> () throws -> Void)] {
        return [
            ("testPutObject", testPutObject),
            ("testListObjects", testListObjects),
            ("testGetObject", testGetObject),
            ("testMultiPartDownload", testMultiPartDownload),
            ("testMultiPartUpload", testMultiPartUpload),
            ("testGetBucketLocation", testGetBucketLocation),
            ("testLifecycleRule", testLifecycleRule),
            ("testMetaData", testMetaData),
        ]
    }
}
