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

// Used to decode model paginators_2.json files
struct Paginators: Decodable {
    struct Paginator: Decodable {
        var inputTokens: [String]?
        var outputTokens: [String]?
        var moreResults: String?
        var limitKey: String?
        var resultKey: [String]?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            if let value = try container.decodeArrayIfPresent(String.self, forKey: .inputToken) {
                self.inputTokens = value
            } else {
                self.inputTokens = try container.decodeIfPresent([String].self, forKey: .inputTokens)
            }
            if let value = try container.decodeArrayIfPresent(String.self, forKey: .outputToken) {
                self.outputTokens = value
            } else {
                self.outputTokens = try container.decodeIfPresent([String].self, forKey: .outputTokens)
            }
            self.moreResults = try container.decodeIfPresent(String.self, forKey: .moreResults)
            self.limitKey = try container.decodeIfPresent(String.self, forKey: .limitKey)
            self.resultKey = try container.decodeArrayIfPresent(String.self, forKey: .resultKey)
        }

        private enum CodingKeys: String, CodingKey {
            case inputToken = "input_token"
            case outputToken = "output_token"
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
            case moreResults = "more_results"
            case limitKey = "limit_key"
            case resultKey = "result_key"
        }
    }

    var pagination: [String: Paginator]
}

extension KeyedDecodingContainer {
    func decodeArray(_ type: String.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [String] {
        do {
            return [try self.decode(String.self, forKey: key)]
        } catch {
            return try self.decode([String].self, forKey: key)
        }
    }

    func decodeArrayIfPresent(_ type: String.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [String]? {
        do {
            if let value = try self.decodeIfPresent(String.self, forKey: key) {
                return [value]
            } else {
                return nil
            }
        } catch {
            return try self.decodeIfPresent([String].self, forKey: key)
        }
    }

    func decodeArray<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [T] where T: Decodable {
        do {
            return [try self.decode(T.self, forKey: key)]
        } catch {
            return try self.decode([T].self, forKey: key)
        }
    }

    func decodeArrayIfPresent<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [T]? where T: Decodable {
        do {
            if let value = try self.decodeIfPresent(T.self, forKey: key) {
                return [value]
            } else {
                return nil
            }
        } catch {
            return try self.decodeIfPresent([T].self, forKey: key)
        }
    }
}
