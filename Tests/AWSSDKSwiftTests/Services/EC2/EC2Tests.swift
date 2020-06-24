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

@testable import AWSEC2

// testing EC2 service

class EC2Tests: XCTestCase {

    var ec2 = EC2(
        credentialProvider: TestEnvironment.credentialProvider,
        region: .useast1,
        endpoint: ProcessInfo.processInfo.environment["EC2_ENDPOINT"] ?? "http://localhost:4566",
        middlewares: (ProcessInfo.processInfo.environment["AWS_ENABLE_LOGGING"] == "true") ? [AWSLoggingMiddleware()] : [],
        httpClientProvider: .createNew
    )

    func testRunInstances() {
        let imageRequest = EC2.DescribeImagesRequest(filters: .init([EC2.Filter(name: "name", values: ["*ubuntu*"]), EC2.Filter(name: "state", values: ["available"])]))
        let response = ec2.describeImages(imageRequest)
        XCTAssertNoThrow(try response.wait())
    }
    
    static var allTests: [(String, (EC2Tests) -> () throws -> Void)] {
        return [
            ("testRunInstances", testRunInstances),
        ]
    }
}

