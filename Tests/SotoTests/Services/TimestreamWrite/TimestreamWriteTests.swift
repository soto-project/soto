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

@testable import SotoTimestreamWrite
import XCTest

// testing query service

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

    func createDatabase(named name: String) -> EventLoopFuture<Void> {
        let request = TimestreamWrite.CreateDatabaseRequest(databaseName: name)
        return self.ts.createDatabase(request)
            .map { _ in }
            .flatMapErrorThrowing { error in
                switch error {
                case let error as TimestreamWriteErrorType where error == .conflictException:
                    return
                default:
                    throw error
                }
            }
    }

    func createTable(named name: String, databaseName: String) -> EventLoopFuture<Void> {
        return self.ts.createTable(.init(databaseName: databaseName, tableName: name))
            .map { _ in }
            .flatMapErrorThrowing { error in
                switch error {
                case let error as TimestreamWriteErrorType where error == .conflictException:
                    return
                default:
                    throw error
                }
            }
    }

    func deleteDatabase(named name: String) -> EventLoopFuture<Void> {
        return self.ts.deleteDatabase(.init(databaseName: name))
    }

    func testCreateDeleteDatabase() {
        guard !TestEnvironment.isUsingLocalstack else { return }
        let name = TestEnvironment.generateResourceName()
        let response = self.createDatabase(named: name)
            .flatMap { _ in
                self.deleteDatabase(named: name)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testCreateTableAndWrite() {
        guard !TestEnvironment.isUsingLocalstack else { return }
        let name = TestEnvironment.generateResourceName()
        let tableName = "\(name)-table"
        let response = self.createDatabase(named: name)
            .flatMap { _ in
                self.createTable(named: tableName, databaseName: name)
                    .flatMap { _ -> EventLoopFuture<Void> in
                        let record = TimestreamWrite.Record(
                            dimensions: [.init(name: "Speed", value: "24.3")],
                            measureName: "Speed",
                            measureValue: "24.3",
                            measureValueType: .double,
                            time: "\(Int(Date().timeIntervalSince1970))",
                            timeUnit: .seconds
                        )
                        return self.ts.writeRecords(.init(databaseName: name, records: [record], tableName: tableName))
                    }
                    .flatAlways { _ in
                        self.ts.deleteTable(.init(databaseName: name, tableName: tableName))
                    }
            }
            .flatAlways { _ in
                self.deleteDatabase(named: name)
            }
        XCTAssertNoThrow(try response.wait())
    }
}
