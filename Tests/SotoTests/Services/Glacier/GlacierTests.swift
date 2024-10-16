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
import XCTest

@testable import SotoGlacier

class GlacierTests: XCTestCase {
    static var client: AWSClient!
    static var glacier: Glacier!

    override class func setUp() {
        self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middleware: TestEnvironment.middlewares)
        self.glacier = Glacier(
            client: GlacierTests.client,
            region: .euwest1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )

        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }
    }

    override class func tearDown() {
        XCTAssertNoThrow(try self.client.syncShutdown())
    }

    func testWaiter() async throws {
        guard !TestEnvironment.isUsingLocalstack else { return }
        let vaultName = TestEnvironment.generateResourceName()
        _ = try await Self.glacier.createVault(.init(accountId: "-", vaultName: vaultName))
        try await Self.glacier.waitUntilVaultExists(.init(accountId: "-", vaultName: vaultName))
        try await Self.glacier.deleteVault(.init(accountId: "-", vaultName: vaultName))
    }

    func testError() async throws {
        // doesnt work with LocalStack
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)
        await XCTAsyncExpectError(GlacierErrorType.resourceNotFoundException) {
            let job = Glacier.JobParameters(description: "Inventory", format: "CSV", type: "inventory-retrieval")
            let inventoryJobInput = Glacier.InitiateJobInput(accountId: "-", jobParameters: job, vaultName: "aws-test-vault-doesnt-exist")
            _ = try await Self.glacier.initiateJob(inventoryJobInput)
        }
    }
}
