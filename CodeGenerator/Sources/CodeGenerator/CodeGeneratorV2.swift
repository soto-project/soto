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

struct CodeGeneratorV2 {
    var api: API
    var docs: Docs
    var paginators: Paginators?
    var endpoints: Endpoints
    var errors: [API.Shape]
    
    init(api: API, docs: Docs, paginators: Paginators?, endpoints: Endpoints) throws {
        self.api = api
        self.docs = docs
        self.paginators = paginators
        self.endpoints = endpoints
        self.errors = try Self.getErrors(from: api)
    }
    
    /// Return list of errors from API
    static func getErrors(from api: API) throws -> [API.Shape] {
        var errorsSet: Set<API.Shape> = []
        for operation in api.operations.values {
            for error in operation.errors {
                try errorsSet.insert(api.getShape(named: error.shapeName))
            }
        }
        return errorsSet.map { $0 }
    }
    
    /// service protocol
    var serviceProtocol: String {
        var versionString: String = ""
        if let version = api.metadata.jsonVersion?.split(separator: ".") {
            versionString = ", version: ServiceProtocol.Version(major: \(version[0]), minor: \(version[1]))"
        }
        return "ServiceProtocol(type: \(api.metadata.protocol.enumStringValue)\(versionString))"
    }
    
    /// Service endpoints from API and Endpoints structure
    var serviceEndpoints: [(key: String, value: String)] {
        guard let serviceEndpoints = endpoints.partitions[0].services[api.metadata.endpointPrefix]?.endpoints else { return [] }
        return serviceEndpoints.compactMap {
            if let hostname = $0.value.hostname {
                return (key: $0.key, value: hostname)
            } else if partitionEndpoint != nil {
                // if there is a partition endpoint, then default this regions endpoint to ensure partition endpoint doesn't override it. Only an issue for S3 at the moment.
                return (key: $0.key, value: "\(api.metadata.endpointPrefix).\($0.key).amazonaws.com")
            }
            return nil
        }
    }

    var partitionEndpoint: String? {
        return endpoints.partitions[0].services[api.metadata.endpointPrefix]?.partitionEndpoint
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

extension CodeGeneratorV2 {
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
    }

    struct PaginatorContext {
        let operation: OperationContext
        let output: String
        let initParams: [String]
        let paginatorProtocol: String
        let tokenType: String
    }

    /// generate operations context
    func generateOperationContext(_ operation: API.Operation, name: String) -> OperationContext {
        return OperationContext(
            comment: docs.operations[name]?.tagStriped().split(separator: "\n") ?? [],
            funcName: name.toSwiftVariableCase(),
            inputShape: operation.input?.shapeName,
            outputShape: operation.output?.shapeName,
            name: operation.name,
            path: operation.http.requestUri,
            httpMethod: operation.http.method,
            deprecated: operation.deprecatedMessage ?? (operation.deprecated == true ? "\(name) is deprecated." : nil)
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
        let endpoints = serviceEndpoints.sorted { $0.key < $1.key }.map {return "\"\($0.key)\": \"\($0.value)\""}
        if endpoints.count > 0 {
            context["serviceEndpoints"] = endpoints
        }
        context["partitionEndpoint"] = partitionEndpoint
        context["middlewareClass"] = middleware

        if !errors.isEmpty {
            context["errorTypes"] = serviceErrorName
        }

        // Operations
        var operationContexts: [OperationContext] = []
        for operation in api.operations {
            operationContexts.append(generateOperationContext(operation.value, name: operation.key))
        }
        context["operations"] = operationContexts.sorted { $0.funcName < $1.funcName }
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
        let paginators = pagination.map { return (key:$0.key, value: $0.value) }.sorted { $0.key < $1.key }
        var context: [String: Any] = [:]
        context["name"] = api.serviceName

        var paginatorContexts: [PaginatorContext] = []
        
        for paginator in paginators {
            // get related operation and its input and output shapes
            guard let operation = api.operations[paginator.key],
                let inputShape = try operation.input.map({ try api.getShape(named: $0.shapeName) }),
                let outputShape = try operation.output.map({ try api.getShape(named: $0.shapeName) }),
                case .structure(_, let inputMembers) = inputShape.type,
                case .structure(let outputRequired, _) = outputShape.type else {
                    continue
            }

            let inputTokens = paginator.value.inputTokens ?? []
            let rawOutputTokens = paginator.value.outputTokens ?? []
            let outputTokens = rawOutputTokens.map { String($0.split(separator: "|")[0]).trimmingCharacters(in: CharacterSet.whitespaces) }

            // get input token member
            guard inputTokens.count > 0,
                outputTokens.count > 0,
                let inputTokenMember = inputMembers[inputTokens[0]] else {
                    continue
            }
            
            let paginatorProtocol = "AWSPaginateToken"
            let tokenType = inputTokenMember.shape.swiftTypeNameWithServiceNamePrefix(api.serviceName)
            
            // process output tokens
            let processedOutputTokens = outputTokens.map { (token)->String in
                var split = token.split(separator: ".")
                for i in 0..<split.count {
                    // if string contains [-1] replace with '.last'.
                    if let negativeIndexRange = split[i].range(of: "[-1]") {
                        split[i].removeSubrange(negativeIndexRange)
                        
                        var replacement = "last"
                        // if a member is mentioned after the '[-1]' then you need to add a ? to the keyPath
                        if split.count > i+1 {
                            replacement += "?"
                        }
                        split.insert(Substring(replacement), at: i+1)
                    }
                }
                // if output token is member of an optional struct add ? suffix
                if outputRequired?.first(where: {$0 == String(split[0])}) == nil,
                    split.count > 1 {
                    split[0] += "?"
                }
                return split.map { String($0).toSwiftVariableCase() }.joined(separator: ".")
            }
                        
            var initParams: [String: String] = [:]
            for member in inputMembers {
                initParams[member.key.toSwiftLabelCase()] = "self.\(member.key.toSwiftLabelCase())"
            }
            initParams[inputTokens[0].toSwiftLabelCase()] = "token"
            let initParamsArray = initParams.map {"\($0.key): \($0.value)"}.sorted { $0.lowercased() < $1.lowercased() }
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
    
}

//MARK: Extensions

extension API.Shape : Hashable, Equatable {
    static func == (lhs: API.Shape, rhs: API.Shape) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        self.name.hash(into: &hasher)
    }
}

extension API.Metadata.ServiceProtocol {
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
            return ".other(\"ec2\")"
        }
    }
}

extension API.Shape {
    public var swiftTypeName: String {
        switch self.type {
        case .string(_, _, _):
            return "String"
        case .integer(_, _):
            return "Int"
        case .structure(_, _):
            return name.toSwiftClassCase()
        case .boolean:
            return "Bool"
        case .list(let member,_,_):
            return "[\(member.shape.swiftTypeName)]"
        case .map(key: let key, value: let value):
            return "[\(key.shape.swiftTypeName): \(value.shape.swiftTypeName)]"
        case .long(_, _):
            return "Int64"
        case .double(_, _):
            return "Double"
        case .float(_, _):
            return "Float"
        case .blob:
            return "Data"
        case .timestamp:
            return "TimeStamp"
        case .enum(_):
            return name.toSwiftClassCase()
        }
    }
    
    /// return swift type name that would compile when referenced outside of service class. You need to prefix all shapes defined in the service class with the service name
    public func swiftTypeNameWithServiceNamePrefix(_ serviceName: String) -> String {
        switch self.type {
        case .structure(_,_), .enum(_):
            return "\(serviceName).\(name.toSwiftClassCase())"
            
        case .list(let member,_,_):
            return "[\(member.shape.swiftTypeNameWithServiceNamePrefix(serviceName))]"
            
        case .map(key: let key, value: let value):
            return "[\(key.shape.swiftTypeNameWithServiceNamePrefix(serviceName)): \(value.shape.swiftTypeNameWithServiceNamePrefix(serviceName))]"
            
        default:
            return self.swiftTypeName
        }
    }
}

