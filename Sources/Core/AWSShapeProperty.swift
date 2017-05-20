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
    
    public let label: String
    public let location: Location?
    public let required: Bool
    public let type: PropertyType
    
    var pathForLocation: String {
        return location?.name ?? label
    }
    
    public init(label: String, location: Location? = nil, required: Bool, type: PropertyType) {
        self.label = label
        self.location = location
        self.required = required
        self.type = type
    }
}
