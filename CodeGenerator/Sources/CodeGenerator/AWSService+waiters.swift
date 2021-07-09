//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2020 the Soto project authors
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
        case path(path: String, expected: String)
        case anyPath(arrayPath: String, elementPath: String, expected: String)
        case allPath(arrayPath: String, elementPath: String, expected: String)
        case jmesPath(path: String, expected: String)
        case jmesAnyPath(path: String, expected: String)
        case jmesAllPath(path: String, expected: String)
        case error(String)
        case errorStatus(Int)
        case success(Int) // success requires a associated value, so a mustache context is created for the value
    }

    func generateWaiterContext() throws -> [String: Any] {
        guard let waitersDictionary = self.waiters?.waiters else { return [:] }
        let waiters = waitersDictionary.map { return (key: $0.key, value: $0.value) }.sorted { $0.key < $1.key }
        var context: [String: Any] = [:]
        context["name"] = self.api.serviceName

        var waiterContexts: [WaiterContext] = []

        for waiter in waiters {
            // get related operation and its input and output shapes
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
            let path = generatePathArgument(argument: argument)
            return .init(state: acceptor.state.rawValue, matcher: .jmesPath(path: path, expected: expected))

        case .anyPath(let argument, let expected):
            let expected = try generateExpectedValue(expected: expected)
            let path = generatePathArgument(argument: argument)
            return .init(state: acceptor.state.rawValue, matcher: .jmesAnyPath(path: path, expected: expected))

        case .allPath(let argument, let expected):
            let expected = try generateExpectedValue(expected: expected)
            let path = generatePathArgument(argument: argument)
            return .init(state: acceptor.state.rawValue, matcher: .jmesAllPath(path: path, expected: expected))
        }
    }

    /// parse JMESPath to make it work with Soto structs instead of the output JSON
    /// Basically convert all fields into format used for variables. ie lowercase first character
    func generatePathArgument(argument: String) -> String {
        // a field is any series of letters that don't end with a (
        var output: String = ""
        var index = argument.startIndex
        var fieldStartIndex: String.Index? = nil
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

    func generateAnyAllPathContext(
        _ shape: Shape,
        argument: String,
        expected: Waiters.Waiter.MatcherValue
    ) throws -> (path: String, elementPath: String, expected: String)? {
        guard case .structure(let structure) = shape.type else { throw Error.matcherInvalidType }
        // split path by "[].". We should get two components
        let arrayComponents = argument.components(separatedBy: "[].")
        if arrayComponents.count == 2 {
            // get array keypath and shape
            let arrayPath = try toKeyPath(token: arrayComponents[0], shape: shape, type: structure)
            // shape should be a list, element should be structure
            guard case .list(let listType) = arrayPath.shape.type else { throw Error.matcherInvalidType }
            let elementShape: Shape = listType.member.shape
            guard case .structure(let elementType) = elementShape.type else { throw Error.matcherInvalidType }
            let elementPath = try toKeyPath(token: arrayComponents[1], shape: elementShape, type: elementType)
            let value: String
            switch expected {
            case .string(let string):
                // assume is enum
                if case .enum = elementPath.shape.type {
                    let enumContext = generateEnumMemberContext(string, shapeName: "")
                    value = ".\(enumContext.case)"
                } else if case .string = elementPath.shape.type {
                    value = "\"string\""
                } else {
                    throw Error.matcherInvalidType
                }
            case .integer(let integer):
                value = String(describing: integer)
            case .bool(let boolean):
                value = String(describing: boolean)
            }
            return (path: arrayPath.keyPath, elementPath: "\(elementShape.name!).\(elementPath.keyPath)", expected: value)
        }
        let mapComponents = argument.components(separatedBy: ".*.")
        if mapComponents.count == 2 {
            // get array keypath and shape
            let mapPath = try toKeyPath(token: mapComponents[0], shape: shape, type: structure)
            // shape should be a list, element should be structure
            guard case .map(let mapType) = mapPath.shape.type else { throw Error.matcherInvalidType }
            let elementShape: Shape = mapType.value.shape
            guard case .structure(let elementType) = elementShape.type else { throw Error.matcherInvalidType }
            let elementPath = try toKeyPath(token: mapComponents[1], shape: elementShape, type: elementType)
            let value: String
            switch expected {
            case .string(let string):
                // assume is enum
                if case .enum = elementPath.shape.type {
                    let enumContext = generateEnumMemberContext(string, shapeName: "")
                    value = ".\(enumContext.case)"
                } else if case .string = elementPath.shape.type {
                    value = "\"string\""
                } else {
                    throw Error.matcherInvalidType
                }
            case .integer(let integer):
                value = String(describing: integer)
            case .bool(let boolean):
                value = String(describing: boolean)
            }
            return (path: "\(mapPath.keyPath).values", elementPath: "\(elementShape.name!).\(elementPath.keyPath)", expected: value)
        }
        print(argument)
        return nil
    }
}
