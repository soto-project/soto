//
//  ServiceProtocol.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/07.
//
//

import Foundation

public enum ServiceProtocol {
    case json
    case restjson
    case restxml
    case query
    case other(String)
}

extension ServiceProtocol {
    public init(rawValue: String) {
        switch rawValue {
        case "json":
            self = .json
        case "rest-json":
            self = .restjson
        case "rest-xml":
            self = .restxml
        case "query":
            self = .query
        default:
            self = .other(rawValue)
        }
    }
    
    public var rawValue: String {
        switch self {
        case .json:
            return "json"
        case .restjson:
            return "rest-json"
        case .restxml:
            return "rest-xml"
        case .query:
            return "query"
        case .other(let value):
            return value
        }
    }
}
