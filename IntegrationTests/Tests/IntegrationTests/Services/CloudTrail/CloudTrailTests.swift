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
import SotoCloudTrail
import Testing

@Suite(
    .disabled(if: TestEnvironment.isUsingLocalstack, "Cloud trail tests don't work with localstack"),
    .awsClient(),
)
struct CloudTrailTests {
    @Test func testLookupEvents() async throws {
        let cloudTrail = CloudTrail(client: AWSClientTrait.client, region: .euwest1)
        let from = Date(timeIntervalSinceNow: -1 * 24 * 60 * 60)
        let to = Date()
        let request = CloudTrail.LookupEventsRequest(endTime: to, lookupAttributes: nil, startTime: from)
        let response = try await cloudTrail.lookupEvents(request)
        let event = try #require(response.events?.first)
        #expect(event.eventTime != nil)
    }

    @Test func testError() async throws {
        let cloudTrail = CloudTrail(client: AWSClientTrait.client, region: .euwest1)
        let error = await #expect(throws: CloudTrailErrorType.self) {
            _ = try await cloudTrail.getTrail(.init(name: "nonexistent-trail"))
        }
        #expect(error?.error == .trailNotFoundException)
    }
}
