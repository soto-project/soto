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

import SotoSQS
import Testing

// testing query service

@Suite(.awsClient())
struct SQSTests {
    /// create SQS queue with supplied name and run supplied closure
    func testQueue(name: String, sqs: SQS, test: @escaping (String) async throws -> Void) async throws {
        try await XCTTestAsset {
            let request = SQS.CreateQueueRequest(queueName: name)
            let response = try await sqs.createQueue(request)
            return try #require(response.queueUrl)
        } test: {
            try await test($0)
        } delete: {
            let request = SQS.DeleteQueueRequest(queueUrl: $0)
            try await sqs.deleteQueue(request)
        }
    }

    func testSendReceiveAndDelete(name: String, messageBody: String, sqs: SQS) async throws {
        try await self.testQueue(name: name, sqs: sqs) { queueUrl in
            let request = SQS.SendMessageRequest(messageBody: messageBody, queueUrl: queueUrl)
            let response = try await sqs.sendMessage(request)
            let messageId: String = try #require(response.messageId)
            let receiveRequest = SQS.ReceiveMessageRequest(maxNumberOfMessages: 10, queueUrl: queueUrl)
            let receiveResponse = try await sqs.receiveMessage(receiveRequest)
            let message = try #require(receiveResponse.messages?.first)
            #expect(message.messageId == messageId)
            #expect(message.body == messageBody)
            let receiptHandle = try #require(message.receiptHandle)
            let deleteRequest = SQS.DeleteMessageRequest(queueUrl: queueUrl, receiptHandle: receiptHandle)
            try await sqs.deleteMessage(deleteRequest)
        }
    }

    // MARK: TESTS

    @Test func testSendReceiveAndDelete() async throws {
        let sqs = SQS(client: AWSClientTrait.client, region: .useast1)
        let name = TestEnvironment.generateResourceName()
        try await self.testSendReceiveAndDelete(name: name, messageBody: "Testing, testing\n,1,2,1,2", sqs: sqs)
    }

    @Test func testGetQueueAttributes() async throws {
        let sqs = SQS(client: AWSClientTrait.client, region: .useast1)
        let name = TestEnvironment.generateResourceName()
        try await self.testQueue(name: name, sqs: sqs) { queueUrl in
            let request = SQS.GetQueueAttributesRequest(attributeNames: [.all], queueUrl: queueUrl)
            let response = try await sqs.getQueueAttributes(request)
            #expect(response.attributes?[.queueArn] != nil)
        }
    }

    @Test func testTestPercentEncodedCharacters() async throws {
        let sqs = SQS(client: AWSClientTrait.client, region: .useast1)
        let name = TestEnvironment.generateResourceName()
        try await self.testSendReceiveAndDelete(name: name, messageBody: "!@#$%^&*()-=_+[]{};':\",.<>\\|`~éñà", sqs: sqs)
    }

    @Test func testSendBatch() async throws {
        let sqs = SQS(client: AWSClientTrait.client, region: .useast1)
        // tests decoding of empty xml arrays
        let name = TestEnvironment.generateResourceName()
        try await self.testQueue(name: name, sqs: sqs) { queueUrl in
            let messageBody = "Testing, testing\n,1,2,1,2"
            let request = SQS.SendMessageBatchRequest(entries: [.init(id: "msg1", messageBody: messageBody)], queueUrl: queueUrl)
            _ = try await sqs.sendMessageBatch(request)
        }
    }

    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Get wrong error when using Localstack"))
    func testError() async throws {
        let sqs = SQS(client: AWSClientTrait.client, region: .useast1)
        let error = await #expect(throws: SQSErrorType.self) {
            try await sqs.addPermission(.init(actions: [], awsAccountIds: [], label: "label", queueUrl: "http://aws-not-a-queue"))
        }
        #expect(error?.error == .queueDoesNotExist)
    }
}
