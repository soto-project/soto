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

import SotoCloudTrail
import XCTest

class CloudTrailTests: XCTestCase {
    static var client: AWSClient!
    static var cloudTrail: CloudTrail!

    override class func setUp() {
        Self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middlewares: TestEnvironment.middlewares, httpClientProvider: .createNew)
        Self.cloudTrail = CloudTrail(
            client: CloudTrailTests.client,
            region: .euwest1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )

        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }
    }

    override class func tearDown() {
        XCTAssertNoThrow(try self.client.syncShutdown())
    }

    func testLookupEvents() {
        // This doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }
        let from = Date(timeIntervalSinceNow: -1 * 24 * 60 * 60)
        let to = Date()
        let request = CloudTrail.LookupEventsRequest(endTime: to, lookupAttributes: nil, startTime: from)
        let response = Self.cloudTrail.lookupEvents(request)
            .flatMapThrowing { response in
                if let event = response.events?.first {
                    XCTAssertNotNil(event.eventTime)
                }
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testError() {
        // This doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }
        let response = Self.cloudTrail.getTrail(.init(name: "nonexistent-trail"))
        XCTAssertThrowsError(try response.wait()) { error in
            switch error {
            case let error as CloudTrailErrorType where error == .trailNotFoundException:
                XCTAssertNotNil(error.message)
            default:
                XCTFail("Wrong error: \(error)")
            }
        }
    }
}
