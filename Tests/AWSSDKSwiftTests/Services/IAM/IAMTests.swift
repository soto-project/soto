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

    let client = IAM(
        accessKeyId: "key",
        secretAccessKey: "secret",
        endpoint: ProcessInfo.processInfo.environment["IAM_ENDPOINT"] ?? "http://localhost:4593",
        middlewares: (ProcessInfo.processInfo.environment["AWS_ENABLE_LOGGING"] == "true") ? [AWSLoggingMiddleware()] : [],
        httpClientProvider: .createNew
    )

    class TestData {
        let userName: String
        let client: IAM

        init(_ testName: String, client: IAM) throws {
            let testName = testName.lowercased().filter { return $0.isLetter }
            self.client = client
            self.userName = "\(testName)-user"

            let request = IAM.CreateUserRequest(userName: self.userName)
            do {
                let response = try client.createUser(request).wait()
                XCTAssertEqual(response.user?.userName, self.userName)
            } catch IAMErrorType.entityAlreadyExistsException(_) {
                print("User (\(self.userName)) already exists")
            }
        }

        deinit {
            attempt {
                let request = IAM.DeleteUserRequest(userName: self.userName)
                try client.deleteUser(request).wait()
            }
        }
    }

    //MARK: TESTS

    func testCreateDeleteUser() {
        attempt {
            let testData = try TestData(#function, client: client)

            let request = IAM.GetUserRequest(userName: testData.userName)
            let response = try client.getUser(request).wait()
            XCTAssertEqual(response.user.userName, testData.userName)
        }
    }

    func testSetGetPolicy() {
        attempt {
            let testData = try TestData(#function, client: client)

            // put a policy on the user
            var policyDocument = """
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
            policyDocument = policyDocument.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let getUserRequest = IAM.GetUserRequest(userName: testData.userName)
            let getUserResponse = try client.getUser(getUserRequest).wait()

            let putRequest = IAM.PutUserPolicyRequest(
                policyDocument: policyDocument,
                policyName: "testSetGetPolicy",
                userName: getUserResponse.user.userName
            )
            _ = try client.putUserPolicy(putRequest).wait()

            let getRequest = IAM.GetUserPolicyRequest(policyName: "testSetGetPolicy", userName: getUserResponse.user.userName)
            let getResponse = try client.getUserPolicy(getRequest).wait()

            XCTAssertEqual(
                getResponse.policyDocument.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                policyDocument.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            )
            
            // make sure we remove all policies attached to user
            let listPolicyRequest = IAM.ListUserPoliciesRequest(userName: getUserResponse.user.userName)
            let _: Void = try client.listUserPolicies(listPolicyRequest).flatMap { response in
                let futures = response.policyNames.map { (policyName) -> EventLoopFuture<Void> in
                    let deletePolicy = IAM.DeleteUserPolicyRequest(policyName: policyName, userName: getUserResponse.user.userName)
                    return self.client.deleteUserPolicy(deletePolicy)
                }
                return EventLoopFuture.andAllSucceed(futures, on: self.client.client.eventLoopGroup.next())
            }.wait()
        }

    }

    static var allTests: [(String, (IAMTests) -> () throws -> Void)] {
        return [
            ("testCreateDeleteUser", testCreateDeleteUser),
            ("testSetGetPolicy", testSetGetPolicy),
        ]
    }
}
