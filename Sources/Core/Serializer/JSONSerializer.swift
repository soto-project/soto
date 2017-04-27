//
//  JSONSerializable.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/23.
//
//

import Foundation

private func dquote(_ str: String) -> String {
    return "\"\(str)\""
}

protocol NumericType {
    static func +(lhs: Self, rhs: Self) -> Self
    static func -(lhs: Self, rhs: Self) -> Self
    static func *(lhs: Self, rhs: Self) -> Self
    static func /(lhs: Self, rhs: Self) -> Self
    static func %(lhs: Self, rhs: Self) -> Self
    init(_ v: Int)
}

extension Double : NumericType { }
extension Float  : NumericType { }
extension Int    : NumericType { }
extension Int8   : NumericType { }
extension Int16  : NumericType { }
extension Int32  : NumericType { }
extension Int64  : NumericType { }
extension UInt   : NumericType { }
extension UInt8  : NumericType { }
extension UInt16 : NumericType { }
extension UInt32 : NumericType { }
extension UInt64 : NumericType { }


enum JSONSerializerError: Error {
    case unserializableType(String)
}

private func serialize(value: Any) throws -> String {
    var s = ""
    switch value {
    case let dict as [String: Any]:
        s += try "{" + serialize(dictionary: dict) + "}"
        
    case let elements as [Any]:
        s += try serialize(array: elements)
        
    case let v as NumericType:
        s += "\(v)"
        
    case let v as Bool:
        s += "\(v)".lowercased()
        
    case _ as Data:
        throw JSONSerializerError.unserializableType("Data")
        
    default:
        s += dquote("\(value)")
    }
    
    return s
}

private func serialize(array: [Any]) throws -> String {
    var s = ""
    for (index, item) in array.enumerated() {
        s += try serialize(value: item)
        if array.count - index > 1 { s += ", " }
    }
    return "[" + s + "]"
}

private func serialize(dictionary: [String: Any]) throws -> String {
    var s = ""
    for (offset: index, element: (key: key, value: value)) in dictionary.enumerated() {
        s += dquote(key)+": "
        s += try serialize(value: value)
        if dictionary.count - index > 1 { s += ", " }
    }
    return s
}

struct JSONSerializer {
    public func serialize(_ dictionary: [String: Any]) throws -> Data {
        let jsonString = try "{" + Core.serialize(dictionary: dictionary) + "}"
        return jsonString.data(using: .utf8) ?? Data()
    }
}
