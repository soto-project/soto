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
    struct WaiterContext {
        let waiterName: String
        let operation: OperationContext
        let inputKey: String?
        let acceptors: [AcceptorContext]
        let minDelayTime: Int?
        let maxDelayTime: Int?
    }

    struct AcceptorContext {
        let state: String
        let matcher: MatcherContext
    }

    enum MatcherContext {
        case jmesPath(path: String, expected: String)
        case jmesAnyPath(path: String, expected: String)
        case jmesAllPath(path: String, expected: String)
        case error(String)
        case errorStatus(Int)
        case success(Int) // Success requires a dummy associated value, so a mustache context is created for the `MatcherContext`
    }

    func generateWaiterContext() throws -> [String: Any] {
        guard let waitersDictionary = self.waiters?.waiters else { return [:] }
        let waiters = waitersDictionary.map { return (key: $0.key, value: $0.value) }.sorted { $0.key < $1.key }
        var context: [String: Any] = [:]
        context["name"] = self.api.serviceName

        var waiterContexts: [WaiterContext] = []

        for waiter in waiters {
            // Get related operation and its input and output shapes
            guard let operation = api.operations[waiter.value.operation],
                  let inputShape = try operation.input.map({ try api.getShape(named: $0.shapeName) }),
                  let outputShape = try operation.output.map({ try api.getShape(named: $0.shapeName) })
            else {
                continue
            }

            var acceptorContexts: [AcceptorContext] = []
            for acceptor in waiter.value.acceptors {
                if let context = try self.generateAcceptorContext(outputShape, acceptor: acceptor) {
                    acceptorContexts.append(context)
                }
            }
            // only add waiters if all the acceptors were generated
            if acceptorContexts.count != waiter.value.acceptors.count {
                continue
            }
            waiterContexts.append(
                WaiterContext(
                    waiterName: waiter.key,
                    operation: self.generateOperationContext(operation, name: waiter.value.operation, streaming: false),
                    inputKey: inputShape.name,
                    acceptors: acceptorContexts,
                    minDelayTime: waiter.value.delay,
                    maxDelayTime: nil
                )
            )
        }

        context["waiters"] = waiterContexts
        return context
    }

    func generateAcceptorContext(_ shape: Shape, acceptor: Waiters.Waiter.Acceptor) throws -> AcceptorContext? {
        switch acceptor.matcher {
        case .error(let error):
            return .init(state: acceptor.state.rawValue, matcher: .error(error))

        case .status(let value):
            if (200..<300).contains(value) {
                return .init(state: acceptor.state.rawValue, matcher: .success(value))
            } else {
                return .init(state: acceptor.state.rawValue, matcher: .errorStatus(value))
            }

        case .path(let argument, let expected):
            let expected = try generateExpectedValue(expected: expected)
            let path = self.generatePathArgument(argument: argument)
            return .init(state: acceptor.state.rawValue, matcher: .jmesPath(path: path, expected: expected))

        case .anyPath(let argument, let expected):
            let expected = try generateExpectedValue(expected: expected)
            let path = self.generatePathArgument(argument: argument)
            return .init(state: acceptor.state.rawValue, matcher: .jmesAnyPath(path: path, expected: expected))

        case .allPath(let argument, let expected):
            let expected = try generateExpectedValue(expected: expected)
            let path = self.generatePathArgument(argument: argument)
            return .init(state: acceptor.state.rawValue, matcher: .jmesAllPath(path: path, expected: expected))
        }
    }

    /// Parse JMESPath to make it work with Soto structs instead of the output JSON
    /// Basically convert all fields into format used for variables - ie lowercase first character
    func generatePathArgument(argument: String) -> String {
        // a field is any series of letters that doesn't end with a `(`
        var output: String = ""
        var index = argument.startIndex
        var fieldStartIndex: String.Index?
        while index != argument.endIndex {
            if argument[index].isLetter {
                if fieldStartIndex == nil {
                    fieldStartIndex = index
                }
            } else {
                if let startIndex = fieldStartIndex {
                    fieldStartIndex = nil
                    if argument[index] != "(" {
                        output += String(argument[startIndex...index]).toSwiftLabelCase()
                    } else {
                        output += argument[startIndex...index]
                    }
                } else {
                    output.append(argument[index])
                }
            }
            index = argument.index(after: index)
        }
        if let startIndex = fieldStartIndex {
            output += argument[startIndex].lowercased()
            output += argument[argument.index(after: startIndex)...]
        }
        return output
    }

    func generateExpectedValue(expected: Waiters.Waiter.MatcherValue) throws -> String {
        switch expected {
        case .string(let string):
            return "\"\(string)\""
        case .integer(let integer):
            return String(describing: integer)
        case .bool(let boolean):
            return String(describing: boolean)
        }
    }
}
