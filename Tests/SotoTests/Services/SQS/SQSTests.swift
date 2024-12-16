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

@testable import SotoSQS

// testing query service

class SQSTests: XCTestCase {
    static var client: AWSClient!
    static var sqs: SQS!

    override class func setUp() {
        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }

        self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middleware: TestEnvironment.middlewares)
        self.sqs = SQS(
            client: SQSTests.client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
    }

    override class func tearDown() {
        XCTAssertNoThrow(try self.client.syncShutdown())
    }

    /// create SQS queue with supplied name and run supplied closure
    func testQueue(name: String, test: @escaping (String) async throws -> Void) async throws {
        try await XCTTestAsset {
            let request = SQS.CreateQueueRequest(queueName: name)
            let response = try await Self.sqs.createQueue(request)
            return try XCTUnwrap(response.queueUrl)
        } test: {
            try await test($0)
        } delete: {
            let request = SQS.DeleteQueueRequest(queueUrl: $0)
            try await Self.sqs.deleteQueue(request)
        }
    }

    func testSendReceiveAndDelete(name: String, messageBody: String) async throws {
        try await self.testQueue(name: name) { queueUrl in
            let request = SQS.SendMessageRequest(messageBody: messageBody, queueUrl: queueUrl)
            let response = try await Self.sqs.sendMessage(request)
            let messageId: String = try XCTUnwrap(response.messageId)
            let receiveRequest = SQS.ReceiveMessageRequest(maxNumberOfMessages: 10, queueUrl: queueUrl)
            let receiveResponse = try await Self.sqs.receiveMessage(receiveRequest)
            let message = try XCTUnwrap(receiveResponse.messages?.first)
            XCTAssertEqual(message.messageId, messageId)
            XCTAssertEqual(message.body, messageBody)
            let receiptHandle = try XCTUnwrap(message.receiptHandle)
            let deleteRequest = SQS.DeleteMessageRequest(queueUrl: queueUrl, receiptHandle: receiptHandle)
            try await Self.sqs.deleteMessage(deleteRequest)
        }
    }

    // MARK: TESTS

    func testSendReceiveAndDelete() async throws {
        let name = TestEnvironment.generateResourceName()
        try await self.testSendReceiveAndDelete(name: name, messageBody: "Testing, testing\n,1,2,1,2")
    }

    func testGetQueueAttributes() async throws {
        let name = TestEnvironment.generateResourceName()
        try await self.testQueue(name: name) { queueUrl in
            let request = SQS.GetQueueAttributesRequest(attributeNames: [.all], queueUrl: queueUrl)
            let response = try await Self.sqs.getQueueAttributes(request)
            XCTAssertNotNil(response.attributes?[.queueArn])
        }
    }

    func testTestPercentEncodedCharacters() async throws {
        let name = TestEnvironment.generateResourceName()
        try await self.testSendReceiveAndDelete(name: name, messageBody: "!@#$%^&*()-=_+[]{};':\",.<>\\|`~éñà")
    }

    func testSendBatch() async throws {
        // tests decoding of empty xml arrays
        let name = TestEnvironment.generateResourceName()
        try await self.testQueue(name: name) { queueUrl in
            let messageBody = "Testing, testing\n,1,2,1,2"
            let request = SQS.SendMessageBatchRequest(entries: [.init(id: "msg1", messageBody: messageBody)], queueUrl: queueUrl)
            _ = try await Self.sqs.sendMessageBatch(request)
        }
    }

    func testError() async throws {
        // get wrong error with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }
        await XCTAsyncExpectError(SQSErrorType.queueDoesNotExist) {
            try await Self.sqs.addPermission(.init(actions: [], awsAccountIds: [], label: "label", queueUrl: "http://aws-not-a-queue"))
        }
    }
}
