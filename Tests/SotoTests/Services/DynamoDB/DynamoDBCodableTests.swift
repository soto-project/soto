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

import SotoCore
import SotoDynamoDB
import XCTest

extension DynamoDBTests {
    // MARK: Tests

    func testCodablePutGet() async throws {
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
        let putRequest = DynamoDB.PutItemCodableInput(item: test, tableName: Self.tableName)
        _ = try await Self.dynamoDB.putItem(putRequest, encoder: encoder, logger: TestEnvironment.logger)

        let getRequest = DynamoDB.GetItemInput(consistentRead: true, key: ["id": .s(id)], tableName: Self.tableName)
        let response = try await Self.dynamoDB.getItem(getRequest, type: TestObject.self, decoder: decoder, logger: TestEnvironment.logger)

        XCTAssertEqual(test, response.item)
    }

    func testCodablePutGetWithISO8601Date() async throws {
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
        let putRequest = DynamoDB.PutItemCodableInput(item: test, tableName: Self.tableName)
        _ = try await Self.dynamoDB.putItem(putRequest, encoder: encoder, logger: TestEnvironment.logger)

        let getRequest = DynamoDB.GetItemInput(consistentRead: true, key: ["id": .s(id)], tableName: Self.tableName)
        let response = try await Self.dynamoDB.getItem(getRequest, type: TestObject.self, decoder: decoder, logger: TestEnvironment.logger)

        XCTAssertEqual(test, response.item)
    }

    func testCodableUpdate() async throws {
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

        let putRequest = DynamoDB.PutItemCodableInput(item: test, tableName: Self.tableName)
        _ = try await Self.dynamoDB.putItem(putRequest, logger: TestEnvironment.logger)
        let updateRequest = DynamoDB.UpdateItemCodableInput(key: ["id"], tableName: Self.tableName, updateItem: nameUpdate)
        _ = try await Self.dynamoDB.updateItem(updateRequest, logger: TestEnvironment.logger)

        // update
        let additionalAttributes1 = AdditionalAttributes(oldAge: 32)
        let conditionExpression1 = "attribute_exists(#id) AND #age = :oldAge"
        let nameUpdateWithAge1 = NameUpdateWithAge(id: id, name: "David", surname: "Jones", age: 33)
        let updateRequest1 = try DynamoDB.UpdateItemCodableInput(
            additionalAttributes: additionalAttributes1,
            conditionExpression: conditionExpression1,
            key: ["id"],
            tableName: Self.tableName,
            updateItem: nameUpdateWithAge1
        )
        _ = try await Self.dynamoDB.updateItem(updateRequest1, logger: TestEnvironment.logger)

        do {
            let additionalAttributes = AdditionalAttributes(oldAge: 34)
            let nameUpdateWithAge = NameUpdateWithAge(id: id, name: "David", surname: "Jones", age: 35)
            let updateRequest = try DynamoDB.UpdateItemCodableInput(
                additionalAttributes: additionalAttributes,
                conditionExpression: "attribute_exists(#id) AND #age = :oldAge",
                key: ["id"],
                returnValuesOnConditionCheckFailure: .allOld,
                tableName: Self.tableName,
                updateItem: nameUpdateWithAge
            )
            _ = try await Self.dynamoDB.updateItem(updateRequest, logger: TestEnvironment.logger)
            XCTFail("Should have thrown error because conditionExpression is not met")
        } catch let error as DynamoDBErrorType where error == .conditionalCheckFailedException {
            let conditionError = try XCTUnwrap(error.context?.extendedError as? DynamoDB.ConditionalCheckFailedException)
            XCTAssertEqual(conditionError.item?["age"], .n("33"))
        } catch {
            XCTFail("Wrong error thrown")
        }
        let getRequest = DynamoDB.GetItemInput(consistentRead: true, key: ["id": .s(id)], tableName: Self.tableName)
        let response = try await Self.dynamoDB.getItem(getRequest, type: TestObject.self, logger: TestEnvironment.logger)

        XCTAssertEqual("David", response.item?.name)
        XCTAssertEqual("Jones", response.item?.surname)
        XCTAssertEqual(33, response.item?.age)
        XCTAssertEqual("1 Park Lane", response.item?.address)
        XCTAssertEqual(["cat", "dog"], response.item?.pets)
    }

    func testCodableQuery() async throws {
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
            try await Self.dynamoDB.putItem(.init(item: $0, tableName: Self.tableWithValueName), logger: TestEnvironment.logger)
        }
        let request = DynamoDB.QueryInput(
            consistentRead: true,
            expressionAttributeValues: [":id": .s("testCodableQuery"), ":version": .n("2")],
            keyConditionExpression: "id = :id and version >= :version",
            tableName: Self.tableWithValueName
        )
        let response = try await Self.dynamoDB.query(request, type: TestObject.self, logger: TestEnvironment.logger)

        XCTAssertEqual(testItems[1], response.items?[0])
        XCTAssertEqual(testItems[2], response.items?[1])
    }

    func testCodableQueryPaginator() async throws {
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
            try await Self.dynamoDB.putItem(.init(item: $0, tableName: Self.tableWithValueName), logger: TestEnvironment.logger)
        }

        let request = DynamoDB.QueryInput(
            consistentRead: true,
            expressionAttributeValues: [":id": .s("testCodableQueryPaginator"), ":version": .n("2")],
            keyConditionExpression: "id = :id and version >= :version",
            limit: 3,
            tableName: Self.tableWithValueName
        )
        let results = try await Self.dynamoDB.queryPaginator(request, type: TestObject.self, logger: TestEnvironment.logger)
            .reduce([]) { $0 + ($1.items ?? []) }

        XCTAssertEqual(testItems[1], results[0])
        XCTAssertEqual(testItems[2], results[1])
        XCTAssertEqual(testItems[3], results[2])
        XCTAssertEqual(testItems[4], results[3])
    }

    func testCodableScan() async throws {
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
            try await Self.dynamoDB.putItem(.init(item: $0, tableName: Self.tableWithValueName), logger: TestEnvironment.logger)
        }

        let request = DynamoDB.ScanInput(
            consistentRead: true,
            expressionAttributeValues: [":message": .s("Message 2")],
            filterExpression: "message = :message",
            tableName: Self.tableWithValueName
        )
        let response = try await Self.dynamoDB.scan(request, type: TestObject.self, logger: TestEnvironment.logger)

        XCTAssertEqual(testItems[1], response.items?[0])
    }
}
