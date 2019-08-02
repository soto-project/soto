//
//  Shape.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/22.
//
//

import Foundation

public enum ShapeTypeError: Error {
    case unsupported(String)
}

public class Shape {
    public let name: String
    public let type: ShapeType
    public var usedInInput : Bool = false
    public var usedInOutput : Bool = false

    public init(name: String, type: ShapeType){
        self.name = name
        self.type = type
    }
}

public class StructureShape {
    public let members: [Member]
    public let payload: String?
    public let xmlNamespace: String?
    
    public init(members: [Member], payload: String?, xmlNamespace: String? = nil){
        self.members = members
        self.payload = payload
        self.xmlNamespace = xmlNamespace
    }
}

public typealias XMLAttribute = [String: [String: String]] // ["elementName": ["key": "value", ...]]

public struct XMLNamespace {
    public let locationName: String
    public let attributeMap: [String: Any]
    
    public var attributes: XMLAttribute {
        var dict: [String: String] = [:]
        attributeMap.forEach {
            dict[$0.key] = "\($0.value)"
        }
        return [locationName: dict]
    }
    
    public init?(dictionary: [String: Any]) {
        if let attributeMap = dictionary["xmlNamespace"] as? [String: Any] {
            self.attributeMap = attributeMap
        }
        else {
            return nil
        }
        
        guard let name = dictionary["locationName"] as? String else {
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
    
    public var name: String {
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
    case list(Shape, max: Int?, min: Int?)
    case map(key: Shape, value: Shape)
    case long(max: Int?, min: Int?)
    case double(max: Int?, min: Int?)
    case float(max: Int?, min: Int?)
    case boolean
    case timestamp
    case `enum`([String])
    case unhandledType
}
