//
//  DictionarySerializer.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/06.
//
//

import Foundation

class DictionarySerializer {
    let dictionary: [String: Any]
    
    init(dictionary: [String: Any]){
        self.dictionary = dictionary
    }
    
    func serializeToXML(attributes: XMLAttribute = [:]) -> String {
        var xmlStr = ""
        //var parentKey: String?
        func _serialize(dictionary: [String: Any]) {
            for (key, value) in dictionary {
                let attrString = attributes.filter({ $0.key == key }).flatMap({ "\($0.value)" }).joined(separator: " ")
                switch value {
                case let v as [String: Any]:
                    xmlStr += "<\(key) \(attrString)>"
                    _serialize(dictionary: v)
                    xmlStr += "</\(key)>"
                    
                case let values as [Any]:
                    for v in values {
                        xmlStr += "<\(key) \(attrString)>\(v)<\(key)>"
                    }
                    
                default:
                    xmlStr += "<\(key) \(attrString)>"
                    xmlStr += "\(value)"
                    xmlStr += "</\(key)>"
                }
            }
        }
        
        _serialize(dictionary: dictionary)
        
        return xmlStr
    }
}
