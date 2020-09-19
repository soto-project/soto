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
import XCTest

@testable import SotoEC2

// testing EC2 service

class EC2Tests: XCTestCase {
    static var client: AWSClient!
    static var ec2: EC2!

    override class func setUp() {
        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }

        Self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middlewares: TestEnvironment.middlewares, httpClientProvider: .createNew)
        Self.ec2 = EC2(
            client: EC2Tests.client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
    }

    override class func tearDown() {
        XCTAssertNoThrow(try Self.client.syncShutdown())
    }

    func testDescribeImages() {
        let imageRequest = EC2.DescribeImagesRequest(filters: .init([EC2.Filter(name: "name", values: ["*ubuntu-18.04-v1.15*"]), EC2.Filter(name: "state", values: ["available"])]))
        let response = Self.ec2.describeImages(imageRequest)
        XCTAssertNoThrow(try response.wait())
    }
    
    func testError() {
        let response = Self.ec2.getConsoleOutput(.init(instanceId: "not-an-instance"))
        XCTAssertThrowsError(try response.wait()) { error in
            switch error {
            case let awsError as AWSResponseError:
                XCTAssertEqual(awsError.errorCode, "InvalidInstanceID.Malformed")
            default:
                XCTFail("Wrong error: \(error)")
            }
        }
    }
}
