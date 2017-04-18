//
//  XMLNodeSerializer.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/07.
//
//

import Foundation

private func dquote(_ str: String) -> String {
    return "\"\(str)\""
}

public class XMLNodeSerializer {
    
    let node: XMLNode
    
    public init(node: XMLNode) {
        self.node = node
    }
    
    public func serializeToXML() -> String {
        var xmlStr = ""
        
        func _serialize(nodeTree: [XMLNode]) {
            for node in nodeTree {
                
                var attr = ""
                if !node.attributes.isEmpty {
                    attr = " " + node.buildAttributes()
                }
                
                if node.hasArrayValue() {
                    for value in node.values {
                        xmlStr += "<\(node.elementName)\(attr)>\(value)</\(node.elementName)>"
                    }
                }
                
                if node.hasSingleValue() {
                    xmlStr += "<\(node.elementName)\(attr)>\(node.values[0])</\(node.elementName)>"
                }
                
                if node.hasChildren() {
                    xmlStr += "<\(node.elementName)\(attr)>"
                    _serialize(nodeTree: node.children)
                    xmlStr += "</\(node.elementName)>"
                }
            }
        }
        
        _serialize(nodeTree: [node])
        
        return xmlStr
    }
    
    public func serializeToJSON() -> String {
        var jsonStr = ""
        jsonStr+="{"
        
        func _serialize(nodeTree: [XMLNode]) {
            for (index, node) in nodeTree.enumerated() {
                jsonStr += dquote(node.elementName) + ":"
                
                if node.hasArrayValue() {
                    jsonStr += "[" +  node.values.map({ dquote($0) }).joined(separator: ",") + "]"
                    if nodeTree.count-index > 1 { jsonStr+="," }
                }
                
                if node.hasSingleValue() {
                    jsonStr += dquote(node.values[0])
                    if nodeTree.count-index > 1 { jsonStr+="," }
                }
                
                if node.hasChildren() {
                    jsonStr += "{"
                    _serialize(nodeTree: node.children)
                    jsonStr += "}"
                    if nodeTree.count-1-index > 0 { jsonStr += "," }
                }
            }
        }
        
        _serialize(nodeTree: [node])
        
        jsonStr+="}"
        
        return jsonStr
    }
}
