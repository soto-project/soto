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

#if compiler(>=5.5) && canImport(_Concurrency)

@testable import SotoTimestreamWrite
import XCTest

// testing query service

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
class TimestreamWriteAsyncTests: XCTestCase {
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
            middlewares: TestEnvironment.middlewares,
            httpClientProvider: .createNew,
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

    func createDatabase(named name: String) async throws {
        do {
            let request = TimestreamWrite.CreateDatabaseRequest(databaseName: name)
            _ = try await self.ts.createDatabase(request)
        } catch let error as TimestreamWriteErrorType where error == .conflictException {
            return
        }
    }

    func createTable(named name: String, databaseName: String) async throws {
        do {
            _ = try await self.ts.createTable(.init(databaseName: databaseName, tableName: name))
        } catch let error as TimestreamWriteErrorType where error == .conflictException {
            return
        }
    }

    func deleteDatabase(named name: String) async throws {
        try await self.ts.deleteDatabase(.init(databaseName: name))
    }

    func testCreateDeleteDatabaseAsync() {
        guard !TestEnvironment.isUsingLocalstack else { return }
        let name = TestEnvironment.generateResourceName()

        XCTRunAsyncAndBlock {
            _ = try await self.createDatabase(named: name)
            _ = try await self.deleteDatabase(named: name)
        }
    }

    func testCreateTableAndWriteAsync() {
        guard !TestEnvironment.isUsingLocalstack else { return }
        let name = TestEnvironment.generateResourceName()
        let tableName = "\(name)-table"

        XCTRunAsyncAndBlock {
            _ = try await self.createDatabase(named: name)
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
                try await self.ts.writeRecords(.init(databaseName: name, records: [record], tableName: tableName))
                try await self.ts.deleteTable(.init(databaseName: name, tableName: tableName))
            } catch {
                XCTFail("\(error)")
                try await self.ts.deleteTable(.init(databaseName: name, tableName: tableName))
            }
            _ = try await self.deleteDatabase(named: name)
        }
    }
}

#endif // compiler(>=5.5) && canImport(_Concurrency)
