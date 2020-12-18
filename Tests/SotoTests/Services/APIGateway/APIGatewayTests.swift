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

@testable import SotoAPIGateway
import XCTest

enum APIGatewayTestsError: Error {
    case noRestApi
}

// testing restjson service

class APIGatewayTests: XCTestCase {
    static var client: AWSClient!
    static var apiGateway: APIGateway!

    static let restApiName: String = TestEnvironment.generateResourceName("APIGatewayTests")
    static var restApiId: String!

    override class func setUp() {
        Self.client = AWSClient(
            credentialProvider: TestEnvironment.credentialProvider,
            middlewares: TestEnvironment.middlewares,
            httpClientProvider: .createNew,
            logger: TestEnvironment.logger
        )
        Self.apiGateway = APIGateway(
            client: APIGatewayTests.client,
            region: .euwest1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )

        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }
        /// If we create a rest api for each test, when we delete them APIGateway will throttle and we will most likely not delete the all APIs
        /// So we create one API to be used by all tests
        let eventLoop = self.apiGateway.client.eventLoopGroup.next()
        let createResult = self.createRestApi(name: self.restApiName, on: eventLoop)
            .flatMapThrowing { response in
                return try XCTUnwrap(response.id)
            }
            .flatMapErrorThrowing { error in
                print("Failed to create APIGateway rest api, error: \(error)")
                throw error
            }
        XCTAssertNoThrow(Self.restApiId = try createResult.wait())
    }

    override class func tearDown() {
        XCTAssertNoThrow(_ = try self.deleteRestApi(id: self.restApiId).wait())
        XCTAssertNoThrow(try self.client.syncShutdown())
    }

    static func createRestApi(name: String, on eventLoop: EventLoop) -> EventLoopFuture<APIGateway.RestApi> {
        let request = APIGateway.GetRestApisRequest()
        return self.apiGateway.getRestApis(request, logger: TestEnvironment.logger)
            .flatMap { response in
                if let restApi = response.items?.first(where: { $0.name == name }) {
                    return eventLoop.makeSucceededFuture(restApi)
                } else {
                    let request = APIGateway.CreateRestApiRequest(
                        description: "\(name) API",
                        endpointConfiguration: APIGateway.EndpointConfiguration(types: [.regional]),
                        name: name
                    )
                    return Self.apiGateway.createRestApi(request, logger: TestEnvironment.logger)
                }
            }
    }

    static func deleteRestApi(id: String) -> EventLoopFuture<Void> {
        let request = APIGateway.DeleteRestApiRequest(restApiId: id)
        return self.apiGateway.deleteRestApi(request, logger: TestEnvironment.logger).map {}
    }

    /// create Rest api with supplied name and run supplied closure with rest api id
    func testRestApi(body: @escaping (String) -> EventLoopFuture<Void>) -> EventLoopFuture<Void> {
        body(Self.restApiId)
    }

    // MARK: TESTS

    func testGetRestApis() {
        let response = self.testRestApi { id in
            let request = APIGateway.GetRestApisRequest()
            return Self.apiGateway.getRestApis(request, logger: TestEnvironment.logger)
                .map { response in
                    let restApi = response.items?.first(where: { $0.id == id })
                    XCTAssertNotNil(restApi)
                    XCTAssertEqual(restApi?.name, Self.restApiName)
                }
        }
        XCTAssertNoThrow(try response.wait())
    }

    func testGetRestApi() {
        let response = self.testRestApi { id in
            let request = APIGateway.GetRestApiRequest(restApiId: id)
            return Self.apiGateway.getRestApi(request, logger: TestEnvironment.logger)
                .map { response in
                    XCTAssertEqual(response.name, Self.restApiName)
                }
        }
        XCTAssertNoThrow(try response.wait())
    }

    func testCreateGetResource() {
        let response = self.testRestApi { id in
            // get parent resource
            let request = APIGateway.GetResourcesRequest(restApiId: id)
            return Self.apiGateway.getResources(request, logger: TestEnvironment.logger)
                .flatMapThrowing { response throws -> String in
                    let items = try XCTUnwrap(response.items)
                    XCTAssertEqual(items.count, 1)
                    let parentId = try XCTUnwrap(items[0].id)
                    return parentId
                }
                // create new resource
                .flatMap { parentId -> EventLoopFuture<APIGateway.Resource> in
                    let request = APIGateway.CreateResourceRequest(parentId: parentId, pathPart: "test", restApiId: id)
                    return Self.apiGateway.createResource(request, logger: TestEnvironment.logger)
                }
                // extract resource id
                .flatMapThrowing { (response) throws -> String in
                    let resourceId = try XCTUnwrap(response.id)
                    return resourceId
                }
                // get resource
                .flatMap { resourceId -> EventLoopFuture<APIGateway.Resource> in
                    let request = APIGateway.GetResourceRequest(embed: ["orange", "apple", "star*"], resourceId: resourceId, restApiId: id)
                    return Self.apiGateway.getResource(request, logger: TestEnvironment.logger)
                }
                // verify resource is correct
                .map { response in
                    XCTAssertEqual(response.pathPart, "test")
                }
        }
        XCTAssertNoThrow(try response.wait())
    }

    func testPathWithSpecialCharacters() {
        let request = APIGateway.GetResourcesRequest(restApiId: "Test+%/*%25")
        let response = Self.apiGateway.getResources(request, logger: TestEnvironment.logger).map { _ in }

        XCTAssertThrowsError(try response.wait()) { error in
            switch error {
            case let error as AWSClientError where error == .invalidSignature:
                XCTFail()
            case let error as APIGatewayErrorType where error == .notFoundException:
                XCTAssertEqual(error.message, "Invalid API identifier specified 931875313149:Test+%/*%25")
            default:
                break
            }
        }
    }

    func testError() {
        let response = Self.apiGateway.getModels(.init(restApiId: "invalid-rest-api-id"), logger: TestEnvironment.logger)
        XCTAssertThrowsError(try response.wait()) { error in
            switch error {
            case let error as APIGatewayErrorType where error == .notFoundException:
                XCTAssertNotNil(error.message)
            default:
                // local stack is returning a duff error at the moment
                if TestEnvironment.isUsingLocalstack {
                    return
                }
                XCTFail("Wrong error: \(error)")
            }
        }
    }
}
