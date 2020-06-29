//===----------------------------------------------------------------------===//
//
// This source file is part of the AWSSDKSwift open source project
//
// Copyright (c) 2017-2020 the AWSSDKSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of AWSSDKSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import AWSSNS

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

        Self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middlewares: TestEnvironment.middlewares, httpClientProvider: .createNew)
        Self.sns = SNS(
            client: SNSTests.client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "SNS_ENDPOINT", default: "http://localhost:4566")
        )
    }

    override class func tearDown() {
        XCTAssertNoThrow(try Self.client.syncShutdown())
    }

    /// create SNS topic with supplied name and run supplied closure
    func testTopic(name: String, body: @escaping (String) -> EventLoopFuture<Void>) -> EventLoopFuture<Void> {
        let eventLoop = Self.sns.client.eventLoopGroup.next()
        var topicArn : String? = nil
        
        let request = SNS.CreateTopicInput(name: name)
        return Self.sns.createTopic(request)
            .flatMapThrowing { response in
                topicArn = try XCTUnwrap(response.topicArn)
                return topicArn!
        }
        .flatMap(body)
        .flatAlways { (_) -> EventLoopFuture<Void> in
            if let topicArn = topicArn {
                let request = SNS.DeleteTopicInput(topicArn: topicArn)
                return Self.sns.deleteTopic(request)
            } else {
                return eventLoop.makeSucceededFuture(())
            }
        }
    }
    
    //MARK: TESTS

    func testCreateDelete() {
        let name = TestEnvironment.generateResourceName()
        let response = testTopic(name: name) { topicArn in
            return Self.sns.client.eventLoopGroup.next().makeSucceededFuture(())
        }
        XCTAssertNoThrow(try response.wait())
    }

    func testListTopics() {
        let name = TestEnvironment.generateResourceName()
        let response = testTopic(name: name) { topicArn in
            let request = SNS.ListTopicsInput()
            return Self.sns.listTopics(request)
                .map { response in
                    let topic = response.topics?.first { $0.topicArn == topicArn }
                    XCTAssertNotNil(topic)
            }
        }
        XCTAssertNoThrow(try response.wait())
    }

    // disabled until we get valid topic arn's returned from Localstack
    func testSetTopicAttributes() {
        guard !TestEnvironment.isUsingLocalstack else { return }
        let name = TestEnvironment.generateResourceName()
        let response = testTopic(name: name) { topicArn in
            let request = SNS.SetTopicAttributesInput(
                attributeName: "DisplayName",
                attributeValue: "aws-test topic &",
                topicArn: topicArn
            )
            return Self.sns.setTopicAttributes(request)
                .flatMap { (_) -> EventLoopFuture<SNS.GetTopicAttributesResponse> in
                    let request = SNS.GetTopicAttributesInput(topicArn: topicArn)
                    return Self.sns.getTopicAttributes(request)
            }
            .map { response in
                XCTAssertEqual(response.attributes?["DisplayName"], "aws-test topic &")
            }
        }
        XCTAssertNoThrow(try response.wait())
    }
}
