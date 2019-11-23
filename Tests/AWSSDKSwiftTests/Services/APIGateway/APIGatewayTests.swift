//
// APIGatewayTests.swift
// written by Adam Fowler
// APIGateway Tests tests
//
import XCTest
import Foundation
@testable import AWSSDKSwiftCore
@testable import APIGateway

enum APIGatewayTestsError : Error {
    case noRestApi
}

//testing restjson service

class APIGatewayTests: XCTestCase {

    let client = APIGateway(
            accessKeyId: "key",
            secretAccessKey: "secret",
            region: .apnortheast1,
            endpoint: "http://localhost:4567"
    )

    class TestData {
        let client: APIGateway
        let apiName: String
        let apiId: String
        
        init(_ testName: String, client: APIGateway) throws {
            let testName = testName.lowercased().filter { return $0.isLetter }
            self.client = client
            self.apiName = "\(testName)-api"

            let request = APIGateway.CreateRestApiRequest(binaryMediaTypes:["jpeg"], description: "Test API", endpointConfiguration: APIGateway.EndpointConfiguration(types:[.regional]), name: self.apiName)
            let response = try client.createRestApi(request).wait()
            guard let apiId = response.id else {throw APIGatewayTestsError.noRestApi}
            self.apiId = apiId
        }
        
        deinit {
            attempt {
                let request = APIGateway.DeleteRestApiRequest(restApiId: self.apiId)
                _ = try client.deleteRestApi(request).wait()
            }
        }
    }

    //MARK: TESTS
    
    func testGetRestApis() {
        attempt {
            let testData = try TestData(#function, client: client)

            let getRequest = APIGateway.GetRestApisRequest()
            let getResponse = try client.getRestApis(getRequest).wait()
            let restApi = getResponse.items?.first {$0.id == testData.apiId}
            
            XCTAssertNotNil(restApi)
        }
    }
    
    func testCreateGetResource() {
        attempt {
            let testData = try TestData(#function, client: client)

            let getRequest = APIGateway.GetResourcesRequest(restApiId: testData.apiId)
            let getResponse = try client.getResources(getRequest).wait()
            
            XCTAssertEqual(getResponse.items?.count, 1)
            XCTAssertNotNil(getResponse.items?[0].id)
            guard let id = getResponse.items?[0].id else { return }

            let request = APIGateway.CreateResourceRequest(parentId: id, pathPart: "test", restApiId: testData.apiId)
            let response = try client.createResource(request).wait()
            
            XCTAssertNotNil(response.id)
            guard let resourceId = response.id else {return}

            let getResourceRequest = APIGateway.GetResourceRequest(resourceId: resourceId, restApiId: testData.apiId)
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

