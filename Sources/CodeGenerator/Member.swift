//
//  Member.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/29.
//
//

import Foundation

struct Member {
    let name: String
    let required: Bool
    let shape: Shape
    let location: Location?
}

extension Member {
    var swiftTypeName: String {
        return shape.swiftTypeName
    }
}

extension Collection where Iterator.Element == Member {
    func toSwiftArgumentSyntax() -> String {
        return self.map({ $0.toSwiftArgumentSyntax() }).joined(separator: ", ")
    }
}
