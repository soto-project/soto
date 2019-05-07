//
//  DynamoDBTests.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/21.
//
//

import Foundation
import Dispatch
import XCTest
@testable import DynamoDB

class DynamoDBTests: XCTestCase {
    static var allTests : [(String, (DynamoDBTests) -> () throws -> Void)] {
        return [
            ("testGetObject", testGetObject),
        ]
    }

    var client: DynamoDB {
        return DynamoDB(
            accessKeyId: "key",
            secretAccessKey: "secret",
            region: .apnortheast1,
            endpoint: "http://localhost:8000"
        )
    }

    var tableName: String {
        return "aws-sdk-swift-test-table"
    }

    func prepare() throws {
        let createTableInput = DynamoDB.CreateTableInput(
            attributeDefinitions: [
                DynamoDB.AttributeDefinition(attributeName: "hashKey", attributeType: .s),
                DynamoDB.AttributeDefinition(attributeName: "rangeKey", attributeType: .s)
            ],
            keySchema: [
                DynamoDB.KeySchemaElement(attributeName: "hashKey", keyType: .hash),
                DynamoDB.KeySchemaElement(attributeName: "rangeKey", keyType: .range)
            ],
            provisionedThroughput: DynamoDB.ProvisionedThroughput(readCapacityUnits: 10, writeCapacityUnits: 10),
            tableName: tableName
        )
        _ = try client.createTable(createTableInput)

        let putItemInput = DynamoDB.PutItemInput(
            item: [
                "hashKey": DynamoDB.AttributeValue(s: "hello"),
                "rangeKey": DynamoDB.AttributeValue(s: "world")
            ],
            tableName: tableName
        )
        _ = try client.putItem(putItemInput)
    }

    override func tearDown() {
        do {
            let input = DynamoDB.DeleteTableInput(tableName: tableName)
            _ = try client.deleteTable(input)
        } catch {
            print(error)
        }
    }

    func testGetObject() {
        do {
            try prepare()
            let input = DynamoDB.GetItemInput(
                key: [
                    "hashKey": DynamoDB.AttributeValue(s: "hello"),
                    "rangeKey": DynamoDB.AttributeValue(s: "world")
                ],
                tableName: tableName
            )

            let output = try client.getItem(input).wait()
            XCTAssertEqual(output.item?["hashKey"]?.s, "hello")
            XCTAssertEqual(output.item?["rangeKey"]?.s, "world")
        } catch {
            XCTFail("\(error)")
        }
    }
}
