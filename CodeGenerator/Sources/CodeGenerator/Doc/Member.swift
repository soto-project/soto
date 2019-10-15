//
//  Member.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/29.
//
//

import Foundation

public enum ShapeEncoding {
    case `default`
    case flatList
    case list(member: String)
    case flatMap(key: String, value: String)
    case map(entry: String, key: String, value: String)
}

public struct Member {

    public struct Options : OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue =  rawValue
        }
        
        static let streaming    = Options(rawValue: 1 << 0)
        static let idempotencyToken  = Options(rawValue: 1 << 1)
    }
    
    public let name: String
    public let required: Bool
    public let shape: Shape
    public let location: Location?
    public let shapeEncoding: ShapeEncoding?
    public let locationName: String?
    public let xmlNamespace: XMLNamespace?
    public let options: Options
    
    public init(name: String, required: Bool, shape: Shape, location: Location?, locationName: String?, shapeEncoding: ShapeEncoding?, xmlNamespace: XMLNamespace?, options: Options){
        self.name = name
        self.required = required
        self.shape = shape
        self.location = location
        self.locationName = locationName
        self.shapeEncoding = shapeEncoding
        self.xmlNamespace = xmlNamespace
        self.options = options
    }
}
