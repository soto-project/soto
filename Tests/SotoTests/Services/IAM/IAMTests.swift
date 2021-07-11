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

import NIO
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

        Self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middlewares: TestEnvironment.middlewares, httpClientProvider: .createNew)
        Self.iam = IAM(
            client: IAMTests.client,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
    }

    override class func tearDown() {
        XCTAssertNoThrow(try Self.client.syncShutdown())
    }

    func createUser(userName: String, tags: [String: String] = [:]) -> EventLoopFuture<Void> {
        let request = IAM.CreateUserRequest(tags: tags.map { return IAM.Tag(key: $0.key, value: $0.value) }, userName: userName)
        return Self.iam.createUser(request, logger: TestEnvironment.logger)
            .map { response in
                XCTAssertEqual(response.user?.userName, userName)
            }
            .flatMapErrorThrowing { error in
                switch error {
                case let error as IAMErrorType where error == .entityAlreadyExistsException:
                    print("User (\(userName)) already exists")
                    return
                default:
                    throw error
                }
            }
            .flatMap { _ in
                Self.iam.waitUntilUserExists(.init(userName: userName))
            }
    }

    func deleteUser(userName: String) -> EventLoopFuture<Void> {
        let eventLoop = Self.iam.client.eventLoopGroup.next()
        let request = IAM.ListUserPoliciesRequest(userName: userName)
        return Self.iam.listUserPolicies(request, logger: TestEnvironment.logger)
            .flatMap { response -> EventLoopFuture<Void> in
                let futures = response.policyNames.map { (policyName) -> EventLoopFuture<Void> in
                    let deletePolicy = IAM.DeleteUserPolicyRequest(policyName: policyName, userName: userName)
                    // add stall to avoid throttling errors.
                    return eventLoop.flatScheduleTask(deadline: .now() + .seconds(2)) {
                        return Self.iam.deleteUserPolicy(deletePolicy, logger: TestEnvironment.logger)
                    }.futureResult
                }
                return EventLoopFuture.andAllComplete(futures, on: Self.iam.client.eventLoopGroup.next())
            }
            .flatMap { _ -> EventLoopFuture<Void> in
                // add stall to avoid throttling errors.
                let scheduled: Scheduled<Void> = eventLoop.scheduleTask(deadline: .now() + .seconds(2)) {}
                return scheduled.futureResult
            }
            .flatMap { _ in
                return Self.iam.deleteUser(.init(userName: userName), logger: TestEnvironment.logger).map { _ in }
            }
    }

    // MARK: TESTS

    func testCreateDeleteUser() {
        let username = TestEnvironment.generateResourceName()
        let response = self.createUser(userName: username)
            .flatMap { _ in self.deleteUser(userName: username) }
        XCTAssertNoThrow(try response.wait())
    }

    func testSetGetPolicy() {
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
        let response = self.createUser(userName: username)
            .flatMap { (_) -> EventLoopFuture<IAM.GetUserResponse> in
                return Self.iam.getUser(.init(userName: username), logger: TestEnvironment.logger)
            }
            .flatMap { (user) -> EventLoopFuture<Void> in
                let request = IAM.PutUserPolicyRequest(
                    policyDocument: policyDocument,
                    policyName: "testSetGetPolicy",
                    userName: user.user.userName
                )
                return Self.iam.putUserPolicy(request, logger: TestEnvironment.logger)
            }
            .flatMap { (_) -> EventLoopFuture<IAM.GetUserPolicyResponse> in
                let request = IAM.GetUserPolicyRequest(policyName: "testSetGetPolicy", userName: username)
                return Self.iam.getUserPolicy(request, logger: TestEnvironment.logger)
            }
            .map { response in
                let responsePolicyDocument = response.policyDocument.removingPercentEncoding
                XCTAssertEqual(responsePolicyDocument, policyDocument)
            }
            .flatAlways { _ in
                return self.deleteUser(userName: username)
            }

        XCTAssertNoThrow(try response.wait())
    }

    func testSimulatePolicy() {
        guard !TestEnvironment.isUsingLocalstack else { return }
        // put a policy on the user
        let policyDocument = """
        {"Version": "2012-10-17","Statement": [{"Effect": "Allow","Action": ["sns:*","s3:*","sqs:*"],"Resource": "*"}]}
        """
        let username = TestEnvironment.generateResourceName()
        let response = self.createUser(userName: username)
            .flatMap { (_) -> EventLoopFuture<IAM.GetUserResponse> in
                return Self.iam.getUser(.init(userName: username), logger: TestEnvironment.logger)
            }
            .flatMap { (user) -> EventLoopFuture<IAM.SimulatePolicyResponse> in
                let request = IAM.SimulateCustomPolicyRequest(actionNames: ["sns:*", "sqs:*", "dynamodb:*"], callerArn: user.user.arn, policyInputList: [policyDocument])
                return Self.iam.simulateCustomPolicy(request, logger: TestEnvironment.logger)
            }
            .map { response -> Void in
                XCTAssertEqual(response.evaluationResults?[0].evalDecision, .allowed)
                XCTAssertEqual(response.evaluationResults?[1].evalDecision, .allowed)
                XCTAssertEqual(response.evaluationResults?[2].evalDecision, .implicitdeny)
            }
            .flatAlways { _ -> EventLoopFuture<Void> in
                let eventLoop = Self.iam.client.eventLoopGroup.next()
                if TestEnvironment.isUsingLocalstack {
                    return self.deleteUser(userName: username)
                }
                // wait ten seconds for user to be deleted. This is to avoid throttled errors
                let scheduled: Scheduled<Void> = eventLoop.flatScheduleTask(deadline: .now() + .seconds(10)) { return self.deleteUser(userName: username) }
                return scheduled.futureResult.map {}
            }

        // this test is quite good at creating a throttling error
        do {
            try response.wait()
        } catch let error as AWSClientError where error == .throttling {
            print("Throttling error")
        } catch {
            XCTFail("\(error)")
        }
    }

    func testUserTags() {
        let username = TestEnvironment.generateResourceName()
        let response = self.createUser(userName: username, tags: ["test": "tag"])
            .flatMap { (_) -> EventLoopFuture<IAM.GetUserResponse> in
                return Self.iam.getUser(.init(userName: username), logger: TestEnvironment.logger)
            }
            .map { response in
                XCTAssertEqual(response.user.tags?.first?.key, "test")
                XCTAssertEqual(response.user.tags?.first?.value, "tag")
            }
            .flatAlways { _ in
                return self.deleteUser(userName: username)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testError() {
        // This doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }
        let response = Self.iam.getRole(.init(roleName: "_invalid-role-name"), logger: TestEnvironment.logger)
        XCTAssertThrowsError(try response.wait()) { error in
            switch error {
            case let error as IAMErrorType where error == .noSuchEntityException:
                XCTAssertNotNil(error.message)
            default:
                XCTFail("Wrong error: \(error)")
            }
        }
    }
}
