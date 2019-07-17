//
//  CodeGenerator.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/04.
//  Edited by Adam Fowler to use Stencil (https://github.com/stencilproject/Stencil.git) templating library
//

import Foundation
import SwiftyJSON
import AWSSDKSwiftCore

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
            return "Int32"
        case .structure(_):
            return name.toSwiftClassCase()
        case .boolean:
            return "Bool"
        case .list(let shape):
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

extension String {
    func allLetterIsNumeric() -> Bool {
        for character in self {
            if let ascii = character.unicodeScalars.first?.value, (0x30..<0x39).contains(ascii) {
                continue
            } else {
                return false
            }
        }
        return true
    }
}

extension ShapeType {
    var memberShapeType : AWSShapeMember.Shape {
        switch self {
        case .structure:
            return .structure
        case .list:
            return .list
        case .map:
            return .map
        case .enum:
            return .enum
        case .boolean:
            return .boolean
        case .blob:
            return .blob
        case .double:
            return .double
        case .float:
            return .float
        case .long:
            return .long
        case .integer:
            return .integer
        case .string:
            return .string
        case .timestamp:
            return .timestamp
        case .unhandledType:
            return .any
        }
    }
}

extension AWSService {
    /// Generate the context information for outputting the error enums
    func generateErrorContext() -> [String: Any] {
        var context : [String: Any] = [:]
        context["name"] = serviceName
        context["errorName"] = serviceErrorName
        
        var errorContexts : [[String : Any]] = []
        for error in errorShapeNames {
            var context : [String: Any] = [:]
            context["enum"] = error.toSwiftVariableCase()
            context["string"] = error
            errorContexts.append(context)
        }
        if errorContexts.count > 0 {
            context["errors"] = errorContexts
        }
        return context
    }

    /// Generate the context information for outputting the service api calls
    func generateServiceContext() -> [String: Any] {
        var context : [String: Any] = [:]
        
        // Service initialization
        context["name"] = serviceName
        context["description"] = serviceDescription
        context["amzTarget"] = apiJSON["metadata"]["targetPrefix"].string
        context["endpointPrefix"] = endpointPrefix
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
        var operationContexts : [[String : Any]] = []
        for operation in operations {
            var context : [String: Any] = [:]
            context["comment"] = docJSON["operations"][operation.name].stringValue.tagStriped().split(separator: "\n")
            context["funcName"] = operation.name.toSwiftVariableCase()
            context["inputShape"] = operation.inputShape?.swiftTypeName
            context["outputShape"] = operation.outputShape?.swiftTypeName
            context["name"] = operation.name
            context["path"] = operation.path
            context["httpMethod"] = operation.httpMethod
            context["deprecated"] = operation.deprecatedMessage
            operationContexts.append(context)
        }
        context["operations"] = operationContexts
        return context
    }
    
    /// Generate the context information for outputting an enum
    func generateEnumContext(_ shape: Shape, values: [String]) -> [String: Any] {
        var context : [String: Any] = [:]
        
        context["name"] = shape.name.toSwiftClassCase().reservedwordEscaped()
        
        // Operations
        var valueContexts : [[String : Any]] = []
        for value in values {
            var context : [String: Any] = [:]
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
            
            let caseName = key.camelCased().reservedwordEscaped()
            if caseName.allLetterIsNumeric() {
                context["case"] = "\(shape.name.toSwiftVariableCase())\(caseName)"
            } else {
                context["case"] = caseName
            }
            context["string"] = value
            valueContexts.append(context)
        }
        context["values"] = valueContexts
        return context
    }
    
    /// Generate the context information for outputting a member variable
    func generateMemberContext(_ member: Member, shape: Shape) -> [String: Any] {
        var context : [String: Any] = [:]
        context["name"] = member.name
        context["variable"] = member.name.toSwiftVariableCase()
        context["locationPath"] = member.location?.name ?? member.name
        context["location"] = member.location?.enumStyleDescription()
        context["parameter"] = member.name.toSwiftLabelCase()
        context["required"] = member.required
        context["type"] = member.shape.swiftTypeName + (member.required ? "" : "?")
        context["typeEnum"] = "\(member.shape.type.memberShapeType)"
        context["encoding"] = member.shapeEncoding?.enumStyleDescription()
        if let comment = shapeDoc[shape.name]?[member.name] {
            context["comment"] = comment.split(separator: "\n")
        }
        return context
    }
    
    /// Generate the context for outputting a single AWSShape
    func generateStructureContext(_ shape: Shape, type: StructureShape) -> [String: Any] {
        var context : [String: Any] = [:]
        let hasRecursiveOwnReference = type.members.contains(where: {
            return $0.shape.swiftTypeName == shape.swiftTypeName
                || $0.shape.swiftTypeName == "[\(shape.swiftTypeName)]"
        })
        
        context["object"] = hasRecursiveOwnReference ? "class" : "struct"
        context["name"] = shape.swiftTypeName
        context["payload"] = type.payload
        context["namespace"] = type.xmlNamespace
        
        var memberContexts : [[String : Any]] = []
        var usedLocationPath : [String] = []
        for member in type.members {
            var memberContext = generateMemberContext(member, shape: shape)
            
            // check for duplicates, this seems to be mainly caused by deprecated variables
            let locationPath = member.location?.name ?? member.name
            if usedLocationPath.contains(locationPath) {
                memberContext["duplicate"] = true
            } else {
                usedLocationPath.append(locationPath)
            }

            memberContexts.append(memberContext)
        }
        context["members"] = memberContexts
        return context
    }
    
    /// Generate the context for outputting all the AWSShape (enums and structures)
    func generateShapesContext() -> [String: Any] {
        var context : [String: Any] = [:]
        context["name"] = serviceName

        var shapeContexts : [[String : Any]] = []
        for shape in shapes {
            if errorShapeNames.contains(shape.name) { continue }

            switch shape.type {
            case .enum(let values):
                var enumContext : [String: Any] = [:]
                enumContext["enum"] = generateEnumContext(shape, values: values)
                shapeContexts.append(enumContext)

            case .structure(let type):
                var structContext : [String: Any] = [:]
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
