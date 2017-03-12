//
//  Shape.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/22.
//
//

import SwiftyJSON
import Foundation

enum ShapeTypeError: Error {
    case unsupported(String)
}

struct Shape {
    let name: String
    let type: ShapeType
}

extension Shape {
    var swiftTypeName: String {
        if isNotSwiftDefinedType() {
            return name.toSwiftClassCase()
        }
        
        return type.toSwiftType()
    }
    
    func isNotSwiftDefinedType() -> Bool {
        switch type {
        case .structure(_):
            return true
        default:
            return false
        }
    }
    
    func isException() -> Bool {
        if Array(name.utf8).count < 9 {
            return false
        }
        let suffix = name.substring(from: name.index(name.endIndex, offsetBy: -9))
        return suffix == "Exception"
    }    
}

enum Location {
    case uri(locationName: String, replaceTo: String)
    case querystring(locationName: String, replaceTo: String)
    case header(locationName: String, replaceTo: String)
    
    init?(key: String, json: JSON) {
        guard let loc = json["location"].string, let name = json["locationName"].string else {
            return nil
        }
        
        switch loc {
        case "uri":
            self = .uri(locationName: name, replaceTo: key)
            
        case "querystring":
            self = .querystring(locationName: name, replaceTo: key)
            
        case "header":
            self = .header(locationName: name, replaceTo: key)
            
        default:
            return nil
        }
    }
}

indirect enum ShapeType {
    case string(max: Int?, min: Int?, pattern: String?)
    case integer(max: Int?, min: Int?)
    case structure([Member])
    case blob(max: Int?, min: Int?)
    case list(Shape)
    case map(key: Shape, value: Shape)
    case long(max: Int?, min: Int?)
    case double(max: Int?, min: Int?)
    case float(max: Int?, min: Int?)
    case boolean
    case timestamp
    case unhandledType
}

extension ShapeType {
    func toSwiftType() -> String {
        switch self {
        case .string(_):
            return "String"
            
        case .integer(_):
            return "Int32"
            
        case .structure(_):
            return "Any" // TODO shouldn't be matched here
        
        case .boolean:
            return "Bool"
            
        case .list(let shape):
            return "[\(shape.swiftTypeName)]"
            
        case .map(key: let keyShape, value: let valueShape):
            return "[\(keyShape.swiftTypeName): \(valueShape.swiftTypeName)]"
            
        case .long(_):
            return "Int64"
            
        case .double(_):
            return "Double"
        
        case .float(_):
            return "Float"
            
        case .blob:
            return "Data"
            
        case .timestamp:
            return "Date"
            
        case .unhandledType:
            return "Any"
        }
    }
}
