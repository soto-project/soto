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
import Testing

@Suite(.awsClient())
struct IAMTests {

    /// create user with supplied name and run supplied closure
    func testUser(
        userName: String,
        tags: [String: String] = [:],
        iam: IAM,
        test: @escaping (String) async throws -> Void
    ) async throws {
        try await testAsset {
            try await self.createUser(userName: userName, tags: tags, iam: iam)
            return userName
        } test: {
            try await test($0)
        } delete: {
            try await self.deleteUser(userName: $0, iam: iam)
        }
    }

    func createUser(userName: String, tags: [String: String] = [:], iam: IAM) async throws {
        let request = IAM.CreateUserRequest(tags: tags.map { IAM.Tag(key: $0.key, value: $0.value) }, userName: userName)
        do {
            let response = try await iam.createUser(request, logger: TestEnvironment.logger)
            #expect(response.user?.userName == userName)
        } catch let error as IAMErrorType {
            switch error.error {
            case .entityAlreadyExistsException:
                print("User (\(userName)) already exists")
            default:
                throw error
            }
        }
        try await iam.waitUntilUserExists(.init(userName: userName))
    }

    func deleteUser(userName: String, iam: IAM) async throws {
        let request = IAM.ListUserPoliciesRequest(userName: userName)
        let response = try await iam.listUserPolicies(request, logger: TestEnvironment.logger)
        for policyName in response.policyNames {
            let deletePolicy = IAM.DeleteUserPolicyRequest(policyName: policyName, userName: userName)
            try await iam.deleteUserPolicy(deletePolicy, logger: TestEnvironment.logger)
        }
        try await iam.deleteUser(.init(userName: userName), logger: TestEnvironment.logger)
    }

    // MARK: TESTS

    @Test func testCreateDeleteUser() async throws {
        let username = TestEnvironment.generateResourceName()
        try await self.testUser(userName: username, iam: IAM(client: AWSClientTrait.client)) { _ in }
    }

    @Test func testFIPSEndpoint() async throws {
        let iam = IAM(client: AWSClientTrait.client, options: .useFipsEndpoint)
        let username = TestEnvironment.generateResourceName()
        try await self.testUser(userName: username, iam: iam) { _ in }
    }

    @Test func testSetGetPolicy() async throws {
        let iam = IAM(client: AWSClientTrait.client)
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
        try await self.testUser(userName: username, iam: iam) { _ in
            let user = try await iam.getUser(.init(userName: username), logger: TestEnvironment.logger)
            let request = IAM.PutUserPolicyRequest(
                policyDocument: policyDocument,
                policyName: "testSetGetPolicy",
                userName: user.user.userName
            )
            try await iam.putUserPolicy(request, logger: TestEnvironment.logger)
            let getPolicyRequest = IAM.GetUserPolicyRequest(policyName: "testSetGetPolicy", userName: username)
            let getPolicyResponse = try await iam.getUserPolicy(getPolicyRequest, logger: TestEnvironment.logger)
            let responsePolicyDocument = getPolicyResponse.policyDocument.removingPercentEncoding
            #expect(responsePolicyDocument == policyDocument)
        }
    }

    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Localstack doesn't support policy simulation"))
    func testSimulatePolicy() async throws {
        let iam = IAM(client: AWSClientTrait.client)
        // put a policy on the user
        let policyDocument = """
            {"Version": "2012-10-17","Statement": [{"Effect": "Allow","Action": ["sns:*","s3:*","sqs:*"],"Resource": "*"}]}
            """
        let username = TestEnvironment.generateResourceName()
        try await testUser(userName: username, iam: iam) { name in
            let user = try await iam.getUser(.init(userName: name), logger: TestEnvironment.logger)
            let request = IAM.SimulateCustomPolicyRequest(
                actionNames: ["sns:*", "sqs:*", "dynamodb:*"],
                callerArn: user.user.arn,
                policyInputList: [policyDocument]
            )
            let response = try await iam.simulateCustomPolicy(request, logger: TestEnvironment.logger)
            #expect(response.evaluationResults?[0].evalDecision == .allowed)
            #expect(response.evaluationResults?[1].evalDecision == .allowed)
            #expect(response.evaluationResults?[2].evalDecision == .implicitDeny)
        }
    }

    @Test func testUserTags() async throws {
        let iam = IAM(client: AWSClientTrait.client)
        let username = TestEnvironment.generateResourceName()
        try await testUser(userName: username, tags: ["test": "tag"], iam: iam) { name in
            do {
                let response = try await iam.getUser(.init(userName: username), logger: TestEnvironment.logger)
                #expect(response.user.tags?.first?.key == "test")
                #expect(response.user.tags?.first?.value == "tag")
            } catch {
                Issue.record("\(error)")
            }
        }
    }

    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Localstack returns the wrong error"))
    func testError() async throws {
        let iam = IAM(client: AWSClientTrait.client)
        let error = await #expect(throws: IAMErrorType.self) {
            _ = try await iam.getRole(.init(roleName: "_invalid-role-name"), logger: TestEnvironment.logger)
        }
        #expect(error?.error == .noSuchEntityException)
    }
}
