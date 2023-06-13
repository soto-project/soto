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

import SotoCore
import SotoDynamoDB
import XCTest

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class DynamoDBCodableAsyncTests: XCTestCase {
    static var client = AWSClient(
        credentialProvider: TestEnvironment.credentialProvider,
        middlewares: TestEnvironment.middlewares,
        httpClientProvider: .createNew
    )

    static var dynamoDB = DynamoDB(
        client: client,
        region: .useast1,
        endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
    )

    func createTable(name: String, attributeDefinitions: [DynamoDB.AttributeDefinition]? = nil, keySchema: [DynamoDB.KeySchemaElement]? = nil) async throws {
        let input = DynamoDB.CreateTableInput(
            attributeDefinitions: attributeDefinitions ?? [.init(attributeName: "id", attributeType: .s)],
            keySchema: keySchema ?? [.init(attributeName: "id", keyType: .hash)],
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

    func deleteTable(name: String) async throws {
        let input = DynamoDB.DeleteTableInput(tableName: name)
        _ = try await Self.dynamoDB.deleteTable(input, logger: TestEnvironment.logger)
    }

    // MARK: Tests

    func testPutGetAsync() async throws {
        struct TestObject: Codable, Equatable {
            let id: String
            let name: String
            let surname: String
            let age: Int
            let address: String
            let pets: [String]?
        }
        let id = UUID().uuidString
        let test = TestObject(id: id, name: "John", surname: "Smith", age: 32, address: "1 Park Lane", pets: ["zebra", "cat", "dog", "cat"])

        let tableName = TestEnvironment.generateResourceName()
        do {
            try await self.createTable(name: tableName)

            let putRequest = DynamoDB.PutItemCodableInput(item: test, tableName: tableName)
            _ = try await Self.dynamoDB.putItem(putRequest, logger: TestEnvironment.logger)

            let getRequest = DynamoDB.GetItemInput(consistentRead: true, key: ["id": .s(id)], tableName: tableName)
            let response = try await Self.dynamoDB.getItem(getRequest, type: TestObject.self, logger: TestEnvironment.logger)

            XCTAssertEqual(test, response.item)
        } catch {
            XCTFail("\(error)")
        }
        try await self.deleteTable(name: tableName)
    }

    func testUpdateAsync() async throws {
        struct TestObject: Codable, Equatable {
            let id: String
            let name: String
            let surname: String
            let age: Int
            let address: String
            let pets: [String]?
        }
        struct NameUpdate: Codable {
            let id: String
            let name: String
            let surname: String
        }
        struct NameUpdateWithAge: Codable {
            let id: String
            let name: String
            let surname: String
            let age: Int
        }
        struct AdditionalAttributes: Codable {
            let oldAge: Int
        }
        let id = UUID().uuidString
        let test = TestObject(id: id, name: "John", surname: "Smith", age: 32, address: "1 Park Lane", pets: ["cat", "dog"])
        let nameUpdate = NameUpdate(id: id, name: "David", surname: "Jones")

        let tableName = TestEnvironment.generateResourceName()
        do {
            _ = try await self.createTable(name: tableName)

            let putRequest = DynamoDB.PutItemCodableInput(item: test, tableName: tableName)
            _ = try await Self.dynamoDB.putItem(putRequest, logger: TestEnvironment.logger)

            let updateRequest = DynamoDB.UpdateItemCodableInput(key: ["id"], tableName: tableName, updateItem: nameUpdate)
            _ = try await Self.dynamoDB.updateItem(updateRequest, logger: TestEnvironment.logger)

            let additionalAttributes1 = AdditionalAttributes(oldAge: 32)
            let conditionExpression1 = "attribute_exists(#id) AND #age = :oldAge"
            let nameUpdateWithAge1 = NameUpdateWithAge(id: id, name: "David", surname: "Jones", age: 33)
            let updateRequest1 = try DynamoDB.UpdateItemCodableInput(additionalAttributes: additionalAttributes1, conditionExpression: conditionExpression1, key: ["id"], tableName: tableName, updateItem: nameUpdateWithAge1)
            _ = try await Self.dynamoDB.updateItem(updateRequest1, logger: TestEnvironment.logger)
    
            do {
                let additionalAttributes = AdditionalAttributes(oldAge: 34)
                let conditionExpression = "attribute_exists(#id) AND #age = :oldAge"
                let nameUpdateWithAge = NameUpdateWithAge(id: id, name: "David", surname: "Jones", age: 35)
                let updateRequest = try DynamoDB.UpdateItemCodableInput(additionalAttributes: additionalAttributes, conditionExpression: conditionExpression, key: ["id"], tableName: tableName, updateItem: nameUpdateWithAge)
                _ = try await Self.dynamoDB.updateItem(updateRequest, logger: TestEnvironment.logger)
                XCTFail("Should have thrown error because conditionExpression is not met")
            } catch {
                XCTAssertNotNil(error)
            }
            let getRequest = DynamoDB.GetItemInput(consistentRead: true, key: ["id": .s(id)], tableName: tableName)
            let response = try await Self.dynamoDB.getItem(getRequest, type: TestObject.self, logger: TestEnvironment.logger)

            XCTAssertEqual("David", response.item?.name)
            XCTAssertEqual("Jones", response.item?.surname)
            XCTAssertEqual(32, response.item?.age)
            XCTAssertEqual("1 Park Lane", response.item?.address)
            XCTAssertEqual(["cat", "dog"], response.item?.pets)
        } catch {
            XCTFail("\(error)")
        }
        try await self.deleteTable(name: tableName)
    }

    func testQueryPaginatorAsync() async throws {
        struct TestObject: Codable, Equatable {
            let id: String
            let version: Int
            let message: String
        }
        let testItems = [
            TestObject(id: "test", version: 1, message: "Message 1"),
            TestObject(id: "test", version: 2, message: "Message 2"),
            TestObject(id: "test", version: 3, message: "Message 3"),
            TestObject(id: "test", version: 4, message: "Message 4"),
            TestObject(id: "test", version: 5, message: "Message 5"),
        ]

        var results: [TestObject] = []
        let tableName = TestEnvironment.generateResourceName()
        do {
            _ = try await self.createTable(
                name: tableName,
                attributeDefinitions: [.init(attributeName: "id", attributeType: .s), .init(attributeName: "version", attributeType: .n)],
                keySchema: [.init(attributeName: "id", keyType: .hash), .init(attributeName: "version", keyType: .range)]
            )

            try await withThrowingTaskGroup(of: Void.self) { group in
                testItems.forEach { item in
                    group.addTask {
                        _ = try await Self.dynamoDB.putItem(.init(item: item, tableName: tableName), logger: TestEnvironment.logger)
                    }
                }
                while let _ = try await group.next() {}
            }

            let queryRequest = DynamoDB.QueryInput(
                consistentRead: true,
                expressionAttributeValues: [":id": .s("test"), ":version": .n("2")],
                keyConditionExpression: "id = :id and version >= :version",
                limit: 3,
                tableName: tableName
            )
            let paginator = Self.dynamoDB.queryPaginator(queryRequest, type: TestObject.self, logger: TestEnvironment.logger)
            for try await response in paginator {
                results.append(contentsOf: response.items ?? [])
            }

            XCTAssertEqual(testItems[1], results[0])
            XCTAssertEqual(testItems[2], results[1])
            XCTAssertEqual(testItems[3], results[2])
            XCTAssertEqual(testItems[4], results[3])
        } catch {
            XCTFail("\(error)")
        }
        try await self.deleteTable(name: tableName)
    }
}
