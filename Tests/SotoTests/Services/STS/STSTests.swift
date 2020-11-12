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

import SotoS3
import SotoSNS
@testable import SotoSTS
import XCTest

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

        Self.client = AWSClient(
            credentialProvider: TestEnvironment.credentialProvider,
            middlewares: TestEnvironment.middlewares,
            httpClientProvider: .createNew,
            logger: Logger(label: "Soto")
        )
        Self.sts = STS(
            client: STSTests.client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
    }

    override class func tearDown() {
        XCTAssertNoThrow(try Self.client.syncShutdown())
    }

    func testGetCallerIdentity() {
        let response = Self.sts.getCallerIdentity(.init())
        XCTAssertNoThrow(try response.wait())
    }

    func testSTSCredentialProviderShutdown() {
        let credentialProvider = CredentialProviderFactory.stsAssumeRole(request: .init(roleArn: "arn:aws:iam::000000000000:role/Admin", roleSessionName: "test-session"), region: .euwest2)
        let client = AWSClient(credentialProvider: credentialProvider, httpClientProvider: .createNew, logger: Logger(label: "Soto"))
        XCTAssertNoThrow(try client.syncShutdown())
    }

    func testSTSCredentialProviderClosure() {
        let request = STS.AssumeRoleRequest(roleArn: "arn:aws:iam::000000000000:role/Admin", roleSessionName: "test-session")
        var returnedRequest: STS.AssumeRoleRequest?
        let credentialProvider = CredentialProviderFactory.stsAssumeRole(region: .euwest2) { eventLoop in
            return eventLoop.scheduleTask(in: .milliseconds(500)) {
                returnedRequest = request
                return request
            }.futureResult
        }
        let client = AWSClient(credentialProvider: credentialProvider, httpClientProvider: .createNew, logger: Logger(label: "Soto"))
        XCTAssertNoThrow(try client.syncShutdown())
        XCTAssertEqual(request.roleSessionName, returnedRequest?.roleSessionName)
    }

    func testFederationToken() {
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
            httpClientProvider: .createNew,
            logger: Logger(label: "Soto")
        )
        defer { XCTAssertNoThrow(try client.syncShutdown()) }
        let s3 = S3(client: client, region: .euwest1)
        XCTAssertNoThrow(try s3.listBuckets().wait())
        let sns = SNS(client: client)
        XCTAssertThrowsError(try sns.listTopics(.init()).wait()) { error in
            switch error {
            case let error as SNSErrorType where error == .authorizationErrorException:
                break
            default:
                XCTFail("Wrong error \(error)")
            }
        }
    }

    func testError() {
        let request = STS.AssumeRoleWithWebIdentityRequest(roleArn: "arn:aws:iam::000000000000:role/Admin", roleSessionName: "now", webIdentityToken: "webtoken")
        let response = Self.sts.assumeRoleWithWebIdentity(request)
            .map { _ in }
            .flatMapErrorThrowing { error in
                switch error {
                case let error as STSErrorType where error == .invalidIdentityTokenException:
                    XCTAssertNotNil(error.message)
                default:
                    throw error
                }
            }
        XCTAssertNoThrow(try response.wait())
    }
}
