////
////  Service.swift
////  AWSSDKSwift
////
////  Created by Yuki Takei on 2017/04/11.
////
////
//
//import Foundation
//import SwiftyJSON
//
//func rootPath() -> String {
//    return #file.characters
//        .split(separator: "/", omittingEmptySubsequences: false)
//        .dropLast(4)
//        .map { String($0) }
//        .joined(separator: "/")
//}
//
//private func _apiPathMap() -> [String: String] {
//    let directories = Glob.entries(pattern: "\(rootPath())/models/apis/**")
//    var map: [String: String] = [:]
//    directories.forEach({
//        let entries = Glob.entries(pattern: $0+"/**/api-*.json")
//        let entry = entries[entries.count-1]
//        let paths = entry.components(separatedBy: "/")
//        let serviceName = paths[paths.count-3]
//        map[serviceName] = entry
//    })
//    
//    return map
//}
//
//private let apiPathMap = _apiPathMap()
//
////    return try apiPaths.map {
////        let data = try Data(contentsOf: URL(string: "file://\($0)")!)
////        return JSON(data: data)
////    }
//
//public struct AWSServiceAPI {
//    public static var shared: AWSServiceAPI = AWSServiceAPI()
//    
////    public static var shared: AWSServiceAPI {
////        if _shared == nil {
////            do {
////                _shared = try AWSServiceAPI()
////            } catch {
////                fatalError("\(error)")
////            }
////        }
////        return _shared!
////    }
//    
//    var services: [String: [String: Operation]] = [:]
//    
//    init() {
////        var services: [String: [String: Operation]] = [:]
////        let apis = try loadAPIJSONList()
////        for api in apis {
////            let endpointPrefix = api["metadata"]["endpointPrefix"].stringValue
////            var operationMap: [String: Operation] = [:]
////            let parser = try APIParser(apiJSON: api)
////            let operations = parser.parseOperations()
////            let shapes = try parser.parseShapes()
////            
////            for op in operations {
////                var inputShape: Shape?
////                var outputShape: Shape?
////                if let inputShapeName = op.inputShapeName {
////                    if let index = shapes.index(where: { inputShapeName == $0.name }) {
////                        inputShape = shapes[index]
////                    }
////                }
////                if let outputShapeName = op.outputShapeName {
////                    if let index = shapes.index(where: { outputShapeName == $0.name }) {
////                        outputShape = shapes[index]
////                    }
////                }
////                operationMap[op.name] = Operation(operation: op, inputShape: inputShape, outputShape: outputShape)
////            }
////            services[endpointPrefix] = operationMap
////        }
////        self.services = services
//    }
//    
//    public mutating func getOperation(serviceName: String, operationName: String) -> Operation? {
//        if let service = services[serviceName] {
//            return service[operationName]
//        } else {
//            services[serviceName] = [:]
//        }
//        
//        do {
//            let data = try Data(contentsOf: URL(string: "file://\(apiPathMap[serviceName]!)")!)
//            let json = JSON(data: data)
//        } catch {
//            return nil
//        }
//        return nil
//    }
//}
//
//struct APIParser {
//    let apiJSON: JSON
//    
//    public init(apiJSON: JSON) throws {
//        self.apiJSON = apiJSON
//    }
//    
//    private func shapeType(from json: JSON, level: Int = 0) throws -> ShapeType {
//        // TODO 10 is unspecific number to break
//        if level > 10 {
//            return .unhandledType
//        }
//        
//        let type: ShapeType
//        switch json["type"].stringValue {
//        case "string":
//            let max = json["max"].int
//            let min = json["min"].int
//            let pattern = json["pattern"].string
//            type = .string(max: max, min: min, pattern: pattern)
//            
//        case "integer":
//            let max = json["max"].int
//            let min = json["min"].int
//            type = .integer(max: max, min: min)
//            
//        case "blob":
//            let max = json["max"].int
//            let min = json["min"].int
//            type = .blob(max: max, min: min)
//            
//            
//        case "list":
//            let shapeJSON = apiJSON["shapes"][json["member"]["shape"].stringValue]
//            let _type = try shapeType(from: shapeJSON, level: level+1)
//            let shape = Shape(name: json["member"]["shape"].stringValue, type: _type)
//            type = .list(shape)
//            
//        case "structure":
//            var structure: [String: ShapeType] = [:]
//            for (_, _struct) in json["members"].dictionaryValue {
//                let shapeJSON = apiJSON["shapes"][_struct["shape"].stringValue]
//                structure[_struct["shape"].stringValue] = try shapeType(from: shapeJSON, level: level+1)
//            }
//            
//            let members: [Member] = json["members"].dictionaryValue.map { name, memberJSON in
//                let shapeName = memberJSON["shape"].stringValue
//                let requireds = json["required"].arrayValue.map({ $0.stringValue })
//                let dict = structure.filter({ $0.key == shapeName }).first!
//                let shape = Shape(name: dict.key, type: dict.value)
//                return Member(
//                    name: name,
//                    required: requireds.contains(name),
//                    shape: shape,
//                    location: Location(key: name, json: memberJSON),
//                    xmlNamespace: XMLNamespace(json: memberJSON),
//                    isStreaming: memberJSON["streaming"].bool ?? false
//                )
//            }
//            
//            let shape = StructureShape(members: members, payload: json["payload"].string)
//            type = .structure(shape)
//            
//        case "map":
//            let keyType = try shapeType(from: apiJSON["shapes"][json["key"]["shape"].stringValue], level: level+1)
//            let keyShape = Shape(name: json["key"]["shape"].stringValue, type: keyType)
//            
//            let valueType = try shapeType(from: apiJSON["shapes"][json["value"]["shape"].stringValue], level: level+1)
//            let valueShape = Shape(name: json["value"]["shape"].stringValue, type: valueType)
//            
//            type = .map(key: keyShape, value: valueShape)
//            
//        case "long":
//            let max = json["max"].int
//            let min = json["min"].int
//            type = .long(max: max, min: min)
//            
//        case "double":
//            let max = json["max"].int
//            let min = json["min"].int
//            type = .double(max: max, min: min)
//            
//        case "float":
//            let max = json["max"].int
//            let min = json["min"].int
//            type = .float(max: max, min: min)
//            
//        case "timestamp":
//            type = .timestamp
//            
//        case "boolean":
//            type = .boolean
//            
//        default:
//            throw ShapeTypeError.unsupported(json["type"].stringValue)
//        }
//        
//        return type
//    }
//    
//    public func parseOperations() -> [OperationDefinition] {
//        var operations = [OperationDefinition]()
//        for (_, json) in apiJSON["operations"].dictionaryValue {
//            let operation = OperationDefinition(
//                name: json["name"].stringValue,
//                httpMethod: json["http"]["method"].stringValue,
//                path: json["http"]["requestUri"].stringValue,
//                inputShapeName: json["input"]["shape"].string,
//                outputShapeName: json["output"]["shape"].string
//            )
//            operations.append(operation)
//        }
//        return operations
//    }
//    
//    public func parseShapes() throws -> [Shape] {
//        var shapes = [Shape]()
//        for (key, json) in apiJSON["shapes"].dictionaryValue {
//            let shape = try Shape(name: key, type: shapeType(from: json))
//            shapes.append(shape)
//        }
//        return shapes
//    }
//}
//
//
