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

import SotoSNS
import Testing

// testing query service

@Suite(.awsClient())
struct SNSTests {
    /// create SNS topic with supplied name and run supplied closure
    func testTopic(name: String, sns: SNS, test: @escaping (String) async throws -> Void) async throws {
        try await XCTTestAsset {
            let createRequest = SNS.CreateTopicInput(name: name)
            let createResponse = try await sns.createTopic(createRequest)
            return try #require(createResponse.topicArn)
        } test: {
            try await test($0)
        } delete: {
            let deleteRequest = SNS.DeleteTopicInput(topicArn: $0)
            try await sns.deleteTopic(deleteRequest)
        }
    }

    // MARK: TESTS

    @Test func testCreateDelete() async throws {
        let sns = SNS(client: AWSClientTrait.client, region: .useast1)
        let name = TestEnvironment.generateResourceName()
        try await self.testTopic(name: name, sns: sns) { _ in }
    }

    @Test func testListTopics() async throws {
        let sns = SNS(client: AWSClientTrait.client, region: .useast1)
        let name = TestEnvironment.generateResourceName()
        try await self.testTopic(name: name, sns: sns) { topicArn in
            let request = SNS.ListTopicsInput()
            let response = try await sns.listTopics(request)
            let topic = response.topics?.first { $0.topicArn == topicArn }
            #expect(topic != nil)
        }
    }

    // disabled until we get valid topic arn's returned from Localstack
    @Test func testSetTopicAttributes() async throws {
        let sns = SNS(client: AWSClientTrait.client, region: .useast1)
        guard !TestEnvironment.isUsingLocalstack else { return }
        let name = TestEnvironment.generateResourceName()
        try await self.testTopic(name: name, sns: sns) { topicArn in
            let request = SNS.SetTopicAttributesInput(
                attributeName: "DisplayName",
                attributeValue: "aws-test topic &",
                topicArn: topicArn
            )
            _ = try await sns.setTopicAttributes(request)
            let getRequest = SNS.GetTopicAttributesInput(topicArn: topicArn)
            let getResponse = try await sns.getTopicAttributes(getRequest)
            #expect(getResponse.attributes?["DisplayName"] == "aws-test topic &")
        }
    }

    @Test func testError() async throws {
        let sns = SNS(client: AWSClientTrait.client, region: .useast1)
        guard !TestEnvironment.isUsingLocalstack else { return }
        let error = await XCTAsyncExpectError(SNSErrorType.self) {
            _ = try await sns.getTopicAttributes(.init(topicArn: "arn:sns:invalid"))
        }
        switch error?.error {
        case .invalidParameterException:
            break
        default:
            Issue.record()
        }
    }
}
