//
//  Member.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/29.
//
//

import Foundation

public struct Member {
    public let name: String
    public let required: Bool
    public let shape: Shape
    public let location: Location?
    public let locationName: String?
    public let xmlNamespace: XMLNamespace?
    public let isStreaming: Bool
    
    public init(name: String, required: Bool, shape: Shape, location: Location?, locationName: String?, xmlNamespace: XMLNamespace?, isStreaming: Bool){
        self.name = name
        self.required = required
        self.shape = shape
        self.location = location
        self.locationName = locationName
        self.xmlNamespace = xmlNamespace
        self.isStreaming = isStreaming
    }
}
