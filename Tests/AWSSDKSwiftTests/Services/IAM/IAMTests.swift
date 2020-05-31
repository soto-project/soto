//===----------------------------------------------------------------------===//
//
// This source file is part of the AWSSDKSwift open source project
//
// Copyright (c) 2017-2020 the AWSSDKSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of AWSSDKSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import XCTest

@testable import AWSIAM

//testing query service

class IAMTests: XCTestCase {

    let iam = IAM(
        endpoint: TestEnvironment.getEndPoint(environment: "IAM_ENDPOINT", default: "http://localhost:4593"),
        middlewares: TestEnvironment.middlewares,
        httpClientProvider: .createNew
    )

    func createUser(userName: String) -> EventLoopFuture<Void> {
        let request = IAM.CreateUserRequest(userName: userName)
        return iam.createUser(request)
            .map { response in
                XCTAssertEqual(response.user?.userName, userName)
            }
            .flatMapErrorThrowing { error in
                switch error {
                case IAMErrorType.entityAlreadyExistsException(_):
                    print("User (\(userName)) already exists")
                    return
                default:
                    throw error
                }
        }
    }

    func deleteUser(userName: String) -> EventLoopFuture<Void> {
        let request = IAM.DeleteUserRequest(userName: userName)
        return iam.deleteUser(request).map { _ in }
    }
    
    //MARK: TESTS

    func testCreateDeleteUser() {
        let username = TestEnvironment.getName(#function)
        let response = createUser(userName: username)
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
        let username = TestEnvironment.getName(#function)
        let response = createUser(userName: username)
            .flatMap { (_) -> EventLoopFuture<IAM.GetUserResponse> in
                let request = IAM.GetUserRequest(userName: username)
                return self.iam.getUser(request)
        }
        .flatMap { (user) -> EventLoopFuture<Void> in
            let request = IAM.PutUserPolicyRequest(
                policyDocument: policyDocument,
                policyName: "testSetGetPolicy",
                userName: user.user.userName
            )
            return self.iam.putUserPolicy(request)
        }
        .flatMap { (_) -> EventLoopFuture<IAM.GetUserPolicyResponse> in
            let request = IAM.GetUserPolicyRequest(policyName: "testSetGetPolicy", userName: username)
            return self.iam.getUserPolicy(request)
        }
        .map { response in
            let responsePolicyDocument = response.policyDocument.removingPercentEncoding?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            XCTAssertEqual(responsePolicyDocument, policyDocument.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
        }
        .flatMap { (_) -> EventLoopFuture<IAM.ListUserPoliciesResponse> in
            let request = IAM.ListUserPoliciesRequest(userName: username)
            return self.iam.listUserPolicies(request)
        }
        .flatMap { response -> EventLoopFuture<Void> in
            let futures = response.policyNames.map { (policyName) -> EventLoopFuture<Void> in
                let deletePolicy = IAM.DeleteUserPolicyRequest(policyName: policyName, userName: username)
                return self.iam.deleteUserPolicy(deletePolicy)
            }
            return EventLoopFuture.andAllComplete(futures, on: self.iam.client.eventLoopGroup.next())
        }
        .flatAlways { _ in
            return self.deleteUser(userName: username)
        }
        
        XCTAssertNoThrow(try response.wait())
    }

    static var allTests: [(String, (IAMTests) -> () throws -> Void)] {
        return [
            ("testCreateDeleteUser", testCreateDeleteUser),
            ("testSetGetPolicy", testSetGetPolicy),
        ]
    }
}
