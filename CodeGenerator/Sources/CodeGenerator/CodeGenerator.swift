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
import SwiftyJSON

/*
 CHANGES/ASSUMPTIONS from shape member cleanup
 
 AWSShapeMember label is the name coming from the model file. The member variable lowercases the first letter
 Payload data blob has encoding: .blob. They need the AWSShapeMember label to identify them
 
 */
extension Location {
    func enumStyleDescription() -> String {
        switch self {
        case .uri(locationName: let name):
            return ".uri(locationName: \"\(name)\")"
        case .querystring(locationName: let name):
            return ".querystring(locationName: \"\(name)\")"
        case .header(locationName: let name):
            return ".header(locationName: \"\(name)\")"
        case .body(locationName: let name):
            return ".body(locationName: \"\(name)\")"
        }
    }

    init?(json: JSON) {
        guard let name = json["locationName"].string else {
            return nil
        }

        let loc = json["location"].string ?? "body"

        switch loc.lowercased() {
        case "uri":
            self = .uri(locationName: name)

        case "querystring":
            self = .querystring(locationName: name)

        case "header", "headers":
            self = .header(locationName: name)

        case  "body":
            self = .body(locationName: name)

        default:
            return nil
        }
    }
}

extension ShapeEncoding {
    func enumStyleDescription() -> String {
        switch self {
        case .default:
            return ".default"
        case .list(let member):
            return ".list(member:\"\(member)\")"
        case .flatList:
            return ".flatList"
        case .map(let entry, let key, let value):
            return ".map(entry:\"\(entry)\", key: \"\(key)\", value: \"\(value)\")"
        case .flatMap(let key, let value):
            return ".flatMap(key: \"\(key)\", value: \"\(value)\")"
        case .blob:
            return ".blob"
        }
    }

    init?(json: JSON) {
        if json["type"].string == "list" {
            if json["flattened"].bool == true {
                self = .flatList
            } else {
                self = .list(member: json["member"]["locationName"].string ?? "member")
            }
        } else if json["type"].string == "map" {
            let key = json["key"]["locationName"].string ?? "key"
            let value = json["value"]["locationName"].string ?? "value"
            if json["flattened"].bool == true {
                self = .flatMap(key: key, value: value)
            } else {
                let entry = "entry"
                self = .map(entry: entry, key: key, value: value)
            }
        } else {
            return nil
        }
    }
}

extension ServiceProtocol {
    public func instantiationCode() -> String {
        if let version = self.version {
            return "ServiceProtocol(type: .\(type), version: ServiceProtocol.Version(major: \(version.major), minor: \(version.minor)))"
        } else {
            return "ServiceProtocol(type: .\(type))"
        }
    }
}

extension Shape {
    public var swiftTypeName: String {
        switch self.type {
        case .string(_, _, _):
            return "String"
        case .integer(_, _):
            return "Int"
        case .structure(_):
            return name.toSwiftClassCase()
        case .boolean:
            return "Bool"
        case .list(let shape,_,_):
            return "[\(shape.swiftTypeName)]"
        case .map(key: let keyShape, value: let valueShape):
            return "[\(keyShape.swiftTypeName): \(valueShape.swiftTypeName)]"
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
        case .unhandledType:
            return "Any"
        }
    }
    
    /// return swift type name that would compile when referenced outside of service class. You need to prefix all shapes defined in the service class with the service name
    public func swiftTypeNameWithServiceNamePrefix(_ serviceName: String) -> String {
        switch self.type {
        case .structure(_), .enum(_):
            return "\(serviceName).\(name.toSwiftClassCase())"
        case .list(let shape,_,_):
            return "[\(shape.swiftTypeNameWithServiceNamePrefix(serviceName))]"
        case .map(key: let keyShape, value: let valueShape):
            return "[\(keyShape.swiftTypeNameWithServiceNamePrefix(serviceName)): \(valueShape.swiftTypeNameWithServiceNamePrefix(serviceName))]"
        default:
            return self.swiftTypeName
        }
    }
}

extension ShapeType {
    var description: String {
        switch self {
        case .structure:
            return "structure"
        case .list:
            return "list"
        case .map:
            return "map"
        case .enum:
            return "enum"
        case .boolean:
            return "boolean"
        case .blob:
            return "blob"
        case .double:
            return "double"
        case .float:
            return "float"
        case .long:
            return "long"
        case .integer:
            return "integer"
        case .string:
            return "string"
        case .timestamp:
            return "timestamp"
        case .unhandledType:
            return "any"
        }
    }
}

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
    }

    struct EnumMemberContext {
        let `case`: String
        let string: String
    }

    struct EnumContext {
        let name: String
        let values: [EnumMemberContext]
    }

    struct MemberContext {
        let variable : String
        let locationPath : String
        let parameter : String
        let required : Bool
        let `default` : String?
        let type : String
        let typeEnum : String
        let comment : [String.SubSequence]
        var duplicate : Bool
    }

    struct AWSShapeMemberContext {
        let name : String
        let location : String?
        let encoding : String?
    }

    class ValidationContext {
        let name : String
        let shape : Bool
        let required : Bool
        let reqs : [String : Any]
        let member : ValidationContext?
        let key : ValidationContext?
        let value : ValidationContext?

        init(name: String, shape: Bool = false, required: Bool = true, reqs: [String: Any] = [:], member: ValidationContext? = nil, key: ValidationContext? = nil, value: ValidationContext? = nil) {
            self.name = name
            self.shape = shape
            self.required = required
            self.reqs = reqs
            self.member = member
            self.key = key
            self.value = value
        }
    }

    struct StructureContext {
        let object : String
        let name : String
        let payload : String?
        let namespace : String?
        let members : [MemberContext]
        let awsShapeMembers : [AWSShapeMemberContext]
        let validation : [ValidationContext]
    }

    struct ResultContext {
        let name: String
        let type: String
    }
    struct PaginatorContext {
        let operation: OperationContext
        let output: String
        let initParams: [String]
        let paginatorProtocol: String
        let tokenType: String
    }

    /// Generate the context information for outputting the error enums
    func generateErrorContext() -> [String: Any] {
        var context: [String: Any] = [:]
        context["name"] = serviceName
        context["errorName"] = serviceErrorName

        var errorContexts: [ErrorContext] = []
        for error in errors {
            let code = error.code ?? error.name
            errorContexts.append(ErrorContext(enum: error.name.toSwiftVariableCase(), string: code))
        }
        if errorContexts.count > 0 {
            context["errors"] = errorContexts
        }
        return context
    }

    /// generate operations context
    func generateOperationContext(_ operation: Operation) -> OperationContext {
        return OperationContext(
            comment: docJSON["operations"][operation.name].stringValue.tagStriped().split(separator: "\n"),
            funcName: operation.name.toSwiftVariableCase(),
            inputShape: operation.inputShape?.swiftTypeName,
            outputShape: operation.outputShape?.swiftTypeName,
            name: operation.operationName,
            path: operation.path,
            httpMethod: operation.httpMethod,
            deprecated: operation.deprecatedMessage
        )
    }
    
    func getMiddleware() -> String? {
        switch serviceName {
        case "APIGateway":
            return "APIGatewayMiddleware()"
        case "Glacier":
            return "GlacierRequestMiddleware(apiVersion: \"\(version)\")"
        case "S3":
            return "S3RequestMiddleware()"
        case "S3Control":
            return "S3ControlMiddleware()"
        default:
            return nil
        }
    }
    
    /// Generate the context information for outputting the service api calls
    func generateServiceContext() -> [String: Any] {
        var context: [String: Any] = [:]

        // Service initialization
        context["name"] = serviceName
        context["description"] = serviceDescription
        context["amzTarget"] = apiJSON["metadata"]["targetPrefix"].string
        context["endpointPrefix"] = endpointPrefix
        if signingName != endpointPrefix {
            context["signingName"] = signingName
        }
        context["protocol"] = serviceProtocol.instantiationCode()
        context["apiVersion"] = version
        let endpoints = serviceEndpoints.sorted { $0.key < $1.key }.map {return "\"\($0.key)\": \"\($0.value)\""}
        if endpoints.count > 0 {
            context["serviceEndpoints"] = endpoints
        }
        context["partitionEndpoint"] = partitionEndpoint
        context["middlewareClass"] = getMiddleware()

        if !errors.isEmpty {
            context["errorTypes"] = serviceErrorName
        }

        // Operations
        var operationContexts: [OperationContext] = []
        for operation in operations {
            operationContexts.append(generateOperationContext(operation))
        }
        context["operations"] = operationContexts
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

            if Int(String(key[key.startIndex])) != nil { key = "_"+key }

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

    /// Generate the context information for outputting a member variable
    func generateMemberContext(_ member: Member, shape: Shape) -> MemberContext {
        let defaultValue : String?
        if member.options.contains(.idempotencyToken) {
            defaultValue = "\(shape.swiftTypeName).idempotencyToken()"
        } else if !member.required {
            defaultValue = "nil"
        } else {
            defaultValue = nil
        }
        return MemberContext(
            variable: member.name.toSwiftVariableCase(),
            locationPath: member.location?.name ?? member.name,
            parameter: member.name.toSwiftLabelCase(),
            required: member.required,
            default: defaultValue,
            type: member.shape.swiftTypeName + (member.required ? "" : "?"),
            typeEnum: "\(member.shape.type.description)",
            comment: shapeDoc[shape.name]?[member.name]?.split(separator: "\n") ?? [],
            duplicate: false
        )
    }

    /// Generate the context information for outputting a member variable
    func generateAWSShapeMemberContext(_ member: Member, shape: Shape, forceOutput: Bool) -> AWSShapeMemberContext? {
        let encoding = member.shapeEncoding?.enumStyleDescription()
        var location = member.location
        
        // if member has collection encoding ie the codingkey will be needed, or name has been force to output then add a Location.body
        if (encoding != nil || forceOutput) && location == nil {
            location = .body(locationName: member.name)
        }
        // remove location if equal to body and name is same as variable name
        if case .body(let name) = location, name == member.name.toSwiftLabelCase() {
            location = nil
        }
        guard location != nil || encoding != nil else { return nil }
        return AWSShapeMemberContext(
            name: member.name.toSwiftLabelCase(),
            location: location?.enumStyleDescription(),
            encoding: encoding
        )
    }

    /// Generate validation context
    func generateValidationContext(name: String, shape: Shape, required: Bool, container: Bool = false) -> ValidationContext? {
        var requirements : [String: Any] = [:]
        switch shape.type {
        case .integer(let max, let min),
             .long(let max, let min),
             .float(let max, let min),
             .double(let max, let min):
            requirements["max"] = max
            requirements["min"] = min

        case .blob(let max, let min):
            requirements["max"] = max
            requirements["min"] = min

        case .list(let shape, let max, let min):
            requirements["max"] = max
            requirements["min"] = min
            // validation code doesn't support containers inside containers. Only service affected by this is SSM
            if !container {
                if let memberValidationContext = generateValidationContext(name: name, shape: shape, required: true, container: true) {
                    return ValidationContext(name: name.toSwiftVariableCase(), required: required, reqs: requirements, member: memberValidationContext)
                }
            }
        case .map(let key, let value):
            // validation code doesn't support containers inside containers. Only service affected by this is SSM
            if !container {
                let keyValidationContext = generateValidationContext(name: name, shape: key, required: true, container: true)
                let valueValiationContext = generateValidationContext(name: name, shape: value, required: true, container: true)
                if keyValidationContext != nil || valueValiationContext != nil {
                    return ValidationContext(name: name.toSwiftVariableCase(), required: required, key: keyValidationContext, value: valueValiationContext)
                }
            }
        case .string(let max, let min, let pattern):
            requirements["max"] = max
            requirements["min"] = min
            if let pattern = pattern {
                requirements["pattern"] = "\"\(pattern.addingBackslashEncoding())\""
            }
        case .structure(let shape):
            for member2 in shape.members {
                if generateValidationContext(name:member2.name, shape:member2.shape, required: member2.required) != nil {
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
    func generateStructureContext(_ shape: Shape, type: StructureShape) -> StructureContext {
        var memberContexts : [MemberContext] = []
        var awsShapeMemberContexts : [AWSShapeMemberContext] = []
        var validationContexts : [ValidationContext] = []
        var usedLocationPath : [String] = []
        for member in type.members {
            var memberContext = generateMemberContext(member, shape: shape)

            // check for duplicates, this seems to be mainly caused by deprecated variables
            let locationPath = member.location?.name ?? member.name
            if usedLocationPath.contains(locationPath) {
                memberContext.duplicate = true
            } else {
                usedLocationPath.append(locationPath)
            }

            memberContexts.append(memberContext)

            if let awsShapeMemberContext = generateAWSShapeMemberContext(member, shape: shape, forceOutput: type.payload == member.name) {
                awsShapeMemberContexts.append(awsShapeMemberContext)
            }

            // only output validation for shapes used in inputs to service apis
            if shape.usedInInput {
                if let validationContext = generateValidationContext(name:member.name, shape: member.shape, required: member.required) {
                    validationContexts.append(validationContext)
                }
            }
        }

        return StructureContext(
            object: doesShapeHaveRecursiveOwnReference(shape, type: type) ? "class" : "struct",
            name: shape.swiftTypeName,
            payload: type.payload?.toSwiftLabelCase(),
            namespace: type.xmlNamespace,
            members: memberContexts,
            awsShapeMembers: awsShapeMemberContexts,
            validation: validationContexts)
    }

    /// return if shape has a recursive reference (function only tests 2 levels)
    func doesShapeHaveRecursiveOwnReference(_ shape: Shape, type: StructureShape) -> Bool {
        let hasRecursiveOwnReference = type.members.contains(where: { member in
            // does shape have a member of same type as itself
            if member.shape.swiftTypeName == shape.swiftTypeName || member.shape.swiftTypeName == "[\(shape.swiftTypeName)]" {
                return true
            } else if case .structure(let type) = member.shape.type {
                // test children structures as well to see if they contain a member of same type as the parent shape
                if type.members.contains(where: {
                    return $0.shape.swiftTypeName == shape.swiftTypeName || $0.shape.swiftTypeName == "[\(shape.swiftTypeName)]"
                }) {
                    return true
                }
            }
            return false
        })
        
        return hasRecursiveOwnReference
    }
    
    /// Generate the context for outputting all the AWSShape (enums and structures)
    func generateShapesContext() -> [String: Any] {
        var context: [String: Any] = [:]
        context["name"] = serviceName

        var shapeContexts: [[String: Any]] = []
        for shape in shapes {
            if shape.usedInInput == false && shape.usedInOutput == false {
                continue
            }
            // don't output error shapes
            //if errorShapeNames.contains(shape.name) { continue }

            switch shape.type {
            case .enum(let values):
                var enumContext: [String: Any] = [:]
                enumContext["enum"] = generateEnumContext(shape, values: values)
                shapeContexts.append(enumContext)

            case .structure(let type):
                var structContext: [String: Any] = [:]
                structContext["struct"] = generateStructureContext(shape, type: type)
                shapeContexts.append(structContext)

            default:
                break
            }
        }
        context["shapes"] = shapeContexts
        return context
    }

    /// Generate paginator context
    func generatePaginatorContext() -> [String: Any] {
        var context: [String: Any] = [:]
        context["name"] = serviceName

        var paginatorContexts: [PaginatorContext] = []
        
        for paginator in paginators {
            // get related operation and its input and output shapes
            guard let operation = operations.first(where: {$0.name == paginator.methodName}),
                let inputShape = operation.inputShape,
                let outputShape = operation.outputShape,
                case .structure(let inputShapeStruct) = inputShape.type,
                case .structure(let outputShapeStruct) = outputShape.type else {
                    continue
            }

            // get input token member
            guard paginator.inputTokens.count > 0,
                paginator.outputTokens.count > 0,
                let inputTokenMember = inputShapeStruct.members.first(where: {$0.name == paginator.inputTokens[0]}) else {
                    continue
            }
            
            let paginatorProtocol = "AWSPaginateToken"
            let tokenType = inputTokenMember.shape.swiftTypeNameWithServiceNamePrefix(serviceName)
            
            // process output tokens
            let outputTokens = paginator.outputTokens.map { (token)->String in
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
                if let outputTokenMember = outputShapeStruct.members.first(where: {$0.name == split[0]}), !outputTokenMember.required, split.count > 1 {
                    split[0] += "?"
                }
                return split.map { String($0).toSwiftVariableCase() }.joined(separator: ".")
            }
                        
            var initParams: [String: String] = [:]
            for member in inputShapeStruct.members {
                initParams[member.name.toSwiftLabelCase()] = "self.\(member.name.toSwiftLabelCase())"
            }
            initParams[paginator.inputTokens[0].toSwiftLabelCase()] = "token"
            let initParamsArray = initParams.map {"\($0.key): \($0.value)"}.sorted { $0.lowercased() < $1.lowercased() }
            paginatorContexts.append(
                PaginatorContext(
                    operation: generateOperationContext(operation),
                    output: outputTokens[0],
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
    
    func getCustomTemplates() -> [String] {
        return Glob.entries(pattern: "\(rootPath())/CodeGenerator/Templates/Custom/\(endpointPrefix)/*.stencil")
    }

}
