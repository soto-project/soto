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

@testable import SotoApiGatewayV2
import XCTest

enum APIGatewayV2TestsError: Error {
    case noApi
}

class APIGatewayV2Tests: XCTestCase {
    static var client: AWSClient!
    static var apiGatewayV2: ApiGatewayV2!

    static let restApiName: String = TestEnvironment.generateResourceName("ApiGatewayV2Tests")
    static var restApiId: String!

    override class func setUp() {
        guard !TestEnvironment.isUsingLocalstack else { return }
        Self.client = AWSClient(
            credentialProvider: TestEnvironment.credentialProvider,
            middlewares: TestEnvironment.middlewares,
            httpClientProvider: .createNew,
            logger: TestEnvironment.logger
        )
        Self.apiGatewayV2 = ApiGatewayV2(
            client: Self.client,
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
        let eventLoop = self.apiGatewayV2.client.eventLoopGroup.next()
        let createResult = self.createRestApi(name: self.restApiName, on: eventLoop)
            .flatMapErrorThrowing { error in
                print("Failed to create APIGateway rest api, error: \(error)")
                throw error
            }
        XCTAssertNoThrow(Self.restApiId = try createResult.wait())
    }

    override class func tearDown() {
        guard !TestEnvironment.isUsingLocalstack else { return }
        XCTAssertNoThrow(_ = try self.deleteRestApi(id: self.restApiId).wait())
        XCTAssertNoThrow(try self.client.syncShutdown())
    }

    static func createRestApi(name: String, on eventLoop: EventLoop) -> EventLoopFuture<String> {
        return self.apiGatewayV2.getApis(.init(), logger: TestEnvironment.logger)
            .flatMap { response in
                if let restApi = response.items?.first(where: { $0.name == name }) {
                    guard let apiId = restApi.apiId else { return eventLoop.makeFailedFuture(APIGatewayV2TestsError.noApi) }
                    return eventLoop.makeSucceededFuture(apiId)
                } else {
                    let request = ApiGatewayV2.CreateApiRequest(
                        description: "\(name) API",
                        name: name,
                        protocolType: .http
                    )
                    return Self.apiGatewayV2.createApi(request, logger: TestEnvironment.logger).flatMapThrowing { response -> String in
                        let apiId = try XCTUnwrap(response.apiId)
                        return apiId
                    }
                }
            }
    }

    static func deleteRestApi(id: String) -> EventLoopFuture<Void> {
        return self.apiGatewayV2.deleteApi(.init(apiId: id), logger: TestEnvironment.logger).map {}
    }

    /// create Rest api with supplied name and run supplied closure with rest api id
    func testRestApi(body: @escaping (String) -> EventLoopFuture<Void>) -> EventLoopFuture<Void> {
        body(Self.restApiId)
    }

    // MARK: TESTS

    /// tests whether created date is loading correctly
    func testGetApis() {
        guard !TestEnvironment.isUsingLocalstack else { return }
        // get date from 1 minute before now.
        let date = Date(timeIntervalSinceNow: -60.0)
        let response = self.testRestApi { id in
            return Self.apiGatewayV2.getApis(.init(), logger: TestEnvironment.logger)
                .flatMapThrowing { response in
                    let restApi = response.items?.first(where: { $0.apiId == id })
                    XCTAssertNotNil(restApi)
                    XCTAssertEqual(restApi?.name, Self.restApiName)
                    let createdDate = try XCTUnwrap(restApi?.createdDate)
                    XCTAssertGreaterThanOrEqual(createdDate, date)
                }
        }
        XCTAssertNoThrow(try response.wait())
    }
}
