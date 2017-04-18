//
//  XMLNode.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/07.
//
//

public class XMLNode {
    var elementName: String
    var attributes: [String: String] = [:]
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
    
    public init(elementName: String) {
        self.elementName = elementName
    }
    
    public func buildAttributes() -> String {
        return attributes.map({ "\($0.key)=\"\($0.value)\"" }).joined(separator: " ")
    }
    
}
