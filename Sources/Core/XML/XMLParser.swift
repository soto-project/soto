//
//  XMLParser.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/04.
//
//

import Foundation

public enum XML2ParserError: Error {
    case unknownError
}

public class XML2Parser: NSObject, XMLParserDelegate {
    
    private let parser: XMLParser
    
    private var error: Error?
    
    private var nodeTree: XMLNode?
    
    private var currentNode: XMLNode?
    
    private var lastElementName: String?
    
    public init(data: Data) {
        self.parser = XMLParser(data: data)
        super.init()
        self.parser.delegate = self
    }
    
    public func parse() throws -> XMLNode {
        _ = parser.parse()
        if let nodeTree = nodeTree {
            return nodeTree
        }
        throw XML2ParserError.unknownError
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        let string = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !string.isEmpty && string != "\"" {
            currentNode?.values.append(string)
        }
    }
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        let elementName = elementName.upperFirst()
        let node = XMLNode(elementName: elementName)
        node.attributes = attributeDict
        
        if nodeTree == nil {
            nodeTree = node
        } else {
            // array value
            if lastElementName == elementName {
                if let arrayNode = currentNode?.children.filter({ $0.elementName.lowercased() == elementName.lowercased() }).first {
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
    
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.error = parseError
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let currentElementName = currentNode?.elementName, currentElementName.lowercased() == elementName.lowercased() {
            if currentNode?.children.count == 0, currentNode?.values.count == 0 {
                currentNode?.values.append("null")
            }
            currentNode = currentNode?.parent
        }
    }
}
