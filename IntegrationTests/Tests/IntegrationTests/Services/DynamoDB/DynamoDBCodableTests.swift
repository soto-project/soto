//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2025 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import SotoCore
import SotoDynamoDB
import Testing

@Suite(
    .awsClient(),
    DynamoDBTableTrait(
        tableName: TestEnvironment.generateResourceName("soto-dynamodb-codable-tests"),
        attributeDefinitions: [.init(attributeName: "id", attributeType: .s)],
        keySchema: [.init(attributeName: "id", keyType: .hash)]
    )
)
struct DynamoDBCodableTests {
    @Test func testCodablePutGet() async throws {
        let dynamoDB = DynamoDB(client: AWSClientTrait.client, region: .useast1)
        struct TestObject: Codable, Equatable {
            let id: String
            let name: String
            let surname: String
            let age: Int
            let address: String
            let pets: [String]?
            let date: Date
        }
        let id = UUID().uuidString
        let test = TestObject(
            id: id,
            name: "John",
            surname: "Smith",
            age: 32,
            address: "1 Park Lane",
            pets: ["zebra", "cat", "dog", "cat"],
            date: Date(timeIntervalSinceReferenceDate: 134500.5)
        )
        let decoder = DynamoDBDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let encoder = DynamoDBEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let putRequest = DynamoDB.PutItemCodableInput(item: test, tableName: DynamoDBTableTrait.tableName)
        _ = try await dynamoDB.putItem(putRequest, encoder: encoder, logger: TestEnvironment.logger)

        let getRequest = DynamoDB.GetItemInput(consistentRead: true, key: ["id": .s(id)], tableName: DynamoDBTableTrait.tableName)
        let response = try await dynamoDB.getItem(getRequest, type: TestObject.self, decoder: decoder, logger: TestEnvironment.logger)

        #expect(test == response.item)
    }

    @Test func testCodablePutGetWithISO8601Date() async throws {
        let dynamoDB = DynamoDB(client: AWSClientTrait.client, region: .useast1)
        struct TestObject: Codable, Equatable {
            let id: String
            let date: Date
        }
        let id = UUID().uuidString
        let test = TestObject(id: id, date: Date(timeIntervalSinceReferenceDate: 134500))
        let decoder = DynamoDBDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let encoder = DynamoDBEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let putRequest = DynamoDB.PutItemCodableInput(item: test, tableName: DynamoDBTableTrait.tableName)
        _ = try await dynamoDB.putItem(putRequest, encoder: encoder, logger: TestEnvironment.logger)

        let getRequest = DynamoDB.GetItemInput(consistentRead: true, key: ["id": .s(id)], tableName: DynamoDBTableTrait.tableName)
        let response = try await dynamoDB.getItem(getRequest, type: TestObject.self, decoder: decoder, logger: TestEnvironment.logger)

        #expect(test == response.item)
    }

    @Test func testCodableUpdate() async throws {
        let dynamoDB = DynamoDB(client: AWSClientTrait.client, region: .useast1)
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

        let putRequest = DynamoDB.PutItemCodableInput(item: test, tableName: DynamoDBTableTrait.tableName)
        _ = try await dynamoDB.putItem(putRequest, logger: TestEnvironment.logger)
        let updateRequest = DynamoDB.UpdateItemCodableInput(key: ["id"], tableName: DynamoDBTableTrait.tableName, updateItem: nameUpdate)
        _ = try await dynamoDB.updateItem(updateRequest, logger: TestEnvironment.logger)

        // update
        let additionalAttributes1 = AdditionalAttributes(oldAge: 32)
        let conditionExpression1 = "attribute_exists(#id) AND #age = :oldAge"
        let nameUpdateWithAge1 = NameUpdateWithAge(id: id, name: "David", surname: "Jones", age: 33)
        let updateRequest1 = try DynamoDB.UpdateItemCodableInput(
            additionalAttributes: additionalAttributes1,
            conditionExpression: conditionExpression1,
            key: ["id"],
            tableName: DynamoDBTableTrait.tableName,
            updateItem: nameUpdateWithAge1
        )
        _ = try await dynamoDB.updateItem(updateRequest1, logger: TestEnvironment.logger)

        let error = await #expect(throws: DynamoDBErrorType.self) {
            let additionalAttributes = AdditionalAttributes(oldAge: 34)
            let nameUpdateWithAge = NameUpdateWithAge(id: id, name: "David", surname: "Jones", age: 35)
            let updateRequest = try DynamoDB.UpdateItemCodableInput(
                additionalAttributes: additionalAttributes,
                conditionExpression: "attribute_exists(#id) AND #age = :oldAge",
                key: ["id"],
                returnValuesOnConditionCheckFailure: .allOld,
                tableName: DynamoDBTableTrait.tableName,
                updateItem: nameUpdateWithAge
            )
            _ = try await dynamoDB.updateItem(updateRequest, logger: TestEnvironment.logger)
        }
        switch error?.error {
        case .conditionalCheckFailedException(let context):
            #expect(context.item?["age"] == .n("33"))
        default:
            Issue.record("Expected conditionalCheckFailedException, got: \(error)")
        }
        let getRequest = DynamoDB.GetItemInput(consistentRead: true, key: ["id": .s(id)], tableName: DynamoDBTableTrait.tableName)
        let response = try await dynamoDB.getItem(getRequest, type: TestObject.self, logger: TestEnvironment.logger)

        #expect("David" == response.item?.name)
        #expect("Jones" == response.item?.surname)
        #expect(33 == response.item?.age)
        #expect("1 Park Lane" == response.item?.address)
        #expect(["cat", "dog"] == response.item?.pets)
    }

    @Suite(
        DynamoDBTableTrait(
            tableName: TestEnvironment.generateResourceName("soto-dynamodb-codable-tests2"),
            attributeDefinitions: [
                .init(attributeName: "id", attributeType: .s),
                .init(attributeName: "version", attributeType: .n),
            ],
            keySchema: [.init(attributeName: "id", keyType: .hash), .init(attributeName: "version", keyType: .range)]
        )
    )
    struct WithValueTable {
        @Test func testCodableQuery() async throws {
            let dynamoDB = DynamoDB(client: AWSClientTrait.client, region: .useast1)
            struct TestObject: Codable, Equatable {
                let id: String
                let version: Int
                let message: String
            }
            let testItems = [
                TestObject(id: "testCodableQuery", version: 1, message: "Message 1"),
                TestObject(id: "testCodableQuery", version: 2, message: "Message 2"),
                TestObject(id: "testCodableQuery", version: 3, message: "Message 3"),
            ]
            _ = try await testItems.concurrentMap {
                try await dynamoDB.putItem(.init(item: $0, tableName: DynamoDBTableTrait.tableName), logger: TestEnvironment.logger)
            }
            let request = DynamoDB.QueryInput(
                consistentRead: true,
                expressionAttributeValues: [":id": .s("testCodableQuery"), ":version": .n("2")],
                keyConditionExpression: "id = :id and version >= :version",
                tableName: DynamoDBTableTrait.tableName
            )
            let response = try await dynamoDB.query(request, type: TestObject.self, logger: TestEnvironment.logger)

            #expect(testItems[1] == response.items?[0])
            #expect(testItems[2] == response.items?[1])
        }

        @Test func testCodableQueryPaginator() async throws {
            let dynamoDB = DynamoDB(client: AWSClientTrait.client, region: .useast1)
            struct TestObject: Codable, Equatable {
                let id: String
                let version: Int
                let message: String
            }
            let testItems = [
                TestObject(id: "testCodableQueryPaginator", version: 1, message: "Message 1"),
                TestObject(id: "testCodableQueryPaginator", version: 2, message: "Message 2"),
                TestObject(id: "testCodableQueryPaginator", version: 3, message: "Message 3"),
                TestObject(id: "testCodableQueryPaginator", version: 4, message: "Message 4"),
                TestObject(id: "testCodableQueryPaginator", version: 5, message: "Message 5"),
            ]
            _ = try await testItems.concurrentMap {
                try await dynamoDB.putItem(.init(item: $0, tableName: DynamoDBTableTrait.tableName), logger: TestEnvironment.logger)
            }

            let request = DynamoDB.QueryInput(
                consistentRead: true,
                expressionAttributeValues: [":id": .s("testCodableQueryPaginator"), ":version": .n("2")],
                keyConditionExpression: "id = :id and version >= :version",
                limit: 3,
                tableName: DynamoDBTableTrait.tableName
            )
            let results = try await dynamoDB.queryPaginator(request, type: TestObject.self, logger: TestEnvironment.logger)
                .reduce([]) { $0 + ($1.items ?? []) }

            #expect(testItems[1] == results[0])
            #expect(testItems[2] == results[1])
            #expect(testItems[3] == results[2])
            #expect(testItems[4] == results[3])
        }

        @Test func testCodableScan() async throws {
            let dynamoDB = DynamoDB(client: AWSClientTrait.client, region: .useast1)
            struct TestObject: Codable, Equatable {
                let id: String
                let version: Int
                let message: String
            }
            let testItems = [
                TestObject(id: "testCodableScan", version: 1, message: "Message 1"),
                TestObject(id: "testCodableScan", version: 2, message: "Message 2"),
                TestObject(id: "testCodableScan", version: 3, message: "Message 3"),
            ]
            _ = try await testItems.concurrentMap {
                try await dynamoDB.putItem(.init(item: $0, tableName: DynamoDBTableTrait.tableName), logger: TestEnvironment.logger)
            }

            let request = DynamoDB.ScanInput(
                consistentRead: true,
                expressionAttributeValues: [":id": .s("testCodableScan"), ":message": .s("Message 2")],
                filterExpression: "id = :id and message = :message",
                tableName: DynamoDBTableTrait.tableName
            )
            let response = try await dynamoDB.scan(request, type: TestObject.self, logger: TestEnvironment.logger)

            #expect(testItems[1] == response.items?[0])
        }
    }
}
