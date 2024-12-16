//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2021 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import XCTest

@testable import SotoTimestreamWrite

// testing query service

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class TimestreamWriteTests: XCTestCase {
    var client: AWSClient!
    var ts: TimestreamWrite!

    override func setUp() {
        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }

        self.client = AWSClient(
            credentialProvider: TestEnvironment.credentialProvider,
            middleware: TestEnvironment.middlewares,
            logger: Logger(label: "Soto")
        )
        self.ts = TimestreamWrite(
            client: self.client,
            region: .euwest1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
    }

    override func tearDown() {
        XCTAssertNoThrow(try self.client.syncShutdown())
    }

    func createTable(named name: String, databaseName: String) async throws {
        do {
            _ = try await self.ts.createTable(.init(databaseName: databaseName, tableName: name))
        } catch let error as TimestreamWriteErrorType where error == .conflictException {
            return
        }
    }

    /// create SNS topic with supplied name and run supplied closure
    func testDatabase(name: String, test: @escaping (String) async throws -> Void) async throws {
        try await XCTTestAsset {
            do {
                let request = TimestreamWrite.CreateDatabaseRequest(databaseName: name)
                _ = try await self.ts.createDatabase(request)
            } catch let error as TimestreamWriteErrorType where error == .conflictException {}
            return name
        } test: {
            try await test($0)
        } delete: {
            try await self.ts.deleteDatabase(.init(databaseName: $0))
        }
    }

    func testCreateDeleteDatabase() async throws {
        // doesnt work with LocalStack
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)

        let name = TestEnvironment.generateResourceName()
        try await self.testDatabase(name: name) { _ in }
    }

    func testCreateTableAndWrite() async throws {
        // doesnt work with LocalStack
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)

        let name = TestEnvironment.generateResourceName()
        let tableName = "\(name)-table"

        try await self.testDatabase(name: name) { name in
            do {
                try await self.createTable(named: tableName, databaseName: name)
                let record = TimestreamWrite.Record(
                    dimensions: [.init(name: "Speed", value: "24.3")],
                    measureName: "Speed",
                    measureValue: "24.3",
                    measureValueType: .double,
                    time: "\(Int(Date().timeIntervalSince1970))",
                    timeUnit: .seconds
                )
                _ = try await self.ts.writeRecords(.init(databaseName: name, records: [record], tableName: tableName))
                try await self.ts.deleteTable(.init(databaseName: name, tableName: tableName))
            } catch {
                XCTFail("\(error)")
                try await self.ts.deleteTable(.init(databaseName: name, tableName: tableName))
            }
        }
    }
}
