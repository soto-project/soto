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

@testable import SotoSQS
import XCTest

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

        Self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middlewares: TestEnvironment.middlewares, httpClientProvider: .createNew)
        Self.sqs = SQS(
            client: SQSTests.client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
    }

    override class func tearDown() {
        XCTAssertNoThrow(try Self.client.syncShutdown())
    }

    /// create SQS queue with supplied name and run supplied closure
    func testQueue(name: String, body: @escaping (String) -> EventLoopFuture<Void>) -> EventLoopFuture<Void> {
        let eventLoop = Self.sqs.client.eventLoopGroup.next()
        var queueUrl: String?

        let request = SQS.CreateQueueRequest(queueName: name)
        return Self.sqs.createQueue(request)
            .flatMapThrowing { response in
                queueUrl = try XCTUnwrap(response.queueUrl)
                return queueUrl!
            }
            .flatMap(body)
            .flatAlways { (_) -> EventLoopFuture<Void> in
                if let queueUrl = queueUrl {
                    let request = SQS.DeleteQueueRequest(queueUrl: queueUrl)
                    return Self.sqs.deleteQueue(request)
                } else {
                    return eventLoop.makeSucceededFuture(())
                }
            }
    }

    func testSendReceiveAndDelete(name: String, messageBody: String) -> EventLoopFuture<Void> {
        return self.testQueue(name: name) { queueUrl in
            let request = SQS.SendMessageRequest(messageBody: messageBody, queueUrl: queueUrl)
            return Self.sqs.sendMessage(request)
                .flatMapThrowing { (response) throws -> String in
                    let messageId = try XCTUnwrap(response.messageId)
                    return messageId
                }
                .flatMap { messageId -> EventLoopFuture<(SQS.ReceiveMessageResult, String)> in
                    let request = SQS.ReceiveMessageRequest(maxNumberOfMessages: 10, queueUrl: queueUrl)
                    return Self.sqs.receiveMessage(request).map { ($0, messageId) }
                }
                .flatMapThrowing { (result, messageId) -> String in
                    let message = try XCTUnwrap(result.messages?.first)
                    XCTAssertEqual(message.messageId, messageId)
                    XCTAssertEqual(message.body, messageBody)
                    let receiptHandle = try XCTUnwrap(message.receiptHandle)
                    return receiptHandle
                }
                .flatMap { receiptHandle -> EventLoopFuture<Void> in
                    let request = SQS.DeleteMessageRequest(queueUrl: queueUrl, receiptHandle: receiptHandle)
                    return Self.sqs.deleteMessage(request).map { _ in }
                }
        }
    }

    // MARK: TESTS

    func testSendReceiveAndDelete() {
        let name = TestEnvironment.generateResourceName()
        let response = self.testSendReceiveAndDelete(name: name, messageBody: "Testing, testing\n,1,2,1,2")
        XCTAssertNoThrow(try response.wait())
    }

    func testGetQueueAttributes() {
        let name = TestEnvironment.generateResourceName()
        let response = self.testQueue(name: name) { queueUrl in
            let request = SQS.GetQueueAttributesRequest(attributeNames: [.queuearn], queueUrl: queueUrl)
            return Self.sqs.getQueueAttributes(request)
                .map { response in
                    XCTAssertNotNil(response.attributes?[.queuearn])
                }
        }
        XCTAssertNoThrow(try response.wait())
    }

    func testTestPercentEncodedCharacters() {
        let name = TestEnvironment.generateResourceName()
        let response = self.testSendReceiveAndDelete(name: name, messageBody: "!@#$%^&*()-=_+[]{};':\",.<>\\|`~éñà")
        XCTAssertNoThrow(try response.wait())
    }

    func testSendBatch() {
        // tests decoding of empty xml arrays
        let name = TestEnvironment.generateResourceName()
        let response = self.testQueue(name: name) { queueUrl in
            let messageBody = "Testing, testing\n,1,2,1,2"
            let request = SQS.SendMessageBatchRequest(entries: [.init(id: "msg1", messageBody: messageBody)], queueUrl: queueUrl)
            return Self.sqs.sendMessageBatch(request).map { _ in }
        }
        XCTAssertNoThrow(try response.wait())
    }

    func testError() {
        // get wrong error with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }
        let response = Self.sqs.addPermission(.init(actions: [], aWSAccountIds: [], label: "label", queueUrl: "http://aws-not-a-queue"))
        XCTAssertThrowsError(try response.wait()) { error in
            switch error {
            case let error as SQSErrorType where error == .queueDoesNotExist:
                XCTAssertNotNil(error.message)
            default:
                XCTFail("Wrong error: \(error)")
            }
        }
    }
}
