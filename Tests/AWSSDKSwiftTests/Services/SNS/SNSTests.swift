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

import Foundation
import XCTest

@testable import AWSSNS

enum SNSTestsError: Error {
    case noTopicArn
}

// testing query service

class SNSTests: XCTestCase {

    let sns = SNS(
        region: .useast1,
        endpoint: TestEnvironment.getEndPoint(environment: "SNS_ENDPOINT", default: "http://localhost:4575"),
        middlewares: TestEnvironment.middlewares,
        httpClientProvider: .createNew
    )

    /// create SNS topic with supplied name and run supplied closure
    func testTopic(name: String, body: @escaping (String) -> EventLoopFuture<Void>) -> EventLoopFuture<Void> {
        let eventLoop = self.sns.client.eventLoopGroup.next()
        var topicArn : String? = nil
        
        let request = SNS.CreateTopicInput(name: name)
        return sns.createTopic(request)
            .flatMapThrowing { response in
                topicArn = try XCTUnwrap(response.topicArn)
                return topicArn!
        }
        .flatMap(body)
        .flatAlways { (_) -> EventLoopFuture<Void> in
            if let topicArn = topicArn {
                let request = SNS.DeleteTopicInput(topicArn: topicArn)
                return self.sns.deleteTopic(request)
            } else {
                return eventLoop.makeSucceededFuture(())
            }
        }
    }
    
    //MARK: TESTS

    func testCreateDelete() {
        let name = TestEnvironment.getName(#function)
        let response = testTopic(name: name) { topicArn in
            return self.sns.client.eventLoopGroup.next().makeSucceededFuture(())
        }
        XCTAssertNoThrow(try response.wait())
    }

    func testListTopics() {
        let name = TestEnvironment.getName(#function)
        let response = testTopic(name: name) { topicArn in
            let request = SNS.ListTopicsInput()
            return self.sns.listTopics(request)
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
        let name = TestEnvironment.getName(#function)
        let response = testTopic(name: name) { topicArn in
            let request = SNS.SetTopicAttributesInput(
                attributeName: "DisplayName",
                attributeValue: "aws-test topic &",
                topicArn: topicArn
            )
            return self.sns.setTopicAttributes(request)
                .flatMap { (_) -> EventLoopFuture<SNS.GetTopicAttributesResponse> in
                    let request = SNS.GetTopicAttributesInput(topicArn: topicArn)
                    return self.sns.getTopicAttributes(request)
            }
            .map { response in
                XCTAssertEqual(response.attributes?["DisplayName"], "aws-test topic &")
            }
        }
        XCTAssertNoThrow(try response.wait())
    }

    static var allTests: [(String, (SNSTests) -> () throws -> Void)] {
        return [
            ("testCreateDelete", testCreateDelete),
            ("testListTopics", testListTopics),
            ("testSetTopicAttributes", testSetTopicAttributes),
        ]
    }
}
