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

import Foundation
import SotoApiGatewayV2
import Testing

enum APIGatewayV2TestsError: Error {
    case noApi
}

@Suite(
    .disabled(if: TestEnvironment.isUsingLocalstack, "APIGatewayV2 tests don't work with localstack"),
    .awsClient()
)
struct APIGatewayV2Tests {
    /// tests whether created date is loading correctly
    @Test
    func testGetApis() async throws {
        let apiGatewayV2 = ApiGatewayV2(client: AWSClientTrait.client, region: .euwest1)
        let restApiName: String = TestEnvironment.generateResourceName("ApiGatewayV2Tests")

        try await testAsset {
            let response = try await apiGatewayV2.getApis(.init(), logger: TestEnvironment.logger)
            if let restApi = response.items?.first(where: { $0.name == restApiName }) {
                return restApi.apiId
            }
            return try await apiGatewayV2.createApi(description: "\(restApiName) API", name: restApiName, protocolType: .http).apiId
        } test: { id in
            let id = try #require(id)
            let response = try await apiGatewayV2.getApis(.init(), logger: TestEnvironment.logger)
            let restApi = try #require(response.items?.first(where: { $0.apiId == id }))
            #expect(restApi.name == restApiName)
            let createdDate = try #require(restApi.createdDate)
            #expect(createdDate > Date(timeIntervalSinceNow: -60.0))
        } delete: { id in
            let id = try #require(id)
            try await apiGatewayV2.deleteApi(apiId: id)
        }
    }
}
