//
//  CodeGenerator.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/04.
//  Edited by Adam Fowler to use Stencil (https://github.com/stencilproject/Stencil.git) templating library
//

import Foundation
import SwiftyJSON

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
        case .string(_):
            return "String"
        case .integer(_):
            return "Int"
        case .structure(_):
            return name.toSwiftClassCase()
        case .boolean:
            return "Bool"
        case .list(let shape,_,_):
            return "[\(shape.swiftTypeName)]"
        case .map(key: let keyShape, value: let valueShape):
            return "[\(keyShape.swiftTypeName): \(valueShape.swiftTypeName)]"
        case .long(_):
            return "Int64"
        case .double(_):
            return "Double"
        case .float(_):
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
        let name : String
        let variable : String
        let locationPath : String
        let location : String?
        let parameter : String
        let required : Bool
        let `default` : String?
        let type : String
        let typeEnum : String
        let encoding : String?
        let comment : [String.SubSequence]
        var duplicate : Bool
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
        let validation : [ValidationContext]
    }

    /// Generate the context information for outputting the error enums
    func generateErrorContext() -> [String: Any] {
        var context: [String: Any] = [:]
        context["name"] = serviceName
        context["errorName"] = serviceErrorName

        var errorContexts: [ErrorContext] = []
        for error in errorShapeNames {
            errorContexts.append(ErrorContext(enum: error.toSwiftVariableCase(), string: error))
        }
        if errorContexts.count > 0 {
            context["errors"] = errorContexts
        }
        return context
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
        switch endpointPrefix {
        case "s3":
            context["middlewareFramework"] = "S3Middleware"
            context["middlewareClass"] = "S3RequestMiddleware()"
        case "glacier":
            context["middlewareFramework"] = "GlacierMiddleware"
            context["middlewareClass"] = "GlacierRequestMiddleware(apiVersion: \"\(version)\")"
        default:
            break
        }
        if !errorShapeNames.isEmpty {
            context["errorTypes"] = serviceErrorName
        }

        // Operations
        var operationContexts: [OperationContext] = []
        for operation in operations {
            operationContexts.append(OperationContext(
                comment: docJSON["operations"][operation.name].stringValue.tagStriped().split(separator: "\n"),
                funcName: operation.name.toSwiftVariableCase(),
                inputShape: operation.inputShape?.swiftTypeName,
                outputShape: operation.outputShape?.swiftTypeName,
                name: operation.name,
                path: operation.path,
                httpMethod: operation.httpMethod,
                deprecated: operation.deprecatedMessage))
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
            name: member.name,
            variable: member.name.toSwiftVariableCase(),
            locationPath: member.location?.name ?? member.name,
            location: member.location?.enumStyleDescription(),
            parameter: member.name.toSwiftLabelCase(),
            required: member.required,
            default: defaultValue,
            type: member.shape.swiftTypeName + (member.required ? "" : "?"),
            typeEnum: "\(member.shape.type.description)",
            encoding: member.shapeEncoding?.enumStyleDescription(),
            comment: shapeDoc[shape.name]?[member.name]?.split(separator: "\n") ?? [],
            duplicate: false
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
        let hasRecursiveOwnReference = type.members.contains(where: {
            return $0.shape.swiftTypeName == shape.swiftTypeName
                || $0.shape.swiftTypeName == "[\(shape.swiftTypeName)]"
        })

        var memberContexts : [MemberContext] = []
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

            // only output validation for shapes used in inputs to service apis
            if shape.usedInInput {
                if let validationContext = generateValidationContext(name:member.name, shape: member.shape, required: member.required) {
                    validationContexts.append(validationContext)
                }
            }
        }

        return StructureContext(
            object: hasRecursiveOwnReference ? "class" : "struct",
            name: shape.swiftTypeName,
            payload: type.payload,
            namespace: type.xmlNamespace,
            members: memberContexts,
            validation: validationContexts)
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
            if errorShapeNames.contains(shape.name) { continue }

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

}
