//
// SQSTests.swift
// written by Adam Fowler
// SQS tests
//
import XCTest
import Foundation
@testable import AWSSDKSwiftCore
@testable import SQS

enum SQSTestsError : Error {
    case noQueueUrl
}

// testing query service

class SQSTests: XCTestCase {

    let client = SQS(
        accessKeyId: "key",
        secretAccessKey: "secret",
        region: .useast1,
        endpoint: ProcessInfo.processInfo.environment["SQS_ENDPOINT"] ?? "http://localhost:4576"
    )

    class TestData {
        var client: SQS
        var queueName: String
        var queueUrl: String

        init(_ testName: String, client: SQS) throws {
            let testName = testName.lowercased().filter { return $0.isLetter }
            self.client = client
            self.queueName = "\(testName)-queue"

            let request = SQS.CreateQueueRequest(queueName: self.queueName)
            let response = try client.createQueue(request).wait()
            XCTAssertNotNil(response.queueUrl)
            guard let queueUrl = response.queueUrl else {throw SQSTestsError.noQueueUrl}
            
            self.queueUrl = queueUrl
        }
        
        deinit {
            attempt {
                let request = SQS.DeleteQueueRequest(queueUrl: self.queueUrl)
                try client.deleteQueue(request).wait()
            }
        }
    }

    //MARK: TESTS
    
    func testSendReceiveAndDelete() {
        attempt {
            let testData = try TestData(#function, client: client)

            let messageBody = "Testing, testing,1,2,1,2"
            let sendMessageRequest = SQS.SendMessageRequest(messageBody: messageBody, queueUrl: testData.queueUrl)
            let messageId = try client.sendMessage(sendMessageRequest).wait().messageId
            
            // receive message tests the flattened arrays in XML response
            let receiveMessageRequest = SQS.ReceiveMessageRequest(maxNumberOfMessages: 10, queueUrl: testData.queueUrl)
            let messages = try client.receiveMessage(receiveMessageRequest).wait().messages ?? []
            
            guard let message = messages.first else {
                XCTFail("Expected to get first message")
                return
            }
            XCTAssertEqual(message.messageId, messageId)
            guard let body = message.body else {
                XCTFail("Expected to have message body")
                return
            }
            XCTAssertEqual(body, messageBody)
            guard let receiptHandle = message.receiptHandle else {
                XCTFail("Expected to have message receiptHandle")
                return
            }
            let deleteRequest = SQS.DeleteMessageRequest(queueUrl: testData.queueUrl, receiptHandle: receiptHandle)
            try client.deleteMessage(deleteRequest).wait()
        }
    }
    
    func testGetQueueAttributes() {
        attempt {
            let testData = try TestData(#function, client: client)

            let request = SQS.GetQueueAttributesRequest(attributeNames:[.queuearn], queueUrl: testData.queueUrl)
            let result = try client.getQueueAttributes(request).wait()
            XCTAssertNotNil(result.attributes?[.queuearn])
        }
    }
    
    func testTestPercentEncodedCharacters() {
        attempt {
            let testData = try TestData(#function, client: client)

            let messageBody = "!@#$%^&*()-=_+[]{};':\",.<>\\|`~éñà"
            let sendMessageRequest = SQS.SendMessageRequest(messageBody: messageBody, queueUrl: testData.queueUrl)
            let messageId = try client.sendMessage(sendMessageRequest).wait().messageId
            
            let receiveMessageRequest = SQS.ReceiveMessageRequest(maxNumberOfMessages: 10, queueUrl: testData.queueUrl)
            let messages = try client.receiveMessage(receiveMessageRequest).wait().messages ?? []
            
            guard let message = messages.first else {
                XCTFail("Expected to get first message")
                return
            }
            XCTAssertEqual(message.messageId, messageId)
            guard let body = message.body else {
                XCTFail("Expected to have message body")
                return
            }
            XCTAssertEqual(body, messageBody)
            guard let receiptHandle = message.receiptHandle else {
                XCTFail("Expected to have message receiptHandle")
                return
            }
            let deleteRequest = SQS.DeleteMessageRequest(queueUrl: testData.queueUrl, receiptHandle: receiptHandle)
            try client.deleteMessage(deleteRequest).wait()
        }
    }

    static var allTests : [(String, (SQSTests) -> () throws -> Void)] {
        return [
            ("testSendReceiveAndDelete", testSendReceiveAndDelete),
            ("testGetQueueAttributes", testGetQueueAttributes),
            ("testTestPercentEncodedCharacters", testTestPercentEncodedCharacters),
        ]
    }
}

