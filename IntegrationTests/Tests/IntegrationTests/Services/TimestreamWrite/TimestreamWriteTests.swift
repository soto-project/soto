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

import Foundation
import Testing

@testable import SotoTimestreamWrite

// testing query service
@Suite(
    .awsClient(),
    .disabled(if: TestEnvironment.isUsingLocalstack, "TimestreamWrite is not available while using Localstack")
)
struct TimestreamWriteTests {
    /// create Timestream database with supplied name and run supplied closure
    func testDatabase(name: String, ts: TimestreamWrite, test: @escaping (String) async throws -> Void) async throws {
        try await testAsset {
            do {
                _ = try await ts.createDatabase(databaseName: name)
            } catch let error as TimestreamWriteErrorType {
                switch error.error {
                case .conflictException:
                    break
                default:
                    throw error
                }
            }
            return name
        } test: {
            try await test($0)
        } delete: {
            try await ts.deleteDatabase(.init(databaseName: $0))
        }
    }

    @Test func testCreateDeleteDatabase() async throws {
        let name = TestEnvironment.generateResourceName()
        let ts = TimestreamWrite(client: AWSClientTrait.client, region: .euwest1)
        try await self.testDatabase(name: name, ts: ts) { _ in }
    }

    @Test func testCreateTableAndWrite() async throws {
        let name = TestEnvironment.generateResourceName()
        let tableName = "\(name)-table"
        let ts = TimestreamWrite(client: AWSClientTrait.client, region: .euwest1)

        try await self.testDatabase(name: name, ts: ts) { name in
            try await testAsset {
                do {
                    _ = try await ts.createTable(databaseName: name, tableName: tableName)
                    return name
                } catch let error as TimestreamWriteErrorType {
                    switch error.error {
                    case .conflictException:
                        return name
                    default:
                        throw error
                    }
                }
            } test: { name in
                let record = TimestreamWrite.Record(
                    dimensions: [.init(name: "Speed", value: "24.3")],
                    measureName: "Speed",
                    measureValue: "24.3",
                    measureValueType: .double,
                    time: "\(Int(Date().timeIntervalSince1970))",
                    timeUnit: .seconds
                )
                _ = try await ts.writeRecords(.init(databaseName: name, records: [record], tableName: tableName))
            } delete: { name in
                try await ts.deleteTable(databaseName: name, tableName: tableName)
            }
        }
    }
}
