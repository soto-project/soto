//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIO
import SotoDynamoDB
import XCTest

final class DynamoDBCoderTests: XCTestCase {
    func testEncodeDecode<Value: Codable & Equatable>(_ value: Value) throws {
        let result = try DynamoDBEncoder().encode(value)
        print(result)
        let result2 = try DynamoDBDecoder().decode(Value.self, from: result)
        XCTAssertEqual(value, result2)
    }

    func testDecodeEncode<Value: Codable>(_ attributes: [String: DynamoDB.AttributeValue], type: Value.Type) throws {
        let result = try DynamoDBDecoder().decode(Value.self, from: attributes)
        let result2 = try DynamoDBEncoder().encode(result)
        XCTAssertEqual(attributes, result2)
    }

    func testNumbers() {
        struct Numbers: Codable, Equatable {
            let b: Bool
            let i: Int
            let f: Float
            let d: Double
        }
        XCTAssertNoThrow(try self.testEncodeDecode(Numbers(b: true, i: 23, f: 3.14, d: 2.165)))
    }

    func testStrings() {
        struct Strings: Codable, Equatable {
            let s: String
        }
        XCTAssertNoThrow(try self.testEncodeDecode(Strings(s: "TestString")))
    }

    func testData() {
        struct DataTest: Codable, Equatable {
            let d: Data
        }
        XCTAssertNoThrow(try self.testEncodeDecode(DataTest(d: Data("data test".utf8))))
    }

    func testArray() {
        struct Arrays: Codable, Equatable {
            let i: [Int]
            let s: [String]
            let set: Set<String>?
        }
        XCTAssertNoThrow(try self.testEncodeDecode(Arrays(i: [2, 8, 24], s: ["TestString", "TestString1"], set: .init(["hello", "goodbye"]))))
        XCTAssertNoThrow(try self.testDecodeEncode([
            "i": .l([.n("24"), .n("78"), .n("1")]),
            "s": .l([.s("this"), .s("is"), .s("a"), .s("test")]),
        ], type: Arrays.self))
    }

    func testArrayOfBool() {
        struct ArrayOfBoolsTest: Codable, Equatable {
            let b: [Bool]
        }
        XCTAssertNoThrow(try self.testEncodeDecode(ArrayOfBoolsTest(b: [true, false, true, true])))
        XCTAssertNoThrow(try self.testDecodeEncode(
            ["b": .l([.bool(true), .bool(false), .bool(true), .bool(true)])],
            type: ArrayOfBoolsTest.self
        ))
    }

    func testArrayOfData() {
        struct ArrayOfDataTest: Codable, Equatable {
            let d: [Data]
        }
        XCTAssertNoThrow(try self.testEncodeDecode(ArrayOfDataTest(d: [Data("test".utf8), Data("data".utf8)])))
    }

    func testDictionary() {
        struct DictionaryTest: Codable, Equatable {
            let d: [String: Int]
        }
        XCTAssertNoThrow(try self.testEncodeDecode(DictionaryTest(d: ["One": 1, "Two": 2])))
    }

    func testChildObject() {
        struct Object: Codable, Equatable {
            let s: String
        }
        struct ChildObjectTest: Codable, Equatable {
            let f: Float
            let o: Object
        }
        XCTAssertNoThrow(try self.testEncodeDecode(ChildObjectTest(f: 500.1, o: Object(s: "Test"))))
    }

    func testArrayOfObjects() {
        struct Object: Codable, Equatable {
            let s: String
        }
        struct ChildObjectTest: Codable, Equatable {
            let f: Float
            let o: [Object]
        }
        XCTAssertNoThrow(try self.testEncodeDecode(ChildObjectTest(f: 500.1, o: [Object(s: "Test"), Object(s: "Test2")])))
    }

    func testEnum() {
        enum YesNo: String, Codable {
            case yes
            case no
        }
        struct EnumTest: Codable, Equatable {
            let answer: YesNo
        }
        XCTAssertNoThrow(try self.testEncodeDecode(EnumTest(answer: .yes)))
        XCTAssertNoThrow(try self.testDecodeEncode(["answer": .s("no")], type: EnumTest.self))
    }

    func testNestedKDC() {
        struct NestedKDCTest: Codable, Equatable {
            let firstName: String
            let surname: String
            let age: Int

            init(firstName: String, surname: String, age: Int) {
                self.firstName = firstName
                self.surname = surname
                self.age = age
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let nameContainer = try container.nestedContainer(keyedBy: NameCodingKeys.self, forKey: .name)
                self.firstName = try nameContainer.decode(String.self, forKey: .firstName)
                self.surname = try nameContainer.decode(String.self, forKey: .surname)
                self.age = try container.decode(Int.self, forKey: .age)
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                var nameContainer = container.nestedContainer(keyedBy: NameCodingKeys.self, forKey: .name)
                try nameContainer.encode(self.firstName, forKey: .firstName)
                try nameContainer.encode(self.surname, forKey: .surname)
                try container.encode(self.age, forKey: .age)
            }

            private enum CodingKeys: String, CodingKey {
                case name
                case age
            }

            private enum NameCodingKeys: String, CodingKey {
                case firstName
                case surname
            }
        }
        XCTAssertNoThrow(try self.testEncodeDecode(NestedKDCTest(firstName: "John", surname: "Smith", age: 38)))
        XCTAssertNoThrow(try self.testDecodeEncode([
            "name": .m(["firstName": .s("John"), "surname": .s("Smith")]),
            "age": .n("62"),
        ], type: NestedKDCTest.self))
    }

    func testNestedUKDC() {
        struct NestedUKDCTest: Codable, Equatable {
            let indices: [Int]
            let selected: Int

            init(indices: [Int], selected: Int) {
                self.indices = indices
                self.selected = selected
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                var testContainer = try container.nestedUnkeyedContainer(forKey: .test)
                var indices: [Int] = []
                while !testContainer.isAtEnd {
                    indices.append(try testContainer.decode(Int.self))
                }
                self.indices = indices
                self.selected = try container.decode(Int.self, forKey: .selected)
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                var testContainer = container.nestedUnkeyedContainer(forKey: .test)
                for index in self.indices {
                    try testContainer.encode(index)
                }
                try container.encode(self.selected, forKey: .selected)
            }

            private enum CodingKeys: String, CodingKey {
                case selected
                case test
            }
        }
        XCTAssertNoThrow(try self.testEncodeDecode(NestedUKDCTest(indices: [1, 4, 7, 8], selected: 3)))
        XCTAssertNoThrow(try self.testDecodeEncode([
            "test": .l([.n("1"), .n("4"), .n("7"), .n("8")]),
            "selected": .n("3"),
        ], type: NestedUKDCTest.self))
    }

    func testSuperEncoder() {
        class BaseClass: Codable {
            let type: String

            init(type: String) {
                self.type = type
            }
        }

        class SuperEncoderTest: BaseClass {
            let subtype: String

            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let superDecoder = try container.superDecoder()
                self.subtype = try container.decode(String.self, forKey: .subtype)
                try super.init(from: superDecoder)
            }

            override func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                let superEncoder = container.superEncoder()
                try super.encode(to: superEncoder)
                try container.encode(self.subtype, forKey: .subtype)
            }

            private enum CodingKeys: String, CodingKey {
                case subtype
            }
        }

        XCTAssertNoThrow(try self.testDecodeEncode([
            "subtype": .s("test type"),
            "super": .m(["type": .s("base")]),
        ], type: SuperEncoderTest.self))
    }
}
