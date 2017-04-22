//
//  DictionarySerializer.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/06.
//
//

import Foundation
import XCTest
@testable import Core

typealias Serializable = DictionarySerializable & XMLNodeSerializable

class SerializableTests: XCTestCase {
    
    struct B: Serializable {
        let a = "1"
        let b = [1, 2]
        let c = ["key": "value"]
    }
    
    struct C: Serializable {
        let value = "hello"
    }
    
    struct D: Serializable {
        let value = "world"
    }
    
    struct A: Serializable {
        let structure = B()
        let structures: [Serializable] = [C(), D()]
        let array = ["foo", "bar"]
    }
    
    static var allTests : [(String, (SerializableTests) -> () throws -> Void)] {
        return [
            ("testSerializeToXML", testSerializeToXML),
            ("testSerializeToDictionaryAndJSON", testSerializeToDictionaryAndJSON)
        ]
    }
    
    func testSerializeToXML() {
        let node = try! A().serializeToXMLNode(attributes: ["A": ["url": "https://example.com"]])
        XCTAssertEqual(node.attributes["url"], "https://example.com")
        
        let xml = XMLNodeSerializer(node: node).serializeToXML()
        let expected = "<A url=\"https://example.com\"><Structure><A>1</A><B>1</B><B>2</B><C><key>value</key></C></Structure><Structures><Value>hello</Value><Value>world</Value></Structures><Array>foo</Array><Array>bar</Array></A>"
        XCTAssertEqual(xml, expected)
    }
    
    func testSerializeToDictionaryAndJSON() {
        let dict = try! A().serializeToDictionary()
        let data = try! JSONSerializer().serialize(dict)
        let jsonObect = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        XCTAssertEqual(dict.count, jsonObect.count)
    }
    
}
