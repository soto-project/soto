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

public enum ServiceProtocolType {
    case json
    case restjson
    case restxml
    case query
    case other(String)
}

extension ServiceProtocolType {
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

public struct ServiceProtocol {
    public struct Version {
        public var major: Int
        public var minor: Int
        
        public init(major: Int, minor: Int) {
            self.major = major
            self.minor = minor
        }
    }
    
    public let type: ServiceProtocolType
    public let version: Version?
    
    public init(type: ServiceProtocolType, version: Version? = nil) {
        self.type = type
        self.version = version
    }
}

extension ServiceProtocol.Version {
    public var stringValue: String {
        return "\(major).\(minor)"
    }
    
    public var hashValue: Int {
        return major ^ minor
    }
}

extension ServiceProtocol {
    public init(name: String, version: Version? = nil) {
        self.type = ServiceProtocolType(rawValue: name)
        self.version = version
    }
    
    var contentTypeString: String {
        var contentSubTypeStr = "x-amz-\(type.rawValue)"
        if let version = self.version {
            contentSubTypeStr += "-\(version.stringValue)"
        }
        return "application/\(contentSubTypeStr)"
    }
}

public func == (lhs: ServiceProtocol, rhs: ServiceProtocol) -> Bool {
    return lhs.contentTypeString == lhs.contentTypeString
}
