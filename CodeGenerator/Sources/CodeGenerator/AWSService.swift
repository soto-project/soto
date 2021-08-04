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
import HummingbirdMustache

struct AWSService {
    var api: API
    var docs: Docs
    var paginators: Paginators?
    var waiters: Waiters?
    var endpoints: Endpoints
    var errors: [Shape]
    var stripHTMLTagsFromComments: Bool

    enum Error: Swift.Error {
        /// JMES path can either not be processed or it does not represent a member of an object
        case illegalJMESPath
        case matcherInvalidType
    }

    init(api: API, docs: Docs, paginators: Paginators?, waiters: Waiters?, endpoints: Endpoints, stripHTMLTags: Bool) throws {
        self.api = api
        self.docs = docs
        self.paginators = paginators
        self.waiters = waiters
        self.endpoints = endpoints
        self.errors = try Self.getErrors(from: api)
        self.stripHTMLTagsFromComments = stripHTMLTags
    }

    /// Return list of errors from API
    static func getErrors(from api: API) throws -> [Shape] {
        var errorsSet: Set<Shape> = []
        for operation in api.operations.values {
            for error in operation.errors {
                try errorsSet.insert(api.getShape(named: error.shapeName))
            }
        }
        return errorsSet.map { $0 }
    }

    /// service protocol
    var serviceProtocol: String {
        if let version = api.metadata.jsonVersion, api.metadata.protocol == .json {
            return ".json(version: \"\(version)\")"
        }
        return self.api.metadata.protocol.enumStringValue
    }

    /// Service endpoints from API and Endpoints structure
    var serviceEndpoints: [(key: String, value: String)] {
        // create dictionary of endpoint name to Endpoint and partition from across all partitions
        struct EndpointInfo {
            let endpoint: Endpoints.Service.Endpoint
            let partition: String
        }
        let serviceEndpoints: [(key: String, value: EndpointInfo)] = self.endpoints.partitions.reduce([]) { value, partition in
            let endpoints = partition.services[api.metadata.endpointPrefix]?.endpoints
            return value + (endpoints?.map { (key: $0.key, value: EndpointInfo(endpoint: $0.value, partition: partition.partition)) } ?? [])
        }
        let partitionEndpoints = self.partitionEndpoints
        let partitionEndpointSet = Set<String>(partitionEndpoints.map { $0.value.endpoint })
        return serviceEndpoints.compactMap {
            // if service endpoint isn't in the set of partition endpoints or a region name return nil
            if partitionEndpointSet.contains($0.key) == false, Region(rawValue: $0.key) == nil {
                return nil
            }
            // if endpoint has a hostname return that
            if let hostname = $0.value.endpoint.hostname {
                return (key: $0.key, value: hostname)
            } else if partitionEndpoints[$0.value.partition] != nil {
                // if there is a partition endpoint, then default this regions endpoint to ensure partition endpoint doesn't override it.
                // Only an issue for S3 at the moment.
                return (key: $0.key, value: "\(api.metadata.endpointPrefix).\($0.key).amazonaws.com")
            }
            return nil
        }
    }

    // return dictionary of partition endpoints keyed by endpoint name
    var partitionEndpoints: [String: (endpoint: String, region: Region)] {
        var partitionEndpoints: [String: (endpoint: String, region: Region)] = [:]
        endpoints.partitions.forEach {
            if let endpoint = $0.services[api.metadata.endpointPrefix]?.partitionEndpoint {
                guard let region = $0.services[api.metadata.endpointPrefix]?.endpoints[endpoint]?.credentialScope?.region else {
                    preconditionFailure("Found partition endpoint without a credential scope region")
                }
                partitionEndpoints[$0.partition] = (endpoint: endpoint, region: region)
            }
        }
        return partitionEndpoints
    }

    /// Get middleware name
    var middleware: String? {
        switch self.api.serviceName {
        case "APIGateway":
            return "APIGatewayMiddleware()"
        case "Glacier":
            return "GlacierRequestMiddleware(apiVersion: \"\(self.api.metadata.apiVersion)\")"
        case "S3":
            return "S3RequestMiddleware()"
        default:
            return nil
        }
    }

    var serviceErrorName: String {
        return self.api.serviceName + "ErrorType"
    }
}

// MARK: Generate contexts

protocol EncodingPropertiesContext {}

extension AWSService {
    struct ErrorContext {
        let comment: [String.SubSequence]
        let `enum`: String
        let string: String
    }

    struct OperationContext {
        let comment: [String.SubSequence]
        let funcName: String
        let inputShape: String?
        let outputShape: String?
        let name: String
        let path: String
        let httpMethod: String
        let hostPrefix: String?
        let deprecated: String?
        let streaming: String?
        let documentationUrl: String?
    }

    struct PaginatorContext {
        let operation: OperationContext
        let inputKey: String?
        let outputKey: String
        let moreResultsKey: String?
        let initParams: [String]
        let paginatorProtocol: String
        let tokenType: String
    }

    struct EnumMemberContext {
        let `case`: String
        let string: String
    }

    struct EnumContext {
        let name: String
        let values: [EnumMemberContext]
        let isExtensible: Bool
    }

    struct ArrayEncodingPropertiesContext: EncodingPropertiesContext {
        let name: String
        let member: String
    }

    struct DictionaryEncodingPropertiesContext: EncodingPropertiesContext {
        let name: String
        let entry: String?
        let key: String
        let value: String
    }

    struct MemberContext {
        let variable: String
        let locationPath: String
        let parameter: String
        let required: Bool
        let `default`: String?
        let propertyWrapper: String?
        let type: String
        let comment: [String.SubSequence]
        var duplicate: Bool
    }

    struct AWSShapeMemberContext {
        let name: String
        let location: String?
        let locationName: String?
    }

    class ValidationContext: HBMustacheTransformable {
        let name: String
        let shape: Bool
        let required: Bool
        let reqs: [String: Any]
        let member: ValidationContext?
        let keyValidation: ValidationContext?
        let valueValidation: ValidationContext?

        init(
            name: String,
            shape: Bool = false,
            required: Bool = true,
            reqs: [String: Any] = [:],
            member: ValidationContext? = nil,
            key: ValidationContext? = nil,
            value: ValidationContext? = nil
        ) {
            self.name = name
            self.shape = shape
            self.required = required
            self.reqs = reqs
            self.member = member
            self.keyValidation = key
            self.valueValidation = value
        }

        func transform(_ name: String) -> Any? {
            switch name {
            case "withDictionaryContexts":
                if self.keyValidation != nil || self.valueValidation != nil {
                    return self
                }
            default:
                break
            }
            return nil
        }
    }

    struct CodingKeysContext {
        let variable: String
        let codingKey: String
        var duplicate: Bool
    }

    struct StructureContext {
        let object: String
        let name: String
        let shapeProtocol: String
        let payload: String?
        var payloadOptions: String?
        let namespace: String?
        let isEncodable: Bool
        let isDecodable: Bool
        let encoding: [EncodingPropertiesContext]
        let members: [MemberContext]
        let awsShapeMembers: [AWSShapeMemberContext]
        let codingKeys: [CodingKeysContext]
        let validation: [ValidationContext]
        let requiresDefaultValidation: Bool
    }

    struct ResultContext {
        let name: String
        let type: String
    }

    struct PartitionEndpoint {
        let partition: String
        let endpoint: String
        let region: String
    }

    func stripHTMLTags<S: StringProtocol>(_ string: S?) -> Substring? {
        guard self.stripHTMLTagsFromComments == true else { return string.map { Substring($0) } }
        return string?.tagStriped()
    }

    /// generate operations context
    func generateOperationContext(_ operation: Operation, name: String, streaming: Bool) -> OperationContext {
        let comment = self.stripHTMLTags(self.docs.operations[name])?.split(separator: "\n")
        return OperationContext(
            comment: comment ?? [],
            funcName: name.toSwiftVariableCase(),
            inputShape: operation.input?.shapeName,
            outputShape: operation.output?.shapeName,
            name: operation.name,
            path: operation.http.requestUri,
            httpMethod: operation.http.method,
            hostPrefix: operation.endpoint?.hostPrefix,
            deprecated: operation.deprecatedMessage ?? (operation.deprecated == true ? "\(name) is deprecated." : nil),
            streaming: streaming ? "ByteBuffer" : nil,
            documentationUrl: operation.documentationUrl
        )
    }

    /// Generate the context information for outputting the service api calls
    func generateServiceContext() -> [String: Any] {
        var context: [String: Any] = [:]

        // Service initialization
        context["name"] = self.api.serviceName
        context["description"] = self.stripHTMLTags(self.docs.service)?.split(separator: "\n") ?? []
        context["amzTarget"] = self.api.metadata.targetPrefix
        context["endpointPrefix"] = self.api.metadata.endpointPrefix
        if self.api.metadata.signingName != self.api.metadata.endpointPrefix {
            context["signingName"] = self.api.metadata.signingName
        }
        context["protocol"] = self.serviceProtocol
        context["apiVersion"] = self.api.metadata.apiVersion
        let endpoints = self.serviceEndpoints
            .sorted { $0.key < $1.key }
            .map { "\"\($0.key)\": \"\($0.value)\"" }
        context["serviceEndpoints"] = endpoints

        let isRegionalized: Bool? = self.endpoints.partitions.reduce(nil) {
            guard let regionalized = $1.services[api.metadata.endpointPrefix]?.isRegionalized else { return $0 }
            return ($0 ?? false) || regionalized
        }
        context["regionalized"] = isRegionalized ?? true

        if isRegionalized != true {
            context["partitionEndpoints"] = self.partitionEndpoints
                .map { (partition: $0.key, endpoint: $0.value.endpoint, region: $0.value.region) }
                .sorted { $0.partition < $1.partition }
                .map { ".\($0.partition.toSwiftRegionEnumCase()): (endpoint: \"\($0.endpoint)\", region: .\($0.region.rawValue.toSwiftRegionEnumCase()))" }
        }

        context["middlewareClass"] = self.middleware

        if !self.errors.isEmpty {
            context["errorTypes"] = self.serviceErrorName
        }

        // Operations
        var operationContexts: [OperationContext] = []
        var streamingOperationContexts: [OperationContext] = []
        for operation in self.api.operations {
            if operation.value.eventStream != true {
                operationContexts.append(self.generateOperationContext(operation.value, name: operation.key, streaming: false))
            }
            if operation.value.streaming == true {
                streamingOperationContexts.append(self.generateOperationContext(operation.value, name: operation.key, streaming: true))
            }
        }
        context["operations"] = operationContexts.sorted { $0.funcName < $1.funcName }
        context["streamingOperations"] = streamingOperationContexts.sorted { $0.funcName < $1.funcName }
        context["logger"] = self.getSymbol(for: "Logger", from: "Logging", api: self.api)
        return context
    }

    func getSymbol(for symbol: String, from framework: String, api: API) -> String {
        if api.shapes[symbol] != nil {
            return "\(framework).\(symbol)"
        }
        return symbol
    }

    /// Generate the context information for outputting the error enums
    func generateErrorContext() -> [String: Any] {
        var context: [String: Any] = [:]
        context["name"] = self.api.serviceName
        context["errorName"] = self.serviceErrorName

        var errorContexts: [ErrorContext] = []
        let errors = self.errors.sorted { $0.name < $1.name }
        for error in errors {
            let code: String = error.error?.code ?? error.name
            let errorContext = ErrorContext(
                comment: stripHTMLTags(self.docs.shapes[error.name]?.base)?.split(separator: "\n") ?? [],
                enum: error.name.toSwiftVariableCase(),
                string: code
            )
            errorContexts.append(errorContext)
        }
        if errorContexts.count > 0 {
            context["errors"] = errorContexts
        }
        return context
    }

    /// Generate paginator context
    func generatePaginatorContext() throws -> [String: Any] {
        guard let pagination = paginators?.pagination else { return [:] }
        let paginators = pagination.map { return (key: $0.key, value: $0.value) }.sorted { $0.key < $1.key }
        var context: [String: Any] = [:]
        context["name"] = self.api.serviceName

        var paginatorContexts: [PaginatorContext] = []

        for paginator in paginators {
            // get related operation and its input and output shapes
            guard let operation = api.operations[paginator.key],
                  let inputShape = try operation.input.map({ try api.getShape(named: $0.shapeName) }),
                  let outputShape = try operation.output.map({ try api.getShape(named: $0.shapeName) }),
                  case .structure(let inputStructure) = inputShape.type,
                  case .structure(let outputStructure) = outputShape.type
            else {
                continue
            }

            let inputTokens = paginator.value.inputTokens ?? []
            let rawOutputTokens = paginator.value.outputTokens ?? []
            let outputTokens = rawOutputTokens.map { String($0.split(separator: "|")[0]).trimmingCharacters(in: CharacterSet.whitespaces) }

            // get input token member
            guard inputTokens.count > 0,
                  outputTokens.count > 0,
                  let inputTokenMember = inputStructure.members[inputTokens[0]]
            else {
                continue
            }

            let paginatorProtocol = "AWSPaginateToken"
            let tokenType = inputTokenMember.shape.swiftTypeNameWithServiceNamePrefix(self.api.serviceName)

            // process input tokens
            var processedInputTokens = try inputTokens.map { (token) -> String in
                return try self.toKeyPath(token: token, shape: inputShape, type: inputStructure).keyPath
            }

            // process output tokens
            let processedOutputTokens = try outputTokens.map { (token) -> String in
                return try self.toKeyPath(token: token, shape: outputShape, type: outputStructure).keyPath
            }
            var moreResultsKey = try paginator.value.moreResults.map {
                try self.toKeyPath(token: $0, shape: outputShape, type: outputStructure).keyPath
            }

            // S3 uses moreResultKey, everything else uses inputToken
            if self.api.serviceName == "S3" {
                if moreResultsKey != nil {
                    processedInputTokens = []
                }
            } else {
                moreResultsKey = nil
            }
            if self.api.serviceName == "DynamoDB" {
                processedInputTokens = []
            }
            var initParams: [String: String] = [:]
            for member in inputStructure.members {
                initParams[member.key.toSwiftLabelCase()] = "self.\(member.key.toSwiftLabelCase())"
            }
            initParams[inputTokens[0].toSwiftLabelCase()] = "token"
            let initParamsArray = initParams.map { "\($0.key): \($0.value)" }.sorted { $0.lowercased() < $1.lowercased() }
            paginatorContexts.append(
                PaginatorContext(
                    operation: self.generateOperationContext(operation, name: paginator.key, streaming: false),
                    inputKey: processedInputTokens.first,
                    outputKey: processedOutputTokens[0],
                    moreResultsKey: moreResultsKey,
                    initParams: initParamsArray,
                    paginatorProtocol: paginatorProtocol,
                    tokenType: tokenType
                )
            )
        }

        if paginatorContexts.count > 0 {
            context["paginators"] = paginatorContexts
        }
        context["logger"] = self.getSymbol(for: "Logger", from: "Logging", api: self.api)
        return context
    }

    func generateEnumMemberContext(_ value: String, shapeName: String) -> EnumMemberContext {
        var key = value.lowercased()
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "(", with: "_")
            .replacingOccurrences(of: ")", with: "_")
            .replacingOccurrences(of: "*", with: "all")

        if Int(String(key[key.startIndex])) != nil { key = "_" + key }

        var caseName = key.camelCased()
        if caseName.allLetterIsNumeric() {
            caseName = "\(shapeName.toSwiftVariableCase())\(caseName)"
        }
        return EnumMemberContext(case: caseName, string: value)
    }

    /// Generate the context information for outputting an enum
    func generateEnumContext(_ shape: Shape, enumType: Shape.ShapeType.EnumType) -> EnumContext {
        // Operations
        var valueContexts: [EnumMemberContext] = []
        for value in enumType.cases {
            let enumMemberContext = self.generateEnumMemberContext(value, shapeName: shape.name)
            valueContexts.append(enumMemberContext)
        }
        // sort value contexts alphabetically and then reserve word escape
        valueContexts = valueContexts.sorted { $0.case < $1.case }.map { .init(case: $0.case.reservedwordEscaped(), string: $0.string) }
        return EnumContext(
            name: shape.name.toSwiftClassCase().reservedwordEscaped(),
            values: valueContexts,
            isExtensible: enumType.isExtensible
        )
    }

    func getArrayEntryName(_ list: Shape.ShapeType.ListType) -> String {
        return list.member.locationName ?? "member"
    }

    func getDictionaryEntryNames(_ map: Shape.ShapeType.MapType, member: Shape.Member) -> (entry: String?, key: String, value: String) {
        if map.flattened == true || member.flattened == true {
            return (entry: nil, key: map.key.locationName ?? "key", value: map.value.locationName ?? "value")
        } else {
            return (entry: "entry", key: map.key.locationName ?? "key", value: map.value.locationName ?? "value")
        }
    }

    func encodingName(_ name: String) -> String {
        return "_\(name)Encoding"
    }

    func generatePropertyWrapper(_ member: Shape.Member, name: String) -> String? {
        let codingWrapper: String
        if member.required {
            codingWrapper = "@CustomCoding"
        } else {
            codingWrapper = "@OptionalCustomCoding"
        }

        switch member.shape.type {
        case .list(let list):
            // if not located in body don't generate collection encoding property wrapper
            // nil location assumes located in body
            if let location = member.location {
                guard case .body = location else { return nil }
            }
            guard self.api.metadata.protocol != .json, self.api.metadata.protocol != .restjson else { return nil }
            guard list.flattened != true, member.flattened != true else { return nil }
            let entryName = self.getArrayEntryName(list)
            if entryName == "member" {
                return "\(codingWrapper)<StandardArrayCoder>"
            } else {
                return "\(codingWrapper)<ArrayCoder<\(self.encodingName(name)), \(list.member.shape.swiftTypeName)>>"
            }
        case .map(let map):
            // if not located in body don't generate collection encoding property wrapper
            // nil location assumes located in body
            if let location = member.location {
                guard case .body = location else { return nil }
            }
            guard self.api.metadata.protocol != .json, self.api.metadata.protocol != .restjson else { return nil }
            let names = self.getDictionaryEntryNames(map, member: member)
            if names.entry == "entry", names.key == "key", names.value == "value" {
                return "\(codingWrapper)<StandardDictionaryCoder>"
            } else {
                return "\(codingWrapper)<DictionaryCoder<\(self.encodingName(name)), \(map.key.shape.swiftTypeName), \(map.value.shape.swiftTypeName)>>"
            }
        case .timestamp(let format):
            switch format {
            case .iso8601:
                return "\(codingWrapper)<ISO8601DateCoder>"
            case .unixTimestamp:
                return "\(codingWrapper)<UnixEpochDateCoder>"
            case .rfc822:
                return "\(codingWrapper)<HTTPHeaderDateCoder>"
            case .unspecified:
                if member.location == .header {
                    return "\(codingWrapper)<HTTPHeaderDateCoder>"
                }
                return nil
            }
        default:
            return nil
        }
    }

    /// Generate encoding contexts
    func generateEncodingPropertyContext(_ member: Shape.Member, name: String) -> EncodingPropertiesContext? {
        guard self.api.metadata.protocol != .json, self.api.metadata.protocol != .restjson else { return nil }
        if let location = member.location {
            guard case .body = location else { return nil }
        }
        switch member.shape.type {
        case .list(let list):
            guard list.flattened != true, member.flattened != true else { return nil }
            let entryName = self.getArrayEntryName(list)
            guard entryName != "member" else { return nil }
            return ArrayEncodingPropertiesContext(name: self.encodingName(name), member: entryName)
        case .map(let map):
            let names = self.getDictionaryEntryNames(map, member: member)
            guard names.entry != "entry" || names.key != "key" || names.value != "value" else { return nil }
            return DictionaryEncodingPropertiesContext(name: self.encodingName(name), entry: names.entry, key: names.key, value: names.value)
        default:
            return nil
        }
    }

    /// return if shape has a recursive reference (function only tests 2 levels)
    func doesShapeHaveRecursiveOwnReference(_ shape: Shape, type: Shape.ShapeType.StructureType) -> Bool {
        let hasRecursiveOwnReference = type.members.values.contains(where: { member in
            // does shape have a member of same type as itself
            if member.shape === shape {
                return true
            } else {
                switch member.shape.type {
                case .list(let list):
                    if list.member.shape === shape {
                        return true
                    }

                case .structure(let type):
                    // test children structures as well to see if they contain a member of same type as the parent shape
                    if type.members.values.contains(where: {
                        return $0.shape === shape
                    }) {
                        return true
                    }
                default:
                    break
                }
                return false
            }
        })

        return hasRecursiveOwnReference
    }

    /// Generate the context information for outputting a member variable
    func generateMemberContext(_ member: Shape.Member, name: String, shape: Shape, typeIsEnum: Bool) -> MemberContext {
        let defaultValue: String?
        if member.idempotencyToken == true {
            defaultValue = "\(shape.swiftTypeName).idempotencyToken()"
        } else if !member.required {
            defaultValue = "nil"
        } else {
            defaultValue = nil
        }
        let memberDocs = self.stripHTMLTags(self.docs.shapes[shape.name]?.refs[name])?
            .split(separator: "\n")
        let propertyWrapper = self.generatePropertyWrapper(member, name: name)

        return MemberContext(
            variable: name.toSwiftVariableCase(),
            locationPath: member.getLocationName() ?? name,
            parameter: name.toSwiftLabelCase(),
            required: member.required,
            default: defaultValue,
            propertyWrapper: propertyWrapper,
            type: member.shape.swiftTypeName + ((member.required || typeIsEnum) ? "" : "?"),
            comment: memberDocs ?? [],
            duplicate: false
        )
    }

    /// Generate the context information for outputting a member variable
    func generateCodingKeyContext(_ member: Shape.Member, name: String, shape: Shape) -> CodingKeysContext? {
        if !shape.usedInOutput {
            switch member.location {
            case .header, .headers, .querystring, .uri:
                return nil
            default:
                break
            }
            // ensure payload objects aren't added to the codingkeys
            if case .payload = member.shape.type {
                return nil
            }
        }
        return CodingKeysContext(
            variable: name.toSwiftVariableCase(),
            codingKey: member.getLocationName() ?? name,
            duplicate: false
        )
    }

    /// Generate the context information for outputting a member variable
    func generateAWSShapeMemberContexts(_ member: Shape.Member, name: String, shape: Shape, isPropertyWrapper: Bool) -> [AWSShapeMemberContext] {
        let isPayload = (shape.payload == name)
        var locationName: String? = member.locationName
        let location = member.location ?? .body

        if isPayload || location != .body, locationName == nil {
            locationName = name
        }
        // remove location if equal to body and name is same as variable name
        if location == .body, locationName == name.toSwiftLabelCase() || !isPayload {
            locationName = nil
        }
        guard locationName != nil else { return [] }
        // prefix property wrapped shapes with "_" so they can be found by Mirror
        let varName = isPropertyWrapper ? "_\(name.toSwiftLabelCase())" : name.toSwiftLabelCase()

        var contexts: [AWSShapeMemberContext] = [
            .init(
                name: varName,
                location: locationName.map { location.enumStringValue(named: $0) },
                locationName: locationName
            )
        ]
        // if member is a host label, then add an additional uri shape member to apply to host name. Ideally this would be a
        // new location type but that would require a major version change
        if member.hostLabel == true {
            contexts.append(.init(name: varName, location: Shape.Location.uri.enumStringValue(named: name), locationName: name))
        }
        return contexts
    }

    /// Generate validation context
    func generateValidationContext(name: String, shape: Shape, required: Bool, container: Bool = false, alreadyProcessed: Set<String> = [])
        -> ValidationContext?
    {
        var requirements: [String: Any] = [:]
        switch shape.type {
        case .integer(let min, let max):
            requirements["max"] = max
            requirements["min"] = min

        case .long(let min, let max):
            requirements["max"] = max
            requirements["min"] = min

        case .float(let min, let max):
            requirements["max"] = max.map { Int($0) }
            requirements["min"] = min.map { Int($0) }

        case .double(let min, let max):
            requirements["max"] = max.map { Int($0) }
            requirements["min"] = min.map { Int($0) }

        case .blob(let min, let max), .payload(let min, let max):
            requirements["max"] = max
            requirements["min"] = min

        case .list(let list):
            requirements["max"] = list.max
            requirements["min"] = list.min
            // validation code doesn't support containers inside containers. Only service affected by this is SSM
            if !container {
                if let memberValidationContext = generateValidationContext(
                    name: name,
                    shape: list.member.shape,
                    required: required,
                    container: true,
                    alreadyProcessed: alreadyProcessed
                ) {
                    return ValidationContext(
                        name: name.toSwiftVariableCase(),
                        required: required,
                        reqs: requirements,
                        member: memberValidationContext
                    )
                }
            }
        case .map(let map):
            // validation code doesn't support containers inside containers. Only service affected by this is SSM
            if !container {
                let keyValidationContext = self.generateValidationContext(
                    name: name,
                    shape: map.key.shape,
                    required: required,
                    container: true,
                    alreadyProcessed: alreadyProcessed
                )
                let valueValiationContext = self.generateValidationContext(
                    name: name,
                    shape: map.value.shape,
                    required: required,
                    container: true,
                    alreadyProcessed: alreadyProcessed
                )
                if keyValidationContext != nil || valueValiationContext != nil {
                    return ValidationContext(
                        name: name.toSwiftVariableCase(),
                        required: required,
                        key: keyValidationContext,
                        value: valueValiationContext
                    )
                }
            }
        case .string(let type):
            requirements["max"] = type.max
            requirements["min"] = type.min
            if let pattern = type.pattern {
                requirements["pattern"] = "\"\(pattern.addingBackslashEncoding())\""
            }
        case .structure(let structure):
            guard !alreadyProcessed.contains(shape.name) else { return nil }
            var alreadyProcessed = alreadyProcessed
            alreadyProcessed.insert(shape.name)
            for member2 in structure.members {
                if self.generateValidationContext(
                    name: member2.key,
                    shape: member2.value.shape,
                    required: member2.value.required,
                    container: false,
                    alreadyProcessed: alreadyProcessed
                ) != nil {
                    return ValidationContext(name: name.toSwiftVariableCase(), shape: true, required: required)
                }
            }
        default:
            break
        }
        if requirements.count > 0 {
            return ValidationContext(name: name.toSwiftVariableCase(), required: required, reqs: requirements)
        }
        return nil
    }

    /// Generate the context for outputting a single AWSShape
    func generateStructureContext(_ shape: Shape, type: Shape.ShapeType.StructureType) -> StructureContext {
        var encodingContexts: [EncodingPropertiesContext] = []
        var memberContexts: [MemberContext] = []
        var codingKeyContexts: [CodingKeysContext] = []
        var awsShapeMemberContexts: [AWSShapeMemberContext] = []
        var validationContexts: [ValidationContext] = []
        var usedLocationPath: [String] = []
        var shapeProtocol: String
        var shapePayloadOptions: [String] = []

        if shape.usedInInput {
            shapeProtocol = "AWSEncodableShape"
            if shape.usedInOutput {
                shapeProtocol += " & AWSDecodableShape"
            }
        } else if shape.usedInOutput {
            shapeProtocol = "AWSDecodableShape"
        } else {
            preconditionFailure("AWSShape has to be used in either input or output")
        }

        if let payload = shape.payload {
            shapeProtocol += " & AWSShapeWithPayload"

            let member = type.members[payload]
            if case .payload = member?.shape.type {
                shapePayloadOptions.append("raw")
                if member?.streaming == true {
                    shapePayloadOptions.append("allowStreaming")
                    if shape.authtype == "v4-unsigned-body" {
                        shapePayloadOptions.append("allowChunkedStreaming")
                    }
                }
            }
        }

        let members = type.members.map { (key: $0.key, value: $0.value) }.sorted { $0.key.lowercased() < $1.key.lowercased() }
        for member in members {
            var memberContext = self.generateMemberContext(member.value, name: member.key, shape: shape, typeIsEnum: type.isEnum)

            // check for duplicates, this seems to be mainly caused by deprecated variables
            let locationPath = member.value.locationName ?? member.key
            if usedLocationPath.contains(locationPath) {
                memberContext.duplicate = true
            } else {
                usedLocationPath.append(locationPath)
            }

            memberContexts.append(memberContext)

            if let encodingContext = generateEncodingPropertyContext(member.value, name: member.key) {
                encodingContexts.append(encodingContext)
            }

            let awsShapeMemberContext = self.generateAWSShapeMemberContexts(
                member.value,
                name: member.key,
                shape: shape,
                isPropertyWrapper: memberContext.propertyWrapper != nil && shape.usedInInput
            )
            awsShapeMemberContexts += awsShapeMemberContext

            // CodingKey entry
            if let codingKeyContext = generateCodingKeyContext(member.value, name: member.key, shape: shape) {
                codingKeyContexts.append(codingKeyContext)
            }

            // only output validation for shapes used in inputs to service apis
            if shape.usedInInput {
                if let validationContext = generateValidationContext(name: member.key, shape: member.value.shape, required: member.value.required) {
                    validationContexts.append(validationContext)
                }
            }
        }

        return StructureContext(
            object: self.doesShapeHaveRecursiveOwnReference(shape, type: type) ? "class" : "struct",
            name: shape.swiftTypeName,
            shapeProtocol: shapeProtocol,
            payload: shape.payload?.toSwiftLabelCase(),
            payloadOptions: shapePayloadOptions.count > 0 ? shapePayloadOptions.map { ".\($0)" }.joined(separator: ", ") : nil,
            namespace: shape.xmlNamespace?.uri,
            isEncodable: shape.usedInInput,
            isDecodable: shape.usedInOutput,
            encoding: encodingContexts,
            members: memberContexts,
            awsShapeMembers: awsShapeMemberContexts,
            codingKeys: codingKeyContexts,
            validation: validationContexts,
            requiresDefaultValidation: validationContexts.count != memberContexts.count
        )
    }

    /// Generate the context for outputting all the AWSShape (enums and structures)
    func generateShapesContext() -> [String: Any] {
        var context: [String: Any] = [:]
        context["name"] = self.api.serviceName

        var shapeContexts: [[String: Any]] = []
        let shapes = self.api.shapes.values.sorted { $0.name < $1.name }
        for shape in shapes {
            if shape.usedInInput == false, shape.usedInOutput == false {
                continue
            }

            switch shape.type {
            case .enum(let enumType):
                var enumContext: [String: Any] = [:]
                enumContext["enum"] = self.generateEnumContext(shape, enumType: enumType)
                shapeContexts.append(enumContext)

            case .structure(let type):
                var structContext: [String: Any] = [:]
                if type.isEnum {
                    structContext["enumWithValues"] = self.generateStructureContext(shape, type: type)
                } else {
                    structContext["struct"] = self.generateStructureContext(shape, type: type)
                }
                shapeContexts.append(structContext)

            default:
                break
            }
        }
        context["shapes"] = shapeContexts
        return context
    }
}

// MARK: Extensions

/// extend Shape to be Hashable so we can store them in a Set<>
extension Shape: Hashable, Equatable {
    static func == (lhs: Shape, rhs: Shape) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        self.name.hash(into: &hasher)
    }
}

extension API.Metadata.ServiceProtocol {
    /// return enum as a string to output in client
    var enumStringValue: String {
        switch self {
        case .restxml:
            return ".restxml"
        case .restjson:
            return ".restjson"
        case .json:
            return ".json"
        case .query:
            return ".query"
        case .ec2:
            return ".ec2"
        }
    }
}

extension Shape {
    /// return shape type as a string for output
    public var swiftTypeName: String {
        switch self.type {
        case .string:
            return "String"
        case .integer:
            return "Int"
        case .structure:
            return name.toSwiftClassCase()
        case .boolean:
            return "Bool"
        case .list(let list):
            return "[\(list.member.shape.swiftTypeName)]"
        case .map(let map):
            return "[\(map.key.shape.swiftTypeName): \(map.value.shape.swiftTypeName)]"
        case .long:
            return "Int64"
        case .double:
            return "Double"
        case .float:
            return "Float"
        case .blob:
            return "Data"
        case .payload:
            return "AWSPayload"
        case .timestamp:
            return "Date"
        case .enum:
            return name.toSwiftClassCase()
        case .stub:
            return name.toSwiftClassCase()
        }
    }

    /// return swift type name that would compile when referenced outside of service class. You need to prefix all shapes defined in the service class with the service name
    public func swiftTypeNameWithServiceNamePrefix(_ serviceName: String) -> String {
        switch self.type {
        case .structure(_), .enum:
            return "\(serviceName).\(name.toSwiftClassCase())"

        case .list(let list):
            return "[\(list.member.shape.swiftTypeNameWithServiceNamePrefix(serviceName))]"

        case .map(let map):
            return
                "[\(map.key.shape.swiftTypeNameWithServiceNamePrefix(serviceName)): \(map.value.shape.swiftTypeNameWithServiceNamePrefix(serviceName))]"

        default:
            return self.swiftTypeName
        }
    }
}

extension Shape.Location {
    /// return enum as a string to output in AWSMemberEncoding
    func enumStringValue(named: String) -> String {
        switch self {
        case .header, .headers:
            return ".header(locationName: \"\(named)\")"
        case .querystring:
            return ".querystring(locationName: \"\(named)\")"
        case .uri:
            return ".uri(locationName: \"\(named)\")"
        case .body:
            return ".body(locationName: \"\(named)\")"
        case .statusCode:
            return ".statusCode"
        }
    }
}

extension Shape.Member {
    /// flattemed lists can pass their member locationName up to the instance of list
    func getLocationName() -> String? {
        if case .list(let list) = self.shape.type, list.flattened == true, let locationNameInList = list.member.locationName {
            return locationNameInList
        }
        return locationName
    }
}
