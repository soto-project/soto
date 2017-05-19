//
//  XMLConvertible.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/05/20.
//
//

import Foundation

public typealias XMLAttribute = [String: [String: String]] // ["elementName": ["key": "value", ...]]

public protocol XMLNodeSerializable {}

extension XMLNodeSerializable {
    public func serializeToXMLNode(attributes: XMLAttribute = [:]) throws -> XMLNode {
        let mirror = Mirror.init(reflecting: self)
        let name = "\(mirror.subjectType)"
        let xmlNode = XMLNode(elementName: name.upperFirst())
        if let attr = attributes.filter({ $0.key == name }).first {
            xmlNode.attributes = attr.value
        }
        
        for el in mirror.children {
            guard let label = el.label?.upperFirst() else {
                continue
            }
            
            guard let value = unwrap(any: el.value) else {
                continue
            }
            let node = XMLNode(elementName: label)
            switch value {
            case let v as XMLNodeSerializable:
                let cNode = try v.serializeToXMLNode()
                node.children.append(contentsOf: cNode.children)
                
            case let v as [XMLNodeSerializable]:
                for vv in v {
                    let cNode = try vv.serializeToXMLNode()
                    node.children.append(contentsOf: cNode.children)
                }
                
            default:
                switch value {
                case let v as [Any]:
                    for vv in v {
                        node.values.append("\(vv)")
                    }
                    
                case let v as [AnyHashable: Any]:
                    for (key, value) in v {
                        let cNode = XMLNode(elementName: "\(key)")
                        cNode.values.append("\(value)")
                        node.children.append(cNode)
                    }
                default:
                    node.values.append("\(value)")
                }
            }
            
            xmlNode.children.append(node)
        }
        
        return xmlNode
    }
}
