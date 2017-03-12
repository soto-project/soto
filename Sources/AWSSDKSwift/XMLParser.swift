//
//  XMLParser.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/04.
//
//

import Foundation


class XMLNode {
    var elementName: String
    var values = [String]()
    var parent: XMLNode? = nil
    var children = [XMLNode]()
    
    func isElement() -> Bool {
        return values.count == 0
    }
    
    func hasSingleValue() -> Bool {
        return values.count == 1
    }
    
    func hasArrayValue() -> Bool {
        return values.count > 1
    }
    
    func hasChildren() -> Bool {
        return children.count > 0
    }
    
    init(elementName: String) {
        self.elementName = elementName
    }
}

class XML2Parser: NSObject, XMLParserDelegate {
    
    private let parser: XMLParser
    
    private var error: Error?
    
    private var nodeTree = [XMLNode]()
    
    private var currentNode: XMLNode?
    
    private var lastElementName: String?
    
    init(data: Data) {
        self.parser = XMLParser(data: data)
        super.init()
        self.parser.delegate = self
    }
    
    func parse() throws -> [XMLNode] {
        parser.parse()
//        if let error = self.error {
//            throw error
//        }
        return nodeTree
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let string = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !string.isEmpty {
            currentNode?.values.append(string)
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        let node = XMLNode(elementName: elementName)
        
        if nodeTree.count == 0{
            nodeTree.append(node)
        } else {
            // array value
            if lastElementName == elementName {
                if let arrayNode = currentNode?.children.filter({ $0.elementName == elementName }).first {
                    currentNode = arrayNode
                    return
                }
            }
            
            node.parent = currentNode
            currentNode?.children.append(node)
        }
        
        lastElementName = elementName
        currentNode = node
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.error = parseError
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let currentElementName = currentNode?.elementName, currentElementName == elementName {
            currentNode = currentNode?.parent
        }
    }
}


class XMLSerializer {
    
    let nodes: [XMLNode]
    
    init(nodes: [XMLNode]) {
        self.nodes = nodes
    }
    
    func dquote(_ str: String) -> String {
        return "\"\(str)\""
    }
    
    func serializeToJSON() -> String {
        var jsonStr = ""
        jsonStr+="{"
        
        func stringify(nodeTree: [XMLNode]) {
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
                    stringify(nodeTree: node.children)
                    jsonStr += "}"
                    if nodeTree.count-1-index > 0 { jsonStr += "," }
                }
            }
        }
        
        stringify(nodeTree: nodes)
        
        jsonStr+="}"
        
        return jsonStr
    }
}
