//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2025 the Soto project authors
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
    /// The strategy to use for decoding `Date` values.
    public enum DateDecodingStrategy: Sendable {
        /// Defer to `Date` for decoding. This is the default strategy.
        case deferredToDate

        /// Decode the `Date` as a UNIX timestamp from a JSON number.
        case secondsSince1970

        /// Decode the `Date` as UNIX millisecond timestamp from a JSON number.
        case millisecondsSince1970

        /// Decode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
        case iso8601

        /// Decode the `Date` as a custom value decoded by the given closure.
        @preconcurrency
        case custom(@Sendable (_ decoder: Decoder) throws -> Date)
    }

    /// Options set on the top-level encoder to pass down the decoding hierarchy.
    fileprivate struct Options {
        var dateDecodingStrategy: DateDecodingStrategy = .deferredToDate
        var userInfo: [CodingUserInfoKey: any Sendable] = [:]
    }
    fileprivate var options: Options = .init()

    public var dateDecodingStrategy: DateDecodingStrategy {
        get { self.options.dateDecodingStrategy }
        set { self.options.dateDecodingStrategy = newValue }
    }
    public var userInfo: [CodingUserInfoKey: any Sendable] {
        get { self.options.userInfo }
        _modify {
            var value = self.options.userInfo
            defer {
                options.userInfo = value
            }
            yield &value
        }
        set { self.options.userInfo = newValue }
    }

    public init() {}

    public func decode<T: Decodable>(_ type: T.Type, from attributes: [String: DynamoDB.AttributeValue]) throws -> T {
        let decoder = _DynamoDBDecoder(referencing: attributes, options: options)
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
    var topAttribute: DynamoDB.AttributeValue { self.attributes.last! }

    /// push a new attribute onto the storage
    mutating func pushAttribute(_ attribute: DynamoDB.AttributeValue) {
        self.attributes.append(attribute)
    }

    /// pop a attribute from the storage
    @discardableResult mutating func popAttribute() -> DynamoDB.AttributeValue {
        self.attributes.removeLast()
    }
}

private class _DynamoDBDecoder: Decoder {
    var codingPath: [CodingKey]
    var options: DynamoDBDecoder.Options
    let attributes: [String: DynamoDB.AttributeValue]
    var storage: _DecoderStorage
    var userInfo: [CodingUserInfoKey: Any] {
        options.userInfo
    }
    init(referencing: [String: DynamoDB.AttributeValue], options: DynamoDBDecoder.Options, codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
        self.options = options
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
        UKDC(attribute: self.storage.topAttribute, decoder: self)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        self
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
            self.allKeys.first { $0.stringValue == key.stringValue } != nil
        }

        func getValue(forKey key: Key) throws -> DynamoDB.AttributeValue {
            guard let value = attributes[key.stringValue] else {
                throw DecodingError.keyNotFound(key, .init(codingPath: self.codingPath, debugDescription: ""))
            }
            return value
        }

        func decodeNil(forKey key: Key) throws -> Bool {
            try self.decoder.unboxNil(self.getValue(forKey: key))
        }

        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
            try self.decoder.unbox(self.getValue(forKey: key), as: Bool.self)
        }

        func decode(_ type: String.Type, forKey key: Key) throws -> String {
            try self.decoder.unbox(self.getValue(forKey: key), as: String.self)
        }

        func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
            try self.decoder.unbox(self.getValue(forKey: key), as: Double.self)
        }

        func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
            try self.decoder.unbox(self.getValue(forKey: key), as: Float.self)
        }

        func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
            try self.decoder.unbox(self.getValue(forKey: key), as: Int.self)
        }

        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
            try self.decoder.unbox(self.getValue(forKey: key), as: Int8.self)
        }

        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
            try self.decoder.unbox(self.getValue(forKey: key), as: Int16.self)
        }

        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
            try self.decoder.unbox(self.getValue(forKey: key), as: Int32.self)
        }

        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
            try self.decoder.unbox(self.getValue(forKey: key), as: Int64.self)
        }

        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
            try self.decoder.unbox(self.getValue(forKey: key), as: UInt.self)
        }

        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
            try self.decoder.unbox(self.getValue(forKey: key), as: UInt8.self)
        }

        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
            try self.decoder.unbox(self.getValue(forKey: key), as: UInt16.self)
        }

        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
            try self.decoder.unbox(self.getValue(forKey: key), as: UInt32.self)
        }

        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
            try self.decoder.unbox(self.getValue(forKey: key), as: UInt64.self)
        }

        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }

            return try self.decoder.unbox(self.getValue(forKey: key), as: T.self)
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey>
        where NestedKey: CodingKey {
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

            return try UKDC(attribute: self.getValue(forKey: key), decoder: self.decoder)
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
            return _DynamoDBDecoder(referencing: attributes, options: self.decoder.options, codingPath: self.decoder.codingPath)
        }

        func superDecoder() throws -> Decoder {
            try self._superDecoder(forKey: DynamoDBCodingKey.super)
        }

        func superDecoder(forKey key: Key) throws -> Decoder {
            try self._superDecoder(forKey: key)
        }
    }

    struct UKDC: UnkeyedDecodingContainer {
        var codingPath: [CodingKey]
        var count: Int?
        var isAtEnd: Bool { self.currentIndex >= self.count! }
        var currentIndex: Int
        var attribute: DynamoDB.AttributeValue
        let decoder: _DynamoDBDecoder

        init(attribute: DynamoDB.AttributeValue, decoder: _DynamoDBDecoder) {
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
                throw DecodingError.typeMismatch(
                    type(of: self.attribute),
                    .init(codingPath: self.codingPath, debugDescription: "Expected DynamoDB.AttributeValue.l")
                )
            }
            let value = values[currentIndex]
            self.currentIndex += 1
            return value
        }

        mutating func getNumberValue() throws -> String {
            switch self.attribute {
            case .ns(let values):
                let value = values[currentIndex]
                self.currentIndex += 1
                return value
            case .l(let attributes):
                let attribute = attributes[currentIndex]
                guard case .n(let value) = attribute else {
                    throw DecodingError.typeMismatch(
                        type(of: self.attribute),
                        .init(codingPath: self.codingPath, debugDescription: "Expected DynamoDB.AttributeValue.l holding a number attribute")
                    )
                }
                self.currentIndex += 1
                return value
            default:
                throw DecodingError.typeMismatch(
                    type(of: self.attribute),
                    .init(codingPath: self.codingPath, debugDescription: "Expected DynamoDB.AttributeValue.l")
                )
            }
        }

        mutating func getStringValue() throws -> String {
            switch self.attribute {
            case .ss(let values):
                let value = values[currentIndex]
                self.currentIndex += 1
                return value
            case .l(let attributes):
                let attribute = attributes[currentIndex]
                guard case .s(let value) = attribute else {
                    throw DecodingError.typeMismatch(
                        type(of: self.attribute),
                        .init(codingPath: self.codingPath, debugDescription: "Expected DynamoDB.AttributeValue.l holding a string attribute")
                    )
                }
                self.currentIndex += 1
                return value
            default:
                throw DecodingError.typeMismatch(
                    type(of: self.attribute),
                    .init(codingPath: self.codingPath, debugDescription: "Expected DynamoDB.AttributeValue.l")
                )
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
            try self.getStringValue()
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
                self.currentIndex += 1
                return try self.decoder.unbox(.b(value), as: T.self)

            case .ss(let values):
                let value = values[currentIndex]
                self.currentIndex += 1
                return try self.decoder.unbox(.s(value), as: T.self)

            case .ns(let values):
                let value = values[currentIndex]
                self.currentIndex += 1
                return try self.decoder.unbox(.n(value), as: T.self)

            case .l(let values):
                let value = values[currentIndex]
                self.currentIndex += 1
                return try self.decoder.unbox(value, as: T.self)

            default:
                throw DecodingError.typeMismatch(type, .init(codingPath: self.codingPath, debugDescription: "Expected list attribute"))
            }
        }

        mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey>
        where NestedKey: CodingKey {
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

            return try UKDC(attribute: self.getAttributeValue(), decoder: self.decoder)
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
        try unbox(self.storage.topAttribute, as: Bool.self)
    }

    func decode(_: String.Type) throws -> String {
        try unbox(self.storage.topAttribute, as: String.self)
    }

    func decode(_: Double.Type) throws -> Double {
        try unbox(self.storage.topAttribute, as: Double.self)
    }

    func decode(_: Float.Type) throws -> Float {
        try unbox(self.storage.topAttribute, as: Float.self)
    }

    func decode(_: Int.Type) throws -> Int {
        try unbox(self.storage.topAttribute, as: Int.self)
    }

    func decode(_: Int8.Type) throws -> Int8 {
        try unbox(self.storage.topAttribute, as: Int8.self)
    }

    func decode(_: Int16.Type) throws -> Int16 {
        try unbox(self.storage.topAttribute, as: Int16.self)
    }

    func decode(_: Int32.Type) throws -> Int32 {
        try unbox(self.storage.topAttribute, as: Int32.self)
    }

    func decode(_: Int64.Type) throws -> Int64 {
        try unbox(self.storage.topAttribute, as: Int64.self)
    }

    func decode(_: UInt.Type) throws -> UInt {
        try unbox(self.storage.topAttribute, as: UInt.self)
    }

    func decode(_: UInt8.Type) throws -> UInt8 {
        try unbox(self.storage.topAttribute, as: UInt8.self)
    }

    func decode(_: UInt16.Type) throws -> UInt16 {
        try unbox(self.storage.topAttribute, as: UInt16.self)
    }

    func decode(_: UInt32.Type) throws -> UInt32 {
        try unbox(self.storage.topAttribute, as: UInt32.self)
    }

    func decode(_: UInt64.Type) throws -> UInt64 {
        try unbox(self.storage.topAttribute, as: UInt64.self)
    }

    func decode<T>(_: T.Type) throws -> T where T: Decodable {
        try unbox(self.storage.topAttribute, as: T.self)
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

    func unbox(_ attribute: DynamoDB.AttributeValue, as type: AWSBase64Data.Type) throws -> AWSBase64Data {
        guard case .b(let value) = attribute else {
            throw DecodingError.typeMismatch(
                AWSBase64Data.self,
                .init(codingPath: self.codingPath, debugDescription: "Cannot convert from \(attribute)")
            )
        }
        return value
    }

    func unbox(_ attribute: DynamoDB.AttributeValue, as type: Date.Type) throws -> Date {
        switch self.options.dateDecodingStrategy {
        case .deferredToDate:
            self.storage.pushAttribute(attribute)
            defer { self.storage.popAttribute() }
            return try Date(from: self)
        case .millisecondsSince1970:
            let value = try self.unbox(attribute, as: Double.self)
            return Date(timeIntervalSince1970: value / 1000)
        case .secondsSince1970:
            let value = try self.unbox(attribute, as: Double.self)
            return Date(timeIntervalSince1970: value)
        case .iso8601:
            let string = try self.unbox(attribute, as: String.self)
            let date: Date?
            #if compiler(<6.0)
            date = _iso8601DateFormatter.date(from: string)
            #else
            if #available(macOS 12, iOS 15, tvOS 15, watchOS 8, *) {
                date = try? Date(string, strategy: .iso8601)
            } else {
                date = _iso8601DateFormatter.date(from: string)
            }
            #endif
            guard let date else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected date string to be ISO8601-formatted.")
                )
            }
            return date
        case .custom(let closure):
            return try closure(self)
        }
    }

    func unbox<T>(_ attribute: DynamoDB.AttributeValue, as type: T.Type) throws -> T where T: Decodable {
        try self.unbox_(attribute, as: T.self) as! T
    }

    func unbox_(_ attribute: DynamoDB.AttributeValue, as type: Decodable.Type) throws -> Any {
        if type == AWSBase64Data.self {
            return try self.unbox(attribute, as: AWSBase64Data.self)
        } else if type == Date.self {
            return try self.unbox(attribute, as: Date.self)
        } else {
            self.storage.pushAttribute(attribute)
            defer { self.storage.popAttribute() }
            return try type.init(from: self)
        }
    }
}

#if compiler(>=5.10)
nonisolated(unsafe) let _iso8601DateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = .withInternetDateTime
    return formatter
}()
#else
let _iso8601DateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = .withInternetDateTime
    return formatter
}()
#endif
