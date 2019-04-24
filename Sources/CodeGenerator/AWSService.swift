//
//  AWSService.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/28.
//
//

import Foundation
import SwiftyJSON
import AWSSDKSwiftCore

enum AWSServiceError: Error {
    case eventStreamingCodeGenerationsAreUnsupported
}

struct AWSService {
    let apiJSON: JSON
    let docJSON: JSON
    let endpointJSON: JSON
    var shapes = [Shape]()
    var operations: [AWSSDKSwiftCore.Operation] = []
    var errorShapeNames = [String]()
    var shapeDoc: [String: [String: String]] = [:]

    var version: String {
        return apiJSON["metadata"]["apiVersion"].stringValue
    }

    var jsonVersion: ServiceProtocol.Version? {
        if let version = apiJSON["metadata"]["jsonVersion"].string {
            let componets = version.components(separatedBy: ".")
            return ServiceProtocol.Version(major: Int(componets[0])!, minor: Int(componets[1])!)
        }

        return nil
    }

    var serviceProtocol: ServiceProtocol {
        if let version = jsonVersion {
            return ServiceProtocol(name: apiJSON["metadata"]["protocol"].stringValue, version: version)
        }
        return ServiceProtocol(name: apiJSON["metadata"]["protocol"].stringValue)
    }

    var endpointPrefix: String {
        return apiJSON["metadata"]["endpointPrefix"].stringValue
    }

    var serviceName: String {
        return apiJSON["serviceName"].stringValue.toSwiftClassCase()
    }

    var serviceErrorName: String {
        return serviceName+"ErrorType"
    }

    var serviceDescription: String {
        return docJSON["service"].stringValue.tagStriped()
    }

    var endpoint: JSON {
        return endpointJSON["partitions"].arrayValue[0]["services"][endpointPrefix]
    }

    var serviceEndpoints: [String: String] {
        var endpointMap: [String: String] = [:]
        endpoint["endpoints"].dictionaryValue.forEach {
            if let hostname = $0.value["hostname"].string {
                endpointMap[$0.key] = hostname
            }
        }
        return endpointMap
    }

    var partitionEndpoint: String? {
        return endpoint.dictionaryValue["partitionEndpoint"]?.string
    }

    init(fromAPIJSON apiJSON: JSON, docJSON: JSON, endpointJSON: JSON) throws {
        self.apiJSON = apiJSON
        self.docJSON = docJSON
        self.endpointJSON = endpointJSON
        self.shapes = try parseShapes()
        (self.operations, self.errorShapeNames) = try parseOperation(shapes: shapes)
        self.shapeDoc = parseDoc()
    }

    private func shapeType(from json: JSON, level: Int = 0) throws -> ShapeType {
        // TODO 10 is unspecific number to break
        if level > 10 {
            return .unhandledType
        }

        if let isEventstream = json["eventstream"].bool, isEventstream {
            throw AWSServiceError.eventStreamingCodeGenerationsAreUnsupported
        }

        let type: ShapeType
        switch json["type"].stringValue {
        case "string":
            if let enumValues = json["enum"].arrayObject as? [String] {
                type = .enum(enumValues)
            } else {
                let max = json["max"].int
                let min = json["min"].int
                let pattern = json["pattern"].string
                type = .string(max: max, min: min, pattern: pattern)
            }

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
            if let locationName = json["member"]["locationName"].string {
                let _type = try shapeType(from: shapeJSON, level: level+1)
                let repeats = Shape(name: json["member"]["shape"].stringValue, type: _type)
                let shape = Shape(name: json["member"]["shape"].stringValue, type: .list(repeats))
                let member = Member(
                    name: locationName,
                    required: false,
                    shape: shape,
                    location: nil,
                    locationName: locationName,
                    xmlNamespace: nil,
                    isStreaming: false
                )
                type = .structure(StructureShape(members: [member], payload: nil))
            } else {
                let _type = try shapeType(from: shapeJSON, level: level+1)
                let shape = Shape(name: json["member"]["shape"].stringValue, type: _type)
                type = .list(shape)
            }

        case "structure":
            var structure: [String: ShapeType] = [:]
            for (_, _struct) in json["members"].dictionaryValue {
                let shapeJSON = apiJSON["shapes"][_struct["shape"].stringValue]
                structure[_struct["shape"].stringValue] = try shapeType(from: shapeJSON, level: level+1)
            }

            let members: [Member] = try json["members"].dictionaryValue.map { name, memberJSON in
                let memberDict = try JSONSerialization.jsonObject(with: memberJSON.rawData(), options: []) as? [String: Any] ?? [:]
                let shapeName = memberJSON["shape"].stringValue
                let requireds = json["required"].arrayValue.map({ $0.stringValue })
                let dict = structure.filter({ $0.key == shapeName }).first!
                let shape = Shape(name: dict.key, type: dict.value)
                return Member(
                    name: name,
                    required: requireds.contains(name),
                    shape: shape,
                    location: Location(key: name, json: memberJSON),
                    locationName: memberJSON["locationName"].string,
                    xmlNamespace: XMLNamespace(dictionary: memberDict),
                    isStreaming: memberJSON["streaming"].bool ?? false
                )
            }.sorted{ $0.name < $1.name }

            let shape = StructureShape(members: members, payload: json["payload"].string)
            type = .structure(shape)

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

    private mutating func parseDoc() -> [String: [String: String]] {
        var shapeDoc: [String: [String: String]] = [:]
        for (_, json) in docJSON["shapes"].dictionaryValue {
            for (key, comment) in json["refs"].dictionaryValue  {
                let separeted = key.components(separatedBy: "$")
                guard separeted.count >= 2 else { continue }
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
        return shapeDoc
    }

    var autoGeneratedHeader: String {
        var code = ""
        code += AUTO_GENERATE_TEXT
        code += "\n\n"
        return code
    }

    private func parseShapes() throws -> [Shape] {
        var shapes = [Shape]()
        for (key, json) in apiJSON["shapes"].dictionaryValue {
            do {
                let shape = try Shape(name: key, type: shapeType(from: json))
                shapes.append(shape)
            } catch AWSServiceError.eventStreamingCodeGenerationsAreUnsupported {
                // Skip to generate code.
                // Becase eventstream is outside the scope of existing code generation rules.
                // It should be implemented manually.
            } catch {
                throw error
            }
        }
        return shapes.sorted{ $0.name < $1.name }
    }

    private func parseOperation(shapes: [Shape]) throws -> ([AWSSDKSwiftCore.Operation], [String])  {
        var operations: [AWSSDKSwiftCore.Operation] = []
        var errorShapeNames: [String] = []
        for (_, json) in apiJSON["operations"].dictionaryValue {
            for json in json["errors"].arrayValue {
                let shape = json["shape"].stringValue
                if !errorShapeNames.contains(shape) {
                    errorShapeNames.append(shape)
                }
            }

            var inputShape: Shape?
            if let inputShapeName = json["input"]["shape"].string {
                if let index = shapes.index(where: { inputShapeName == $0.name }) {
                    inputShape = shapes[index]
                }
            }

            var outputShape: Shape?
            if let outputShapeName = json["output"]["shape"].string {
                if let index = shapes.index(where: { outputShapeName == $0.name }) {
                    outputShape = shapes[index]
                }
            }

            let operation = AWSSDKSwiftCore.Operation(
                name: json["name"].stringValue,
                httpMethod: json["http"]["method"].stringValue,
                path: json["http"]["requestUri"].stringValue,
                inputShape: inputShape,
                outputShape: outputShape
            )

            operations.append(operation)
        }

        return (operations.sorted { $0.name < $1.name }, errorShapeNames.sorted { $0 < $1 })
    }
}
