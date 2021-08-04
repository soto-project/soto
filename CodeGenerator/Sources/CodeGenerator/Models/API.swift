//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2021 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation

enum APIError: Error {
    case shapeDoesNotExist(String)
    case cannotSerialiseAsEnum
}

// MARK: API

// Used to decode model api_2 files
struct API: Decodable, PatchBase {
    struct Metadata: Decodable {
        enum ServiceProtocol: String, Decodable {
            case restxml = "rest-xml"
            case restjson = "rest-json"
            case json
            case query
            case ec2
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

    struct XMLNamespace: Decodable {
        var uri: String
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
        guard let shape = shapes[named] else { throw APIError.shapeDoesNotExist(named) }
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
    /// function run after JSONDecode to fixup some variables
    mutating func postProcess() throws {
        // patch error in json files
        try patch()

        // post setup of Shape pointers
        for shape in self.shapes {
            shape.value.name = shape.key
            try shape.value.setupShapes(api: self)
        }

        // process operations, set where shapes are used, set streaming and eventstream flags
        for key in self.operations.keys {
            let operation = self.operations[key]!
            if let input = operation.input {
                let inputShape = try getShape(named: input.shapeName)
                if let xmlNamespace = input.xmlNamespace {
                    inputShape.xmlNamespace = xmlNamespace
                }
                inputShape.authtype = operation.authType
                self.setShapeUsedIn(shape: inputShape, input: true, output: false)
            }
            if let output = operation.output {
                let outputShape = try getShape(named: output.shapeName)
                self.setShapeUsedIn(shape: outputShape, input: false, output: true)
                // set eventStream flag if payload is flagged as an eventStream, set streaming flags if payload member or payload shape is flagged as streaming
                if let payload = outputShape.payload,
                   case .structure(let structure) = outputShape.type,
                   let member = structure.members[payload]
                {
                    self.operations[key]?.eventStream = member.shape.eventStream ?? false
                    if member.streaming == true || member.shape.streaming == true, member.required == false {
                        self.operations[key]?.streaming = true
                    }
                }
            }
        }

        // post processing of shapes, now that used in flags are set
        for shape in self.shapes {
            shape.value.postProcess(api: self)
        }

        // if query check if GET operation includes body elements
        if self.metadata.protocol == .query {
            for op in self.operations.values {
                guard op.http.method == "GET" else { continue }
                guard let input = op.input else { continue }
                let shape = try getShape(named: input.shapeName)
                guard case .structure(let structure) = shape.type else { continue }
                for member in structure.members {
                    if member.value.location == .body || member.value.location == nil {
                        fatalError("GET operation \(self.serviceName).\(input.shapeName) has members in body")
                    }
                }
            }
        }
    }

    mutating func setShapeUsedIn(shape: Shape, input: Bool, output: Bool) {
        if input == true {
            guard shape.usedInInput == false else { return }
            shape.usedInInput = true
        }
        if output == true {
            guard shape.usedInOutput == false else { return }
            shape.usedInOutput = true
        }

        switch shape.type {
        case .list(let list):
            self.setShapeUsedIn(shape: list.member.shape, input: input, output: output)
        case .map(let map):
            self.setShapeUsedIn(shape: map.key.shape, input: input, output: output)
            self.setShapeUsedIn(shape: map.value.shape, input: input, output: output)
        case .structure(let structure):
            for member in structure.members.values {
                self.setShapeUsedIn(shape: member.shape, input: input, output: output)
            }
        default:
            break
        }
    }
}

// MARK: Operation

/// Operation loaded from api_2.json
struct Operation: Decodable {
    struct HTTP: Decodable {
        var method: String
        var requestUri: String
    }

    struct Input: Decodable {
        var shapeName: String
        var locationName: String?
        var xmlNamespace: API.XMLNamespace?
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

    struct Endpoint: Decodable {
        var hostPrefix: String
    }

    var name: String
    var http: HTTP
    var input: Input?
    var output: Output?
    var errors: [Error]
    var authType: String?
    var deprecated: Bool
    var deprecatedMessage: String?
    var eventStream: Bool
    var streaming: Bool
    var documentationUrl: String?
    var endpoint: Endpoint?

    init(from decoder: Decoder) throws {
        self.eventStream = false
        self.streaming = false
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.http = try container.decode(HTTP.self, forKey: .http)
        self.input = try container.decodeIfPresent(Input.self, forKey: .input)
        self.output = try container.decodeIfPresent(Output.self, forKey: .output)
        self.errors = try container.decodeIfPresent([Error].self, forKey: .errors) ?? []
        self.authType = try container.decodeIfPresent(String.self, forKey: .authType)
        self.deprecated = try container.decodeIfPresent(Bool.self, forKey: .deprecated) ?? false
        self.deprecatedMessage = try container.decodeIfPresent(String.self, forKey: .deprecatedMessage)
        self.documentationUrl = try container.decodeIfPresent(String.self, forKey: .documentationUrl)
        self.endpoint = try container.decodeIfPresent(Endpoint.self, forKey: .endpoint)
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case http
        case input
        case output
        case errors
        case authType = "authtype"
        case deprecated
        case deprecatedMessage
        case eventStream
        case documentationUrl
        case endpoint
    }
}

// MARK: Shape

/// Shape loaded from api_2.json
class Shape: Decodable {
    enum Location: String, Decodable {
        case header
        case headers
        case querystring
        case uri
        case body
        case statusCode
    }

    class Member: Decodable {
        var location: Location?
        var locationName: String?
        var shapeName: String
        var deprecated: Bool?
        var xmlNamespace: API.XMLNamespace?
        var flattened: Bool?
        var streaming: Bool?
        var idempotencyToken: Bool?
        var hostLabel: Bool?
        // set after decode in postProcess stage
        var required: Bool = false
        var shape: Shape!

        private enum CodingKeys: String, CodingKey {
            case location
            case locationName
            case shapeName = "shape"
            case deprecated
            case xmlNamespace
            case flattened
            case streaming
            case idempotencyToken
            case hostLabel
        }
    }

    struct Error: Decodable {
        let code: String?
        let httpStatusCode: Int
        let senderFault: Bool?
    }

    /// Enum defining a shape type
    enum ShapeType: Decodable {
        class StructureType {
            var required: [String]
            var members: [String: Member]
            var isEnum: Bool

            init(required: [String]? = nil, members: [String: Member], isEnum: Bool) {
                self.required = required ?? []
                self.members = members
                self.isEnum = isEnum
            }

            func setupShapes(api: API) throws {
                if self.isEnum {
                    // enums cannot have required values
                    guard self.required.count == 0 else { throw APIError.cannotSerialiseAsEnum }
                    // enums cannot have variables outside of body
                    guard self.members.values.reduce(false, { $0 || ($1.location != nil && $1.location != .body) }) == false else {
                        throw APIError.cannotSerialiseAsEnum
                    }
                }
                // setup member shape
                let updatedMembers: [String: Member] = try members.mapValues {
                    let member = $0
                    member.shape = try api.getShape(named: member.shapeName)
                    // pass xmlNamespace from member to shape
                    if let xmlNamespace = member.xmlNamespace {
                        member.shape.xmlNamespace = xmlNamespace
                    }
                    return member
                }
                for require in self.required {
                    updatedMembers[require]?.required = true
                }
                // remove deprecated members
                self.members = updatedMembers.compactMapValues {
                    if $0.deprecated == true { return nil }
                    return $0
                }
            }
        }

        class StringType {
            var min: Int?
            var max: Int?
            var pattern: String?
            init(min: Int? = nil, max: Int? = nil, pattern: String? = nil) {
                self.min = min
                self.max = max
                self.pattern = pattern
            }
        }

        struct ListType {
            var member: Member
            var min: Int?
            var max: Int?
            var flattened: Bool?
        }

        struct MapType {
            var key: Member
            var value: Member
            var flattened: Bool?
        }

        enum TimeStampFormat: String, Decodable {
            case iso8601
            case unixTimestamp
            case rfc822
            case unspecified
        }

        struct EnumType {
            var cases: [String]
            var isExtensible: Bool
            init(cases: [String]) {
                self.cases = cases
                self.isExtensible = false
            }
        }

        case string(StringType)
        case integer(min: Int? = nil, max: Int? = nil)
        case structure(StructureType)
        case blob(min: Int? = nil, max: Int? = nil)
        case payload(min: Int? = nil, max: Int? = nil)
        case list(ListType)
        case map(MapType)
        case long(min: Int64? = nil, max: Int64? = nil)
        case double(min: Double? = nil, max: Double? = nil)
        case float(min: Float? = nil, max: Float? = nil)
        case boolean
        case timestamp(TimeStampFormat)
        case `enum`(EnumType)
        case stub

        // added so we can access enum type through keypaths
        var `enum`: EnumType? {
            get {
                if case .enum(let type) = self { return type }
                return nil
            }
            set(newValue) {
                precondition(newValue != nil)
                self = .enum(newValue!)
            }
        }

        // added so we can access structure type through keypaths
        var structure: StructureType? {
            get {
                if case .structure(let type) = self { return type }
                return nil
            }
            set(newValue) {
                precondition(newValue != nil)
                self = .structure(newValue!)
            }
        }

        // added so we can access string type through keypaths
        var string: StringType? {
            get {
                if case .string(let type) = self { return type }
                return nil
            }
            set(newValue) {
                precondition(newValue != nil)
                self = .string(newValue!)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "string":
                if let enumStrings = try container.decodeIfPresent([String].self, forKey: .enum) {
                    self = .enum(EnumType(cases: enumStrings))
                } else {
                    let min = try container.decodeIfPresent(Int.self, forKey: .min)
                    let max = try container.decodeIfPresent(Int.self, forKey: .max)
                    let pattern = try container.decodeIfPresent(String.self, forKey: .pattern)
                    self = .string(StringType(min: min, max: max, pattern: pattern))
                }
            case "integer":
                let min = try container.decodeIfPresent(Int.self, forKey: .min)
                let max = try container.decodeIfPresent(Int.self, forKey: .max)
                self = .integer(min: min, max: max)
            case "structure":
                let required = try container.decodeIfPresent([String].self, forKey: .required)
                let members = try container.decode([String: Member].self, forKey: .members)
                self = .structure(StructureType(required: required, members: members, isEnum: false))
            case "list":
                let min = try container.decodeIfPresent(Int.self, forKey: .min)
                let max = try container.decodeIfPresent(Int.self, forKey: .max)
                let member = try container.decode(Member.self, forKey: .member)
                let flattened = try container.decodeIfPresent(Bool.self, forKey: .flattened)
                self = .list(ListType(member: member, min: min, max: max, flattened: flattened))
            case "map":
                let key = try container.decode(Member.self, forKey: .key)
                let value = try container.decode(Member.self, forKey: .value)
                let flattened = try container.decodeIfPresent(Bool.self, forKey: .flattened)
                self = .map(MapType(key: key, value: value, flattened: flattened))
            case "long":
                let min = try container.decodeIfPresent(Int64.self, forKey: .min)
                let max = try container.decodeIfPresent(Int64.self, forKey: .max)
                self = .long(min: min, max: max)
            case "double":
                let min = try container.decodeIfPresent(Double.self, forKey: .min)
                let max = try container.decodeIfPresent(Double.self, forKey: .max)
                self = .double(min: min, max: max)
            case "float":
                let min = try container.decodeIfPresent(Float.self, forKey: .min)
                let max = try container.decodeIfPresent(Float.self, forKey: .max)
                self = .float(min: min, max: max)
            case "blob":
                let min = try container.decodeIfPresent(Int.self, forKey: .min)
                let max = try container.decodeIfPresent(Int.self, forKey: .max)
                self = .blob(min: min, max: max)
            case "boolean":
                self = .boolean
            case "timestamp":
                let format = try container.decodeIfPresent(TimeStampFormat.self, forKey: .timestampFormat)
                self = .timestamp(format ?? .unspecified)
            default:
                throw DecodingError.typeMismatch(
                    ShapeType.self,
                    .init(codingPath: decoder.codingPath, debugDescription: "Invalid shape type: \(type)")
                )
            }
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case `enum`
            case min
            case max
            case pattern
            case required
            case flattened
            case members
            case member
            case key
            case value
            case streaming
            case timestampFormat
        }
    }

    var type: ShapeType
    var payload: String?
    var xmlNamespace: API.XMLNamespace?
    var error: Error?
    var exception: Bool?
    var streaming: Bool?
    var eventStream: Bool?
    // set after decode in postProcess stage
    var usedInInput: Bool
    var usedInOutput: Bool
    var name: String!
    var authtype: String?

    init(type: ShapeType, name: String) {
        self.type = type
        self.name = name
        self.usedInOutput = false
        self.usedInInput = false
    }

    required init(from decoder: Decoder) throws {
        self.usedInInput = false
        self.usedInOutput = false

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.payload = try container.decodeIfPresent(String.self, forKey: .payload)
        self.xmlNamespace = try container.decodeIfPresent(API.XMLNamespace.self, forKey: .xmlNamespace)
        self.error = try container.decodeIfPresent(Error.self, forKey: .error)
        self.exception = try container.decodeIfPresent(Bool.self, forKey: .exception)
        self.streaming = try container.decodeIfPresent(Bool.self, forKey: .streaming)
        self.eventStream = try container.decodeIfPresent(Bool.self, forKey: .eventStream)
        self.type = try ShapeType(from: decoder)
    }

    /// once everything has been loaded this is called to post process the ShapeType
    func setupShapes(api: API) throws {
        switch self.type {
        case .structure(let structure):
            try structure.setupShapes(api: api)

        case .list(let list):
            list.member.shape = try api.getShape(named: list.member.shapeName)
            self.type = .list(list)

        case .map(let map):
            map.key.shape = try api.getShape(named: map.key.shapeName)
            map.value.shape = try api.getShape(named: map.value.shapeName)
            self.type = .map(map)

        default:
            break
        }
    }

    /// post process
    func postProcess(api: API) {
        switch self.type {
        case .structure(let structure):
            // set raw payloads to be a payload object
            if let payload = self.payload {
                if case .blob(let min, let max) = structure.members[payload]?.shape.type {
                    // pass streaming flag down to member struct
                    if structure.members[payload]?.shape.streaming == true {
                        structure.members[payload]?.streaming = true
                    }
                    structure.members[payload]!.shape = Shape(type: .payload(min: min, max: max), name: "AWSPayload")
                }
            }

        default:
            break
        }
    }

    // remember to add to init(from:Decoder) function as well
    private enum CodingKeys: String, CodingKey {
        case type
        case payload
        case xmlNamespace
        case error
        case exception
        case streaming
        case eventStream = "eventstream"
    }
}
