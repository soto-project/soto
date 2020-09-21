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

// testing json service

class DynamoDBTests: XCTestCase {

    var client = DynamoDB(
        accessKeyId: "key",
        secretAccessKey: "secret",
        region: .useast1,
        endpoint: ProcessInfo.processInfo.environment["DYNAMODB_ENDPOINT"] ?? "http://localhost:4566",
        middlewares: [AWSLoggingMiddleware()]
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
                    .init(attributeName: "rangeKey", attributeType: .s)
                ],
                keySchema: [
                    DynamoDB.KeySchemaElement(attributeName: "hashKey", keyType: .hash),
                    DynamoDB.KeySchemaElement(attributeName: "rangeKey", keyType: .range)
                ],
                provisionedThroughput: DynamoDB.ProvisionedThroughput(readCapacityUnits: 10, writeCapacityUnits: 10),
                tableName: self.tableName
            )
            _ = try client.createTable(createTableInput).wait()

            let putItemInput = DynamoDB.PutItemInput(
                item: [
                    "hashKey": DynamoDB.AttributeValue(s: "hello"),
                    "rangeKey": DynamoDB.AttributeValue(s: "world")
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
                    "rangeKey": DynamoDB.AttributeValue(s: "world")
                ],
                tableName: testData.tableName
            )

            let output = try client.getItem(input).wait()
            XCTAssertEqual(output.item?["hashKey"]?.s, "hello")
            XCTAssertEqual(output.item?["rangeKey"]?.s, "world")
        }
    }

    static var allTests : [(String, (DynamoDBTests) -> () throws -> Void)] {
        return [
            ("testGetObject", testGetObject),
        ]
    }
}
