//
//  Shape.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/22.
//
//

import SwiftyJSON
import Foundation

public enum ShapeTypeError: Error {
    case unsupported(String)
}

public struct Shape {
    public let name: String
    public let type: ShapeType
    
    public init(name: String, type: ShapeType){
        self.name = name
        self.type = type
    }
    
    public var isStruct: Bool {
        switch type {
        case .structure(_):
            return true
        default:
            return false
        }
    }
    
    public var isOutputType: Bool {
        if name.characters.count <= 6 {
            return false
        }
        let suffix = name.substring(from: name.index(name.endIndex, offsetBy: -6))
        return suffix.lowercased() == "output"
    }
}

public struct StructureShape {
    public let members: [Member]
    public let payload: String?
    
    public init(members: [Member], payload: String?){
        self.members = members
        self.payload = payload
    }
}

public struct XMLNamespace {
    public let locationName: String
    public let attributeMap: [String: JSON]
    
    public var attributes: XMLAttribute {
        var dict: [String: String] = [:]
        attributeMap.forEach {
            dict[$0.key] = $0.value.stringValue
        }
        return [locationName: dict]
    }
    
    public init?(json: JSON) {
        if let attributeMap = json["xmlNamespace"].dictionary {
            self.attributeMap = attributeMap
        }
        else {
            return nil
        }
        
        guard let name = json["locationName"].string else {
            return nil
        }
        
        self.locationName = name
    }
}

public enum Location {
    case uri(locationName: String)
    case querystring(locationName: String)
    case header(locationName: String)
    case body(locationName: String)
    
    var name: String {
        switch self {
        case .uri(locationName: let name):
            return name
        case .querystring(locationName: let name):
            return name
        case .header(locationName: let name):
            return name
        case .body(locationName: let name):
            return name
        }
    }
}

public indirect enum ShapeType {
    case string(max: Int?, min: Int?, pattern: String?)
    case integer(max: Int?, min: Int?)
    case structure(StructureShape)
    case blob(max: Int?, min: Int?)
    case list(Shape)
    case map(key: Shape, value: Shape)
    case long(max: Int?, min: Int?)
    case double(max: Int?, min: Int?)
    case float(max: Int?, min: Int?)
    case boolean
    case timestamp
    case `enum`([String])
    case unhandledType
}
