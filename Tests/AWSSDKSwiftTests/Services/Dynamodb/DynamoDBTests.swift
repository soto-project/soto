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

    struct TestData {
        
        var tableName: String
        
        init(_ testName: String) {
            let testName = testName.lowercased().filter { return $0.isLetter }
            self.tableName = "\(testName)-tablename"
        }
    }

    var client = DynamoDB(
            accessKeyId: "key",
            secretAccessKey: "secret",
            region: .apnortheast1,
            endpoint: "http://localhost:4569"
        )


    func setUp(_ testData: TestData) throws {
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
            tableName: testData.tableName
        )
        _ = try client.createTable(createTableInput).wait()

        let putItemInput = DynamoDB.PutItemInput(
            item: [
                "hashKey": DynamoDB.AttributeValue(s: "hello"),
                "rangeKey": DynamoDB.AttributeValue(s: "world")
            ],
            tableName: testData.tableName
        )
        _ = try client.putItem(putItemInput).wait()
    }

    func tearDown(_ testData: TestData) throws {
        let input = DynamoDB.DeleteTableInput(tableName: testData.tableName)
        _ = try client.deleteTable(input).wait()
    }

    func testGetObject() {
        attempt {
            
            let testData = TestData(#function)
            try setUp(testData)

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
            
            try tearDown(testData)
        }
    }

    static var allTests : [(String, (DynamoDBTests) -> () throws -> Void)] {
        return [
            ("testGetObject", testGetObject),
        ]
    }
}
