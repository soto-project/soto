//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2021 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation

extension AWSService {
    /// convert paginator/waiter JMESPath to KeyPath
    func toKeyPath(token: String, shape: Shape, type: Shape.ShapeType.StructureType) throws -> (keyPath: String, shape: Shape) {
        var type = type
        var shape = shape
        let split = token.split(separator: ".")
        var keyPathSplit: [Substring] = []
        for i in 0..<split.count {
            var result = split[i]
            var addition: String?
            // if string contains [-1] replace with '.last'.
            if let negativeIndexRange = result.range(of: "[-1]") {
                result.removeSubrange(negativeIndexRange)
                // if a member is mentioned after the '[-1]' then you need to add a ? to the keyPath
                if split.count > i + 1 {
                    addition = "last?"
                } else {
                    addition = "last"
                }
            }
            let resultWithoutBrackets = result
            // if output token is member of an optional struct add ? suffix
            // ie token isn't in required array
            if type.required.first(where: { $0 == String(result) }) == nil,
               split.count > i + 1
            {
                result += "?"
            }

            keyPathSplit.append(result)
            if let addition = addition {
                keyPathSplit.append(addition[...])
            }

            // ensure member exists
            guard let member = type.members[String(resultWithoutBrackets)] else {
                throw Error.illegalJMESPath
            }

            shape = member.shape
            if i < split.count - 1 {
                if case .list(let listType) = shape.type {
                    shape = listType.member.shape
                }
                if case .structure(let newType) = shape.type {
                    type = newType
                } else {
                    // if member is neither a structure or array we can't process it
                    throw Error.illegalJMESPath
                }
            }
        }
        let keyPath = keyPathSplit.map { String($0).toSwiftVariableCase() }.joined(separator: ".")
        return (keyPath: keyPath, shape: shape)
    }
}
