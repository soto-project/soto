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
        Self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middlewares: TestEnvironment.middlewares, httpClientProvider: .createNew)
        Self.glacier = Glacier(
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

    func testWaiter() {
        guard !TestEnvironment.isUsingLocalstack else { return }
        let vaultName = TestEnvironment.generateResourceName()
        let response = Self.glacier.createVault(.init(accountId: "-", vaultName: vaultName))
            .flatMap { _ in
                Self.glacier.waitUntilVaultExists(.init(accountId: "-", vaultName: vaultName))
            }
            .flatAlways { _ in
                Self.glacier.deleteVault(.init(accountId: "-", vaultName: vaultName))
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testError() throws {
        // doesnt work with LocalStack
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)

        let job = Glacier.JobParameters(description: "Inventory", format: "CSV", type: "inventory-retrieval")
        let inventoryJobInput = Glacier.InitiateJobInput(accountId: "-", jobParameters: job, vaultName: "aws-test-vault-doesnt-exist")
        let response = Self.glacier.initiateJob(inventoryJobInput)
        XCTAssertThrowsError(try response.wait()) { error in
            switch error {
            case let error as GlacierErrorType where error == .resourceNotFoundException:
                XCTAssertNotNil(error.message)
            default:
                XCTFail("Wrong error: \(error)")
            }
        }
    }
}
