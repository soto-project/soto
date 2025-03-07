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

public class DynamoDBEncoder {
    /// The strategy to use for encoding `Date` values.
    public enum DateEncodingStrategy: Sendable {
        /// Defer to `Date` for encoding. This is the default strategy.
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
        case custom(@Sendable (Date, Encoder) -> DynamoDB.AttributeValue)
    }

    /// Options set on the top-level encoder to pass down the encoding hierarchy.
    fileprivate struct Options {
        var dateEncodingStrategy: DateEncodingStrategy = .deferredToDate
        var userInfo: [CodingUserInfoKey: any Sendable] = [:]
    }
    fileprivate var options: Options = .init()

    public var dateEncodingStrategy: DateEncodingStrategy {
        get { self.options.dateEncodingStrategy }
        set { self.options.dateEncodingStrategy = newValue }
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

    public func encode(_ value: some Encodable) throws -> [String: DynamoDB.AttributeValue] {
        let encoder = _DynamoDBEncoder(options: options)
        try value.encode(to: encoder)
        return try encoder.storage.collapse()
    }
}

private protocol _EncoderContainer {
    var attribute: DynamoDB.AttributeValue { get }
}

/// class for holding a keyed container (dictionary). Need to encapsulate dictionary in class so we can be sure we are
/// editing the dictionary we push onto the stack
private class _EncoderKeyedContainer: _EncoderContainer {
    private(set) var values: [String: DynamoDB.AttributeValue] = [:]
    private(set) var nestedContainers: [String: _EncoderContainer] = [:]

    func addChild(path: String, child: DynamoDB.AttributeValue) {
        self.values[path] = child
    }

    func addNestedContainer(path: String, child: _EncoderContainer) {
        self.nestedContainers[path] = child
    }

    func copy(to: _EncoderKeyedContainer) {
        to.values = self.values
        to.nestedContainers = self.nestedContainers
    }

    var attribute: DynamoDB.AttributeValue {
        // merge child values, plus nested containers
        let values = self.values.merging(self.nestedContainers.mapValues { $0.attribute }) { rt, _ in return rt }
        return .m(values)
    }
}

/// class for holding unkeyed container (array). Need to encapsulate array in class so we can be sure we are
/// editing the array we push onto the stack
private class _EncoderUnkeyedContainer: _EncoderContainer {
    private(set) var values: [DynamoDB.AttributeValue] = []
    private(set) var nestedContainers: [_EncoderContainer] = []

    func addChild(_ child: DynamoDB.AttributeValue) {
        self.values.append(child)
    }

    func addNestedContainer(_ child: _EncoderContainer) {
        self.nestedContainers.append(child)
    }

    var attribute: DynamoDB.AttributeValue {
        // merge child values, plus nested containers
        let values = self.values + self.nestedContainers.map(\.attribute)
        return .l(values)
    }
}

/// struct for holding a single attribute value.
private struct _EncoderSingleValueContainer: _EncoderContainer {
    let attribute: DynamoDB.AttributeValue
}

/// storage for DynamoDB Encoder. Stores a stack of encoder containers
private struct _EncoderStorage {
    /// the container stack
    private var containers: [_EncoderContainer] = []

    /// initializes self with no containers
    init() {}

    /// push a new container onto the storage
    mutating func pushKeyedContainer() -> _EncoderKeyedContainer {
        let container = _EncoderKeyedContainer()
        self.containers.append(container)
        return container
    }

    /// push a new container onto the storage
    mutating func pushUnkeyedContainer() -> _EncoderUnkeyedContainer {
        let container = _EncoderUnkeyedContainer()
        self.containers.append(container)
        return container
    }

    mutating func pushSingleValueContainer(_ attribute: DynamoDB.AttributeValue) {
        let container = _EncoderSingleValueContainer(attribute: attribute)
        self.containers.append(container)
    }

    /// pop a container from the storage
    @discardableResult mutating func popContainer() -> _EncoderContainer {
        self.containers.removeLast()
    }

    func collapse() throws -> [String: DynamoDB.AttributeValue] {
        assert(self.containers.count == 1)
        guard case .m(let values) = self.containers.first?.attribute else { throw DynamoDBEncoderError.topLevelArray }
        return values
    }
}

private class _DynamoDBEncoder: Encoder {
    var codingPath: [CodingKey]
    fileprivate var storage: _EncoderStorage
    fileprivate let options: DynamoDBEncoder.Options
    var userInfo: [CodingUserInfoKey: Any] {
        self.options.userInfo
    }

    fileprivate init(options: DynamoDBEncoder.Options, codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
        self.options = options
        self.storage = _EncoderStorage()
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        let container = self.storage.pushKeyedContainer()
        return KeyedEncodingContainer(KEC(container: container, encoder: self))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let container = self.storage.pushUnkeyedContainer()
        return UKEC(container: container, encoder: self)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        self
    }

    fileprivate struct KEC<Key: CodingKey>: KeyedEncodingContainerProtocol {
        var codingPath: [CodingKey]
        let container: _EncoderKeyedContainer
        let encoder: _DynamoDBEncoder

        init(container: _EncoderKeyedContainer, encoder: _DynamoDBEncoder) {
            self.container = container
            self.encoder = encoder
            self.codingPath = encoder.codingPath
        }

        mutating func encode(_ attribute: DynamoDB.AttributeValue, forKey key: Key) {
            self.container.addChild(path: key.stringValue, child: attribute)
        }

        mutating func encodeNil(forKey key: Key) throws {
            self.encode(.null(true), forKey: key)
        }

        mutating func encode(_ value: Bool, forKey key: Key) throws {
            self.encode(.bool(value), forKey: key)
        }

        mutating func encode(_ value: String, forKey key: Key) throws {
            self.encode(.s(value), forKey: key)
        }

        mutating func encode(_ value: Double, forKey key: Key) throws {
            self.encode(.n(value.description), forKey: key)
        }

        mutating func encode(_ value: Float, forKey key: Key) throws {
            self.encode(.n(value.description), forKey: key)
        }

        mutating func encode(_ value: Int, forKey key: Key) throws {
            self.encode(.n(value.description), forKey: key)
        }

        mutating func encode(_ value: Int8, forKey key: Key) throws {
            self.encode(.n(value.description), forKey: key)
        }

        mutating func encode(_ value: Int16, forKey key: Key) throws {
            self.encode(.n(value.description), forKey: key)
        }

        mutating func encode(_ value: Int32, forKey key: Key) throws {
            self.encode(.n(value.description), forKey: key)
        }

        mutating func encode(_ value: Int64, forKey key: Key) throws {
            self.encode(.n(value.description), forKey: key)
        }

        mutating func encode(_ value: UInt, forKey key: Key) throws {
            self.encode(.n(value.description), forKey: key)
        }

        mutating func encode(_ value: UInt8, forKey key: Key) throws {
            self.encode(.n(value.description), forKey: key)
        }

        mutating func encode(_ value: UInt16, forKey key: Key) throws {
            self.encode(.n(value.description), forKey: key)
        }

        mutating func encode(_ value: UInt32, forKey key: Key) throws {
            self.encode(.n(value.description), forKey: key)
        }

        mutating func encode(_ value: UInt64, forKey key: Key) throws {
            self.encode(.n(value.description), forKey: key)
        }

        mutating func encode(_ value: some Encodable, forKey key: Key) throws {
            self.encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }

            let attribute = try encoder.box(value)
            self.encode(attribute, forKey: key)
        }

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey>
        where NestedKey: CodingKey {
            self.encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }

            let nestedContainer = _EncoderKeyedContainer()
            self.container.addNestedContainer(path: key.stringValue, child: nestedContainer)

            return KeyedEncodingContainer(KEC<NestedKey>(container: nestedContainer, encoder: self.encoder))
        }

        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            self.encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }

            let nestedContainer = _EncoderUnkeyedContainer()
            self.container.addNestedContainer(path: key.stringValue, child: nestedContainer)

            return UKEC(container: nestedContainer, encoder: self.encoder)
        }

        func _superEncoder(forKey key: CodingKey) -> Encoder {
            self.encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }

            let nestedContainer = _EncoderKeyedContainer()
            self.container.addNestedContainer(path: key.stringValue, child: nestedContainer)

            return _DynamoDBReferencingEncoder(encoder: self.encoder, container: nestedContainer)
        }

        mutating func superEncoder() -> Encoder {
            self._superEncoder(forKey: DynamoDBCodingKey.super)
        }

        mutating func superEncoder(forKey key: Key) -> Encoder {
            self._superEncoder(forKey: key)
        }
    }

    fileprivate struct UKEC: UnkeyedEncodingContainer {
        var codingPath: [CodingKey]
        var count: Int
        let container: _EncoderUnkeyedContainer
        let encoder: _DynamoDBEncoder

        init(container: _EncoderUnkeyedContainer, encoder: _DynamoDBEncoder) {
            self.container = container
            self.encoder = encoder
            self.codingPath = encoder.codingPath
            self.count = 0
        }

        mutating func encode(_ attribute: DynamoDB.AttributeValue) {
            self.container.addChild(attribute)
            self.count += 1
        }

        mutating func encodeNil() throws {
            self.encode(.null(true))
        }

        mutating func encode(_ value: Bool) throws {
            self.encode(.bool(value))
        }

        mutating func encode(_ value: String) throws {
            self.encode(.s(value))
        }

        mutating func encode(_ value: Double) throws {
            self.encode(.n(value.description))
        }

        mutating func encode(_ value: Float) throws {
            self.encode(.n(value.description))
        }

        mutating func encode(_ value: Int) throws {
            self.encode(.n(value.description))
        }

        mutating func encode(_ value: Int8) throws {
            self.encode(.n(value.description))
        }

        mutating func encode(_ value: Int16) throws {
            self.encode(.n(value.description))
        }

        mutating func encode(_ value: Int32) throws {
            self.encode(.n(value.description))
        }

        mutating func encode(_ value: Int64) throws {
            self.encode(.n(value.description))
        }

        mutating func encode(_ value: UInt) throws {
            self.encode(.n(value.description))
        }

        mutating func encode(_ value: UInt8) throws {
            self.encode(.n(value.description))
        }

        mutating func encode(_ value: UInt16) throws {
            self.encode(.n(value.description))
        }

        mutating func encode(_ value: UInt32) throws {
            self.encode(.n(value.description))
        }

        mutating func encode(_ value: UInt64) throws {
            self.encode(.n(value.description))
        }

        mutating func encode(_ value: some Encodable) throws {
            let attribute = try encoder.box(value)
            self.encode(attribute)
        }

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            self.encoder.codingPath.append(DynamoDBCodingKey(index: self.count))
            defer { self.encoder.codingPath.removeLast() }

            self.count += 1

            let nestedContainer = _EncoderKeyedContainer()
            self.container.addNestedContainer(nestedContainer)

            return KeyedEncodingContainer(KEC<NestedKey>(container: nestedContainer, encoder: self.encoder))
        }

        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            self.encoder.codingPath.append(DynamoDBCodingKey(index: self.count))
            defer { self.encoder.codingPath.removeLast() }

            self.count += 1

            let nestedContainer = _EncoderUnkeyedContainer()
            self.container.addNestedContainer(nestedContainer)

            return UKEC(container: nestedContainer, encoder: self.encoder)
        }

        mutating func superEncoder() -> Encoder {
            preconditionFailure("Attaching a superDecoder to a unkeyed container is unsupported")
        }
    }
}

extension _DynamoDBEncoder: SingleValueEncodingContainer {
    func encode(attribute: DynamoDB.AttributeValue) {
        self.storage.pushSingleValueContainer(attribute)
    }

    func encodeNil() throws {
        self.encode(attribute: .null(true))
    }

    func encode(_ value: Bool) throws {
        self.encode(attribute: .bool(value))
    }

    func encode(_ value: String) throws {
        self.encode(attribute: .s(value))
    }

    func encode(_ value: Double) throws {
        self.encode(attribute: .n(value.description))
    }

    func encode(_ value: Float) throws {
        self.encode(attribute: .n(value.description))
    }

    func encode(_ value: Int) throws {
        self.encode(attribute: .n(value.description))
    }

    func encode(_ value: Int8) throws {
        self.encode(attribute: .n(value.description))
    }

    func encode(_ value: Int16) throws {
        self.encode(attribute: .n(value.description))
    }

    func encode(_ value: Int32) throws {
        self.encode(attribute: .n(value.description))
    }

    func encode(_ value: Int64) throws {
        self.encode(attribute: .n(value.description))
    }

    func encode(_ value: UInt) throws {
        self.encode(attribute: .n(value.description))
    }

    func encode(_ value: UInt8) throws {
        self.encode(attribute: .n(value.description))
    }

    func encode(_ value: UInt16) throws {
        self.encode(attribute: .n(value.description))
    }

    func encode(_ value: UInt32) throws {
        self.encode(attribute: .n(value.description))
    }

    func encode(_ value: UInt64) throws {
        self.encode(attribute: .n(value.description))
    }

    func encode(_ value: some Encodable) throws {
        let attribute = try box(value)
        self.encode(attribute: attribute)
    }
}

extension _DynamoDBEncoder {
    func box(_ data: AWSBase64Data) throws -> DynamoDB.AttributeValue {
        .b(data)
    }

    func box(_ date: Date) throws -> DynamoDB.AttributeValue {
        switch self.options.dateEncodingStrategy {
        case .deferredToDate:
            try date.encode(to: self)
            return self.storage.popContainer().attribute
        case .millisecondsSince1970:
            return .n((date.timeIntervalSince1970 * 1000).description)
        case .secondsSince1970:
            return .n(date.timeIntervalSince1970.description)
        case .iso8601:
            #if compiler(<6.0)
            return .s(_iso8601DateFormatter.string(from: date))
            #else
            if #available(macOS 12, iOS 15, tvOS 15, watchOS 8, *) {
                return .s(date.formatted(.iso8601))
            } else {
                return .s(_iso8601DateFormatter.string(from: date))
            }
            #endif
        case .custom(let closure):
            return closure(date, self)
        }
    }

    func box(_ value: Encodable) throws -> DynamoDB.AttributeValue {
        let type = Swift.type(of: value)
        if type == AWSBase64Data.self {
            return try self.box(value as! AWSBase64Data)
        } else if type == Date.self {
            return try self.box(value as! Date)
        } else {
            try value.encode(to: self)
            return self.storage.popContainer().attribute
        }
    }
}

// MARK: DynamoDBEncoderError

public enum DynamoDBEncoderError: Error {
    case topLevelArray
}

// MARK: Referencing Encoder

private class _DynamoDBReferencingEncoder: _DynamoDBEncoder {
    let container: _EncoderKeyedContainer

    init(encoder: _DynamoDBEncoder, container: _EncoderKeyedContainer) {
        self.container = container
        super.init(options: encoder.options, codingPath: encoder.codingPath)
    }

    deinit {
        (storage.popContainer() as? _EncoderKeyedContainer)?.copy(to: container)
    }
}
