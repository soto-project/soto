//
//  String.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/22.
//
//

import Foundation

let swiftReservedWords: [String] = [
    "protocol",
    "return",
    "operator",
    "class",
    "struct",
    "break",
    "continue",
    "extension",
    "self",
    "public",
    "private",
    "internal",
    "where",
    "catch",
    "try",
    "default",
    "case"
]

extension String {
    public func lowerFirst() -> String {
        return String(self[self.startIndex]).lowercased() + self.substring(from: self.index(after: self.startIndex))
    }
    
    public func upperFirst() -> String {
        return String(self[self.startIndex]).uppercased() + self.substring(from: self.index(after: self.startIndex))
    }
    
    public func toSwiftLabelCase() -> String {
        return self.replacingOccurrences(of: "-", with: "_").camelCased().lowerFirst()
    }
    
    public func toSwiftVariableCase() -> String {
        let variable = toSwiftLabelCase()
        if swiftReservedWords.contains(variable) {
            return "`\(variable)`"
        }
        return variable
    }
    
    public func toSwiftClassCase() -> String {
        return self.replacingOccurrences(of: "-", with: "_").replacingOccurrences(of: ".", with: "").camelCased().upperFirst()
    }
    
    public func camelCased() -> String {
        let items = self.components(separatedBy: "_")
        var camelCase = ""
        items.enumerated().forEach {
            camelCase += 0 == $0 ? $1 : $1.capitalized
        }
        return camelCase
    }
    
    public func tagStriped() -> String {
        return self.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}

