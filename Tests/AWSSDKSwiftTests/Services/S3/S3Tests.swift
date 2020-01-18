//
//  S3Tests.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/06.
//
//

import Foundation
import XCTest
import NIO
@testable import AWSSDKSwiftCore
@testable import AWSS3

// testing xml service

class S3Tests: XCTestCase {

    var client = S3(
        accessKeyId: "key",
        secretAccessKey: "secret",
        region: .euwest1,
        endpoint: ProcessInfo.processInfo.environment["S3_ENDPOINT"] ?? "http://localhost:4572",
        middlewares: [AWSLoggingMiddleware()]
    )

    class TestData {
        let client: S3
        let bucket : String
        let bodyData : Data
        let key : String

        init(_ testName: String, client: S3) throws {
            let testName = testName.lowercased().filter { return $0.isLetter }
            self.client = client
            self.bucket = "\(testName)-bucket"
            self.bodyData = "\(testName) hello world".data(using: .utf8)!
            self.key = "\(testName)-key.txt"

            do {
                let bucketRequest = S3.CreateBucketRequest(bucket: self.bucket)
                _ = try client.createBucket(bucketRequest).wait()
            } catch S3ErrorType.bucketAlreadyOwnedByYou(_) {
                print("Bucket (\(self.bucket)) already owned by you")
            } catch S3ErrorType.bucketAlreadyExists(_) {
                print("Bucket (\(self.bucket)) already exists")
            }
        }

        deinit {
            attempt {
                let objects = try client.listObjects(S3.ListObjectsRequest(bucket: self.bucket)).wait()
                if let objects = objects.contents {
                    for object in objects {
                        if let key = object.key {
                            let deleteRequest = S3.DeleteObjectRequest(bucket: self.bucket, key: key)
                            _ = try client.deleteObject(deleteRequest).wait()
                        }
                    }
                }
                let deleteRequest = S3.DeleteBucketRequest(bucket: self.bucket)
                _ = try client.deleteBucket(deleteRequest).wait()
            }
        }
    }

    //MARK: TESTS

    func testPutObject() {
        attempt {
            let testData = try TestData(#function, client: client)

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
            let testData = try TestData(#function, client: client)

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
            let testData = try TestData(#function, client: client)

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
            let testData = try TestData(#function, client: client)

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
            let testData = try TestData(#function, client: client)

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
            let testData = try TestData(#function, client: client)

            let request = S3.GetBucketLocationRequest(bucket: testData.bucket)
            let response = try client.getBucketLocation(request).wait()
            XCTAssertNotNil(response.locationConstraint)
        }
    }

    /// test lifecycle rules are uploaded and downloaded ok
    func testLifecycleRule() {
        attempt {
            let testData = try TestData(#function, client: client)

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
            let testData = try TestData(#function, client: client)

            let putObjectRequest = S3.PutObjectRequest(body: testData.bodyData, bucket: testData.bucket, key: testData.key, metadata: ["Test": "testing", "first" : "one"])
            _ = try client.putObject(putObjectRequest).wait()

            let getObjectRequest = S3.GetObjectRequest(bucket: testData.bucket, key: testData.key)
            let result = try client.getObject(getObjectRequest).wait()
            XCTAssertEqual(result.metadata?["test"], "testing")
            XCTAssertEqual(result.metadata?["first"], "one")
        }
    }

    func testMultipleUpload() {
        attempt {
            let testData = try TestData(#function, client: client)

            // uploads 100 files at the same time and then downloads them to check they uploaded correctly
            var responses : [Future<Void>] = []
            for i in 0..<16 {
                let objectName = "testMultiple\(i).txt"
                let text = "Testing, testing,1,2,1,\(i)"
                let data = text.data(using: .utf8)!

                let request = S3.PutObjectRequest(body: data, bucket: testData.bucket, key: objectName)
                let response = client.putObject(request)
                    .flatMap { (response)->Future<S3.GetObjectOutput> in
                        let request = S3.GetObjectRequest(bucket: testData.bucket, key: objectName)
                        print("Put \(objectName)")
                        return self.client.getObject(request)
                    }
                    .flatMapThrowing { response in
                        print("Get \(objectName)")
                        guard let body = response.body else {throw AWSError(message: "Get \(objectName) failed", rawBody: "") }
                        guard text == String(data: body, encoding: .utf8) else {throw AWSError(message: "Get \(objectName) contents is incorrect", rawBody: "") }
                        return
                }
                responses.append(response)
            }

            let results = try EventLoopFuture.whenAllComplete(responses, on: client.client.eventLoopGroup.next()).wait()
            
            for r in results {
                if case .failure(let error) = r {
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }
    
    func testGetAclRequestPayer() {
        attempt {
            let testData = try TestData(#function, client: client)
            let putRequest = S3.PutObjectRequest(
                body: testData.bodyData,
                bucket: testData.bucket,
                contentLength: Int64(testData.bodyData.count),
                key: testData.key
            )
            _ = try client.putObject(putRequest).wait()
            let request = S3.GetObjectAclRequest(bucket: testData.bucket, key: testData.key, requestPayer: .requester)
            _ = try client.getObjectAcl(request).wait()
        }
    }

    func listObjects(bucket : String, count: Int) -> Future<[S3.Object]> {
        var list : [S3.Object] = []
        func listObjectsPart(token: String? = nil) -> Future<[S3.Object]> {
            let request = S3.ListObjectsV2Request(bucket: bucket, continuationToken: token, maxKeys: count)
            let objects = client.listObjectsV2(request).flatMap { response -> Future<[S3.Object]> in
                if let contents = response.contents {
                    list.append(contentsOf: contents)
                }
                if let token = response.nextContinuationToken {
                    return listObjectsPart(token: token)
                } else {
                    return self.client.client.eventLoopGroup.next().makeSucceededFuture(list)
                }
            }
            return objects
        }
        return listObjectsPart()
    }

    func testListPaginate() {
        attempt {
            let testData = try TestData(#function, client: client)

            // uploads 16 files
            var responses : [Future<Void>] = []
            for i in 0..<16 {
                let objectName = "testMultiple\(i).txt"
                let text = "Testing, testing,1,2,1,\(i)"
                let data = text.data(using: .utf8)!

                let request = S3.PutObjectRequest(body: data, bucket: testData.bucket, key: objectName)
                let response = client.putObject(request).map { _ in }
                responses.append(response)
            }
            _ = try EventLoopFuture.whenAllSucceed(responses, on: client.client.eventLoopGroup.next()).wait()

            let list = try listObjects(bucket: testData.bucket, count:5).wait()
            XCTAssertEqual(list.count, 16)
        }
    }

    func testS3VirtualAddressing(_ urlString: String) throws -> String {
        let url = URL(string: urlString)!
        let request = try AWSRequest(region: .useast1, url: url, serviceProtocol: client.client.serviceProtocol, operation: "TestOperation", httpMethod: "GET", httpHeaders: [:], body: .empty).applyMiddlewares(client.client.middlewares)
        return request.url.relativeString
    }

    func testS3VirtualAddressing() {
        attempt {
            XCTAssertEqual(try testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket"), "https://bucket.s3.us-east-1.amazonaws.com/")
            XCTAssertEqual(try testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket/filename"), "https://bucket.s3.us-east-1.amazonaws.com/filename")
            XCTAssertEqual(try testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket/filename?test=test&test2=test2"), "https://bucket.s3.us-east-1.amazonaws.com/filename?test=test&test2=test2")
            XCTAssertEqual(try testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket/filename?test=%3D"), "https://bucket.s3.us-east-1.amazonaws.com/filename?test=%3D")
            XCTAssertEqual(try testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket/file%20name"), "https://bucket.s3.us-east-1.amazonaws.com/file%20name")
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
            ("testMultipleUpload", testMultipleUpload),
            ("testListPaginate", testListPaginate),
        ]
    }
}
