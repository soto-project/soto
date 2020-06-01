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
@testable import AWSSTS

// testing query service

class STSTests: XCTestCase {

    let sqs = STS(
        region: .useast1,
        endpoint: TestEnvironment.getEndPoint(environment: "STS_ENDPOINT", default: "http://localhost:4592"),
        middlewares: TestEnvironment.middlewares,
        httpClientProvider: .createNew
    )

    override class func setUp() {
        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }
    }



    static var allTests: [(String, (SQSTests) -> () throws -> Void)] {
        return [
 //           ("testSendReceiveAndDelete", testSendReceiveAndDelete),
        ]
    }
}

