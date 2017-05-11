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
    case uri(locationName: String, replaceTo: String)
    case querystring(locationName: String, replaceTo: String)
    case header(locationName: String, replaceTo: String)
    
    public init?(key: String, json: JSON) {
        guard let loc = json["location"].string, let name = json["locationName"].string else {
            return nil
        }
        
        switch loc.lowercased() {
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
