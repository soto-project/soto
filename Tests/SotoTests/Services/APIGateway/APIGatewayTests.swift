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

import XCTest

@testable import SotoAPIGateway

enum APIGatewayTestsError: Error {
    case noRestApi
}

// testing restjson service

class APIGatewayTests: XCTestCase {
    static var client: AWSClient!
    static var apiGateway: APIGateway!
    static var setup = false

    static let restApiName: String = TestEnvironment.generateResourceName("APIGatewayTests")
    static var restApiId: String!

    override class func setUp() {
        self.client = AWSClient(
            credentialProvider: TestEnvironment.credentialProvider,
            middleware: TestEnvironment.middlewares,
            logger: TestEnvironment.logger
        )
        self.apiGateway = APIGateway(
            client: APIGatewayTests.client,
            region: .euwest1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )

        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }
        Task {
            /// If we create a rest api for each test, when we delete them APIGateway will
            /// throttle and we will most likely not delete the all APIs so we create one API to be used by all tests
            await XCTAsyncAssertNoThrow {
                let response = try await self.createRestApi(name: self.restApiName)
                Self.restApiId = try XCTUnwrap(response.id)
            }
        }.syncAwait()
    }

    override class func tearDown() {
        Task {
            await XCTAsyncAssertNoThrow {
                _ = try await self.deleteRestApi(id: self.restApiId)
                try await self.client.shutdown()
            }
        }.syncAwait()
    }

    static func createRestApi(name: String) async throws -> APIGateway.RestApi {
        let request = APIGateway.GetRestApisRequest()
        let response = try await self.apiGateway.getRestApis(request, logger: TestEnvironment.logger)
        if let restApi = response.items?.first(where: { $0.name == name }) {
            return restApi
        } else {
            let request = APIGateway.CreateRestApiRequest(
                description: "\(name) API",
                endpointConfiguration: APIGateway.EndpointConfiguration(types: [.regional]),
                name: name
            )
            return try await Self.apiGateway.createRestApi(request, logger: TestEnvironment.logger)
        }
    }

    static func deleteRestApi(id: String) async throws {
        let request = APIGateway.DeleteRestApiRequest(restApiId: id)
        _ = try await self.apiGateway.deleteRestApi(request, logger: TestEnvironment.logger)
    }

    /// create Rest api with supplied name and run supplied closure with rest api id
    func testRestApi(body: @escaping (String) async throws -> Void) async throws {
        try await body(Self.restApiId)
    }

    // MARK: TESTS

    func testGetRestApis() async throws {
        try await self.testRestApi { id in
            let request = APIGateway.GetRestApisRequest()
            let response = try await Self.apiGateway.getRestApis(request, logger: TestEnvironment.logger)
            let restApi = response.items?.first(where: { $0.id == id })
            XCTAssertNotNil(restApi)
            XCTAssertEqual(restApi?.name, Self.restApiName)
        }
    }

    func testGetRestApi() async throws {
        try await self.testRestApi { id in
            let request = APIGateway.GetRestApiRequest(restApiId: id)
            let response = try await Self.apiGateway.getRestApi(request, logger: TestEnvironment.logger)
            XCTAssertEqual(response.name, Self.restApiName)
        }
    }

    func testCreateGetResource() async throws {
        try await self.testRestApi { id in
            // get parent resource
            let request = APIGateway.GetResourcesRequest(restApiId: id)
            let response = try await Self.apiGateway.getResources(request, logger: TestEnvironment.logger)
            let items = try XCTUnwrap(response.items)
            XCTAssertEqual(items.count, 1)
            let parentId = try XCTUnwrap(items[0].id)
            let createRequest = APIGateway.CreateResourceRequest(parentId: parentId, pathPart: "test", restApiId: id)
            let createResponse = try await Self.apiGateway.createResource(createRequest, logger: TestEnvironment.logger)
            let resourceId = try XCTUnwrap(createResponse.id)
            let getResourceRequest = APIGateway.GetResourceRequest(embed: ["orange", "apple", "star*"], resourceId: resourceId, restApiId: id)
            let getResourceResponse = try await Self.apiGateway.getResource(getResourceRequest, logger: TestEnvironment.logger)
            XCTAssertEqual(getResourceResponse.pathPart, "test")
        }
    }

    func testPathWithSpecialCharacters() async throws {
        // doesnt work with LocalStack
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)
        do {
            let request = APIGateway.GetResourcesRequest(restApiId: "Test+%/*%25")
            _ = try await Self.apiGateway.getResources(request, logger: TestEnvironment.logger)
            XCTFail("This request should fail")
        } catch let error as APIGatewayErrorType where error == .notFoundException {
            // Localstack produces a different error message to AWS
            if !TestEnvironment.isUsingLocalstack {
                XCTAssert(error.message?.hasPrefix("Invalid API identifier specified") == true)
                XCTAssert(error.message?.hasSuffix(":Test+%/*%25") == true)
            }
        } catch let error as AWSClientError where error == .invalidSignature {
            XCTFail("Invalid signature")
        }
    }

    func testError() async throws {
        do {
            _ = try await Self.apiGateway.getModels(.init(restApiId: "invalid-rest-api-id"), logger: TestEnvironment.logger)
            XCTFail("This request should fail")
        } catch let error as APIGatewayErrorType where error == .notFoundException {
            XCTAssertNotNil(error.message)

        } catch {
            // local stack is returning a duff error at the moment
            if !TestEnvironment.isUsingLocalstack {
                throw error
            }
        }
    }
}
