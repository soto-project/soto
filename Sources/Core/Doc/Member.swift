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
    public let xmlNamespace: XMLNamespace?
    public let isStreaming: Bool
    
    public init(name: String, required: Bool, shape: Shape, location: Location?, xmlNamespace: XMLNamespace?, isStreaming: Bool){
        self.name = name
        self.required = required
        self.shape = shape
        self.location = location
        self.xmlNamespace = xmlNamespace
        self.isStreaming = isStreaming
    }
}

extension Collection where Iterator.Element == Member {
    public func toRequestParam() -> RequestParam {
        var headersParams: [String: String] = [:]
        var queryParams: [String: String] = [:]
        var pathParams: [String: String] = [:]
        
        for member in self {
            guard let location = member.location else { continue }
            switch location {
            case .header(let replaceTo, let keyForHeader):
                headersParams[replaceTo] = keyForHeader

            case .querystring(let replaceTo, let keyForQuery):
                queryParams[replaceTo] = keyForQuery

            case .uri(let replaceTo, let replaceToKey):
                pathParams[replaceTo] = replaceToKey
            }
        }
        return RequestParam(pathParams: pathParams, queryParams: queryParams, headerParams: headersParams)
    }
}

public struct RequestParam {
    public let pathParams: [String: String]
    public let queryParams: [String: String]
    public let headerParams: [String: String]
    
    public init(pathParams: [String: String], queryParams: [String: String], headerParams: [String: String]) {
        self.pathParams = pathParams
        self.queryParams = queryParams
        self.headerParams = headerParams
    }
}
