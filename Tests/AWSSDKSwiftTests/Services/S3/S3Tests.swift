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
@testable import AWSSDKSwift

class S3Tests: XCTestCase {
    static var allTests : [(String, (S3Tests) -> () throws -> Void)] {
        return [
            ("testGetObject", testGetObject),
        ]
    }
    
    var client: S3 {
        return S3(
            accessKeyId: "key",
            secretAccessKey: "secret",
            region: .apnortheast1,
            endpoint: "http://localhost:4572"
        )
    }
    
    var bucket: String {
        return "aws-sdk-swift-test-bucket"
    }
    
    override func setUp() {
        do {
            let bucketRequest = S3.CreateBucketRequest(bucket: bucket)
            let response = try client.createBucket(bucketRequest)
        } catch {
            print(error)
        }
        
        do {
            let bodyData = "hello world".data(using: .utf8)!
            let putRequest = S3.PutObjectRequest(bucket: bucket, contentLength: Int64(bodyData.count), key: "hello.txt", body: bodyData, aCL: "public-read")
            
            _ = try client.putObject(putRequest)
        } catch {
            print(error)
        }
    }
    
    func testGetObject() {
        let request = S3.GetObjectRequest(bucket: bucket, key: "hello.txt")
        do {
            let response = try client.getObject(request)
            XCTAssertEqual(String(data: response.body!, encoding: .utf8), "hello world")
        } catch {
            XCTFail("\(error)")
        }
    }
}
