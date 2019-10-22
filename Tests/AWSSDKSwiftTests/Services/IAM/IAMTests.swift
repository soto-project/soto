//
// iam.swift
// written by Adam Fowler
// SES tests
//
import XCTest
import Foundation
@testable import AWSSDKSwiftCore
@testable import IAM

class IAMTests: XCTestCase {
    let client = IAM(
            accessKeyId: "key",
            secretAccessKey: "secret",
            region: .apnortheast1,
            endpoint: "http://localhost:4593"
    )

    func testCreateDeleteUser() {
        attempt {
            let request = IAM.CreateUserRequest(userName: "aws-test-user")
            let response = try client.createUser(request).wait()
            
            XCTAssertNotNil(response.user)
            if let user = response.user {
                XCTAssertEqual(user.userName, "aws-test-user")
                let request2 = IAM.GetUserRequest(userName: user.userName)
                let response2 = try client.getUser(request2).wait()
                XCTAssertEqual(response2.user.userName, "aws-test-user")
            }
            let request3 = IAM.DeleteUserRequest(userName: "aws-test-user")
            try client.deleteUser(request3).wait()
        }
    }
}
