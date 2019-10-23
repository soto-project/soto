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
    struct TestData {
        
        var userName: String
        
        init(_ testName: String) {
            let testName = testName.lowercased().filter { return $0.isLetter }
            self.userName = "\(testName)-user"
        }
    }

    let client = IAM(
            accessKeyId: "key",
            secretAccessKey: "secret",
            region: .apnortheast1,
            endpoint: "http://localhost:4593"
    )

    /// setup test
    func setup(_ testData: TestData) throws {
        let request = IAM.CreateUserRequest(userName: testData.userName)
        do {
            let response = try client.createUser(request).wait()
            XCTAssertEqual(response.user?.userName, testData.userName)
        } catch IAMErrorType.entityAlreadyExistsException(_) {
            print("User (\(testData.userName)) already exists")
        }
    }
    
    /// teardown test
    func tearDown(_ testData: TestData) throws {
        let request = IAM.DeleteUserRequest(userName: testData.userName)
        try client.deleteUser(request).wait()
    }
    
    //MARK: TESTS
    
    func testCreateDeleteUser() {
        attempt {
            let testData = TestData(#function)
            try setup(testData)
            
            let request = IAM.GetUserRequest(userName: testData.userName)
            let response = try client.getUser(request).wait()
            XCTAssertEqual(response.user.userName, testData.userName)
            
            try tearDown(testData)
        }
    }

    static var allTests : [(String, (IAMTests) -> () throws -> Void)] {
        return [
            ("testCreateDeleteUser", testCreateDeleteUser),
        ]
    }
}
