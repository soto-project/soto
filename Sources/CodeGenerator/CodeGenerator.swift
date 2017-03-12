//
//  CodeGenerator.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/04.
//
//

// TODO should use template engine to generate code

import Foundation
import SwiftyJSON

struct OperationBuilder {
    let serviceName: String
    
    let operation: Operation
    
    let inputShape: Shape?
    
    let outputShape: Shape?
    
    init(serviceName: String, operation: Operation, inputShape: Shape?, outputShape: Shape?) {
        self.serviceName = serviceName
        self.operation = operation
        self.inputShape = inputShape
        self.outputShape = outputShape
    }
    
    func generateSwiftFunctionCode() -> String {
        var code = ""
        
        if let shape = self.inputShape {
            code += "public func \(operation.name.toSwiftVariableCase())(_ input: \(shape.swiftTypeName))"
        } else {
            code += "public func \(operation.name.toSwiftVariableCase())()"
        }
        
        code += " throws"
        
        if let shape = self.outputShape {
            code += " -> \(shape.swiftTypeName)"
        }
        
        code += " {\n"
        
        if outputShape != nil {
            code += "\(indt(1))let (bodyData, urlResponse) = try request.invoke("
        } else {
            code += "\(indt(1))_ = try request.invoke("
        }
        
        code += "operation: \"\(operation.name)\", "
        code += "path: \"\(buildEndpointPathWithQueryString())\", "
        code += "httpMethod: \"\(operation.httpMethod)\", "
        code += "httpHeaders: \(buildHeaders()), "
        code += "input: \(self.inputShape == nil ? "nil": "input")"
        code += ")\n"
        
        if outputShape != nil {
            code += "\(indt(1))return try \(serviceName)ResponseBuilder(bodyData: bodyData, urlResponse: urlResponse).build()\n"
        }
        
        code += "}"
        
        return code
    }
    
    func buildHeaders() -> String {
        guard let shape = self.inputShape else {
            return "[:]"
        }
        
        var headers: [String: String] = [:]
        switch shape.type {
        case .structure(let members):
            for member in members {
                if let loc = member.location {
                    switch loc {
                    case .header(let replaceTo, let keyForHeader):
                        headers[replaceTo] = "input.\(keyForHeader.toSwiftVariableCase())"
                        
                    default:
                        break
                    }
                }
            }
        default:
            break
        }
        
        if headers.count == 0 {
            return "[:]"
        }
        
        var headerDictString = ""
        headerDictString += "["
        
        for e in headers.enumerated() {
            headerDictString += "\"\(e.element.key)\": \(e.element.value)"
            if e.offset != headers.count-1 {
                headerDictString += ", "
            }
        }
        headerDictString += "]"
        
        return headerDictString
    }
    
    func buildQueryString() -> String {
        guard let shape = self.inputShape else {
            return ""
        }
        
        var queryParams: [String: String] = [:]
        switch shape.type {
        case .structure(let members):
            for member in members {
                if let loc = member.location {
                    switch loc {
                    case .querystring(let replaceTo, let key):
                        if member.required {
                            queryParams[replaceTo] = "\\(input.\(key.toSwiftVariableCase()))"
                        } else {
                            queryParams[replaceTo] = "\\(input.\(key.toSwiftVariableCase())?.description ?? \"\")"
                        }
                        
                        
                    default:
                        break
                    }
                }
            }
        default:
            break
        }
        
        return queryParams.map({
            return "\($0.key)=\($0.value)"
        }).joined(separator: "&")
    }
    
    func buildEndpointPath() -> String {
        var path = operation.path
        guard let shape = self.inputShape else {
            return path
        }
        
        switch shape.type {
        case .structure(let members):
            for member in members {
                if let loc = member.location {
                    switch loc {
                    case .uri(let replaceToKey, let key):
                        let replaceTo = "input.\(key.toSwiftVariableCase())".toSwiftVariableCase()
                        path = path.replacingOccurrences(of: "{\(replaceToKey)}", with: "\\("+replaceTo+")")
                        
                    default:
                        break
                    }
                }
            }
        default:
            break
        }
        
        return path
    }
    
    func buildEndpointPathWithQueryString() -> String {
        let path = buildEndpointPath()
        let queryString = buildQueryString()
        if queryString.isEmpty {
            return path
        }
        
        let separator = path.contains("?") ? "&" : "?"
        
        return path+separator+queryString
    }
}


extension Shape {
    func generateSerializeFunctionCode() -> String? {
        switch type {
        case .structure(let members):
            var code = ""
            code += "public func serialize() throws -> [String: Any?] {\n"
            if members.count == 0 {
                code += indt(1)+"return [:]\n"
            } else {
                code += "\(indt(1))return [\n"
                for member in members {
                    let variableName = member.name.toSwiftVariableCase()
                    switch member.shape.type {
                        
                    case .list(let shape):
                        switch shape.type {
                        case .structure(_):
                            let optional = member.required ? "" : "?"
                            code += "\(indt(2))\"\(member.name)\": try self.\(variableName)\(optional).serialize(),\n"
                        default:
                            code += "\(indt(2))\"\(member.name)\": self.\(variableName),\n"
                        }
                        
                    case .structure(_):
                        let optional = member.required ? "" : "?"
                        code += "\(indt(2))\"\(member.name)\": try self.\(variableName)\(optional).serialize(),\n"
                    default:
                        code += "\(indt(2))\"\(member.name)\": self.\(variableName),\n"
                    }
                }
                code += "\(indt(1))]\n"
            }
            code += "}\n"
            
            return code
            
        default:
            return nil
        }
    }
}


extension Member {
    var defaultValue: String {
        if !required {
            return "nil"
        }
        
        switch shape.type {
        case .integer(_), .float(_), .double(_), .long(_):
            return "0"
        case .boolean:
            return "false"
        case .blob(_):
            return "Data()"
        case .timestamp:
            return "Date()"
        case .list(_):
            return "[]"
        case .map(_):
            return "[:]"
        case .structure(_):
            return "\(shape.name)()"
        default:
            return "\"\""
        }
    }
    
    func toSwiftMutableMemberSyntax() -> String {
        let optionalSuffix = required ? "" : "?"
        return "var \(name.toSwiftVariableCase()): \(swiftTypeName)\(optionalSuffix) = \(defaultValue)"
    }
    
    func toSwiftImmutableMemberSyntax() -> String {
        let optionalSuffix = required ? "" : "?"
        return "let \(name.toSwiftVariableCase()): \(swiftTypeName)\(optionalSuffix)"
    }
    
    func toSwiftArgumentSyntax() -> String {
        let optionalSuffix = required ? "" : "?"
        let defaultArgument = required ? "" : " = nil"
        return "\(name.toSwiftLabelCase()): \(swiftTypeName)\(optionalSuffix)\(defaultArgument)"
    }
}

extension AWSService {
    func generateResponseBuilderCode() -> String {
        var code = ""
        code += autoGeneratedHeader
        code += "import Foundation\n"
        code += "import Core"
        code += "\n\n"
        
        switch contentType {
        case .xml:
            code += "struct \(serviceName)ResponseBuilder<T: Initializable> {"
        case .json:
            code += "struct \(serviceName)ResponseBuilder<T: Initializable> {"
        }
        code += "\n"
        code += "\(indt(1))let bodyData: Data\n"
        code += "\(indt(1))let urlResponse: HTTPURLResponse\n\n"
        code += "\(indt(1))init(bodyData: Data, urlResponse: HTTPURLResponse) {\n"
        code += "\(indt(2))self.bodyData = bodyData\n"
        code += "\(indt(2))self.urlResponse = urlResponse\n"
        code += "\(indt(1))}\n\n"

        code += "\(indt(1))public func build() throws -> T {\n"
        switch contentType {
        case .xml:
            code += "\(indt(2))let xmlNodes = try XML2Parser(data: bodyData).parse()\n"
            code += "\(indt(2))let jsonString = XMLSerializer(nodes: xmlNodes).serializeToJSON()\n"
            code += "\(indt(2))guard let dictionary = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!, options: []) as? [String: Any] else { throw ResponseBuilderError.couldNotParseResponseJSON }\n"
            code += "\(indt(2))let errorDict = dictionary[\"Error\"] as? [String: Any]\n"
            code += "\(indt(2))let errorCode = errorDict?[\"Code\"] as? String ?? \"UnknownError\"\n"
            code += "\(indt(2))let message = errorDict?[\"Message\"] as? String\n"
        case .json:
            code += "\(indt(2))guard let dictionary = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any] else { throw ResponseBuilderError.couldNotParseResponseJSON }\n"
            code += "\(indt(2))let errorCode = dictionary[\"__type\"] as? String ?? \"UnknownError\"\n"
            code += "\(indt(2))let message = dictionary.filter({ $0.key.lowercased() == \"message\" }).first?.value as? String\n"
        }
        
        code += "\(indt(2))guard (200..<300).contains(urlResponse.statusCode) else {\n"
        code += "\(indt(3))if let error = \(serviceName)Error(errorCode: errorCode, message: message) {\n"
        code += "\(indt(4))throw error\n"
        code += "\(indt(3))}\n"
        
        code += "\(indt(3))if let error = AWSServerError(errorCode: errorCode, message: message) {\n"
        code += "\(indt(4))throw error\n"
        code += "\(indt(3))}\n"
        
        code += "\(indt(3))throw AWSClientError(errorCode: errorCode, message: message)\n"
        code += "\(indt(2))}\n"
        code += "\(indt(2))return try AWSSDKSwift.construct(dictionary: dictionary)\n"
        code += "\(indt(1))}\n"
        code += "}"
        
        return code
    }
    
    func generateErrorCode() -> String {
        var code = ""
        code += autoGeneratedHeader
        code += "\n\n"
        
        code += "/// Error enum for \(serviceName)\n"
        code += ""
        code += "public enum \(serviceName)Error: Error {\n"
        for name in errorShapeNames {
            code += "\(indt(1))case \(name.toSwiftVariableCase())(message: String?)\n"
        }
        code += "}"
        code += "\n\n"
        code += "extension \(serviceName)Error {\n"
        code += "\(indt(1))public init?(errorCode: String, message: String?){\n"
        code += "\(indt(2))switch errorCode {\n"
        for name in errorShapeNames {
            code += "\(indt(2))case \"\(name)\":\n"
            code += "\(indt(3))self = .\(name.toSwiftVariableCase())(message: message)\n"
        }
        code += "\(indt(2))default:\n"
        code += "\(indt(3))return nil\n"
        code += "\(indt(2))}\n"
        code += "\(indt(1))}\n"
        code += "}"
        return code
    }
    
    func generateServiceCode() -> String {
        var code = ""
        code += autoGeneratedHeader
        code += "import Foundation\n"
        code += "import Core\n\n"
        code += "/**\n"
        code += serviceDescription+"\n"
        code += "*/\n"
        code += "public "
        code += "struct \(serviceName) {\n\n"
        code += "\(indt(1))let request: AWSRequest\n\n"
        code += "\(indt(1))public init(accessKeyId: String? = nil, secretAccessKey: String? = nil, region: Core.Region? = nil, endpoint: String? = nil) {\n"
        code += "\(indt(2))self.request = AWSRequest(\n"
        code += "\(indt(3))accessKeyId: accessKeyId,\n"
        code += "\(indt(3))secretAccessKey: secretAccessKey,\n"
        code += "\(indt(3))region: region,\n"
        if let target = apiJSON["metadata"]["targetPrefix"].string {
            code += "\(indt(3))amzTarget: \"\(target)\",\n"
        }
        code += "\(indt(3))service: \"\(endpointPrefix)\",\n"
        code += "\(indt(3))endpoint: endpoint\n"
        code += indt(2)+")\n"
        code += "\(indt(1))}\n"
        code += "\n"
        for operation in operations {
            let inputShape = shapes.filter({ $0.name == operation.inputShapeName }).first
            
            let outputShape = shapes.filter({ $0.name == operation.outputShapeName }).first
            
            let builder = OperationBuilder(
                serviceName: serviceName,
                operation: operation,
                inputShape: inputShape,
                outputShape: outputShape
            )
            
            let functionCode = builder.generateSwiftFunctionCode()
                .components(separatedBy: "\n")
                .map({ indt(1)+$0 })
                .joined(separator: "\n")
            
            let comment = docJSON["operations"][operation.name].stringValue.tagStriped()
            
            code += "\(indt(1))///  \(comment)\n"
            code += functionCode
            code += "\n\n"
        }
        code += "\n"
        code += "}"
        
        return code
    }
    
    func generateShapesCode() -> String {
        var code = ""
        code += autoGeneratedHeader
        code += "import Foundation\n"
        code += "import Core\n\n"
        code += "extension \(serviceName) {\n\n"
        
        for shape in shapes {
            if errorShapeNames.contains(shape.name) { continue }
            if !shape.isNotSwiftDefinedType() { continue }
            
            switch shape.type {
            case .structure(let members):
                code += "\(indt(1))public struct \(shape.name): Serializable, Initializable"
                
                code += " {\n"
                for member in members {
                    if let comment = shapeDoc[shape.name]?[member.name], !comment.isEmpty {
                        code += "\(indt(2))/// \(comment)\n"
                    }
                    code += "\(indt(2))\(member.toSwiftMutableMemberSyntax())\n"
                }
                code += "\n"
                code += "\(indt(2))public init() {}\n\n"
                if members.count > 0 {
                    code += "\(indt(2))public init(\(members.toSwiftArgumentSyntax())) {\n"
                    for member in members {
                        code += "\(indt(3))self.\(member.name.toSwiftVariableCase()) = \(member.name.toSwiftVariableCase())\n"
                    }
                    code += "\(indt(2))}\n\n"
                }
                code += "\(indt(1))}"
                
                code += "\n\n"
                
            default:
                continue
            }
        }
        
        code += "}"
        
        return code
    }
}
