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

import NIOConcurrencyHelpers
import SotoS3
import SotoSNS
import XCTest

@testable import SotoSTS

// testing query service

class STSTests: XCTestCase {
    static var client: AWSClient!
    static var sts: STS!

    override class func setUp() {
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
        self.sts = STS(
            client: STSTests.client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
    }

    override class func tearDown() {
        XCTAssertNoThrow(try self.client.syncShutdown())
    }

    func testGetCallerIdentity() async throws {
        _ = try await Self.sts.getCallerIdentity(.init())
    }

    func testSTSCredentialProviderShutdown() async throws {
        let request = STS.AssumeRoleRequest(roleArn: "arn:aws:iam::000000000000:role/Admin", roleSessionName: "test-session")
        let credentialProvider = CredentialProviderFactory.stsAssumeRole(request: request, region: .euwest2)
        let client = AWSClient(credentialProvider: credentialProvider, logger: TestEnvironment.logger)
        try await client.shutdown()
    }

    func testSTSCredentialProviderClosure() async throws {
        let request = STS.AssumeRoleRequest(roleArn: "arn:aws:iam::000000000000:role/Admin", roleSessionName: "test-session")
        let returnedRequest: NIOLockedValueBox<STS.AssumeRoleRequest?> = .init(nil)
        let credentialProvider = CredentialProviderFactory.stsAssumeRole(region: .euwest2) {
            try await Task.sleep(nanoseconds: 500_000_000)
            returnedRequest.withLockedValue { value in
                value = request
            }
            return request
        }
        let client = AWSClient(credentialProvider: credentialProvider, logger: TestEnvironment.logger)
        _ = try? await client.credentialProvider.getCredential(logger: TestEnvironment.logger)
        try await client.shutdown()
        returnedRequest.withLockedValue { value in
            XCTAssertEqual(request.roleSessionName, value?.roleSessionName)
        }
    }

    func testFederationToken() async throws {
        // This doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }
        // create a role with this policy
        let policyDocument = """
            {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Action": [
                            "s3:*",
                            "sqs:*"
                        ],
                        "Resource": "*"
                    }
                ]
            }
            """
        let name = TestEnvironment.generateResourceName("federationToken")
        let federationRequest = STS.GetFederationTokenRequest(name: name, policy: policyDocument)
        let client = AWSClient(
            credentialProvider: .stsFederationToken(
                request: federationRequest,
                credentialProvider: TestEnvironment.credentialProvider,
                region: .useast1
            ),
            logger: Logger(label: "Soto")
        )
        do {
            let s3 = S3(client: client, region: .euwest1)
            _ = try await s3.listBuckets(.init())
            let sns = SNS(client: client)
            await XCTAsyncExpectError(SNSErrorType.authorizationErrorException) {
                _ = try await sns.listTopics(.init())
            }
        }
        try await client.shutdown()
    }

    func testError() async throws {
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)
        await XCTAsyncExpectError(STSErrorType.invalidIdentityTokenException) {
            let request = STS.AssumeRoleWithWebIdentityRequest(
                roleArn: "arn:aws:iam::000000000000:role/Admin",
                roleSessionName: "now",
                webIdentityToken: "webtoken"
            )
            _ = try await Self.sts.assumeRoleWithWebIdentity(request, logger: TestEnvironment.logger)
        }
    }
}
