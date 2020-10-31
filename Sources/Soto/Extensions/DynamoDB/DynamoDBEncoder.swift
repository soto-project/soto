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

public class DynamoDBEncoder {
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    public init() {}

    public func encode<T: Encodable>(_ value: T) throws -> [String: DynamoDB.AttributeValue] {
        let encoder = _DynamoDBEncoder(userInfo: userInfo)
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
        let values = self.values + self.nestedContainers.map { $0.attribute }
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
        containers.append(container)
        return container
    }

    /// push a new container onto the storage
    mutating func pushUnkeyedContainer() -> _EncoderUnkeyedContainer {
        let container = _EncoderUnkeyedContainer()
        containers.append(container)
        return container
    }

    mutating func pushSingleValueContainer(_ attribute: DynamoDB.AttributeValue) {
        let container = _EncoderSingleValueContainer(attribute: attribute)
        containers.append(container)
    }

    /// pop a container from the storage
    @discardableResult mutating func popContainer() -> _EncoderContainer {
        return self.containers.removeLast()
    }

    func collapse() throws -> [String: DynamoDB.AttributeValue] {
        assert(self.containers.count == 1)
        guard case .m(let values) = self.containers.first?.attribute else { throw DynamoDBEncoderError.topLevelArray }
        return values
    }
}

class _DynamoDBEncoder: Encoder {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    fileprivate var storage: _EncoderStorage

    init(userInfo: [CodingUserInfoKey: Any], codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
        self.userInfo = userInfo
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
        return self
    }

    fileprivate struct KEC<Key: CodingKey>: KeyedEncodingContainerProtocol {
        var codingPath: [CodingKey]
        let container: _EncoderKeyedContainer
        let encoder: _DynamoDBEncoder

        internal init(container: _EncoderKeyedContainer, encoder: _DynamoDBEncoder) {
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

        mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
            self.encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }

            let attribute = try encoder.box(value)
            self.encode(attribute, forKey: key)
        }

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            self.encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }

            let nestedContainer = _EncoderKeyedContainer()
            container.addNestedContainer(path: key.stringValue, child: nestedContainer)

            return KeyedEncodingContainer(KEC<NestedKey>(container: nestedContainer, encoder: self.encoder))
        }

        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            self.encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }

            let nestedContainer = _EncoderUnkeyedContainer()
            container.addNestedContainer(path: key.stringValue, child: nestedContainer)

            return UKEC(container: nestedContainer, encoder: self.encoder)
        }

        func _superEncoder(forKey key: CodingKey) -> Encoder {
            self.encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }

            let nestedContainer = _EncoderKeyedContainer()
            container.addNestedContainer(path: key.stringValue, child: nestedContainer)

            return _DynamoDBReferencingEncoder(encoder: self.encoder, container: nestedContainer)
        }

        mutating func superEncoder() -> Encoder {
            return self._superEncoder(forKey: DynamoDBCodingKey.super)
        }

        mutating func superEncoder(forKey key: Key) -> Encoder {
            return self._superEncoder(forKey: key)
        }
    }

    fileprivate struct UKEC: UnkeyedEncodingContainer {
        var codingPath: [CodingKey]
        var count: Int
        let container: _EncoderUnkeyedContainer
        let encoder: _DynamoDBEncoder

        internal init(container: _EncoderUnkeyedContainer, encoder: _DynamoDBEncoder) {
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

        mutating func encode<T>(_ value: T) throws where T: Encodable {
            let attribute = try encoder.box(value)
            self.encode(attribute)
        }

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            self.encoder.codingPath.append(DynamoDBCodingKey(index: self.count))
            defer { self.encoder.codingPath.removeLast() }

            self.count += 1

            let nestedContainer = _EncoderKeyedContainer()
            container.addNestedContainer(nestedContainer)

            return KeyedEncodingContainer(KEC<NestedKey>(container: nestedContainer, encoder: self.encoder))
        }

        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            self.encoder.codingPath.append(DynamoDBCodingKey(index: self.count))
            defer { self.encoder.codingPath.removeLast() }

            self.count += 1

            let nestedContainer = _EncoderUnkeyedContainer()
            container.addNestedContainer(nestedContainer)

            return UKEC(container: nestedContainer, encoder: self.encoder)
        }

        mutating func superEncoder() -> Encoder {
            preconditionFailure("Attaching a superDecoder to a unkeyed container is unsupported")
        }
    }
}

extension _DynamoDBEncoder: SingleValueEncodingContainer {
    func encode(_ attribute: DynamoDB.AttributeValue) {
        self.storage.pushSingleValueContainer(attribute)
    }

    func encodeNil() throws {
        self.encode(.null(true))
    }

    func encode(_ value: Bool) throws {
        self.encode(.bool(value))
    }

    func encode(_ value: String) throws {
        self.encode(.s(value))
    }

    func encode(_ value: Double) throws {
        self.encode(.n(value.description))
    }

    func encode(_ value: Float) throws {
        self.encode(.n(value.description))
    }

    func encode(_ value: Int) throws {
        self.encode(.n(value.description))
    }

    func encode(_ value: Int8) throws {
        self.encode(.n(value.description))
    }

    func encode(_ value: Int16) throws {
        self.encode(.n(value.description))
    }

    func encode(_ value: Int32) throws {
        self.encode(.n(value.description))
    }

    func encode(_ value: Int64) throws {
        self.encode(.n(value.description))
    }

    func encode(_ value: UInt) throws {
        self.encode(.n(value.description))
    }

    func encode(_ value: UInt8) throws {
        self.encode(.n(value.description))
    }

    func encode(_ value: UInt16) throws {
        self.encode(.n(value.description))
    }

    func encode(_ value: UInt32) throws {
        self.encode(.n(value.description))
    }

    func encode(_ value: UInt64) throws {
        self.encode(.n(value.description))
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        let attribute = try box(value)
        encode(attribute)
    }
}

extension _DynamoDBEncoder {
    func box(_ data: Data) throws -> DynamoDB.AttributeValue {
        return .b(data)
    }

    func box(_ value: Encodable) throws -> DynamoDB.AttributeValue {
        let type = Swift.type(of: value)
        if type == Data.self || type == NSData.self {
            return try self.box(value as! Data)
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
        super.init(userInfo: encoder.userInfo, codingPath: encoder.codingPath)
    }

    deinit {
        (storage.popContainer() as? _EncoderKeyedContainer)?.copy(to: container)
    }
}
