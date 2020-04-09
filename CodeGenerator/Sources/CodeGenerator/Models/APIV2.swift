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

enum APIError: Error {
    case shapeDoesNotExist(String)
}

// Used to decode model api_2 files
struct API: Decodable {
    struct Metadata: Decodable {
        enum ServiceProtocol: String, Decodable {
            case restxml = "rest-xml"
            case restjson = "rest-json"
            case json = "json"
            case query = "query"
            case ec2 = "ec2"
        }
        
        var apiVersion: String
        var endpointPrefix: String
        var jsonVersion: String?
        var `protocol`: ServiceProtocol
        var serviceAbbreviation: String?
        var serviceFullName: String
        var serviceId: String?
        var signatureVersion: String
        var signingName: String?
        var targetPrefix: String?
        var uid: String?
    }

    struct HTTP: Decodable {
        var method: String
        var requestUri: String
    }
    
    struct XMLNamespace: Decodable {
        var uri: String
    }
    
    class Operation: Decodable, Patchable {
        struct Input: Decodable {
            var shapeName: String
            var locationName: String?
            var xmlNamespace: XMLNamespace?
            var payload: String?
            private enum CodingKeys: String, CodingKey {
                case shapeName = "shape"
                case locationName
                case xmlNamespace
                case payload
            }
        }
        struct Output: Decodable {
            var shapeName: String
            var payload: String?
            private enum CodingKeys: String, CodingKey {
                case shapeName = "shape"
                case payload
            }
        }
        struct Error: Decodable {
            var shapeName: String
            private enum CodingKeys: String, CodingKey {
                case shapeName = "shape"
            }
        }
        var name: String
        var http: HTTP
        var input: Input?
        var output: Output?
        var errors: [Error]
        var deprecated: Bool
        var deprecatedMessage: String?
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.http = try container.decode(HTTP.self, forKey: .http)
            self.input = try container.decodeIfPresent(Input.self, forKey: .input)
            self.output = try container.decodeIfPresent(Output.self, forKey: .output)
            self.errors = try container.decodeIfPresent([Error].self, forKey: .errors) ?? []
            self.deprecated = try container.decodeIfPresent(Bool.self, forKey: .deprecated) ?? false
            self.deprecatedMessage = try container.decodeIfPresent(String.self, forKey: .deprecatedMessage)
        }
        
        private enum CodingKeys: String, CodingKey {
            case name
            case http
            case input
            case output
            case errors
            case deprecated
            case deprecatedMessage
        }
    }

    class Shape: Decodable, Patchable {
        
        enum Location: String, Decodable {
            case header
            case headers
            case querystring
            case uri
            case body
            case statusCode
        }
        
        struct Member: Decodable {
            var location: Location?
            var locationName: String?
            var shapeName: String
            var deprecated: Bool?
            // set after decode in postProcess stage
            var shape: Shape!
            
            private enum CodingKeys: String, CodingKey {
                case location
                case locationName
                case shapeName = "shape"
                case deprecated
            }
        }

        struct Error: Decodable {
            let code: String?
            let httpStatusCode: Int
            let senderFault: Bool?
        }

        enum ShapeType {
            case string(min: Int? = nil, max: Int? = nil, pattern: String? = nil)
            case integer(min: Int? = nil, max: Int? = nil)
            case structure(required: [String]?, members: [String: Member])
            case blob
            case list(member: Member, min: Int? = nil, max: Int? = nil)
            case map(key: Member, value: Member)
            case long(min: Int64? = nil, max: Int64? = nil)
            case double(min: Double? = nil, max: Double? = nil)
            case float(min: Float? = nil, max: Float? = nil)
            case boolean
            case timestamp
            case `enum`([String])
            
            /// once everything has been loaded this is called to post process the ShapeType
            mutating func setupShapes(api: API) throws {
                switch self {
                case .structure(let required, let members):
                    // setup member shape
                    var updatedMembers: [String: Member] = try members.mapValues {
                        var member = $0;
                        member.shape = try api.getShape(named: member.shapeName);
                        return member
                    }
                    // remove deprecated members
                    updatedMembers = updatedMembers.compactMapValues { if $0.deprecated == true { return nil }; return $0 }
                    self = .structure(required: required, members: updatedMembers)
                        
                case .list(var member, let min, let max):
                    member.shape = try api.getShape(named: member.shapeName)
                    self = .list(member: member, min: min, max: max)
                    
                case .map(var key, var value):
                    key.shape = try api.getShape(named: key.shapeName)
                    value.shape = try api.getShape(named: value.shapeName)
                    self = .map(key: key, value: value)
                    
                default:
                    break
                }
            }
        }
        
        var type: ShapeType
        var error: Error?
        var exception: Bool?
        // set after decode in postProcess stage
        var usedInInput: Bool
        var usedInOutput: Bool
        var name: String!

        required init(from decoder: Decoder) throws {
            self.usedInInput = false
            self.usedInOutput = false
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.error = try container.decodeIfPresent(Error.self, forKey: .error)
            self.exception = try container.decodeIfPresent(Bool.self, forKey: .exception)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "string":
                if let enumStrings = try container.decodeIfPresent([String].self, forKey: .enum) {
                    self.type = .enum(enumStrings)
                } else {
                    let min = try container.decodeIfPresent(Int.self, forKey: .min)
                    let max = try container.decodeIfPresent(Int.self, forKey: .max)
                    let pattern = try container.decodeIfPresent(String.self, forKey: .pattern)
                    self.type = .string(min: min, max: max, pattern: pattern)
                }
            case "integer":
                let min = try container.decodeIfPresent(Int.self, forKey: .min)
                let max = try container.decodeIfPresent(Int.self, forKey: .max)
                self.type = .integer(min: min, max: max)
            case "structure":
                let required = try container.decodeIfPresent([String].self, forKey: .required)
                let members = try container.decode([String: Member].self, forKey: .members)
                self.type = .structure(required: required, members: members)
            case "list":
                let min = try container.decodeIfPresent(Int.self, forKey: .min)
                let max = try container.decodeIfPresent(Int.self, forKey: .max)
                let member = try container.decode(Member.self, forKey: .member)
                self.type = .list(member: member, min: min, max: max)
            case "map":
                let key = try container.decode(Member.self, forKey: .key)
                let value = try container.decode(Member.self, forKey: .value)
                self.type = .map(key: key, value: value)
            case "long":
                let min = try container.decodeIfPresent(Int64.self, forKey: .min)
                let max = try container.decodeIfPresent(Int64.self, forKey: .max)
                self.type = .long(min: min, max: max)
            case "double":
                let min = try container.decodeIfPresent(Double.self, forKey: .min)
                let max = try container.decodeIfPresent(Double.self, forKey: .max)
                self.type = .double(min: min, max: max)
            case "float":
                let min = try container.decodeIfPresent(Float.self, forKey: .min)
                let max = try container.decodeIfPresent(Float.self, forKey: .max)
                self.type = .float(min: min, max: max)
            case "blob":
                self.type = .blob
            case "boolean":
                self.type = .boolean
            case "timestamp":
                self.type = .timestamp
            default:
                throw DecodingError.typeMismatch(ShapeType.self, .init(codingPath: decoder.codingPath, debugDescription:"Invalid shape type: \(type)"))
            }
        }
        
        private enum CodingKeys: String, CodingKey {
            case type
            case error
            case exception
            case min
            case max
            case pattern
            case required
            case members
            case member
            case key
            case value
            case `enum`
        }
    }

    var version: String?
    var metadata: Metadata
    var operations: [String: Operation]
    var shapes: [String: Shape]
    var serviceName: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decodeIfPresent(String.self, forKey: .version)
        self.metadata = try container.decode(Metadata.self, forKey: .metadata)
        self.operations = try container.decode([String: Operation].self, forKey: .operations)
        self.shapes = try container.decode([String: Shape].self, forKey: .shapes)
        self.serviceName = Self.getServiceName(from: self.metadata)
    }
    
    /// Return service name from API
    static func getServiceName(from metadata: Metadata) -> String {
        // port of https://github.com/aws/aws-sdk-go-v2/blob/996478f06a00c31ee7e7b0c3ac6674ce24ba0120/private/model/api/api.go#L105
        //
        let stripServiceNamePrefixes: [String] = ["Amazon", "AWS"]

        var serviceName = metadata.serviceAbbreviation ?? metadata.serviceFullName

        // Strip out prefix names not reflected in service client symbol names.
        for prefix in stripServiceNamePrefixes {
            serviceName.deletePrefix(prefix)
        }
        serviceName.removeCharacterSet(in: CharacterSet.alphanumerics.inverted)
        serviceName.removeWhitespaces()
        serviceName.capitalizeFirstLetter()

        return serviceName
    }

    /// return Shape given a name
    func getShape(named: String) throws -> Shape {
        guard let shape = shapes[named] else { throw APIError.shapeDoesNotExist(named)}
        return shape
    }
    
    private enum CodingKeys: String, CodingKey {
        case version
        case metadata
        case operations
        case shapes
    }
}

extension API {
    mutating func postProcess() throws {
        // post setup of Shape pointers
        for shape in shapes {
            shape.value.name = shape.key
            try shape.value.type.setupShapes(api: self)
        }
        
        // set where shapes are used
        for operation in operations.values {
            if let input = operation.input {
                try setShapeUsedIn(shape: getShape(named: input.shapeName), input: true, output: false)
            }
            if let output = operation.output {
                try setShapeUsedIn(shape: getShape(named: output.shapeName), input: false, output: true)
            }
        }
        
        try patch()
    }

    mutating func setShapeUsedIn(shape: Shape, input: Bool, output: Bool) throws {
        if input == true {
            guard shape.usedInInput == false else { return }
            shape.usedInInput = true
        }
        if output == true {
            guard shape.usedInOutput == false else { return }
            shape.usedInOutput = true
        }
        
        switch shape.type {
        case .list(let member, _, _):
            try setShapeUsedIn(shape: self.getShape(named: member.shapeName), input: input, output: output)
        case .map(let key, let value):
            try setShapeUsedIn(shape: self.getShape(named: key.shapeName), input: input, output: output)
            try setShapeUsedIn(shape: self.getShape(named: value.shapeName), input: input, output: output)
        case .structure(_, let members):
            for member in members.values {
                try setShapeUsedIn(shape: self.getShape(named: member.shapeName), input: input, output: output)
            }
        default:
            break
        }
    }


}
