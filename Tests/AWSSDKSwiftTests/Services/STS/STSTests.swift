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

    let sts = STS(
        region: .useast1,
        endpoint: TestEnvironment.getEndPoint(environment: "STS_ENDPOINT", default: "http://localhost:4566"),
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

    func testGetCallerIdentity() {
        let response = sts.getCallerIdentity(.init())
        XCTAssertNoThrow(try response.wait())
    }

    func testErrorCodes() {
        let request = STS.AssumeRoleWithWebIdentityRequest(roleArn: "arn:aws:iam::000000000000:role/Admin", roleSessionName: "now", webIdentityToken: "webtoken")
        let response = sts.assumeRoleWithWebIdentity(request)
            .map { _ in }
            .flatMapErrorThrowing { error in
                switch error {
                case STSErrorType.invalidIdentityTokenException(_):
                    return
                default:
                    throw error
                }
        }
        XCTAssertNoThrow(try response.wait())
    }


    static var allTests: [(String, (STSTests) -> () throws -> Void)] {
        return [
            ("testGetCallerIdentity", testGetCallerIdentity),
            ("testErrorCodes", testErrorCodes),
        ]
    }
}

