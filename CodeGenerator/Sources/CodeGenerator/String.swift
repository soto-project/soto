//
//  String.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/22.
//
//

import Foundation

let swiftReservedWords: Set<String> = [
    "as",
    "break",
    "case",
    "catch",
    "class",
    "continue",
    "default",
    "do",
    "else",
    "enum",
    "extension",
    "false",
    "for",
    "func",
    "if",
    "import",
    "in",
    "internal",
    "is",
    "nil",
    "operator",
    "private",
    "protocol",
    "public",
    "repeat",
    "return",
    "self",
    "static",
    "struct",
    "switch",
    "true",
    "try",
    "type",
    "where"
]

extension String {
    public func lowerFirst() -> String {
        return String(self[startIndex]).lowercased() + self[index(after: startIndex)...]
    }
    
    public func upperFirst() -> String {
        return String(self[self.startIndex]).uppercased() + self[index(after: startIndex)...]
    }
    
    public func toSwiftLabelCase() -> String {
        if allLetterIsUppercasedAlnum() {
            return self.lowercased()
        }
        return self.replacingOccurrences(of: "-", with: "_").camelCased()
    }
    
    public func reservedwordEscaped() -> String {
        if swiftReservedWords.contains(self.lowercased()) {
            return "`\(self)`"
        }
        return self
    }
    
    public func toSwiftVariableCase() -> String {
        return toSwiftLabelCase().reservedwordEscaped()
    }
    
    public func toSwiftClassCase() -> String {
        if self == "Type" {
            return "`\(self)`"
        }
        
        return self.replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: ".", with: "")
            .camelCased()
            .upperFirst()
    }
    
    public func camelCased(separator: String = "_") -> String {
        let items = self.components(separatedBy: separator)
        var camelCase = ""
        items.enumerated().forEach {
            camelCase += 0 == $0 ? $1 : $1.capitalized
        }
        return camelCase.lowerFirst()
    }
    
    private func allLetterIsUppercasedAlnum() -> Bool {
        for character in self {
            guard let ascii = character.unicodeScalars.first?.value else {
                return false
            }
            if !(0x30..<0x39).contains(ascii) && !(0x41..<0x5a).contains(ascii) {
                return false
            }
        }
        return true
    }
    
    public func tagStriped() -> String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }

    func allLetterIsNumeric() -> Bool {
        for character in self {
            if let ascii = character.unicodeScalars.first?.value, (0x30..<0x39).contains(ascii) {
                continue
            } else {
                return false
            }
        }
        return true
    }

    private static let backslashEncodeMap : [String.Element: String] = [
        "\"": "\\\"",
        "\\": "\\\\",
        "\n": "\\n",
        "\t": "\\t",
        "\r": "\\r"
    ]
    
    /// back slash encode special characters
    public func addingBackslashEncoding() -> String {
        var newString = ""
        for c in self {
            if let replacement = String.backslashEncodeMap[c] {
                newString.append(contentsOf:replacement)
            } else {
                newString.append(c)
            }
        }
        return newString
    }
    
}

