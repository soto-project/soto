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
import NIO
@testable import SotoDynamoDB
import XCTest

// testing json service

class DynamoDBTests: XCTestCase {
    static var client: AWSClient!
    static var dynamoDB: DynamoDB!

    override class func setUp() {
        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }

        Self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middlewares: TestEnvironment.middlewares, httpClientProvider: .createNew)
        Self.dynamoDB = DynamoDB(
            client: DynamoDBTests.client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
    }

    override class func tearDown() {
        XCTAssertNoThrow(try Self.client.syncShutdown())
    }

    func createTable(name: String, hashKey: String) -> EventLoopFuture<Void> {
        let input = DynamoDB.CreateTableInput(
            attributeDefinitions: [.init(attributeName: hashKey, attributeType: .s)],
            keySchema: [.init(attributeName: hashKey, keyType: .hash)],
            provisionedThroughput: .init(readCapacityUnits: 5, writeCapacityUnits: 5),
            tableName: name
        )
        return Self.dynamoDB.createTable(input)
            .map { response in
                XCTAssertEqual(response.tableDescription?.tableName, name)
                return
            }
            .flatMapErrorThrowing { error in
                switch error {
                case let error as DynamoDBErrorType where error == .resourceInUseException:
                    print("Table (\(name)) already exists")
                    return
                default:
                    throw error
                }
            }
            .flatMap { (_) -> EventLoopFuture<Void> in
                return Self.dynamoDB.waitUntilTableExists(.init(tableName: name))
            }
    }

    func waitForActiveTable(name: String, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let promise = eventLoop.makePromise(of: Void.self)
        func waitForActiveTableInternal(waitTime: TimeAmount) {
            let scheduled = eventLoop.flatScheduleTask(in: waitTime) {
                return Self.dynamoDB.describeTable(.init(tableName: name))
            }
            scheduled.futureResult.map { response in
                if response.table?.tableStatus == .active {
                    promise.succeed(())
                } else {
                    waitForActiveTableInternal(waitTime: waitTime + .seconds(1))
                }
            }.cascadeFailure(to: promise)
        }
        waitForActiveTableInternal(waitTime: .seconds(1))
        return promise.futureResult
    }

    func deleteTable(name: String) -> EventLoopFuture<Void> {
        let input = DynamoDB.DeleteTableInput(tableName: name)
        return Self.dynamoDB.deleteTable(input).map { _ in }
    }

    func putItem(tableName: String, values: [String: Any]) -> EventLoopFuture<DynamoDB.PutItemOutput> {
        let input = DynamoDB.PutItemInput(item: values.mapValues { DynamoDB.AttributeValue(any: $0) }, tableName: tableName)
        return Self.dynamoDB.putItem(input)
    }

    func getItem(tableName: String, keys: [String: String]) -> EventLoopFuture<DynamoDB.GetItemOutput> {
        let input = DynamoDB.GetItemInput(consistentRead: true, key: keys.mapValues { DynamoDB.AttributeValue.s($0) }, tableName: tableName)
        return Self.dynamoDB.getItem(input)
    }

    // MARK: TESTS

    func testCreateDeleteTable() {
        let tableName = TestEnvironment.generateResourceName()
        let response = self.createTable(name: tableName, hashKey: "ID")
            .flatAlways { _ in
                return self.deleteTable(name: tableName)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testGetObject() {
        let tableName = TestEnvironment.generateResourceName()
        let response = self.createTable(name: tableName, hashKey: "ID")
            .flatMap { _ in
                return self.putItem(tableName: tableName, values: ["ID": "first", "First name": "John", "Surname": "Smith"])
            }
            .flatMap { (_) -> EventLoopFuture<DynamoDB.GetItemOutput> in
                return self.getItem(tableName: tableName, keys: ["ID": "first"])
            }
            .map { response -> Void in
                XCTAssertEqual(response.item?["ID"], .s("first"))
                XCTAssertEqual(response.item?["First name"], .s("John"))
                XCTAssertEqual(response.item?["Surname"], .s("Smith"))
            }
            .flatAlways { _ in
                return self.deleteTable(name: tableName)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testDataItem() {
        let tableName = TestEnvironment.generateResourceName()
        let data = Data("testdata".utf8)
        let response = self.createTable(name: tableName, hashKey: "ID")
            .flatMap { _ in
                return self.putItem(tableName: tableName, values: ["ID": "1", "data": data])
            }
            .flatMap { (_) -> EventLoopFuture<DynamoDB.GetItemOutput> in
                return self.getItem(tableName: tableName, keys: ["ID": "1"])
            }
            .map { response -> Void in
                XCTAssertEqual(response.item?["ID"], .s("1"))
                XCTAssertEqual(response.item?["data"], .b(data))
            }
            .flatAlways { _ in
                return self.deleteTable(name: tableName)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testNumberSetItem() {
        let tableName = TestEnvironment.generateResourceName()
        let response = self.createTable(name: tableName, hashKey: "ID")
            .flatMap { _ in
                return self.putItem(tableName: tableName, values: ["ID": "1", "numbers": [2, 4.001, -6, 8]])
            }
            .flatMap { (_) -> EventLoopFuture<DynamoDB.GetItemOutput> in
                return self.getItem(tableName: tableName, keys: ["ID": "1"])
            }
            .flatMapThrowing { response -> Void in
                XCTAssertEqual(response.item?["ID"], .s("1"))
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
            .flatAlways { _ in
                return self.deleteTable(name: tableName)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testDescribeEndpoints() {
        let response = Self.dynamoDB.describeEndpoints(.init())
        XCTAssertNoThrow(try response.wait())
    }

    func testError() {
        let response = Self.dynamoDB.describeTable(.init(tableName: "non-existent-table"))
        XCTAssertThrowsError(try response.wait()) { error in
            switch error {
            case let error as DynamoDBErrorType where error == .resourceNotFoundException:
                XCTAssertNotNil(error.message)
            default:
                XCTFail("Wrong error: \(error)")
            }
        }
    }
}

extension DynamoDB.AttributeValue {
    init(any: Any) {
        switch any {
        case let data as Data:
            self = .b(data) // self.init(b: data)
        case let bool as Bool:
            self = .bool(bool) // self.init(bool: bool)
        case let int as Int:
            self = .n(int.description) // self.init(n: int.description)
        case let ints as [Int]:
            self = .ns(ints.map { $0.description }) // self.init(ns: ints.map {$0.description})
        case let float as Float:
            self = .n(float.description) // self.init(n: float.description)
        case let double as Double:
            self = .n(double.description) // self.init(n: double.description)
        case let doubles as [Double]:
            self = .ns(doubles.map { $0.description }) // self.init(ns: doubles.map {$0.description})
        case let string as String:
            self = .s(string) // self.init(s: string)
        default:
            self = .s(String(reflecting: any)) // self.init(s: String(reflecting: any))
        }
    }
}
