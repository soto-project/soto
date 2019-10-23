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
        let request = APIGateway.CreateRestApiRequest(binaryMediaTypes:["jpeg"], description: "Test API", endpointConfiguration: APIGateway.EndpointConfiguration(types:[.regional]), name: testData.apiName)
        let response = try client.createRestApi(request).wait()
        testData.apiId = response.id
        XCTAssertNotNil(testData.apiId)
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
    
    func testGetRestApis() {
        attempt {
            var testData = TestData(#function)
            try setup(&testData)
            defer {
                tearDown(testData)
            }

            guard let apiId = testData.apiId else { return }
            
            let getRequest = APIGateway.GetRestApisRequest()
            let getResponse = try client.getRestApis(getRequest).wait()
            let restApi = getResponse.items?.first {$0.id == apiId}
            
            XCTAssertNotNil(restApi)
        }
    }
    
    func testCreateGetResource() {
        attempt {
            var testData = TestData(#function)
            try setup(&testData)
            defer {
                tearDown(testData)
            }
            
            guard let apiId = testData.apiId else { return }

            let getRequest = APIGateway.GetResourcesRequest(restApiId: apiId)
            let getResponse = try client.getResources(getRequest).wait()
            
            XCTAssertEqual(getResponse.items?.count, 1)
            XCTAssertNotNil(getResponse.items?[0].id)
            guard let id = getResponse.items?[0].id else { return }

            let request = APIGateway.CreateResourceRequest(parentId: id, pathPart: "test", restApiId: apiId)
            let response = try client.createResource(request).wait()
            
            XCTAssertNotNil(response.id)
            guard let resourceId = response.id else {return}

            let getResourceRequest = APIGateway.GetResourceRequest(resourceId: resourceId, restApiId: apiId)
            let getResourceResponse = try client.getResource(getResourceRequest).wait()
            
            XCTAssertEqual(getResourceResponse.pathPart, "test")
        }
    }

    static var allTests : [(String, (APIGatewayTests) -> () throws -> Void)] {
        return [
            ("testGetRestApis", testGetRestApis),
            ("testCreateGetResource", testCreateGetResource),
        ]
    }
}

