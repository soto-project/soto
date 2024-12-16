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
import XCTest

@testable import SotoDynamoDB

// testing json service

class DynamoDBTests: XCTestCase {
    static var client: AWSClient!
    static var dynamoDB: DynamoDB!
    static var tableName: String!
    static var tableWithValueName: String!

    override class func setUp() {
        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }

        self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middleware: TestEnvironment.middlewares)
        self.dynamoDB = DynamoDB(
            client: DynamoDBTests.client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
        /// If we create a rest api for each test, when we delete them APIGateway will
        /// throttle and we will most likely not delete the all APIs so we create one API to be used by all tests
        Task {
            await XCTAsyncAssertNoThrow {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        self.tableName = TestEnvironment.generateResourceName("soto-dynamodb-tests")
                        _ = try await Self.createTable(
                            name: self.tableName,
                            attributeDefinitions: [.init(attributeName: "id", attributeType: .s)],
                            keySchema: [.init(attributeName: "id", keyType: .hash)]
                        )
                    }
                    group.addTask {
                        self.tableWithValueName = TestEnvironment.generateResourceName("soto-dynamodb-tests_value")
                        _ = try await Self.createTable(
                            name: self.tableWithValueName,
                            attributeDefinitions: [
                                .init(attributeName: "id", attributeType: .s), .init(attributeName: "version", attributeType: .n),
                            ],
                            keySchema: [.init(attributeName: "id", keyType: .hash), .init(attributeName: "version", keyType: .range)]
                        )
                    }
                    try await group.waitForAll()
                }
            }
        }.syncAwait()
    }

    override class func tearDown() {
        Task {
            await XCTAsyncAssertNoThrow {
                _ = try await Self.deleteTable(name: self.tableName)
                _ = try await Self.deleteTable(name: self.tableWithValueName)
                try await Self.client.shutdown()
            }
        }.syncAwait()
    }

    static func createTable(
        name: String,
        attributeDefinitions: [DynamoDB.AttributeDefinition],
        keySchema: [DynamoDB.KeySchemaElement]
    ) async throws {
        let input = DynamoDB.CreateTableInput(
            attributeDefinitions: attributeDefinitions,
            keySchema: keySchema,
            provisionedThroughput: .init(readCapacityUnits: 5, writeCapacityUnits: 5),
            tableName: name
        )
        do {
            let response = try await Self.dynamoDB.createTable(input, logger: TestEnvironment.logger)
            XCTAssertEqual(response.tableDescription?.tableName, name)
        } catch let error as DynamoDBErrorType where error == .resourceInUseException {
            print("Table (\(name)) already exists")
        }
        try await Self.dynamoDB.waitUntilTableExists(.init(tableName: name), logger: TestEnvironment.logger)
    }

    static func deleteTable(name: String) async throws {
        let input = DynamoDB.DeleteTableInput(tableName: name)
        _ = try await Self.dynamoDB.deleteTable(input, logger: TestEnvironment.logger)
    }

    func putItem(tableName: String, values: [String: Any]) async throws -> DynamoDB.PutItemOutput {
        let input = DynamoDB.PutItemInput(item: values.mapValues { DynamoDB.AttributeValue(any: $0) }, tableName: tableName)
        return try await Self.dynamoDB.putItem(input)
    }

    func getItem(tableName: String, keys: [String: String]) async throws -> DynamoDB.GetItemOutput {
        let input = DynamoDB.GetItemInput(consistentRead: true, key: keys.mapValues { DynamoDB.AttributeValue.s($0) }, tableName: tableName)
        return try await Self.dynamoDB.getItem(input)
    }

    // MARK: TESTS

    func testGetObject() async throws {
        _ = try await self.putItem(tableName: Self.tableName, values: ["id": "testGetObject", "First name": "John", "Surname": "Smith"])
        let response = try await self.getItem(tableName: Self.tableName, keys: ["id": "testGetObject"])
        XCTAssertEqual(response.item?["id"], .s("testGetObject"))
        XCTAssertEqual(response.item?["First name"], .s("John"))
        XCTAssertEqual(response.item?["Surname"], .s("Smith"))
    }

    func testDataItem() async throws {
        let data = Data("testdata".utf8)
        _ = try await self.putItem(tableName: Self.tableName, values: ["id": "testDataItem", "data": data])
        let response = try await self.getItem(tableName: Self.tableName, keys: ["id": "testDataItem"])
        XCTAssertEqual(response.item?["id"], .s("testDataItem"))
        XCTAssertEqual(response.item?["data"], .b(.data(data)))
    }

    func testNumberSetItem() async throws {
        _ = try await self.putItem(tableName: Self.tableName, values: ["id": "testNumberSetItem", "numbers": [2, 4.001, -6, 8]])
        let response = try await self.getItem(tableName: Self.tableName, keys: ["id": "testNumberSetItem"])
        XCTAssertEqual(response.item?["id"], .s("testNumberSetItem"))
        if case .ns(let numbers) = response.item?["numbers"] {
            let numberSet = Set(numbers)
            XCTAssert(numberSet.contains("2"))
            XCTAssert(numberSet.contains("4.001"))
            XCTAssert(numberSet.contains("-6"))
            XCTAssert(numberSet.contains("8"))
        } else {
            XCTFail()
        }
    }

    func testDescribeEndpoints() async throws {
        guard !TestEnvironment.isUsingLocalstack else { return }
        _ = try await Self.dynamoDB.describeEndpoints(.init())
    }

    func testError() async {
        await XCTAsyncExpectError(DynamoDBErrorType.resourceNotFoundException) {
            _ = try await Self.dynamoDB.describeTable(.init(tableName: "non-existent-table"))
        }
    }
}

extension DynamoDB.AttributeValue {
    init(any: Any) {
        switch any {
        case let data as Data:
            self = .b(.data(data))  // self.init(b: data)
        case let bool as Bool:
            self = .bool(bool)  // self.init(bool: bool)
        case let int as Int:
            self = .n(int.description)  // self.init(n: int.description)
        case let ints as [Int]:
            self = .ns(ints.map(\.description))  // self.init(ns: ints.map {$0.description})
        case let float as Float:
            self = .n(float.description)  // self.init(n: float.description)
        case let double as Double:
            self = .n(double.description)  // self.init(n: double.description)
        case let doubles as [Double]:
            self = .ns(doubles.map(\.description))  // self.init(ns: doubles.map {$0.description})
        case let string as String:
            self = .s(string)  // self.init(s: string)
        default:
            self = .s(String(reflecting: any))  // self.init(s: String(reflecting: any))
        }
    }
}
