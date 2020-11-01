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

import Foundation

public class DynamoDBDecoder {
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    public init() {}

    public func decode<T: Decodable>(_ type: T.Type, from attributes: [String: DynamoDB.AttributeValue]) throws -> T {
        let decoder = _DynamoDBDecoder(referencing: attributes, userInfo: userInfo)
        let value = try T(from: decoder)
        return value
    }
}

/// storage for Dynamo Decoder. Stores a stack of Attribute values
private struct _DecoderStorage {
    /// the container stack
    private var attributes: [DynamoDB.AttributeValue] = []

    /// initializes self with no containers
    init(_ attribute: DynamoDB.AttributeValue) {
        self.attributes.append(attribute)
    }

    /// return the attribute at the top of the storage
    var topAttribute: DynamoDB.AttributeValue { return attributes.last! }

    /// push a new attribute onto the storage
    mutating func pushAttribute(_ attribute: DynamoDB.AttributeValue) {
        self.attributes.append(attribute)
    }

    /// pop a attribute from the storage
    @discardableResult mutating func popAttribute() -> DynamoDB.AttributeValue {
        return self.attributes.removeLast()
    }
}

private class _DynamoDBDecoder: Decoder {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    let attributes: [String: DynamoDB.AttributeValue]
    var storage: _DecoderStorage

    init(referencing: [String: DynamoDB.AttributeValue], userInfo: [CodingUserInfoKey: Any], codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.attributes = referencing
        self.storage = _DecoderStorage(.m(self.attributes))
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        guard case .m(let attributes) = self.storage.topAttribute else {
            throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "Expected to decode a map"))
        }
        return KeyedDecodingContainer(KDC(attributes: attributes, decoder: self))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return UKDC(attribute: self.storage.topAttribute, decoder: self)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }

    struct KDC<Key: CodingKey>: KeyedDecodingContainerProtocol {
        var codingPath: [CodingKey]
        var allKeys: [Key]
        var decoder: _DynamoDBDecoder
        var attributes: [String: DynamoDB.AttributeValue]

        init(attributes: [String: DynamoDB.AttributeValue], decoder: _DynamoDBDecoder) {
            self.decoder = decoder
            self.attributes = attributes
            self.codingPath = decoder.codingPath
            self.allKeys = attributes.keys.compactMap { Key(stringValue: $0) }
        }

        func contains(_ key: Key) -> Bool {
            return self.allKeys.first { $0.stringValue == key.stringValue } != nil
        }

        func getValue(forKey key: Key) throws -> DynamoDB.AttributeValue {
            guard let value = attributes[key.stringValue] else {
                throw DecodingError.keyNotFound(key, .init(codingPath: self.codingPath, debugDescription: ""))
            }
            return value
        }

        func decodeNil(forKey key: Key) throws -> Bool {
            return try self.decoder.unboxNil(self.getValue(forKey: key))
        }

        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
            return try self.decoder.unbox(self.getValue(forKey: key), as: Bool.self)
        }

        func decode(_ type: String.Type, forKey key: Key) throws -> String {
            return try self.decoder.unbox(self.getValue(forKey: key), as: String.self)
        }

        func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
            return try self.decoder.unbox(self.getValue(forKey: key), as: Double.self)
        }

        func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
            return try self.decoder.unbox(self.getValue(forKey: key), as: Float.self)
        }

        func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
            return try self.decoder.unbox(self.getValue(forKey: key), as: Int.self)
        }

        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
            return try self.decoder.unbox(self.getValue(forKey: key), as: Int8.self)
        }

        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
            return try self.decoder.unbox(self.getValue(forKey: key), as: Int16.self)
        }

        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
            return try self.decoder.unbox(self.getValue(forKey: key), as: Int32.self)
        }

        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
            return try self.decoder.unbox(self.getValue(forKey: key), as: Int64.self)
        }

        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
            return try self.decoder.unbox(self.getValue(forKey: key), as: UInt.self)
        }

        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
            return try self.decoder.unbox(self.getValue(forKey: key), as: UInt8.self)
        }

        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
            return try self.decoder.unbox(self.getValue(forKey: key), as: UInt16.self)
        }

        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
            return try self.decoder.unbox(self.getValue(forKey: key), as: UInt32.self)
        }

        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
            return try self.decoder.unbox(self.getValue(forKey: key), as: UInt64.self)
        }

        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }

            return try self.decoder.unbox(self.getValue(forKey: key), as: T.self)
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }

            guard case .m(let attributes) = try getValue(forKey: key) else {
                throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "Expected a map"))
            }
            return KeyedDecodingContainer(KDC<NestedKey>(attributes: attributes, decoder: self.decoder))
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }

            return UKDC(attribute: try self.getValue(forKey: key), decoder: self.decoder)
        }

        func _superDecoder(forKey key: CodingKey) throws -> Decoder {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }

            guard let value = attributes[key.stringValue] else {
                throw DecodingError.keyNotFound(key, .init(codingPath: self.codingPath, debugDescription: ""))
            }
            guard case .m(let attributes) = value else {
                throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "Expected a map attribute"))
            }
            return _DynamoDBDecoder(referencing: attributes, userInfo: self.decoder.userInfo, codingPath: self.decoder.codingPath)
        }

        func superDecoder() throws -> Decoder {
            return try self._superDecoder(forKey: DynamoDBCodingKey.super)
        }

        func superDecoder(forKey key: Key) throws -> Decoder {
            return try self._superDecoder(forKey: key)
        }
    }

    struct UKDC: UnkeyedDecodingContainer {
        var codingPath: [CodingKey]
        var count: Int?
        var isAtEnd: Bool { return self.currentIndex >= self.count! }
        var currentIndex: Int
        var attribute: DynamoDB.AttributeValue
        let decoder: _DynamoDBDecoder

        internal init(attribute: DynamoDB.AttributeValue, decoder: _DynamoDBDecoder) {
            self.attribute = attribute
            self.decoder = decoder
            self.codingPath = decoder.codingPath
            self.currentIndex = 0

            switch attribute {
            case .l(let values):
                self.count = values.count
            case .bs(let values):
                self.count = values.count
            case .ns(let values):
                self.count = values.count
            case .ss(let values):
                self.count = values.count
            default:
                self.count = 0
            }
        }

        mutating func getAttributeValue() throws -> DynamoDB.AttributeValue {
            guard case .l(let values) = self.attribute else {
                throw DecodingError.typeMismatch(type(of: self.attribute), .init(codingPath: self.codingPath, debugDescription: "Expected DynamoDB.AttributeValue.l"))
            }
            let value = values[currentIndex]
            currentIndex += 1
            return value
        }

        mutating func getNumberValue() throws -> String {
            switch self.attribute {
            case .ns(let values):
                let value = values[currentIndex]
                currentIndex += 1
                return value
            case .l(let attributes):
                let attribute = attributes[currentIndex]
                guard case .n(let value) = attribute else {
                    throw DecodingError.typeMismatch(type(of: self.attribute), .init(codingPath: self.codingPath, debugDescription: "Expected DynamoDB.AttributeValue.l holding a number attribute"))
                }
                self.currentIndex += 1
                return value
            default:
                throw DecodingError.typeMismatch(type(of: self.attribute), .init(codingPath: self.codingPath, debugDescription: "Expected DynamoDB.AttributeValue.l"))
            }
        }

        mutating func getStringValue() throws -> String {
            switch self.attribute {
            case .ss(let values):
                let value = values[currentIndex]
                currentIndex += 1
                return value
            case .l(let attributes):
                let attribute = attributes[currentIndex]
                guard case .s(let value) = attribute else {
                    throw DecodingError.typeMismatch(type(of: self.attribute), .init(codingPath: self.codingPath, debugDescription: "Expected DynamoDB.AttributeValue.l holding a string attribute"))
                }
                self.currentIndex += 1
                return value
            default:
                throw DecodingError.typeMismatch(type(of: self.attribute), .init(codingPath: self.codingPath, debugDescription: "Expected DynamoDB.AttributeValue.l"))
            }
        }

        mutating func decodeNil() throws -> Bool {
            guard case .null = try self.getAttributeValue() else {
                self.currentIndex -= 1
                return false
            }
            return true
        }

        mutating func decode(_: Bool.Type) throws -> Bool {
            let value = try getAttributeValue()
            guard case .bool(let boolValue) = value else {
                throw DecodingError.typeMismatch(Bool.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(value)"))
            }
            return boolValue
        }

        mutating func decode(_: String.Type) throws -> String {
            return try self.getStringValue()
        }

        mutating func decode(_: Double.Type) throws -> Double {
            let value = try getNumberValue()
            guard let unboxValue = Double(value) else {
                throw DecodingError.typeMismatch(Double.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(value)"))
            }
            return unboxValue
        }

        mutating func decode(_: Float.Type) throws -> Float {
            let value = try getNumberValue()
            guard let unboxValue = Float(value) else {
                throw DecodingError.typeMismatch(Float.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(value)"))
            }
            return unboxValue
        }

        mutating func decode(_: Int.Type) throws -> Int {
            let value = try getNumberValue()
            guard let unboxValue = Int(value) else {
                throw DecodingError.typeMismatch(Int.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(value)"))
            }
            return unboxValue
        }

        mutating func decode(_: Int8.Type) throws -> Int8 {
            let value = try getNumberValue()
            guard let unboxValue = Int8(value) else {
                throw DecodingError.typeMismatch(Int8.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(value)"))
            }
            return unboxValue
        }

        mutating func decode(_: Int16.Type) throws -> Int16 {
            let value = try getNumberValue()
            guard let unboxValue = Int16(value) else {
                throw DecodingError.typeMismatch(Int16.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(value)"))
            }
            return unboxValue
        }

        mutating func decode(_: Int32.Type) throws -> Int32 {
            let value = try getNumberValue()
            guard let unboxValue = Int32(value) else {
                throw DecodingError.typeMismatch(Int32.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(value)"))
            }
            return unboxValue
        }

        mutating func decode(_: Int64.Type) throws -> Int64 {
            let value = try getNumberValue()
            guard let unboxValue = Int64(value) else {
                throw DecodingError.typeMismatch(Int64.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(value)"))
            }
            return unboxValue
        }

        mutating func decode(_: UInt.Type) throws -> UInt {
            let value = try getNumberValue()
            guard let unboxValue = UInt(value) else {
                throw DecodingError.typeMismatch(UInt.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(value)"))
            }
            return unboxValue
        }

        mutating func decode(_: UInt8.Type) throws -> UInt8 {
            let value = try getNumberValue()
            guard let unboxValue = UInt8(value) else {
                throw DecodingError.typeMismatch(UInt8.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(value)"))
            }
            return unboxValue
        }

        mutating func decode(_: UInt16.Type) throws -> UInt16 {
            let value = try getNumberValue()
            guard let unboxValue = UInt16(value) else {
                throw DecodingError.typeMismatch(UInt16.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(value)"))
            }
            return unboxValue
        }

        mutating func decode(_: UInt32.Type) throws -> UInt32 {
            let value = try getNumberValue()
            guard let unboxValue = UInt32(value) else {
                throw DecodingError.typeMismatch(UInt32.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(value)"))
            }
            return unboxValue
        }

        mutating func decode(_: UInt64.Type) throws -> UInt64 {
            let value = try getNumberValue()
            guard let unboxValue = UInt64(value) else {
                throw DecodingError.typeMismatch(UInt64.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(value)"))
            }
            return unboxValue
        }

        mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
            switch self.attribute {
            case .bs(let values):
                let value = values[currentIndex]
                currentIndex += 1
                return try self.decoder.unbox(.b(value), as: T.self)

            case .ss(let values):
                let value = values[currentIndex]
                currentIndex += 1
                return try self.decoder.unbox(.s(value), as: T.self)

            case .ns(let values):
                let value = values[currentIndex]
                currentIndex += 1
                return try self.decoder.unbox(.n(value), as: T.self)

            case .l(let values):
                let value = values[currentIndex]
                currentIndex += 1
                return try self.decoder.unbox(value, as: T.self)

            default:
                throw DecodingError.typeMismatch(type, .init(codingPath: self.codingPath, debugDescription: "Expected list attribute"))
            }
        }

        mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
            self.decoder.codingPath.append(DynamoDBCodingKey(index: self.currentIndex))
            defer { self.decoder.codingPath.removeLast() }

            guard case .m(let attributes) = try getAttributeValue() else {
                throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "Expected a map"))
            }
            return KeyedDecodingContainer(KDC<NestedKey>(attributes: attributes, decoder: self.decoder))
        }

        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            self.decoder.codingPath.append(DynamoDBCodingKey(index: self.currentIndex))
            defer { self.decoder.codingPath.removeLast() }

            return UKDC(attribute: try self.getAttributeValue(), decoder: self.decoder)
        }

        mutating func superDecoder() throws -> Decoder {
            preconditionFailure("Attaching a superDecoder to a unkeyed container is unsupported")
        }
    }
}

extension _DynamoDBDecoder: SingleValueDecodingContainer {
    func decodeNil() -> Bool {
        guard case .null = self.storage.topAttribute else { return false }
        return true
    }

    func decode(_: Bool.Type) throws -> Bool {
        return try unbox(self.storage.topAttribute, as: Bool.self)
    }

    func decode(_: String.Type) throws -> String {
        return try unbox(self.storage.topAttribute, as: String.self)
    }

    func decode(_: Double.Type) throws -> Double {
        return try unbox(self.storage.topAttribute, as: Double.self)
    }

    func decode(_: Float.Type) throws -> Float {
        return try unbox(self.storage.topAttribute, as: Float.self)
    }

    func decode(_: Int.Type) throws -> Int {
        return try unbox(self.storage.topAttribute, as: Int.self)
    }

    func decode(_: Int8.Type) throws -> Int8 {
        return try unbox(self.storage.topAttribute, as: Int8.self)
    }

    func decode(_: Int16.Type) throws -> Int16 {
        return try unbox(self.storage.topAttribute, as: Int16.self)
    }

    func decode(_: Int32.Type) throws -> Int32 {
        return try unbox(self.storage.topAttribute, as: Int32.self)
    }

    func decode(_: Int64.Type) throws -> Int64 {
        return try unbox(self.storage.topAttribute, as: Int64.self)
    }

    func decode(_: UInt.Type) throws -> UInt {
        return try unbox(self.storage.topAttribute, as: UInt.self)
    }

    func decode(_: UInt8.Type) throws -> UInt8 {
        return try unbox(self.storage.topAttribute, as: UInt8.self)
    }

    func decode(_: UInt16.Type) throws -> UInt16 {
        return try unbox(self.storage.topAttribute, as: UInt16.self)
    }

    func decode(_: UInt32.Type) throws -> UInt32 {
        return try unbox(self.storage.topAttribute, as: UInt32.self)
    }

    func decode(_: UInt64.Type) throws -> UInt64 {
        return try unbox(self.storage.topAttribute, as: UInt64.self)
    }

    func decode<T>(_: T.Type) throws -> T where T: Decodable {
        return try unbox(self.storage.topAttribute, as: T.self)
    }
}

extension _DynamoDBDecoder {
    func unboxNil(_ attribute: DynamoDB.AttributeValue) throws -> Bool {
        guard case .null = attribute else {
            return false
        }
        return true
    }

    func unbox(_ attribute: DynamoDB.AttributeValue, as type: Bool.Type) throws -> Bool {
        guard case .bool(let value) = attribute else {
            throw DecodingError.typeMismatch(Bool.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(attribute)"))
        }
        return value
    }

    func unbox(_ attribute: DynamoDB.AttributeValue, as type: String.Type) throws -> String {
        guard case .s(let value) = attribute else {
            throw DecodingError.typeMismatch(String.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(attribute)"))
        }
        return value
    }

    func unbox(_ attribute: DynamoDB.AttributeValue, as type: Double.Type) throws -> Double {
        guard case .n(let value) = attribute, let unboxResult = Double(value) else {
            throw DecodingError.typeMismatch(Double.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(attribute)"))
        }
        return unboxResult
    }

    func unbox(_ attribute: DynamoDB.AttributeValue, as type: Float.Type) throws -> Float {
        guard case .n(let value) = attribute, let unboxResult = Float(value) else {
            throw DecodingError.typeMismatch(Float.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(attribute)"))
        }
        return unboxResult
    }

    func unbox(_ attribute: DynamoDB.AttributeValue, as type: Int.Type) throws -> Int {
        guard case .n(let value) = attribute, let unboxResult = Int(value) else {
            throw DecodingError.typeMismatch(Int.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(attribute)"))
        }
        return unboxResult
    }

    func unbox(_ attribute: DynamoDB.AttributeValue, as type: Int8.Type) throws -> Int8 {
        guard case .n(let value) = attribute, let unboxResult = Int8(value) else {
            throw DecodingError.typeMismatch(Int8.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(attribute)"))
        }
        return unboxResult
    }

    func unbox(_ attribute: DynamoDB.AttributeValue, as type: Int16.Type) throws -> Int16 {
        guard case .n(let value) = attribute, let unboxResult = Int16(value) else {
            throw DecodingError.typeMismatch(Int16.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(attribute)"))
        }
        return unboxResult
    }

    func unbox(_ attribute: DynamoDB.AttributeValue, as type: Int32.Type) throws -> Int32 {
        guard case .n(let value) = attribute, let unboxResult = Int32(value) else {
            throw DecodingError.typeMismatch(Int32.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(attribute)"))
        }
        return unboxResult
    }

    func unbox(_ attribute: DynamoDB.AttributeValue, as type: Int64.Type) throws -> Int64 {
        guard case .n(let value) = attribute, let unboxResult = Int64(value) else {
            throw DecodingError.typeMismatch(Int64.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(attribute)"))
        }
        return unboxResult
    }

    func unbox(_ attribute: DynamoDB.AttributeValue, as type: UInt.Type) throws -> UInt {
        guard case .n(let value) = attribute, let unboxResult = UInt(value) else {
            throw DecodingError.typeMismatch(UInt.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(attribute)"))
        }
        return unboxResult
    }

    func unbox(_ attribute: DynamoDB.AttributeValue, as type: UInt8.Type) throws -> UInt8 {
        guard case .n(let value) = attribute, let unboxResult = UInt8(value) else {
            throw DecodingError.typeMismatch(UInt8.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(attribute)"))
        }
        return unboxResult
    }

    func unbox(_ attribute: DynamoDB.AttributeValue, as type: UInt16.Type) throws -> UInt16 {
        guard case .n(let value) = attribute, let unboxResult = UInt16(value) else {
            throw DecodingError.typeMismatch(UInt16.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(attribute)"))
        }
        return unboxResult
    }

    func unbox(_ attribute: DynamoDB.AttributeValue, as type: UInt32.Type) throws -> UInt32 {
        guard case .n(let value) = attribute, let unboxResult = UInt32(value) else {
            throw DecodingError.typeMismatch(UInt32.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(attribute)"))
        }
        return unboxResult
    }

    func unbox(_ attribute: DynamoDB.AttributeValue, as type: UInt64.Type) throws -> UInt64 {
        guard case .n(let value) = attribute, let unboxResult = UInt64(value) else {
            throw DecodingError.typeMismatch(UInt64.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(attribute)"))
        }
        return unboxResult
    }

    func unbox(_ attribute: DynamoDB.AttributeValue, as type: Data.Type) throws -> Data {
        guard case .b(let value) = attribute else {
            throw DecodingError.typeMismatch(Data.self, .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(attribute)"))
        }
        return value
    }

    func unbox<T>(_ attribute: DynamoDB.AttributeValue, as type: T.Type) throws -> T where T: Decodable {
        return try self.unbox_(attribute, as: T.self) as! T
    }

    func unbox_(_ attribute: DynamoDB.AttributeValue, as type: Decodable.Type) throws -> Any {
        if type == Data.self {
            return try self.unbox(attribute, as: Data.self)
        } else {
            self.storage.pushAttribute(attribute)
            defer { self.storage.popAttribute() }
            return try type.init(from: self)
        }
    }
}
