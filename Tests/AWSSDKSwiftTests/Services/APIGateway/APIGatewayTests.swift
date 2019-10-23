//
// APIGatewayTests.swift
// written by Adam Fowler
// APIGateway Tests tests
//
import XCTest
import Foundation
@testable import AWSSDKSwiftCore
@testable import APIGateway

class APIGatewayTests: XCTestCase {
    struct TestData {
        
        var apiName: String
        var apiId: String? = nil
        
        init(_ testName: String) {
            let testName = testName.lowercased().filter { return $0.isLetter }
            self.apiName = "\(testName)-api"
        }
    }

    let client = APIGateway(
            accessKeyId: "key",
            secretAccessKey: "secret",
            region: .apnortheast1,
            endpoint: "http://localhost:4567"
    )

    /// setup test
    func setup(_ testData: inout TestData) throws {
        let request = APIGateway.CreateRestApiRequest(description: "Test API", endpointConfiguration: APIGateway.EndpointConfiguration(types:[.regional]), name: testData.apiName)
        let response = try client.createRestApi(request).wait()
        testData.apiId = response.id
    }
    
    /// teardown test
    func tearDown(_ testData: TestData) {
        attempt {
            if let apiId = testData.apiId {
                let request = APIGateway.DeleteRestApiRequest(restApiId: apiId)
                _ = try client.deleteRestApi(request).wait()
            }
        }
    }
    
    //MARK: TESTS
    
    func testCreateDeleteRestApi() {
        attempt {
            var testData = TestData(#function)
            try setup(&testData)
            defer {
                tearDown(testData)
            }
        }
    }

    static var allTests : [(String, (APIGatewayTests) -> () throws -> Void)] {
        return [
            ("testCreateDeleteRestApi", testCreateDeleteRestApi),
        ]
    }
}

