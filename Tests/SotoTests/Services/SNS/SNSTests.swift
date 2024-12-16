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

@testable import SotoSNS

// testing query service

class SNSTests: XCTestCase {
    static var client: AWSClient!
    static var sns: SNS!

    override class func setUp() {
        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }

        self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middleware: TestEnvironment.middlewares)
        self.sns = SNS(
            client: SNSTests.client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
    }

    override class func tearDown() {
        XCTAssertNoThrow(try self.client.syncShutdown())
    }

    /// create SNS topic with supplied name and run supplied closure
    func testTopic(name: String, test: @escaping (String) async throws -> Void) async throws {
        try await XCTTestAsset {
            let createRequest = SNS.CreateTopicInput(name: name)
            let createResponse = try await Self.sns.createTopic(createRequest)
            return try XCTUnwrap(createResponse.topicArn)
        } test: {
            try await test($0)
        } delete: {
            let deleteRequest = SNS.DeleteTopicInput(topicArn: $0)
            try await Self.sns.deleteTopic(deleteRequest)
        }
    }

    // MARK: TESTS

    func testCreateDelete() async throws {
        let name = TestEnvironment.generateResourceName()
        try await self.testTopic(name: name) { _ in }
    }

    func testListTopics() async throws {
        let name = TestEnvironment.generateResourceName()
        try await self.testTopic(name: name) { topicArn in
            let request = SNS.ListTopicsInput()
            let response = try await Self.sns.listTopics(request)
            let topic = response.topics?.first { $0.topicArn == topicArn }
            XCTAssertNotNil(topic)
        }
    }

    // disabled until we get valid topic arn's returned from Localstack
    func testSetTopicAttributes() async throws {
        guard !TestEnvironment.isUsingLocalstack else { return }
        let name = TestEnvironment.generateResourceName()
        try await self.testTopic(name: name) { topicArn in
            let request = SNS.SetTopicAttributesInput(
                attributeName: "DisplayName",
                attributeValue: "aws-test topic &",
                topicArn: topicArn
            )
            _ = try await Self.sns.setTopicAttributes(request)
            let getRequest = SNS.GetTopicAttributesInput(topicArn: topicArn)
            let getResponse = try await Self.sns.getTopicAttributes(getRequest)
            XCTAssertEqual(getResponse.attributes?["DisplayName"], "aws-test topic &")
        }
    }

    func testError() async throws {
        guard !TestEnvironment.isUsingLocalstack else { return }
        await XCTAsyncExpectError(SNSErrorType.invalidParameterException) {
            _ = try await Self.sns.getTopicAttributes(.init(topicArn: "arn:sns:invalid"))
        }
    }
}
