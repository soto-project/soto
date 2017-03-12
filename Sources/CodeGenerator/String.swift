//
//  String.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/22.
//
//

import Foundation

extension String {
    func lowerFirst() -> String {
        return String(self[self.startIndex]).lowercased() + self.substring(from: self.index(after: self.startIndex))
    }
    
    func upperFirst() -> String {
        return String(self[self.startIndex]).uppercased() + self.substring(from: self.index(after: self.startIndex))
    }
    
    func toSwiftLabelCase() -> String {
        return self.replacingOccurrences(of: "-", with: "_").camelCased().lowerFirst()
    }
    
    func toSwiftVariableCase() -> String {
        let variable = toSwiftLabelCase()
        if swiftReservedWords.contains(variable) {
            return "`\(variable)`"
        }
        return variable
    }
    
    func toSwiftClassCase() -> String {
        return self.replacingOccurrences(of: "-", with: "_").replacingOccurrences(of: ".", with: "").camelCased().upperFirst()
    }
    
    func camelCased() -> String {
        let items = self.components(separatedBy: "_")
        var camelCase = ""
        items.enumerated().forEach {
            camelCase += 0 == $0 ? $1 : $1.capitalized
        }
        return camelCase
    }
    
    func tagStriped() -> String {
        return self.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}

