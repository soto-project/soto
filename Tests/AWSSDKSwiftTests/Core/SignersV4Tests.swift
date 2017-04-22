//
//  SignersV4Tests.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/05.
//
//

import Foundation
import XCTest
@testable import Core

class SignersV4TestsTests: XCTestCase {
    static var allTests : [(String, (SignersV4TestsTests) -> () throws -> Void)] {
        return [
            ("testHexEncodedBodyHash", testHexEncodedBodyHash),
            ("testSignedHeaders", testSignedHeaders),
            ("testCredential", testCredential),
            ("testStringToSign", testStringToSign),
            ("testCanonicalRequest", testCanonicalRequest),
            ("testSignature", testSignature),
            ("testSignedHeadersForS3", testSignedHeadersForS3),
            ("testSignedQuery", testSignedQuery)
        ]
    }
    
    var requestDate: Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        //dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter.date(from: "2017-01-01 00:00:00")!
    }
    
    var timestamp: String {
        return Signers.V4.timestamp(requestDate)
    }
    
    var credential: Credential {
        return Credential(accessKeyId: "key", secretAccessKey: "secret")
    }
    
    func ec2Signer() -> (Signers.V4, URL, [String: String]) {
        let sign = Signers.V4(credentials: credential, region: .apnortheast1, service: "ec2")
        let host = "\(sign.service).\(sign.region).amazon.com"
        let url = URL(string: "https://\(host)/foo?query=foobar")!
        let headers: [String: String] = ["Host": host]
        return (sign, url, headers)
    }
    
    func testHexEncodedBodyHash() {
        let helloDigest = "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
        let ec2sign = Signers.V4(credentials: credential, region: .apnortheast1, service: "ec2")
        XCTAssertEqual(ec2sign.hexEncodedBodyHash("hello".data(using: .utf8)!), helloDigest)
        
        let s3sign = Signers.V4(credentials: credential, region: .apnortheast1, service: "s3")
        // if body data is empty, should return `UNSIGNED-PAYLOAD`
        XCTAssertEqual(s3sign.hexEncodedBodyHash(Data()), "UNSIGNED-PAYLOAD")
        
        // if body data is not empty, should return body digest
        XCTAssertEqual(s3sign.hexEncodedBodyHash("hello".data(using: .utf8)!), helloDigest)
    }
    
    func testSignedHeaders() {
        let (sign, url, _) = ec2Signer()
        
        let headers = sign.signedHeaders(url: url, headers: [:], method: "POST", date: requestDate, bodyData: "hello".data(using: .utf8)!)
        
        XCTAssertEqual(headers["Host"], "ec2.apnortheast1.amazon.com")
        XCTAssertEqual(headers["x-amz-content-sha256"], "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
        XCTAssertEqual(headers["x-amz-date"], "20170101T000000Z")
        XCTAssertEqual(headers["Authorization"], "AWS4-HMAC-SHA256 Credential=key/20170101/ap-northeast-1/ec2/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=7c6c37e1cbfd7f7594a55dfbc25c49e1ada0b4898f4add6160f6346f40936015")
    }
    
    func testCredential() {
        let (sign, _, _) = ec2Signer()
        XCTAssertEqual(sign.credential(timestamp), "key/20170101/ap-northeast-1/ec2/aws4_request")
    }
    
    func testStringToSign() {
        let (sign, url, httpHeaders) = ec2Signer()
        let stringToSign = sign.stringToSign(url: url, headers: httpHeaders, datetime: timestamp, method: "PUT", bodyDigest: sha256("hello").hexdigest())
        
        let splited = stringToSign.components(separatedBy: "\n")
        XCTAssertEqual(splited[0], "AWS4-HMAC-SHA256")
        XCTAssertEqual(splited[1], "20170101T000000Z")
        XCTAssertEqual(splited[2], "20170101/ap-northeast-1/ec2/aws4_request")
        XCTAssertEqual(splited[3], "13c4a719e774503a37696180fa98caecf7ac29200128f217e337d417f80a4860")
    }
    
    func testCanonicalRequest() {
        let (sign, url, httpHeaders) = ec2Signer()
        let bodyDigest = sha256("hello").hexdigest()
        let canonicalRequest = sign.canonicalRequest(url: url, headers: httpHeaders, method: "PUT", bodyDigest: bodyDigest)
        
        let splited = canonicalRequest.components(separatedBy: "\n")
        XCTAssertEqual(splited[0], "PUT")
        XCTAssertEqual(splited[1], "/foo")
        XCTAssertEqual(splited[2], "query=foobar")
        XCTAssertEqual(splited[3], "host:ec2.apnortheast1.amazon.com")
        XCTAssertEqual(splited[4], "")
        XCTAssertEqual(splited[5], "host")
        XCTAssertEqual(splited[6], "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
    }
    
    func testSignature() {
        let (sign, url, httpHeaders) = ec2Signer()
        let bodyDigest = sha256("hello").hexdigest()
        let signature = sign.signature(url: url, headers: httpHeaders, datetime: timestamp, method: "PUT", bodyDigest: bodyDigest)
        XCTAssertEqual(signature, "4a2fc55d5e517133a8dae28752f36851e77f291221095ee9fb4cfcff8ac63dd9")
    }
    
    func testSignedHeadersForS3() {
        let sign = Signers.V4(credentials: credential, region: .apnortheast1, service: "s3")
        let host = "\(sign.service)-\(sign.region).amazon.com"
        let url = URL(string: "https://\(host)")!
        let headers = sign.signedHeaders(url: url, headers: [:], method: "PUT", date: requestDate, bodyData: Data())
        
        XCTAssertEqual(headers["Host"], "s3-apnortheast1.amazon.com")
        XCTAssertEqual(headers["x-amz-content-sha256"], "UNSIGNED-PAYLOAD")
        XCTAssertEqual(headers["x-amz-date"], "20170101T000000Z")
        XCTAssertEqual(headers["Authorization"], "AWS4-HMAC-SHA256 Credential=key/20170101/ap-northeast-1/s3/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=dcd1b4bbe822227213a38c745eb511a7a017c2709e34af88838a1c8d659ec57a")
    }
    
    func testSignedQuery() {
        let sign = Signers.V4(credentials: credential, region: .apnortheast1, service: "s3")
        let host = "\(sign.service)-\(sign.region).amazon.com"
        let url = URL(string: "https://\(host)")!
        let signedURL = sign.signedURL(url: url, date: requestDate)
        
        XCTAssertEqual(signedURL.absoluteString, "https://s3-apnortheast1.amazon.com?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=key%2F20170101%2Fap-northeast-1%2Fs3%2Faws4_request&X-Amz-Date=20170101T000000Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=c3c920a3b89cb39b01ef6f99228e4cfae5fc8a4ab5de9c5b4ad96e9b05ee0f61")
    }
}

