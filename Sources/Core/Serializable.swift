//
//  Serializer.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/29.
//
//

import Foundation

func unwrap(any: Any) -> Any {
    let mi = Mirror(reflecting: any)
    if mi.displayStyle != .optional {
        return any
    }
    if mi.children.count == 0 { return NSNull() }
    let (_, some) = mi.children.first!
    return some
}

extension String {
    func upperFirst() -> String {
        return String(self[self.startIndex]).uppercased() + self.substring(from: self.index(after: self.startIndex))
    }
}

public protocol Serializable {}

extension Collection where Iterator.Element == Serializable {
    public func serialize() throws -> [[String: Any]] {
        return try self.map({ try $0.serialize() })
    }
}

extension Serializable {
    public func serialize() throws -> [String: Any] {
        let mirror = Mirror.init(reflecting: self)
        var serialized: [String: Any] = [:]
        
        for el in mirror.children {
            guard let label = el.label else {
                continue
            }
            
            let value = unwrap(any: el.value)
            
            switch value {
            case let v as Serializable:
                serialized[label.upperFirst()] = try v.serialize()
                
            case let v as [Serializable]:
                serialized[label.upperFirst()] = try v.serialize()
                
            case let v as [String: Serializable]:
                var dict: [String: Any] = [:]
                for (key, value) in v {
                    dict[key] = try value.serialize()
                }
                serialized[label.upperFirst()] = dict
                
            case _ as NSNull:
                break
                
            default:
                serialized[label.upperFirst()] = value
            }
        }
        return serialized
    }
}
