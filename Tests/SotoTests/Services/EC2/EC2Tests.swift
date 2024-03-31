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

@testable import SotoEC2

// testing EC2 service

class EC2Tests: XCTestCase {
    static var client: AWSClient!
    static var ec2: EC2!

    override class func setUp() {
        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }

        Self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middleware: TestEnvironment.middlewares, httpClientProvider: .createNew)
        Self.ec2 = EC2(
            client: EC2Tests.client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
    }

    override class func tearDown() {
        XCTAssertNoThrow(try Self.client.syncShutdown())
    }

    func testDescribeImages() async throws {
        let imageRequest = EC2.DescribeImagesRequest(
            filters: .init([
                EC2.Filter(name: "name", values: ["*ubuntu-18.04-v1.15*"]),
                EC2.Filter(name: "state", values: ["available"])
            ])
        )
        _ = try await Self.ec2.with(timeout: .minutes(2)).describeImages(imageRequest)
    }

    func testDescribeInstanceTypes() async throws {
        // Localstack returns unknown values
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)
        let describeTypesPaginator = Self.ec2.describeInstanceTypesPaginator(.init(), logger: TestEnvironment.logger)
        _ = try await describeTypesPaginator.reduce([]) { $0 + ($1.instanceTypes ?? []) }
    }

    func testDualStack() async throws {
        let ec2 = Self.ec2.with(region: .euwest1, options: .useDualStackEndpoint)
        let imageRequest = EC2.DescribeImagesRequest(
            filters: .init([
                EC2.Filter(name: "name", values: ["*ubuntu-18.04-v1.15*"]),
                EC2.Filter(name: "state", values: ["available"])
            ])
        )
        _ = try await ec2.with(timeout: .minutes(2)).describeImages(imageRequest)
    }

    func testError() async throws {
        // This doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }
        await XCTAsyncExpectError(AWSResponseError(errorCode: "InvalidInstanceID.Malformed")) {
            _ = try await Self.ec2.getConsoleOutput(.init(instanceId: "not-an-instance"))
        }
    }
}

extension AWSResponseError: Equatable {
    public static func == (lhs: SotoCore.AWSResponseError, rhs: SotoCore.AWSResponseError) -> Bool {
        return lhs.errorCode == rhs.errorCode
    }
}
