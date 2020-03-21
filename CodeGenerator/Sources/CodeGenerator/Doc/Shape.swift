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

public enum ShapeTypeError: Error {
    case unsupported(String)
}

public class Shape {
    public let name: String
    public var type: ShapeType
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

public struct XMLNamespace {
    public let attributeMap: [String: Any]
    
    public init?(dictionary: [String: Any]) {
        if let attributeMap = dictionary["xmlNamespace"] as? [String: Any] {
            self.attributeMap = attributeMap
        }
        else {
            return nil
        }
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
    case payload(max: Int?, min: Int?)
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

/// Operation to be applied to shapes after everything has loaded
protocol ShapeOperation {
    func process(_ shape: Shape) -> Shape
}

/// SetXMLNamespace post process operation to be applied to shapes after everything has loaded
struct SetXMLNamespaceOperation: ShapeOperation {
    let xmlNamespace: String

    func process(_ shape: Shape) -> Shape {
        if case .structure(let shapeStructure) = shape.type {
            precondition(shapeStructure.xmlNamespace == nil || shapeStructure.xmlNamespace == xmlNamespace,
                         "Two different XML namespaces being applied to the same shape")
            shape.type = .structure(
                StructureShape(
                    members: shapeStructure.members,
                    payload: shapeStructure.payload,
                    xmlNamespace: xmlNamespace
                )
            )
        }
        return shape
    }
}
