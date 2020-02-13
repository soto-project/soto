//===----------------------------------------------------------------------===//
//
// This source file is part of the AWSSDKSwift open source project
//
// Copyright (c) 2017-2020 the AWSSDKSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of AWSSDKSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import XCTest

@testable import AWSDynamoDB

// testing json service

class DynamoDBTests: XCTestCase {

    var client = DynamoDB(
        accessKeyId: "key",
        secretAccessKey: "secret",
        region: .useast1,
        endpoint: ProcessInfo.processInfo.environment["DYNAMODB_ENDPOINT"] ?? "http://localhost:4569",
        middlewares: (ProcessInfo.processInfo.environment["AWS_ENABLE_LOGGING"] == "true") ? [AWSLoggingMiddleware()] : [],
        httpClientProvider: .createNew
    )

    class TestData {
        var client: DynamoDB
        var tableName: String

        init(_ testName: String, client: DynamoDB) throws {
            let testName = testName.lowercased().filter { return $0.isLetter }
            self.client = client
            self.tableName = "\(testName)-tablename"

            let createTableInput = DynamoDB.CreateTableInput(
                attributeDefinitions: [
                    .init(attributeName: "hashKey", attributeType: .s),
                    .init(attributeName: "rangeKey", attributeType: .s),
                ],
                keySchema: [
                    DynamoDB.KeySchemaElement(attributeName: "hashKey", keyType: .hash),
                    DynamoDB.KeySchemaElement(attributeName: "rangeKey", keyType: .range),
                ],
                provisionedThroughput: DynamoDB.ProvisionedThroughput(readCapacityUnits: 10, writeCapacityUnits: 10),
                tableName: self.tableName
            )
            _ = try client.createTable(createTableInput).wait()

            let putItemInput = DynamoDB.PutItemInput(
                item: [
                    "hashKey": DynamoDB.AttributeValue(s: "hello"),
                    "rangeKey": DynamoDB.AttributeValue(s: "world"),
                ],
                tableName: self.tableName
            )
            _ = try client.putItem(putItemInput).wait()
        }

        deinit {
            attempt {
                let input = DynamoDB.DeleteTableInput(tableName: self.tableName)
                _ = try client.deleteTable(input).wait()
            }
        }
    }

    //MARK: TESTS

    func testGetObject() {
        attempt {

            let testData = try TestData(#function, client: client)

            let input = DynamoDB.GetItemInput(
                key: [
                    "hashKey": DynamoDB.AttributeValue(s: "hello"),
                    "rangeKey": DynamoDB.AttributeValue(s: "world"),
                ],
                tableName: testData.tableName
            )

            let output = try client.getItem(input).wait()
            XCTAssertEqual(output.item?["hashKey"]?.s, "hello")
            XCTAssertEqual(output.item?["rangeKey"]?.s, "world")
        }
    }

    static var allTests: [(String, (DynamoDBTests) -> () throws -> Void)] {
        return [
            ("testGetObject", testGetObject),
        ]
    }
}
