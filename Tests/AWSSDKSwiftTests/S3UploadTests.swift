//
//  S3UploadTests.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/13.
//
//

import Foundation
import Dispatch
import XCTest
import Core
@testable import AWSSDKSwift

class S3UploadTests: XCTestCase {
    static var allTests : [(String, (S3UploadTests) -> () throws -> Void)] {
        return [
            ("testUpload", testUpload),
        ]
    }
    
    func testUpload() {
        let sig = Signers.V4(
            accessKey: ProcessInfo.processInfo.environment["AWS_ACCESS_KEY_ID"]!,
            secretKey: ProcessInfo.processInfo.environment["AWS_SECRET_ACCESS_KEY"]!,
            region: .apnortheast1,
            endpointPrefix: "s3"
        )
        
        let root = #file.characters
            .split(separator: "/", omittingEmptySubsequences: false)
            .dropLast(3)
            .map { String($0) }
            .joined(separator: "/")
        
        let filePath = "\(root)/Resources/miketokyo-logo.jpg"
        let bodyData = try! Data(contentsOf: URL(string: "file://\(filePath)")!)
        let url = URL(string: ProcessInfo.processInfo.environment["S3_URL_FOR_UPLOAD"]!)!
        let headers = sig.signedHeaders(url: url, bodyDigest: sha256(bodyData).hexdigest())
        
        var request = URLRequest(url: url)
        
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        request.httpMethod = "PUT"
        request.addValue("\(bodyData.count)", forHTTPHeaderField: "Content-Length")
        request.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        
        print(request.allHTTPHeaderFields)
        
        let g = DispatchGroup()
        
        g.enter()
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            let response = (response as! HTTPURLResponse)
            XCTAssertEqual(response.statusCode, 200)
            g.leave()
        }
        
        task.resume()
        g.wait()
    }
}

