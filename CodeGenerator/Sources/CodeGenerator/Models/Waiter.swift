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

// used to decode waiters-2.json files
struct Waiters: Decodable {
    struct Waiter: Decodable {
        enum State: String, Decodable {
            case success
            case failure
            case retry
        }
        enum WaiterMatcherValue: Decodable {
            case string(String)
            case integer(Int)
            case bool(Bool)

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let string = try? container.decode(String.self) {
                    self = .string(string)
                } else if let integer = try? container.decode(Int.self) {
                    self = .integer(integer)
                } else if let boolean = try? container.decode(Bool.self) {
                    self = .bool(boolean)
                } else {
                    throw DecodingError.typeMismatch(
                        WaiterMatcherValue.self,
                        .init(codingPath: decoder.codingPath, debugDescription: "Invalid matcher expected type")
                    )
                }
            }
        }
        enum Matcher {
            case status(Int)
            case path(argument: String, expected: WaiterMatcherValue)
            case pathAll(argument: String, expected: WaiterMatcherValue)
            case pathAny(argument: String, expected: WaiterMatcherValue)
            case error(String)
        }

        struct Acceptor: Decodable {
            let state: State
            let matcher: Matcher

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.state = try container.decode(State.self, forKey: .state)
                
                let type = try container.decode(String.self, forKey: .matcher)
                switch type {
                case "status":
                    let expected = try container.decode(Int.self, forKey: .expected)
                    self.matcher = .status(expected)
                case "path":
                    let argument = try container.decode(String.self, forKey: .argument)
                    let expected = try container.decode(WaiterMatcherValue.self, forKey: .expected)
                    self.matcher = .path(argument: argument, expected: expected)
                case "pathAll":
                    let argument = try container.decode(String.self, forKey: .argument)
                    let expected = try container.decode(WaiterMatcherValue.self, forKey: .expected)
                    self.matcher = .pathAll(argument: argument, expected: expected)
                case "pathAny":
                    let argument = try container.decode(String.self, forKey: .argument)
                    let expected = try container.decode(WaiterMatcherValue.self, forKey: .expected)
                    self.matcher = .pathAny(argument: argument, expected: expected)
                case "error":
                    let expected = try container.decode(String.self, forKey: .expected)
                    self.matcher = .error(expected)
                default:
                    throw DecodingError.typeMismatch(
                        Matcher.self,
                        .init(codingPath: decoder.codingPath, debugDescription: "Invalid matcher type: \(type)")
                    )
                }
            }

            private enum CodingKeys: String, CodingKey {
                case state
                case matcher
                case argument
                case expected
            }
        }
        let delay: Int
        let maxAttempts: Int
        let operation: String
        let acceptors: [Acceptor]
    }

    let version: Int
    let waiters: [String: Waiter]
}
