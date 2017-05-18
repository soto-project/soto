//
//  AWSShapeProperty.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/18.
//
//

import Foundation

public struct AWSShapeProperty {
    public indirect enum PropertyType {
        case structure
        case `enum`
        case map
        case list
        case string
        case integer
        case blob
        case long
        case double
        case float
        case boolean
        case timestamp
        case any
    }

//    public indirect enum PropertyType {
//        case structure(AWSShape.Type)
//        case `enum`(AWSShape.Type)
//        case map(PropertyType, PropertyType)
//        case list(PropertyType)
//        case string
//        case integer
//        case blob
//        case long
//        case double
//        case float
//        case boolean
//        case timestamp
//        case any
//    }
    
    public let label: String
    public let required: Bool
    public let type: PropertyType
    
    public init(label: String, required: Bool, type: PropertyType) {
        self.label = label
        self.required = required
        self.type = type
    }
}
