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

    // create a buffer of random values. Will always create the same given you supply the same z and w values
    // Random number generator from https://www.codeproject.com/Articles/25172/Simple-Random-Number-Generation
    func createRandomBuffer(_ w: UInt, _ z: UInt, size: Int) -> [UInt8] {
        var z = z
        var w = w
        func getUInt8() -> UInt8 {
            z = 36969 * (z & 65535) + (z >> 16)
            w = 18000 * (w & 65535) + (w >> 16)
            return UInt8(((z << 16) + w) & 0xFF)
        }
        var data = [UInt8](repeating: 0, count: size)
        for i in 0..<size {
            data[i] = getUInt8()
        }
        return data
    }

    func testComputeTreeHash() throws {
        //  create buffer full of random data, use the same seeds to ensure we get the same buffer everytime
        let data = self.createRandomBuffer(23, 4, size: 7 * 1024 * 1024 + 258)

        // create byte buffer
        var byteBuffer = ByteBufferAllocator().buffer(capacity: data.count)
        byteBuffer.writeBytes(data)

        let middleware = GlacierRequestMiddleware(apiVersion: "2012-06-01")
        let treeHash = try middleware.computeTreeHash(byteBuffer)

        XCTAssertEqual(
            treeHash,
            [210, 50, 5, 126, 16, 6, 59, 6, 21, 40, 186, 74, 192, 56, 39, 85, 210, 25, 238, 54, 4, 252, 221, 238, 107, 127, 76, 118, 245, 76, 22, 45]
        )
    }

    func testWaiter() {
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

    func testError() {
        // This doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }
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
