//
//  AWSService.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/28.
//
//

import Foundation
import SwiftyJSON

struct AWSService {
    enum ContentType {
        case xml
        case json
    }
    
    let apiJSON: JSON
    let docJSON: JSON
    var shapes = [Shape]()
    var operations = [Operation]()
    var errorShapeNames = [String]()
    var shapeDoc: [String: [String: String]] = [:]
    
    var contentType: ContentType {
        if endpointPrefix == "s3" {
            return .xml
        }
        
        return .json
    }
    
    var endpointPrefix: String {
        return apiJSON["metadata"]["endpointPrefix"].stringValue
    }
    
    var serviceName: String {
        return endpointPrefix.toSwiftClassCase()
    }
    
    var serviceDescription: String {
        return docJSON["service"].stringValue.tagStriped()
    }
    
    init(fromAPIJSON apiJSON: JSON, docJSON: JSON) throws {
        self.apiJSON = apiJSON
        self.docJSON = docJSON
        self.parseOperation()
        try self.parseShapes()
        parseDoc()
    }
    
    private func shapeType(from json: JSON, level: Int = 0) throws -> ShapeType {
        // TODO 10 is unspecific number to break
        if level > 10 {
            return .unhandledType
        }
        
        let type: ShapeType
        switch json["type"].stringValue {
        case "string":
            let max = json["max"].int
            let min = json["min"].int
            let pattern = json["pattern"].string
            type = .string(max: max, min: min, pattern: pattern)
            
        case "integer":
            let max = json["max"].int
            let min = json["min"].int
            type = .integer(max: max, min: min)
            
        case "blob":
            let max = json["max"].int
            let min = json["min"].int
            type = .blob(max: max, min: min)
            
            
        case "list":
            let shapeJSON = apiJSON["shapes"][json["member"]["shape"].stringValue]
            let _type = try shapeType(from: shapeJSON, level: level+1)
            let shape = Shape(name: json["member"]["shape"].stringValue, type: _type)
            type = .list(shape)
            
        case "structure":
            var structure: [String: ShapeType] = [:]
            for (_, _struct) in json["members"].dictionaryValue {
                let shapeJSON = apiJSON["shapes"][_struct["shape"].stringValue]
                structure[_struct["shape"].stringValue] = try shapeType(from: shapeJSON, level: level+1)
            }
            
            let members: [Member] = json["members"].dictionaryValue.map { name, memberJSON in
                let shapeName = memberJSON["shape"].stringValue
                let requireds = json["required"].arrayValue.map({ $0.stringValue })
                let dict = structure.filter({ $0.key == shapeName }).first!
                let shape = Shape(name: dict.key, type: dict.value)
                return Member(
                    name: name,
                    required: requireds.contains(name),
                    shape: shape,
                    location: Location(key: name, json: memberJSON)
                )
            }
            
            type = .structure(members)
            
        case "map":
            let keyType = try shapeType(from: apiJSON["shapes"][json["key"]["shape"].stringValue], level: level+1)
            let keyShape = Shape(name: json["key"]["shape"].stringValue, type: keyType)
            
            let valueType = try shapeType(from: apiJSON["shapes"][json["value"]["shape"].stringValue], level: level+1)
            let valueShape = Shape(name: json["value"]["shape"].stringValue, type: valueType)
            
            type = .map(key: keyShape, value: valueShape)
            
        case "long":
            let max = json["max"].int
            let min = json["min"].int
            type = .long(max: max, min: min)
            
        case "double":
            let max = json["max"].int
            let min = json["min"].int
            type = .double(max: max, min: min)
            
        case "float":
            let max = json["max"].int
            let min = json["min"].int
            type = .float(max: max, min: min)
            
        case "timestamp":
            type = .timestamp
            
        case "boolean":
            type = .boolean
            
        default:
            throw ShapeTypeError.unsupported(json["type"].stringValue)
        }
        
        return type
    }
    
    private mutating func parseDoc() {
        for (_, json) in docJSON["shapes"].dictionaryValue {
            for (key, comment) in json["refs"].dictionaryValue  {
                let separeted = key.components(separatedBy: "$")
                let shape = separeted[0]
                let member = separeted[1]
                if shapeDoc[shape] == nil {
                    shapeDoc[shape] = [:]
                }
                var _doc = shapeDoc[shape]
                _doc?[member] = comment.stringValue.tagStriped()
                shapeDoc[shape] = _doc
            }
        }
    }
    
    var autoGeneratedHeader: String {
        var code = ""
        code += AUTO_GENERATE_TEXT
        code += "\n"
        code += LICENSE_TEXT
        code += "\n\n"
        return code
    }
    
    private mutating func parseOperation() {
        for (_, json) in apiJSON["operations"].dictionaryValue {
            for json in json["errors"].arrayValue {
                let shape = json["shape"].stringValue
                if !errorShapeNames.contains(shape) {
                    errorShapeNames.append(shape)
                }
            }
            
            let operation = Operation(
                name: json["name"].stringValue,
                httpMethod: json["http"]["method"].stringValue,
                path: json["http"]["requestUri"].stringValue,
                inputShapeName: json["input"]["shape"].string,
                outputShapeName: json["output"]["shape"].string
            )
            self.operations.append(operation)
        }
    }
    
    private mutating func parseShapes() throws {
        for (key, json) in apiJSON["shapes"].dictionaryValue {
            let shape = try Shape(name: key, type: shapeType(from: json))
            shapes.append(shape)
        }
    }
}
