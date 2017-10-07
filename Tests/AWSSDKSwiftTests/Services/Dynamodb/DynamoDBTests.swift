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
@testable import AWSSDKSwift

class DynamoDBTests: XCTestCase {
    static var allTests : [(String, (DynamoDBTests) -> () throws -> Void)] {
        return [
            ("testGetObject", testGetObject),
        ]
    }
    
    var client: Dynamodb {
        return Dynamodb(
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
        let createTableInput = Dynamodb.CreateTableInput(
            attributeDefinitions: [
                Dynamodb.AttributeDefinition(attributeType: .s, attributeName: "hashKey"),
                Dynamodb.AttributeDefinition(attributeType: .s, attributeName: "rangeKey")
            ],
            keySchema: [
                Dynamodb.KeySchemaElement(attributeName: "hashKey", keyType: .hash),
                Dynamodb.KeySchemaElement(attributeName: "rangeKey", keyType: .range)
            ],
            provisionedThroughput: Dynamodb.ProvisionedThroughput(writeCapacityUnits: 10, readCapacityUnits: 10),
            tableName: tableName
        )
        _ = try client.createTable(createTableInput)
        
        let putItemInput = Dynamodb.PutItemInput(
            item: [
                "hashKey": Dynamodb.AttributeValue(s: "hello"),
                "rangeKey": Dynamodb.AttributeValue(s: "world")
            ],
            tableName: tableName
        )
        _ = try client.putItem(putItemInput)
    }
    
    override func tearDown() {
        do {
            let input = Dynamodb.DeleteTableInput(tableName: tableName)
            _ = try client.deleteTable(input)
        } catch {
            print(error)
        }
    }
    
    func testGetObject() {
        do {
            try prepare()
            let input = Dynamodb.GetItemInput(
                key: [
                    "hashKey": Dynamodb.AttributeValue(s: "hello"),
                    "rangeKey": Dynamodb.AttributeValue(s: "world")
                ],
                tableName: tableName
            )
            
            let output = try client.getItem(input)
            XCTAssertEqual(output.item?["hashKey"]?.s, "hello")
            XCTAssertEqual(output.item?["rangeKey"]?.s, "world")
        } catch {
            XCTFail("\(error)")
        }
    }
}

