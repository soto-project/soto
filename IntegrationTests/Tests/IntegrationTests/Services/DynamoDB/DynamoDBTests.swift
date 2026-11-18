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
import Testing

@testable import SotoDynamoDB

struct DynamoDBTableTrait: TestScoping, SuiteTrait, TestTrait {
    @TaskLocal
    static var _tableName: String?

    static var tableName: String {
        guard let _tableName else { fatalError("Test needs a DynamoDBTableTrait") }
        return _tableName
    }

    let input: DynamoDB.CreateTableInput

    init(tableName: String, attributeDefinitions: [DynamoDB.AttributeDefinition], keySchema: [DynamoDB.KeySchemaElement]?) {
        self.input = .init(
            attributeDefinitions: attributeDefinitions,
            keySchema: keySchema,
            provisionedThroughput: .init(readCapacityUnits: 5, writeCapacityUnits: 5),
            tableName: tableName
        )
    }

    func provideScope(for test: Test, testCase: Test.Case?, performing function: @concurrent @Sendable () async throws -> Void) async throws {
        let dynamoDB = DynamoDB(client: AWSClientTrait.client, region: .useast1)
        try await testAsset {
            try await self.createTable(input: input, dynamoDB: dynamoDB)
        } test: {
            try await DynamoDBTableTrait.$_tableName.withValue(self.input.tableName) {
                try await function()
            }
        } delete: {
            _ = try await dynamoDB.deleteTable(tableName: input.tableName)
        }
    }

    func createTable(
        input: DynamoDB.CreateTableInput,
        dynamoDB: DynamoDB
    ) async throws {
        do {
            _ = try await dynamoDB.createTable(input, logger: TestEnvironment.logger)
        } catch let error as DynamoDBErrorType {
            switch error.error {
            case .resourceInUseException:
                print("Table (\(input.tableName)) already exists")
            default:
                throw error
            }
        }
        try await dynamoDB.waitUntilTableExists(.init(tableName: input.tableName), logger: TestEnvironment.logger)
    }

}

@Suite(
    .awsClient(),
    DynamoDBTableTrait(
        tableName: TestEnvironment.generateResourceName("soto-dynamodb-tests"),
        attributeDefinitions: [.init(attributeName: "id", attributeType: .s)],
        keySchema: [.init(attributeName: "id", keyType: .hash)]
    )
)
struct DynamoDBTests {
    /*    override class func setUp() {
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
                #expect(response.tableDescription?.tableName == name)
            } catch let error as DynamoDBErrorType {
                switch error.error {
                case .resourceInUseException:
                    print("Table (\(name)) already exists")
                default:
                    throw error
                }
            }
            try await Self.dynamoDB.waitUntilTableExists(.init(tableName: name), logger: TestEnvironment.logger)
        }

        static func deleteTable(name: String) async throws {
            let input = DynamoDB.DeleteTableInput(tableName: name)
            _ = try await Self.dynamoDB.deleteTable(input, logger: TestEnvironment.logger)
        }
*/
    func putItem(tableName: String, values: [String: Any], dynamoDB: DynamoDB) async throws -> DynamoDB.PutItemOutput {
        let input = DynamoDB.PutItemInput(item: values.mapValues { DynamoDB.AttributeValue(any: $0) }, tableName: tableName)
        return try await dynamoDB.putItem(input)
    }

    func getItem(tableName: String, keys: [String: String], dynamoDB: DynamoDB) async throws -> DynamoDB.GetItemOutput {
        let input = DynamoDB.GetItemInput(consistentRead: true, key: keys.mapValues { DynamoDB.AttributeValue.s($0) }, tableName: tableName)
        return try await dynamoDB.getItem(input)
    }

    // MARK: TESTS

    @Test func testGetObject() async throws {
        let dynamoDB = DynamoDB(client: AWSClientTrait.client, region: .useast1)
        _ = try await self.putItem(
            tableName: DynamoDBTableTrait.tableName,
            values: ["id": "testGetObject", "First name": "John", "Surname": "Smith"],
            dynamoDB: dynamoDB
        )
        let response = try await self.getItem(tableName: DynamoDBTableTrait.tableName, keys: ["id": "testGetObject"], dynamoDB: dynamoDB)
        #expect(response.item?["id"] == .s("testGetObject"))
        #expect(response.item?["First name"] == .s("John"))
        #expect(response.item?["Surname"] == .s("Smith"))
    }

    @Test func testDataItem() async throws {
        let dynamoDB = DynamoDB(client: AWSClientTrait.client, region: .useast1)
        let data = Data("testdata".utf8)
        _ = try await self.putItem(tableName: DynamoDBTableTrait.tableName, values: ["id": "testDataItem", "data": data], dynamoDB: dynamoDB)
        let response = try await self.getItem(tableName: DynamoDBTableTrait.tableName, keys: ["id": "testDataItem"], dynamoDB: dynamoDB)
        #expect(response.item?["id"] == .s("testDataItem"))
        #expect(response.item?["data"] == .b(.data(data)))
    }

    @Test func testNumberSetItem() async throws {
        let dynamoDB = DynamoDB(client: AWSClientTrait.client, region: .useast1)
        _ = try await self.putItem(
            tableName: DynamoDBTableTrait.tableName,
            values: ["id": "testNumberSetItem", "numbers": [2, 4.001, -6, 8]],
            dynamoDB: dynamoDB
        )
        let response = try await self.getItem(tableName: DynamoDBTableTrait.tableName, keys: ["id": "testNumberSetItem"], dynamoDB: dynamoDB)
        #expect(response.item?["id"] == .s("testNumberSetItem"))
        if case .ns(let numbers) = response.item?["numbers"] {
            let numberSet = Set(numbers)
            #expect(numberSet.contains("2"))
            #expect(numberSet.contains("4.001"))
            #expect(numberSet.contains("-6"))
            #expect(numberSet.contains("8"))
        } else {
            Issue.record("Expected a number set, but got \(response.item?["numbers"])")
        }
    }

    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Localstack doesn't support dynamoDB endpoints"))
    func testDescribeEndpoints() async throws {
        let dynamoDB = DynamoDB(client: AWSClientTrait.client, region: .useast1)
        _ = try await dynamoDB.describeEndpoints()
    }

    @Test func testError() async {
        let dynamoDB = DynamoDB(client: AWSClientTrait.client, region: .useast1)
        let error = await #expect(throws: DynamoDBErrorType.self) {
            _ = try await dynamoDB.describeTable(.init(tableName: "non-existent-table"))
        }
        switch error?.error {
        case .resourceNotFoundException:
            break
        default:
            Issue.record("Expected resourceNotFoundException, got \(error?.error)")
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
