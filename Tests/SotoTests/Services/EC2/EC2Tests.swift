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

        self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middleware: TestEnvironment.middlewares)
        self.ec2 = EC2(
            client: EC2Tests.client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
    }

    override class func tearDown() {
        XCTAssertNoThrow(try self.client.syncShutdown())
    }

    func testDescribeImages() async throws {
        let imageRequest = EC2.DescribeImagesRequest(
            filters: .init([
                EC2.Filter(name: "name", values: ["*ubuntu-18.04-v1.15*"]),
                EC2.Filter(name: "state", values: ["available"]),
            ])
        )
        _ = try await Self.ec2.with(timeout: .minutes(2)).describeImages(imageRequest)
    }

    func testDescribeInstanceTypes() async throws {
        // Localstack returns unknown values
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)
        // Have to run this with custom HTTPClient as shared HTTPClient decompression
        // throws an error as response expands too much
        try await AWSClient.withAWSClient { awsClient in
            let ec2 = EC2(
                client: awsClient,
                region: .useast1,
                endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
            )
            let describeTypesPaginator = ec2.describeInstanceTypesPaginator(logger: TestEnvironment.logger)
            _ = try await describeTypesPaginator.reduce([]) { $0 + ($1.instanceTypes ?? []) }
        }
    }

    func testDualStack() async throws {
        let ec2 = Self.ec2.with(region: .euwest1, options: .useDualStackEndpoint)
        let imageRequest = EC2.DescribeImagesRequest(
            filters: .init([
                EC2.Filter(name: "name", values: ["*ubuntu-18.04-v1.15*"]),
                EC2.Filter(name: "state", values: ["available"]),
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

extension AWSResponseError {
    public static func == (lhs: AWSResponseError, rhs: AWSResponseError) -> Bool {
        lhs.errorCode == rhs.errorCode
    }
}

#if hasFeature(RetroactiveAttribute)
extension AWSResponseError: @retroactive Equatable {}
#else
extension AWSResponseError: Equatable {}
#endif

extension AWSClient {
    static func withAWSClient<Value>(
        credentialProvider: CredentialProviderFactory = .default,
        middleware: some AWSMiddlewareProtocol = AWSMiddleware { request, context, next in
            try await next(request, context)
        },
        _ operation: (AWSClient) async throws -> Value
    ) async throws -> Value {
        let httpClient = HTTPClient()
        let awsClient = AWSClient(credentialProvider: credentialProvider, middleware: middleware, httpClient: httpClient)
        let value: Value
        do {
            value = try await operation(awsClient)
        } catch {
            try? await awsClient.shutdown()
            try? await httpClient.shutdown()
            throw error
        }
        try await awsClient.shutdown()
        try await httpClient.shutdown()
        return value
    }
}
