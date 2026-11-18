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

import AsyncHTTPClient
import Foundation
import SotoEC2
import Testing

// testing EC2 service

@Suite(.awsClient())
struct EC2Tests {
    @Test func testDescribeImages() async throws {
        let ec2 = EC2(client: AWSClientTrait.client, region: .useast1)
        let imageRequest = EC2.DescribeImagesRequest(
            filters: .init([
                EC2.Filter(name: "name", values: ["*ubuntu-18.04-v1.15*"]),
                EC2.Filter(name: "state", values: ["available"]),
            ])
        )
        _ = try await ec2.with(timeout: .seconds(120)).describeImages(imageRequest)
    }

    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Localstack returns unknown values"))
    func testDescribeInstanceTypes() async throws {
        try await testAsset {
            let httpClient = HTTPClient()
            let awsClient = AWSClient(
                credentialProvider: TestEnvironment.credentialProvider,
                middleware: TestEnvironment.middlewares,
                httpClient: httpClient
            )
            return (http: httpClient, aws: awsClient)
        } test: { clients in
            let ec2 = EC2(client: clients.aws, region: .useast1)
            let describeTypesPaginator = ec2.describeInstanceTypesPaginator(
                filters: [
                    EC2.Filter(name: "bare-metal", values: ["true"])
                ],
                logger: TestEnvironment.logger
            )
            _ = try await describeTypesPaginator.reduce([]) { $0 + ($1.instanceTypes ?? []) }
        } delete: { clients in
            try await clients.aws.shutdown()
            try await clients.http.shutdown()
        }
    }

    @Test func testDualStack() async throws {
        let ec2 = EC2(client: AWSClientTrait.client, region: .euwest1, options: .useDualStackEndpoint)
        let imageRequest = EC2.DescribeImagesRequest(
            filters: .init([
                EC2.Filter(name: "name", values: ["*ubuntu-18.04-v1.15*"]),
                EC2.Filter(name: "state", values: ["available"]),
            ])
        )
        _ = try await ec2.with(timeout: .seconds(120)).describeImages(imageRequest)
    }

    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Localstack returns the wrong error"))
    func testError() async throws {
        let ec2 = EC2(client: AWSClientTrait.client, region: .useast1)
        await #expect(throws: AWSResponseError(errorCode: "InvalidInstanceID.Malformed")) {
            _ = try await ec2.getConsoleOutput(.init(instanceId: "not-an-instance"))
        }
    }
}
