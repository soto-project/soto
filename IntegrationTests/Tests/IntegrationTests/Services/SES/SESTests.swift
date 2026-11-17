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
import SotoSES
import Testing

@Suite(
    .awsClient(),
    .disabled(if: TestEnvironment.isUsingLocalstack, "SES tests don't work with localstack")
)
struct SESTests {
    // Tests query protocol requests with no body
    func testGetAccountSendingEnabled() async throws {
        let ses = SES(client: AWSClientTrait.client, region: .useast1)
        _ = try await ses.getAccountSendingEnabled()
    }

    // test fips region
    func testFipsRegion() async throws {
        struct TestError: Error {}
        struct TestRequestMiddleware: AWSMiddlewareProtocol {
            let test: @Sendable (AWSHTTPRequest) -> Void

            func handle(
                _ request: AWSHTTPRequest,
                context: AWSMiddlewareContext,
                next: (AWSHTTPRequest, AWSMiddlewareContext) async throws -> AWSHTTPResponse
            ) async throws -> AWSHTTPResponse {
                self.test(request)
                throw TestError()
            }
        }
        let testMiddleware = TestRequestMiddleware { request in
            #expect(request.request.url == URL(string: "https://email-fips.us-east-1.amazonaws.com/")!)
        }
        let fipsSES = SES(client: AWSClientTrait.client, region: .useast1, options: .useFipsEndpoint).with(middleware: testMiddleware)
        await #expect(throws: TestError.self) {
            _ = try await fipsSES.createConfigurationSet(.init(configurationSet: .init(name: "test")))
        }
    }
}
