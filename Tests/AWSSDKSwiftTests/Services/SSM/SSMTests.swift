//
// SSMTests.swift
// written by Adam Fowler
// SSM tests
//
import XCTest
import Foundation
@testable import AWSSDKSwiftCore
@testable import SSM

enum SSMTestsError : Error {
    case noTopicArn
}

// testing json service

class SSMTests: XCTestCase {

    let client = SSM(
            accessKeyId: "key",
            secretAccessKey: "secret",
            region: .apnortheast1,
            endpoint: "http://localhost:4583",
            middlewares: [AWSLoggingMiddleware()]
    )

    class TestData {
        var client: SSM
        var parameterName: String
        var parameterValue: String

        init(_ testName: String, client: SSM) throws {
            self.client = client
            let testName = testName.lowercased().filter { return $0.isLetter || $0.isNumber }
            self.parameterName = "/awssdkswift/\(testName)"
            self.parameterValue = "value:\(testName)"

            let request = SSM.PutParameterRequest(name: parameterName, overwrite: true, type: .string, value: parameterValue)
            _ = try client.putParameter(request).wait()
        }
        
        deinit {
            attempt {
                let request = SSM.DeleteParameterRequest(name: parameterName)
                _ = try client.deleteParameter(request).wait()
            }
        }
    }

    //MARK: TESTS
    
    func testGetParameter() {
        attempt {
            let testData = try TestData(#function, client: client)
            let request = SSM.GetParameterRequest(name: testData.parameterName)
            let response = try client.getParameter(request).wait()
            XCTAssertEqual(response.parameter?.name, testData.parameterName)
            XCTAssertEqual(response.parameter?.value, testData.parameterValue)
        }
    }
    
    func testGetParametersByPath() {
        attempt {
            let testData = try TestData(#function, client: client)
            let request = SSM.GetParametersByPathRequest(path: "/awssdkswift/")
            let response = try client.getParametersByPath(request).wait()
            XCTAssertNotNil(response.parameters?.first {$0.name == testData.parameterName})
        }
    }
    
    static var allTests : [(String, (SSMTests) -> () throws -> Void)] {
        return [
            ("testGetParametersByPath", testGetParametersByPath),
        ]
    }
}



