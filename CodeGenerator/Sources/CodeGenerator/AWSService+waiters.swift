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
    }

    struct AcceptorContext {
        let state: String
        let matcher: MatcherContext
    }

    enum MatcherContext {
        case path(path: String, expected: String)
        case error(String)
        case success
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
                    acceptors: acceptorContexts
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
                return .init(state: acceptor.state.rawValue, matcher: .success)
            } else {
                return nil
            }

        case .path(let argument, let expected):
            if argument.firstIndex(of: "(") == nil {
                guard case .structure(let structure) = shape.type else { return nil }
                let keyPath = try toKeyPath(token: argument, shape: shape, type: structure)
                let value: String
                switch expected {
                case .string(let string):
                    // assume is enum
                    if case .enum = keyPath.shape.type {
                        let enumContext = generateEnumMemberContext(string, shapeName: "")
                        value = ".\(enumContext.case)"
                    } else if case .string = keyPath.shape.type {
                        value = "\"string\""
                    } else {
                        throw Error.matcherInvalidType
                    }
                case .integer(let integer):
                    value = String(describing: integer)
                case .bool(let boolean):
                    value = String(describing: boolean)
                }
                return .init(state: acceptor.state.rawValue, matcher: .path(path: keyPath.keyPath, expected: value))
            } else {
                return nil
            }
        default:
            break
        }
        return nil
    }
}
