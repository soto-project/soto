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

        Self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middlewares: TestEnvironment.middlewares, httpClientProvider: .createNew)
        Self.ses = SES(
            client: Self.client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
    }

    override class func tearDown() {
        XCTAssertNoThrow(try Self.client.syncShutdown())
    }

    // Tests query protocol requests with no body
    func testGetAccountSendingEnabled() throws {
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)
        XCTAssertNoThrow(_ = try Self.ses.getAccountSendingEnabled().wait())
    }

    // test fips region
    func testFipsRegion() async throws {
        struct TestError: Error {}
        struct TestRequestMiddleware: AWSServiceMiddleware {
            let test: @Sendable (AWSRequest) -> Void
            func chain(request: AWSRequest, context: AWSMiddlewareContext) throws -> AWSRequest {
                self.test(request)
                throw TestError()
            }
        }
        let testMiddleware = TestRequestMiddleware { request in
            XCTAssertEqual(request.url, URL(string: "https://email-fips.us-east-1.amazonaws.com/")!)
        }
        let ses = SES(client: Self.client, region: .other("fips-us-east-1")).with(middlewares: [testMiddleware])
        do {
            _ = try await ses.createConfigurationSet(.init(configurationSet: .init(name: "test")))
        } catch is TestError {}
    }

    /* func testSESIdentityExistsWaiter() {
         let response = Self.ses.verifyEmailIdentity(.init(emailAddress: "admin@opticalaberration.com"))
             .flatMap{ _ in
                 return Self.ses.waitUntilIdentityExists(.init(identities: ["admin@opticalaberration.com"]))
             }
         XCTAssertNoThrow(try response.wait())
     } */
}
