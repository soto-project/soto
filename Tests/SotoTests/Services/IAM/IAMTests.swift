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

import NIOCore
import SotoIAM
import XCTest

// testing query service

class IAMTests: XCTestCase {
    static var client: AWSClient!
    static var iam: IAM!

    override class func setUp() {
        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }

        self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middleware: TestEnvironment.middlewares)
        self.iam = IAM(
            client: IAMTests.client,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
    }

    override class func tearDown() {
        XCTAssertNoThrow(try self.client.syncShutdown())
    }

    /// create SNS topic with supplied name and run supplied closure
    func testUser(
        userName: String,
        tags: [String: String] = [:],
        iam: IAM? = nil,
        test: @escaping (String) async throws -> Void
    ) async throws {
        try await XCTTestAsset {
            try await self.createUser(userName: userName, tags: tags, iam: iam)
            return userName
        } test: {
            try await test($0)
        } delete: {
            try await self.deleteUser(userName: $0, iam: iam)
        }
    }

    func createUser(userName: String, tags: [String: String] = [:], iam: IAM? = nil) async throws {
        let iam: IAM = iam ?? Self.iam
        let request = IAM.CreateUserRequest(tags: tags.map { return IAM.Tag(key: $0.key, value: $0.value) }, userName: userName)
        do {
            let response = try await iam.createUser(request, logger: TestEnvironment.logger)
            XCTAssertEqual(response.user?.userName, userName)
        } catch let error as IAMErrorType where error == .entityAlreadyExistsException {
            print("User (\(userName)) already exists")
        }
        try await iam.waitUntilUserExists(.init(userName: userName))
    }

    func deleteUser(userName: String, iam: IAM? = nil) async throws {
        let iam: IAM = iam ?? Self.iam
        let request = IAM.ListUserPoliciesRequest(userName: userName)
        let response = try await iam.listUserPolicies(request, logger: TestEnvironment.logger)
        // add stall to avoid throttling errors.
        try await Task.sleep(nanoseconds: 2_000_000_000)
        for policyName in response.policyNames {
            let deletePolicy = IAM.DeleteUserPolicyRequest(policyName: policyName, userName: userName)
            try await iam.deleteUserPolicy(deletePolicy, logger: TestEnvironment.logger)
        }
        try await iam.deleteUser(.init(userName: userName), logger: TestEnvironment.logger)
    }

    // MARK: TESTS

    func testCreateDeleteUser() async throws {
        let username = TestEnvironment.generateResourceName()
        try await self.testUser(userName: username) { _ in }
    }

    func testFIPSEndpoint() async throws {
        let iam = Self.iam.with(options: .useFipsEndpoint)
        let username = TestEnvironment.generateResourceName()
        try await self.testUser(userName: username, iam: iam) { _ in }
    }

    func testSetGetPolicy() async throws {
        // put a policy on the user
        let policyDocument = """
            {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Action": [
                            "sns:*",
                            "s3:*",
                            "sqs:*"
                        ],
                        "Resource": "*"
                    }
                ]
            }
            """
        let username = TestEnvironment.generateResourceName()
        try await self.testUser(userName: username) { _ in
            let user = try await Self.iam.getUser(.init(userName: username), logger: TestEnvironment.logger)
            let request = IAM.PutUserPolicyRequest(
                policyDocument: policyDocument,
                policyName: "testSetGetPolicy",
                userName: user.user.userName
            )
            try await Self.iam.putUserPolicy(request, logger: TestEnvironment.logger)
            let getPolicyRequest = IAM.GetUserPolicyRequest(policyName: "testSetGetPolicy", userName: username)
            let getPolicyResponse = try await Self.iam.getUserPolicy(getPolicyRequest, logger: TestEnvironment.logger)
            let responsePolicyDocument = getPolicyResponse.policyDocument.removingPercentEncoding
            XCTAssertEqual(responsePolicyDocument, policyDocument)
        }
    }

    func testSimulatePolicy() async throws {
        guard !TestEnvironment.isUsingLocalstack else { return }
        // put a policy on the user
        let policyDocument = """
            {"Version": "2012-10-17","Statement": [{"Effect": "Allow","Action": ["sns:*","s3:*","sqs:*"],"Resource": "*"}]}
            """
        let username = TestEnvironment.generateResourceName()
        try await self.createUser(userName: username)
        do {
            let user = try await Self.iam.getUser(.init(userName: username), logger: TestEnvironment.logger)
            let request = IAM.SimulateCustomPolicyRequest(
                actionNames: ["sns:*", "sqs:*", "dynamodb:*"],
                callerArn: user.user.arn,
                policyInputList: [policyDocument]
            )
            let response = try await Self.iam.simulateCustomPolicy(request, logger: TestEnvironment.logger)
            XCTAssertEqual(response.evaluationResults?[0].evalDecision, .allowed)
            XCTAssertEqual(response.evaluationResults?[1].evalDecision, .allowed)
            XCTAssertEqual(response.evaluationResults?[2].evalDecision, .implicitDeny)
            if !TestEnvironment.isUsingLocalstack {
                try await Task.sleep(nanoseconds: 10_000_000_000)
            }
        } catch {
            XCTFail("\(error)")
        }
        // this test is very good as creating throttling errors
        if !TestEnvironment.isUsingLocalstack {
            try await Task.sleep(nanoseconds: 10_000_000_000)
        }
        try await self.deleteUser(userName: username)
    }

    func testUserTags() async throws {
        let username = TestEnvironment.generateResourceName()
        try await self.createUser(userName: username, tags: ["test": "tag"])
        do {
            let response = try await Self.iam.getUser(.init(userName: username), logger: TestEnvironment.logger)
            XCTAssertEqual(response.user.tags?.first?.key, "test")
            XCTAssertEqual(response.user.tags?.first?.value, "tag")
        } catch {
            XCTFail("\(error)")
        }
    }

    func testError() async throws {
        // doesnt work with LocalStack
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)
        await XCTAsyncExpectError(IAMErrorType.noSuchEntityException) {
            _ = try await Self.iam.getRole(.init(roleName: "_invalid-role-name"), logger: TestEnvironment.logger)
        }
    }
}
