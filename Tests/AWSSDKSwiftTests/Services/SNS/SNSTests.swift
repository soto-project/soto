//
// SNSTests.swift
// written by Adam Fowler
// SNS tests
//
import XCTest
import Foundation
@testable import AWSSDKSwiftCore
@testable import SNS

enum SNSTestsError : Error {
    case noTopicArn
}

// testing query service

class SNSTests: XCTestCase {

    let client = SNS(
        accessKeyId: "key",
        secretAccessKey: "secret",
        region: .useast1,
        endpoint: ProcessInfo.processInfo.environment["SNS_ENDPOINT"] ?? "http://localhost:4566"
    )

    class TestData {
        var client: SNS
        var topicName: String
        var topicArn: String

        init(_ testName: String, client: SNS) throws {
            let testName = testName.lowercased().filter { return $0.isLetter }
            self.client = client
            self.topicName = "\(testName)-topic"

            let request = SNS.CreateTopicInput(name: topicName)
            let response = try client.createTopic(request).wait()
            guard let topicArn = response.topicArn else {throw SNSTestsError.noTopicArn}
            
            self.topicArn = topicArn
        }
        
        deinit {
            attempt {
                // disabled until we get valid topic arn's returned from Localstack
                #if false
                let request = SNS.DeleteTopicInput(topicArn: self.topicArn)
                _ = try client.deleteTopic(request).wait()
                #endif
            }
        }
    }

    //MARK: TESTS
    
    func testCreateDelete() {
        attempt {
            _ = try TestData(#function, client: client)
        }
    }
    
    func testListTopics() {
        attempt {
            let testData = try TestData(#function, client: client)

            let request = SNS.ListTopicsInput()
            let response = try client.listTopics(request).wait()
            let topic = response.topics?.first {$0.topicArn == testData.topicArn }
            XCTAssertNotNil(topic)
        }
    }
    
    // disabled until we get valid topic arn's returned from Localstack
    #if false
    func testSetTopicAttributes() {
        attempt {
            let testData = try TestData(#function, client: client)

            let setTopicAttributesInput = SNS.SetTopicAttributesInput(attributeName:"DisplayName", attributeValue: "aws-test topic", topicArn: testData.topicArn)
            try client.setTopicAttributes(setTopicAttributesInput).wait()
            
            let getTopicAttributesInput = SNS.GetTopicAttributesInput(topicArn: testData.topicArn)
            let getTopicAttributesResponse = try client.getTopicAttributes(getTopicAttributesInput).wait()
            
            XCTAssertEqual(getTopicAttributesResponse.attributes?["DisplayName"], "aws-test topic")
        }
    }
    #endif
    
    static var allTests : [(String, (SNSTests) -> () throws -> Void)] {
        return [
            ("testCreateDelete", testCreateDelete),
            ("testListTopics", testListTopics),
//            ("testSetTopicAttributes", testSetTopicAttributes),
        ]
    }
}


