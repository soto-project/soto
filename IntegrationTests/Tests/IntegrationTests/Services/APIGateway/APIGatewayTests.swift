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

import SotoAPIGateway
import Testing

struct APIGatewayTrait: TestScoping, SuiteTrait, TestTrait {
    @TaskLocal
    static var _api: (name: String, id: String)?

    static var api: (name: String, id: String) {
        guard let _api else { fatalError("Test needs a APIGateway rest API") }
        return _api
    }

    let restApiName: String = TestEnvironment.generateResourceName("APIGatewayTests")

    func provideScope(for test: Test, testCase: Test.Case?, performing function: @concurrent @Sendable () async throws -> Void) async throws {
        let apiGateway = APIGateway(client: AWSClientTrait.client, region: .useast1)
        try await testAsset {
            let response = try await apiGateway.createRestApi(name: self.restApiName)
            return try #require(response.id)
        } test: { apiID in
            try await APIGatewayTrait.$_api.withValue((name: restApiName, id: apiID)) {
                try await function()
            }
        } delete: { apiID in
            _ = try await apiGateway.deleteRestApi(restApiId: apiID)
        }
    }
}

// testing restjson service

@Suite(
    .awsClient(),
    APIGatewayTrait()
)
struct APIGatewayTests {
    @Test func testGetRestApis() async throws {
        let apiGateway = APIGateway(client: AWSClientTrait.client, region: .useast1)
        let request = APIGateway.GetRestApisRequest()
        let response = try await apiGateway.getRestApis(request, logger: TestEnvironment.logger)
        let restApi = try #require(response.items?.first(where: { $0.id == APIGatewayTrait.api.id }))
        #expect(restApi.name == APIGatewayTrait.api.name)
    }

    @Test func testGetRestApi() async throws {
        let apiGateway = APIGateway(client: AWSClientTrait.client, region: .useast1)
        let request = APIGateway.GetRestApiRequest(restApiId: APIGatewayTrait.api.id)
        let response = try await apiGateway.getRestApi(request, logger: TestEnvironment.logger)
        #expect(response.name == APIGatewayTrait.api.name)
    }

    @Test func testCreateGetResource() async throws {
        let apiGateway = APIGateway(client: AWSClientTrait.client, region: .useast1)
        // get parent resource
        let request = APIGateway.GetResourcesRequest(restApiId: APIGatewayTrait.api.id)
        let response = try await apiGateway.getResources(request, logger: TestEnvironment.logger)
        let items = try #require(response.items)
        #expect(items.count == 1)
        let parentId = try #require(items[0].id)
        let createRequest = APIGateway.CreateResourceRequest(parentId: parentId, pathPart: "test", restApiId: APIGatewayTrait.api.id)
        let createResponse = try await apiGateway.createResource(createRequest, logger: TestEnvironment.logger)
        let resourceId = try #require(createResponse.id)
        let getResourceRequest = APIGateway.GetResourceRequest(
            embed: ["orange", "apple", "star*"],
            resourceId: resourceId,
            restApiId: APIGatewayTrait.api.id
        )
        let getResourceResponse = try await apiGateway.getResource(getResourceRequest, logger: TestEnvironment.logger)
        #expect(getResourceResponse.pathPart == "test")
    }

    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "This test does not work with localstack"))
    func testPathWithSpecialCharacters() async throws {
        let apiGateway = APIGateway(client: AWSClientTrait.client, region: .useast1)
        let request = APIGateway.GetResourcesRequest(restApiId: "Test+%/*%25")
        let error = await #expect(throws: APIGatewayErrorType.self) {
            try await apiGateway.getResources(request, logger: TestEnvironment.logger)
        }
        switch error?.error {
        case .notFoundException:
            #expect(error?.message?.hasPrefix("Invalid API identifier specified") == true)
            #expect(error?.message?.hasSuffix(":Test+%/*%25") == true)
        default:
            Issue.record("Expected notFoundException, got \(error)")
        }
    }

    @Test func testError() async throws {
        let apiGateway = APIGateway(client: AWSClientTrait.client, region: .useast1)
        let error = await #expect(throws: APIGatewayErrorType.self) {
            _ = try await apiGateway.getModels(.init(restApiId: "invalid-rest-api-id"), logger: TestEnvironment.logger)
        }
        switch error?.error {
        case .notFoundException:
            break
        default:
            Issue.record("Expected notFoundException, got \(error)")
        }
    }
}
