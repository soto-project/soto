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

import SotoSES
import XCTest

// testing json service

class SESTests: XCTestCase {
    static var client: AWSClient!
    static var ses: SES!

    override class func setUp() {
        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }

        self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middleware: TestEnvironment.middlewares)
        self.ses = SES(
            client: self.client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
    }

    override class func tearDown() {
        XCTAssertNoThrow(try self.client.syncShutdown())
    }

    // Tests query protocol requests with no body
    func testGetAccountSendingEnabled() async throws {
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)
        _ = try await Self.ses.getAccountSendingEnabled()
    }

    /* func testSESIdentityExistsWaiter() {
         let response = Self.ses.verifyEmailIdentity(.init(emailAddress: "admin@opticalaberration.com"))
             .flatMap{ _ in
                 return Self.ses.waitUntilIdentityExists(.init(identities: ["admin@opticalaberration.com"]))
             }
         XCTAssertNoThrow(try response.wait())
     } */

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
            XCTAssertEqual(request.url, URL(string: "https://email-fips.us-east-1.amazonaws.com/")!)
        }
        let ses = SES(client: Self.client, region: .useast1, options: .useFipsEndpoint).with(middleware: testMiddleware)
        do {
            _ = try await ses.createConfigurationSet(.init(configurationSet: .init(name: "test")))
        } catch is TestError {}
    }
}
