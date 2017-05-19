//
//  DictionaryConvertible.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/29.
//
//

import Foundation

func unwrap(any: Any) -> Any? {
    let mi = Mirror(reflecting: any)
    if mi.displayStyle != .optional {
        return any
    }
    if mi.children.count == 0 { return nil }
    let (_, some) = mi.children.first!
    return some
}

public enum InitializableError: Error {
    case missingRequiredParam(String)
    case convertingError
}

public protocol ParsingHintProvidable {
    static var parsingHints: [AWSShapeProperty] { get }
}

extension ParsingHintProvidable {
    public static var parsingHints: [AWSShapeProperty] { return [] }
}

public protocol DictionaryInitializable: ParsingHintProvidable {
    init(dictionary: [String: Any]) throws
}

public protocol DictionarySerializable: ParsingHintProvidable {}

extension Collection where Iterator.Element == DictionarySerializable {
    public func serialize() throws -> [[String: Any]] {
        return try self.map({ try $0.serializeToDictionary() })
    }
}

extension DictionarySerializable {
    public func serializeToDictionary() throws -> [String: Any] {
        let mirror = Mirror.init(reflecting: self)
        var serialized: [String: Any] = [:]
        
        let hints = type(of: self).parsingHints
        
        for el in mirror.children {
            guard let hint = hints.filter({ $0.label.lowercased() == el.label?.lowercased() }).first else {
                continue
            }
            
            let key: String
            if let location = hint.location {
                key = location
            } else {
                key = hint.label
            }
            
            guard let value = unwrap(any: el.value) else {
                continue
            }
            
            switch value {
            case let v as DictionarySerializable:
                serialized[key] = try v.serializeToDictionary()
                
            case let v as [DictionarySerializable]:
                serialized[key] = try v.serialize()
                
            case let v as [AnyHashable: DictionarySerializable]:
                var dict: [String: Any] = [:]
                for (key, value) in v {
                    dict["\(key)"] = try value.serializeToDictionary()
                }
                serialized[key] = dict
                
            case _ as NSNull:
                break
                
            default:
                serialized[key] = value
            }
        }
        return serialized
    }
}

public typealias DictionaryConvertible = DictionarySerializable & DictionaryInitializable
