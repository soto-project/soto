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

import Logging
import NIOConcurrencyHelpers
import SotoS3
import SotoSNS
import Testing

@testable import SotoSTS

// testing query service
@Suite(.awsClient())
struct STSTests {
    @Test func testGetCallerIdentity() async throws {
        let sts = STS(client: AWSClientTrait.client, region: .useast1)
        _ = try await sts.getCallerIdentity()
    }

    @Test func testSTSCredentialProviderShutdown() async throws {
        let request = STS.AssumeRoleRequest(roleArn: "arn:aws:iam::000000000000:role/Admin", roleSessionName: "test-session")
        let credentialProvider = CredentialProviderFactory.stsAssumeRole(request: request, region: .euwest2)
        let client = AWSClient(credentialProvider: credentialProvider, logger: TestEnvironment.logger)
        try await client.shutdown()
    }

    @Test func testSTSCredentialProviderClosure() async throws {
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
            #expect(request.roleSessionName == value?.roleSessionName)
        }
    }

    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Cannot verify federation tokens with Localstack"))
    func testFederationToken() async throws {
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
        try await testAsset {
            AWSClient(
                credentialProvider: .stsFederationToken(
                    request: federationRequest,
                    credentialProvider: TestEnvironment.credentialProvider,
                    region: .useast1
                ),
                logger: Logger(label: "Soto")
            )
        } test: { client in
            let s3 = S3(client: client, region: .euwest1)
            _ = try await s3.listBuckets(.init())
            let sns = SNS(client: client)
            let error = await #expect(throws: SNSErrorType.self) {
                _ = try await sns.listTopics(.init())
            }
            switch error?.error {
            case .authorizationErrorException:
                break
            default:
                Issue.record()
            }
        } delete: { client in
            try await client.shutdown()
        }
    }

    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Localstack error is inconsistent with AWS"))
    func testError() async throws {
        let sts = STS(client: AWSClientTrait.client, region: .useast1)
        let error = await #expect(throws: STSErrorType.self) {
            let request = STS.AssumeRoleWithWebIdentityRequest(
                roleArn: "arn:aws:iam::000000000000:role/Admin",
                roleSessionName: "now",
                webIdentityToken: "webtoken"
            )
            do {
                _ = try await sts.assumeRoleWithWebIdentity(request, logger: TestEnvironment.logger)
            } catch {
                throw error
            }
        }
        #expect(error?.error == .invalidIdentityTokenException)
    }
}
