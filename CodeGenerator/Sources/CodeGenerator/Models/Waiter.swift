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

        enum MatcherValue: Decodable, Equatable {
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
                        MatcherValue.self,
                        .init(codingPath: decoder.codingPath, debugDescription: "Invalid matcher expected type")
                    )
                }
            }
        }

        enum Matcher: Equatable {
            case status(Int)
            case path(argument: String, expected: MatcherValue)
            case allPath(argument: String, expected: MatcherValue)
            case anyPath(argument: String, expected: MatcherValue)
            case error(String)
        }

        class Acceptor: Decodable {
            var state: State
            var matcher: Matcher

            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.state = try container.decode(State.self, forKey: .state)

                let type = try container.decode(String.self, forKey: .matcher)
                switch type {
                case "status":
                    let expected = try container.decode(Int.self, forKey: .expected)
                    self.matcher = .status(expected)
                case "path":
                    let argument = try container.decode(String.self, forKey: .argument)
                    let expected = try container.decode(MatcherValue.self, forKey: .expected)
                    self.matcher = .path(argument: argument, expected: expected)
                case "pathAll":
                    let argument = try container.decode(String.self, forKey: .argument)
                    let expected = try container.decode(MatcherValue.self, forKey: .expected)
                    self.matcher = .allPath(argument: argument, expected: expected)
                case "pathAny":
                    let argument = try container.decode(String.self, forKey: .argument)
                    let expected = try container.decode(MatcherValue.self, forKey: .expected)
                    self.matcher = .anyPath(argument: argument, expected: expected)
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

        var delay: Int
        var maxAttempts: Int
        var operation: String
        var acceptors: [Acceptor]
    }

    var version: Int
    var waiters: [String: Waiter]
}
