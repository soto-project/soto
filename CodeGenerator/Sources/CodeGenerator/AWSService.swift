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

struct AWSService {
    var api: API
    var docs: Docs
    var paginators: Paginators?
    var endpoints: Endpoints
    var errors: [Shape]

    init(api: API, docs: Docs, paginators: Paginators?, endpoints: Endpoints) throws {
        self.api = api
        self.docs = docs
        self.paginators = paginators
        self.endpoints = endpoints
        self.errors = try Self.getErrors(from: api)
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
        return api.metadata.protocol.enumStringValue
    }

    /// Service endpoints from API and Endpoints structure
    var serviceEndpoints: [(key: String, value: String)] {
        // create dictionary of endpoint name to Endpoint and partition from across all partitions
        struct EndpointInfo {
            let endpoint: Endpoints.Service.Endpoint
            let partition: String
        }
        let serviceEndpoints: [(key: String, value: EndpointInfo)] = endpoints.partitions.reduce([]) { value, partition in
            let endpoints = partition.services[api.metadata.endpointPrefix]?.endpoints
            return value + (endpoints?.map {(key: $0.key, value: EndpointInfo(endpoint: $0.value, partition: partition.partition))} ?? [])
        }
        let partitionEndpoints = self.partitionEndpoints
        let partitionEndpointSet = Set<String>(partitionEndpoints.map { $0.value.endpoint })
        return serviceEndpoints.compactMap {
            // if service endpoint isn't in the set of partition endpoints or a region name return nil
            if partitionEndpointSet.contains($0.key) == false && Region(rawValue: $0.key) == nil {
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
        switch api.serviceName {
        case "APIGateway":
            return "APIGatewayMiddleware()"
        case "Glacier":
            return "GlacierRequestMiddleware(apiVersion: \"\(api.metadata.apiVersion)\")"
        case "S3":
            return "S3RequestMiddleware()"
        case "S3Control":
            return "S3ControlMiddleware()"
        default:
            return nil
        }
    }

    var serviceErrorName: String {
        return api.serviceName + "ErrorType"
    }
}

//MARK: Generate contexts

protocol EncodingPropertiesContext {}

extension AWSService {
    struct ErrorContext {
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
        let deprecated: String?
        let streaming: String?
    }

    struct PaginatorContext {
        let operation: OperationContext
        let output: String
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
        let encoding: String?
    }

    class ValidationContext {
        let name: String
        let shape: Bool
        let required: Bool
        let reqs: [String: Any]
        let member: ValidationContext?
        let key: ValidationContext?
        let value: ValidationContext?

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
            self.key = key
            self.value = value
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
        let encoding: [EncodingPropertiesContext]
        let members: [MemberContext]
        let awsShapeMembers: [AWSShapeMemberContext]
        let codingKeys: [CodingKeysContext]
        let validation: [ValidationContext]
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

    /// generate operations context
    func generateOperationContext(_ operation: Operation, name: String) -> OperationContext {
        return OperationContext(
            comment: docs.operations[name]?.tagStriped().split(separator: "\n") ?? [],
            funcName: name.toSwiftVariableCase(),
            inputShape: operation.input?.shapeName,
            outputShape: operation.output?.shapeName,
            name: operation.name,
            path: operation.http.requestUri,
            httpMethod: operation.http.method,
            deprecated: operation.deprecatedMessage ?? (operation.deprecated == true ? "\(name) is deprecated." : nil),
            streaming: nil
        )
    }

    /// generate operations context for streaming version of function
    func generateStreamingOperationContext(_ operation: Operation, name: String) -> OperationContext? {
        // get output shape
        guard let output = operation.output,
            let shape = try? api.getShape(named: output.shapeName) else { return nil }
        
        if shape.streaming != true {
            guard let payload = shape.payload,
                case .structure(let structure) = shape.type,
                let member = structure.members[payload],
                member.streaming == true || member.shape.streaming == true,
                member.required == false else {
                        return nil
            }
        }

        return OperationContext(
            comment: docs.operations[name]?.tagStriped().split(separator: "\n") ?? [],
            funcName: name.toSwiftVariableCase() + "Streaming",
            inputShape: operation.input?.shapeName,
            outputShape: operation.output?.shapeName,
            name: operation.name,
            path: operation.http.requestUri,
            httpMethod: operation.http.method,
            deprecated: operation.deprecatedMessage ?? (operation.deprecated == true ? "\(name) is deprecated." : nil),
            streaming: "ByteBuffer"
        )
    }

    /// Generate the context information for outputting the service api calls
    func generateServiceContext() -> [String: Any] {
        var context: [String: Any] = [:]

        // Service initialization
        context["name"] = api.serviceName
        context["description"] = docs.service.tagStriped()
        context["amzTarget"] = api.metadata.targetPrefix
        context["endpointPrefix"] = api.metadata.endpointPrefix
        if api.metadata.signingName != api.metadata.endpointPrefix {
            context["signingName"] = api.metadata.signingName
        }
        context["protocol"] = serviceProtocol
        context["apiVersion"] = api.metadata.apiVersion
        let endpoints = serviceEndpoints
            .sorted { $0.key < $1.key }
            .map { "\"\($0.key)\": \"\($0.value)\"" }
        if endpoints.count > 0 {
            context["serviceEndpoints"] = endpoints
        }
        context["partitionEndpoints"] = partitionEndpoints
            .map { (partition: $0.key, endpoint: $0.value.endpoint, region: $0.value.region) }
            .sorted { $0.partition < $1.partition }
            .map { ".\($0.partition.toSwiftRegionEnumCase()): (endpoint: \"\($0.endpoint)\", region: .\($0.region.rawValue.toSwiftRegionEnumCase()))" }

        context["middlewareClass"] = middleware

        if !errors.isEmpty {
            context["errorTypes"] = serviceErrorName
        }

        // service is considered regionalized if any of its service definitions across all partitions say it is.
        // if no service details are found in the endpoints then it is assumed the service is regionalized
        let isRegionalized: Bool? = self.endpoints.partitions.reduce(nil) {
            var isRegionalized = false
            if let service = $1.services[api.metadata.endpointPrefix] {
                isRegionalized = service.isRegionalized ?? true
            } else {
                return $0
            }
            return ($0 ?? false) || isRegionalized
        } ?? true
        context["regionalized"] = isRegionalized

        // Operations
        var operationContexts: [OperationContext] = []
        var streamingOperationContexts: [OperationContext] = []
        for operation in api.operations {
            operationContexts.append(generateOperationContext(operation.value, name: operation.key))
            if let streamingOperationContext = generateStreamingOperationContext(operation.value, name: operation.key) {
                streamingOperationContexts.append(streamingOperationContext)
            }
        }
        context["operations"] = operationContexts.sorted { $0.funcName < $1.funcName }
        context["streamingOperations"] = streamingOperationContexts.sorted { $0.funcName < $1.funcName }
        return context
    }

    /// Generate the context information for outputting the error enums
    func generateErrorContext() -> [String: Any] {
        var context: [String: Any] = [:]
        context["name"] = api.serviceName
        context["errorName"] = serviceErrorName

        var errorContexts: [ErrorContext] = []
        let errors = self.errors.sorted { $0.name < $1.name }
        for error in errors {
            let code: String = error.error?.code ?? error.name
            errorContexts.append(ErrorContext(enum: error.name.toSwiftVariableCase(), string: code))
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
        context["name"] = api.serviceName

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
            let tokenType = inputTokenMember.shape.swiftTypeNameWithServiceNamePrefix(api.serviceName)

            // process output tokens
            let processedOutputTokens = outputTokens.map { (token) -> String in
                var split = token.split(separator: ".")
                for i in 0..<split.count {
                    // if string contains [-1] replace with '.last'.
                    if let negativeIndexRange = split[i].range(of: "[-1]") {
                        split[i].removeSubrange(negativeIndexRange)

                        var replacement = "last"
                        // if a member is mentioned after the '[-1]' then you need to add a ? to the keyPath
                        if split.count > i + 1 {
                            replacement += "?"
                        }
                        split.insert(Substring(replacement), at: i + 1)
                    }
                }
                // if output token is member of an optional struct add ? suffix
                if outputStructure.required.first(where: { $0 == String(split[0]) }) == nil,
                    split.count > 1
                {
                    split[0] += "?"
                }
                return split.map { String($0).toSwiftVariableCase() }.joined(separator: ".")
            }

            var initParams: [String: String] = [:]
            for member in inputStructure.members {
                initParams[member.key.toSwiftLabelCase()] = "self.\(member.key.toSwiftLabelCase())"
            }
            initParams[inputTokens[0].toSwiftLabelCase()] = "token"
            let initParamsArray = initParams.map { "\($0.key): \($0.value)" }.sorted { $0.lowercased() < $1.lowercased() }
            paginatorContexts.append(
                PaginatorContext(
                    operation: generateOperationContext(operation, name: paginator.key),
                    output: processedOutputTokens[0],
                    initParams: initParamsArray,
                    paginatorProtocol: paginatorProtocol,
                    tokenType: tokenType
                )
            )
        }

        if paginatorContexts.count > 0 {
            context["paginators"] = paginatorContexts
        }
        return context
    }

    /// Generate the context information for outputting an enum
    func generateEnumContext(_ shape: Shape, values: [String]) -> EnumContext {

        // Operations
        var valueContexts: [EnumMemberContext] = []
        for value in values {
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

            var caseName = key.camelCased().reservedwordEscaped()
            if caseName.allLetterIsNumeric() {
                caseName = "\(shape.name.toSwiftVariableCase())\(caseName)"
            }
            valueContexts.append(EnumMemberContext(case: caseName, string: value))
        }

        return EnumContext(
            name: shape.name.toSwiftClassCase().reservedwordEscaped(),
            values: valueContexts
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
            codingWrapper = "@Coding"
        } else {
            codingWrapper = "@OptionalCoding"
        }

        // if not located in body don't generate collection encoding property wrapper
        if let location = member.location {
            guard case .body = location else { return nil }
        }

        switch member.shape.type {
        case .list(let list):
            guard api.metadata.protocol != .json && api.metadata.protocol != .restjson else { return nil }
            guard list.flattened != true && member.flattened != true else { return nil }
            let entryName = getArrayEntryName(list)
            if entryName == "member"  {
                return "\(codingWrapper)<DefaultArrayCoder>"
            } else {
                return "\(codingWrapper)<ArrayCoder<\(encodingName(name)), \(list.member.shape.swiftTypeName)>>"
            }
        case .map(let map):
            guard api.metadata.protocol != .json && api.metadata.protocol != .restjson else { return nil }
            let names = getDictionaryEntryNames(map, member: member)
            if names.entry == "entry" && names.key == "key" && names.value == "value" {
                return "\(codingWrapper)<DefaultDictionaryCoder>"
            } else {
                return "\(codingWrapper)<DictionaryCoder<\(encodingName(name)), \(map.key.shape.swiftTypeName), \(map.value.shape.swiftTypeName)>>"
            }
        case .timestamp(let format):
            switch format {
            case .iso8601:
                return "\(codingWrapper)<ISO8601TimeStampCoder>"
            case .unixTimestamp:
                return "\(codingWrapper)<UnixEpochTimeStampCoder>"
            case .unspecified:
                return nil
            }
        default:
            return nil
        }
    }

    /// Generate encoding contexts
    func generateEncodingPropertyContext(_ member: Shape.Member, name: String) -> EncodingPropertiesContext? {
        guard api.metadata.protocol != .json && api.metadata.protocol != .restjson else { return nil }
        if let location = member.location {
            guard case .body = location else { return nil }
        }
        switch member.shape.type {
            case .list(let list):
                guard list.flattened != true && member.flattened != true else { return nil }
                let entryName = getArrayEntryName(list)
                guard entryName != "member" else { return nil }
                return ArrayEncodingPropertiesContext(name: encodingName(name), member: entryName)
            case .map(let map):
                let names = getDictionaryEntryNames(map, member: member)
                guard names.entry != "entry" || names.key != "key" || names.value != "value" else { return nil }
                return DictionaryEncodingPropertiesContext(name: encodingName(name), entry: names.entry, key: names.key, value: names.value)
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
        let memberDocs = docs.shapes[shape.name]?[name]?.tagStriped().split(separator: "\n")
        return MemberContext(
            variable: name.toSwiftVariableCase(),
            locationPath: member.getLocationName() ?? name,
            parameter: name.toSwiftLabelCase(),
            required: member.required,
            default: defaultValue,
            propertyWrapper: generatePropertyWrapper(member, name: name),
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

    /// Return encoding string for shape member
    func getEncoding(for member: Shape.Member, isPayload: Bool) -> String? {
        switch member.shape.type {
        case .blob, .payload:
            if isPayload {
                return ".blob"
            }
        default:
            break
        }

        /*guard api.metadata.protocol != .json && api.metadata.protocol != .restjson else { return nil }

        switch member.shape.type {
        case .list(let list):
            if list.flattened == true || member.flattened == true {
                return ".flatList"
            } else {
                return ".list(member:\"\(getArrayEntryName(list))\")"
            }
        case .map(let map):
            if map.flattened == true || member.flattened == true {
                return ".flatMap(key: \"\(map.key.locationName ?? "key")\", value: \"\(map.value.locationName ?? "value")\")"
            } else {
                return ".map(entry:\"entry\", key: \"\(map.key.locationName ?? "key")\", value: \"\(map.value.locationName ?? "value")\")"
            }
        default:
            break
        }*/
        return nil
    }

    /// Generate the context information for outputting a member variable
    func generateAWSShapeMemberContext(_ member: Shape.Member, name: String, shape: Shape) -> AWSShapeMemberContext? {
        let isPayload = (shape.payload == name)
        let encoding = getEncoding(for: member, isPayload: isPayload)
        var locationName: String? = member.locationName
        let location = member.location ?? .body

        if ((isPayload && shape.usedInOutput) || encoding != nil || (location != .body)) && locationName == nil {
            locationName = name
        }
        // remove location if equal to body and name is same as variable name
        if location == .body && (locationName == name.toSwiftLabelCase() || !isPayload) {
            locationName = nil
        }
        guard locationName != nil || encoding != nil else { return nil }
        return AWSShapeMemberContext(
            name: name.toSwiftLabelCase(),
            location: locationName.map { location.enumStringValue(named: $0) },
            locationName: locationName,
            encoding: encoding
        )
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
            break

        case .list(let list):
            requirements["max"] = list.max
            requirements["min"] = list.min
            // validation code doesn't support containers inside containers. Only service affected by this is SSM
            if !container {
                if let memberValidationContext = generateValidationContext(
                    name: name,
                    shape: list.member.shape,
                    required: true,
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
                let keyValidationContext = generateValidationContext(
                    name: name,
                    shape: map.key.shape,
                    required: true,
                    container: true,
                    alreadyProcessed: alreadyProcessed
                )
                let valueValiationContext = generateValidationContext(
                    name: name,
                    shape: map.value.shape,
                    required: true,
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
                if generateValidationContext(
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
            return ValidationContext(name: name.toSwiftVariableCase(), reqs: requirements)
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
            
            if type.members[payload]?.streaming == true {
                shapePayloadOptions.append("allowStreaming")
                if shape.authtype == "v4-unsigned-body" {
                    shapePayloadOptions.append("allowChunkedStreaming")
                }
            }
        }

        let members = type.members.map { (key: $0.key, value: $0.value) }.sorted { $0.key.lowercased() < $1.key.lowercased() }
        for member in members {
            var memberContext = generateMemberContext(member.value, name: member.key, shape: shape, typeIsEnum: type.isEnum)

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

            if let awsShapeMemberContext = generateAWSShapeMemberContext(
                member.value,
                name: member.key,
                shape: shape
            ) {
                awsShapeMemberContexts.append(awsShapeMemberContext)
            }

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
            object: doesShapeHaveRecursiveOwnReference(shape, type: type) ? "class" : "struct",
            name: shape.swiftTypeName,
            shapeProtocol: shapeProtocol,
            payload: shape.payload?.toSwiftLabelCase(),
            payloadOptions: shapePayloadOptions.count > 0 ? shapePayloadOptions.map {".\($0)"}.joined(separator: ", ") : nil,
            namespace: shape.xmlNamespace?.uri,
            encoding: encodingContexts,
            members: memberContexts,
            awsShapeMembers: awsShapeMemberContexts,
            codingKeys: codingKeyContexts,
            validation: validationContexts
        )
    }

    /// Generate the context for outputting all the AWSShape (enums and structures)
    func generateShapesContext() -> [String: Any] {
        var context: [String: Any] = [:]
        context["name"] = api.serviceName

        var shapeContexts: [[String: Any]] = []
        let shapes = api.shapes.values.sorted { $0.name < $1.name }
        for shape in shapes {
            if shape.usedInInput == false && shape.usedInOutput == false {
                continue
            }

            switch shape.type {
            case .enum(let enumType):
                var enumContext: [String: Any] = [:]
                enumContext["enum"] = generateEnumContext(shape, values: enumType.cases)
                shapeContexts.append(enumContext)

            case .structure(let type):
                var structContext: [String: Any] = [:]
                if type.isEnum {
                    structContext["enumWithValues"] = generateStructureContext(shape, type: type)
                } else {
                    structContext["struct"] = generateStructureContext(shape, type: type)
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

//MARK: Extensions

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
            return "TimeStamp"
        case .enum:
            return name.toSwiftClassCase()
        }
    }

    /// return swift type name that would compile when referenced outside of service class. You need to prefix all shapes defined in the service class with the service name
    public func swiftTypeNameWithServiceNamePrefix(_ serviceName: String) -> String {
        switch self.type {
        case .structure(_), .enum(_):
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
