//===----------------------------------------------------------------------===//
//
// This source file is part of the AWSSDKSwift open source project
//
// Copyright (c) 2017-2020 the AWSSDKSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of AWSSDKSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation

public class DynamoDBEncoder {
    
    public var userInfo: [CodingUserInfoKey : Any] = [:]
    
    public init() { }
    
    public func encode<T : Encodable>(_ value: T) throws -> [String: DynamoDB.AttributeValue] {
        let encoder = _DynamoDBEncoder(userInfo: userInfo)
        try value.encode(to: encoder)
        return try encoder.storage.collapse()
    }
}

fileprivate protocol _EncoderContainer {
    var attribute: DynamoDB.AttributeValue { get }
}

/// class for holding a keyed container (dictionary). Need to encapsulate dictionary in class so we can be sure we are
/// editing the dictionary we push onto the stack
fileprivate class _EncoderKeyedContainer: _EncoderContainer {
    private(set) var values: [String: DynamoDB.AttributeValue] = [:]
    private(set) var nestedContainers: [String: _EncoderContainer] = [:]

    func addChild(path: String, child: DynamoDB.AttributeValue) {
        values[path] = child
    }
    
    func addNestedContainer(path: String, child: _EncoderContainer) {
        nestedContainers[path] = child
    }
    
    func copy(to: _EncoderKeyedContainer) {
        to.values = values
        to.nestedContainers = nestedContainers
    }
    
    var attribute: DynamoDB.AttributeValue {
        // merge child values, plus nested containers
        let values = self.values.merging(nestedContainers.mapValues { $0.attribute }) { rt,_ in return rt }
        return .m(values)
    }
}

/// class for holding unkeyed container (array). Need to encapsulate array in class so we can be sure we are
/// editing the array we push onto the stack
fileprivate class _EncoderUnkeyedContainer: _EncoderContainer {
    private(set) var values: [DynamoDB.AttributeValue] = []
    private(set) var nestedContainers: [_EncoderContainer] = []

    func addChild(_ child: DynamoDB.AttributeValue) {
        values.append(child)
    }

    func addNestedContainer(_ child: _EncoderContainer) {
        nestedContainers.append(child)
    }
    
    var attribute: DynamoDB.AttributeValue {
        // merge child values, plus nested containers
        let values = self.values + nestedContainers.map { $0.attribute }

        // choose array type based on first element type
        switch values.first {
        case .b:
            return .bs(values.compactMap {
                guard case .b(let value) = $0 else { return nil }
                return value
            })
        case .s:
            return .ss(values.compactMap {
                guard case .s(let value) = $0 else { return nil }
                return value
            })
        case .n:
            return .ns(values.compactMap {
                guard case .n(let value) = $0 else { return nil }
                return value
            })
        default:
            return .l(values)
        }
    }
}

/// struct for holding a single attribute value.
fileprivate struct _EncoderSingleValueContainer: _EncoderContainer {
    let attribute: DynamoDB.AttributeValue
}

/// storage for DynamoDB Encoder. Stores a stack of encoder containers
fileprivate struct _EncoderStorage {
    /// the container stack
    private var containers : [_EncoderContainer] = []

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
        return containers.removeLast()
    }

    func collapse() throws -> [String: DynamoDB.AttributeValue] {
        assert(containers.count == 1)
        guard case .m(let values) = containers.first?.attribute else { throw DynamoDBEncoderError.topLevelArray }
        return values
    }
}

class _DynamoDBEncoder: Encoder {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey : Any]
    fileprivate var storage: _EncoderStorage

    init(userInfo: [CodingUserInfoKey : Any], codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.storage = _EncoderStorage()
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = storage.pushKeyedContainer()
        return KeyedEncodingContainer(KEC(container: container, encoder:self))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let container = storage.pushUnkeyedContainer()
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
            container.addChild(path: key.stringValue, child: attribute)
        }
        
        mutating func encodeNil(forKey key: Key) throws {
            encode(.null(true), forKey: key)
        }
        
        mutating func encode(_ value: Bool, forKey key: Key) throws {
            encode(.bool(value), forKey: key)
        }
        
        mutating func encode(_ value: String, forKey key: Key) throws {
            encode(.s(value), forKey: key)
        }
        
        mutating func encode(_ value: Double, forKey key: Key) throws {
            encode(.n(value.description), forKey: key)
        }
        
        mutating func encode(_ value: Float, forKey key: Key) throws {
            encode(.n(value.description), forKey: key)
        }
        
        mutating func encode(_ value: Int, forKey key: Key) throws {
            encode(.n(value.description), forKey: key)
        }
        
        mutating func encode(_ value: Int8, forKey key: Key) throws {
            encode(.n(value.description), forKey: key)
        }
        
        mutating func encode(_ value: Int16, forKey key: Key) throws {
            encode(.n(value.description), forKey: key)
        }
        
        mutating func encode(_ value: Int32, forKey key: Key) throws {
            encode(.n(value.description), forKey: key)
        }
        
        mutating func encode(_ value: Int64, forKey key: Key) throws {
            encode(.n(value.description), forKey: key)
        }
        
        mutating func encode(_ value: UInt, forKey key: Key) throws {
            encode(.n(value.description), forKey: key)
        }
        
        mutating func encode(_ value: UInt8, forKey key: Key) throws {
            encode(.n(value.description), forKey: key)
        }
        
        mutating func encode(_ value: UInt16, forKey key: Key) throws {
            encode(.n(value.description), forKey: key)
        }
        
        mutating func encode(_ value: UInt32, forKey key: Key) throws {
            encode(.n(value.description), forKey: key)
        }
        
        mutating func encode(_ value: UInt64, forKey key: Key) throws {
            encode(.n(value.description), forKey: key)
        }
        
        mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            self.encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }

            let attribute = try encoder.box(value)
            encode(attribute, forKey: key)
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            self.encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }

            let nestedContainer = _EncoderKeyedContainer()
            container.addNestedContainer(path: key.stringValue, child: nestedContainer)

            return KeyedEncodingContainer(KEC<NestedKey>(container: nestedContainer, encoder:encoder))
        }
        
        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            self.encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }

            let nestedContainer = _EncoderUnkeyedContainer()
            container.addNestedContainer(path: key.stringValue, child: nestedContainer)

            return UKEC(container: nestedContainer, encoder:encoder)
        }
        
        func _superEncoder(forKey key: CodingKey) -> Encoder {
            self.encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }

            let nestedContainer = _EncoderKeyedContainer()
            container.addNestedContainer(path: key.stringValue, child: nestedContainer)

            return _DynamoDBReferencingEncoder(encoder: encoder, container: nestedContainer)
        }
        
        mutating func superEncoder() -> Encoder {
            return _superEncoder(forKey: DynamoDBCodingKey.super)
        }
        
        mutating func superEncoder(forKey key: Key) -> Encoder {
            return _superEncoder(forKey: key)
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
            container.addChild(attribute)
            count += 1
        }
        
        mutating func encodeNil() throws {
            encode(.null(true))
        }
        
        mutating func encode(_ value: Bool) throws {
            encode(.bool(value))
        }
        
        mutating func encode(_ value: String) throws {
            encode(.s(value))
        }
        
        mutating func encode(_ value: Double) throws {
            encode(.n(value.description))
        }
        
        mutating func encode(_ value: Float) throws {
            encode(.n(value.description))
        }
        
        mutating func encode(_ value: Int) throws {
            encode(.n(value.description))
        }
        
        mutating func encode(_ value: Int8) throws {
            encode(.n(value.description))
        }
        
        mutating func encode(_ value: Int16) throws {
            encode(.n(value.description))
        }
        
        mutating func encode(_ value: Int32) throws {
            encode(.n(value.description))
        }
        
        mutating func encode(_ value: Int64) throws {
            encode(.n(value.description))
        }
        
        mutating func encode(_ value: UInt) throws {
            encode(.n(value.description))
        }
        
        mutating func encode(_ value: UInt8) throws {
            encode(.n(value.description))
        }
        
        mutating func encode(_ value: UInt16) throws {
            encode(.n(value.description))
        }
        
        mutating func encode(_ value: UInt32) throws {
            encode(.n(value.description))
        }
        
        mutating func encode(_ value: UInt64) throws {
            encode(.n(value.description))
        }
        
        mutating func encode<T>(_ value: T) throws where T : Encodable {
            let attribute = try encoder.box(value)
            encode(attribute)
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            self.encoder.codingPath.append(DynamoDBCodingKey(index: count))
            defer { self.encoder.codingPath.removeLast() }
            
            count += 1
            
            let nestedContainer = _EncoderKeyedContainer()
            container.addNestedContainer(nestedContainer)
            
            return KeyedEncodingContainer(KEC<NestedKey>(container: nestedContainer, encoder:encoder))
        }
        
        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            self.encoder.codingPath.append(DynamoDBCodingKey(index: count))
            defer { self.encoder.codingPath.removeLast() }

            count += 1
            
            let nestedContainer = _EncoderUnkeyedContainer()
            container.addNestedContainer(nestedContainer)

            return UKEC(container: nestedContainer, encoder:encoder)
        }
        
        mutating func superEncoder() -> Encoder {
            preconditionFailure("Attaching a superDecoder to a unkeyed container is unsupported")
        }
    }
}

extension _DynamoDBEncoder: SingleValueEncodingContainer {
    func encode(_ attribute: DynamoDB.AttributeValue) {
        storage.pushSingleValueContainer(attribute)
    }
    
    func encodeNil() throws {
        encode(.null(true))
    }
    
    func encode(_ value: Bool) throws {
        encode(.bool(value))
    }
    
    func encode(_ value: String) throws {
        encode(.s(value))
    }
    
    func encode(_ value: Double) throws {
        encode(.n(value.description))
    }
    
    func encode(_ value: Float) throws {
        encode(.n(value.description))
    }
    
    func encode(_ value: Int) throws {
        encode(.n(value.description))
    }
    
    func encode(_ value: Int8) throws {
        encode(.n(value.description))
    }
    
    func encode(_ value: Int16) throws {
        encode(.n(value.description))
    }
    
    func encode(_ value: Int32) throws {
        encode(.n(value.description))
    }
    
    func encode(_ value: Int64) throws {
        encode(.n(value.description))
    }
    
    func encode(_ value: UInt) throws {
        encode(.n(value.description))
    }
    
    func encode(_ value: UInt8) throws {
        encode(.n(value.description))
    }
    
    func encode(_ value: UInt16) throws {
        encode(.n(value.description))
    }
    
    func encode(_ value: UInt32) throws {
        encode(.n(value.description))
    }
    
    func encode(_ value: UInt64) throws {
        encode(.n(value.description))
    }
    
    func encode<T>(_ value: T) throws where T : Encodable {
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
            return try self.box((value as! Data))
        } else {
            try value.encode(to: self)
            return storage.popContainer().attribute
        }
    }
}

//MARK: DynamoDBEncoderError

public enum DynamoDBEncoderError: Error {
    case topLevelArray
}

//MARK: Referencing Encoder

fileprivate class _DynamoDBReferencingEncoder: _DynamoDBEncoder {
    let container: _EncoderKeyedContainer
    
    init(encoder: _DynamoDBEncoder, container: _EncoderKeyedContainer) {
        self.container = container
        super.init(userInfo: encoder.userInfo, codingPath: encoder.codingPath)
    }
    
    deinit {
        (storage.popContainer() as? _EncoderKeyedContainer)?.copy(to: container)
    }
}
