//
//  XMLParser.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/05.
//
//

import Foundation
import XCTest
@testable import Core

class XML2ParserTests: XCTestCase {
    static var allTests : [(String, (XML2ParserTests) -> () throws -> Void)] {
        return [
            ("testparse", testparse),
            ("testSerializeJSON", testSerializeJSON)
        ]
    }
    
    var dataSourceXML: Data {
        return "<Error>\n<Hoge><Fuga>aaaaa</Fuga><Fuga>bbbbb</Fuga><Foo>foobar</Foo></Hoge>\n<Code>SignatureDoesNotMatch</Code>\n<Message>\nThe request signature we calculated does not match the signature you provided. Check your key and signing method.\n</Message>\n<AWSAccessKeyId>AKIAJBYT3ZMEZF7Q5MSQ</AWSAccessKeyId>\n<StringToSign>\nAWS4-HMAC-SHA256 20170404T052101Z 20170404/ap-northeast-1/s3/aws4_request 07f340ff9b3aa2329b665ea08b5635a95726f2550b9892ef83b57796d142402f\n</StringToSign>\n<SignatureProvided>\n8005f7c0ed4b2591cb5a08a4da89fc1e6b8f1eb726135ff4cb2beb2da84474fe?content-type=application/json\n</SignatureProvided>\n<StringToSignBytes>\n41 57 53 34 2d 48 4d 41 43 2d 53 48 41 32 35 36 0a 32 30 31 37 30 34 30 34 54 30 35 32 31 30 31 5a 0a 32 30 31 37 30 34 30 34 2f 61 70 2d 6e 6f 72 74 68 65 61 73 74 2d 31 2f 73 33 2f 61 77 73 34 5f 72 65 71 75 65 73 74 0a 30 37 66 33 34 30 66 66 39 62 33 61 61 32 33 32 39 62 36 36 35 65 61 30 38 62 35 36 33 35 61 39 35 37 32 36 66 32 35 35 30 62 39 38 39 32 65 66 38 33 62 35 37 37 39 36 64 31 34 32 34 30 32 66\n</StringToSignBytes>\n<CanonicalRequest>\nGET /foo X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAJBYT3ZMEZF7Q5MSQ%2F20170404%2Fap-northeast-1%2Fs3%2Faws4_request&X-Amz-Date=20170404T052101Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&location= host:s3-ap-northeast-1.amazonaws.com host UNSIGNED-PAYLOAD\n</CanonicalRequest>\n<CanonicalRequestBytes>\n47 45 54 0a 2f 63 68 61 74 63 61 73 74 2d 73 74 61 67 69 6e 67 0a 58 2d 41 6d 7a 2d 41 6c 67 6f 72 69 74 68 6d 3d 41 57 53 34 2d 48 4d 41 43 2d 53 48 41 32 35 36 26 58 2d 41 6d 7a 2d 43 6f 6e 74 65 6e 74 2d 53 68 61 32 35 36 3d 55 4e 53 49 47 4e 45 44 2d 50 41 59 4c 4f 41 44 26 58 2d 41 6d 7a 2d 43 72 65 64 65 6e 74 69 61 6c 3d 41 4b 49 41 4a 42 59 54 33 5a 4d 45 5a 46 37 51 35 4d 53 51 25 32 46 32 30 31 37 30 34 30 34 25 32 46 61 70 2d 6e 6f 72 74 68 65 61 73 74 2d 31 25 32 46 73 33 25 32 46 61 77 73 34 5f 72 65 71 75 65 73 74 26 58 2d 41 6d 7a 2d 44 61 74 65 3d 32 30 31 37 30 34 30 34 54 30 35 32 31 30 31 5a 26 58 2d 41 6d 7a 2d 45 78 70 69 72 65 73 3d 38 36 34 30 30 26 58 2d 41 6d 7a 2d 53 69 67 6e 65 64 48 65 61 64 65 72 73 3d 68 6f 73 74 26 6c 6f 63 61 74 69 6f 6e 3d 0a 68 6f 73 74 3a 73 33 2d 61 70 2d 6e 6f 72 74 68 65 61 73 74 2d 31 2e 61 6d 61 7a 6f 6e 61 77 73 2e 63 6f 6d 0a 0a 68 6f 73 74 0a 55 4e 53 49 47 4e 45 44 2d 50 41 59 4c 4f 41 44\n</CanonicalRequestBytes>\n<RequestId>95C9643CC5D5DA03</RequestId>\n<HostId>\nq6hqG4Dfdh4fADOc4ow9OPrBnBdo5lRGVKJixkzT70N0z8zo0/2bjZ/a+LS6pneiuTCVEXYtP1E=\n</HostId>\n</Error>".data(using: .utf8)!
    }
    
    func testparse() {
        let parser = XML2Parser(data: dataSourceXML)
        let node = try! parser.parse()
        XCTAssertEqual(node.elementName, "Error")
        XCTAssertEqual(node.children.first!.elementName, "Hoge")
        XCTAssertEqual(node.children.first!.children.first!.elementName, "Fuga")
        XCTAssertEqual(node.children.first!.children.first!.values, ["aaaaa", "bbbbb"])
        XCTAssertEqual(node.children.last!.elementName, "CanonicalRequest")
    }
    
    func testSerializeJSON() {
        let parser = XML2Parser(data: dataSourceXML)
        let node = try! parser.parse()
        let jsonString = XMLNodeSerializer(node: node).serializeToJSON()
        let jsonDict = try! JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!, options: []) as! [String: Any]
        
        let error = jsonDict["Error"] as! [String: Any]
        XCTAssertEqual(error["Code"] as! String, "SignatureDoesNotMatch")
    }
}

