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

import NIO
import SotoLambda
import XCTest

// testing query service

class LambdaTests: XCTestCase {
    static var client: AWSClient!
    static var lambda: Lambda!

    override class func setUp() {
        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }

        Self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middlewares: TestEnvironment.middlewares, httpClientProvider: .createNew)
        Self.lambda = Lambda(
            client: LambdaTests.client,
            region: .euwest1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
    }

    override class func tearDown() {
        XCTAssertNoThrow(try Self.client.syncShutdown())
    }

    // MARK: TESTS

    func testInvoke() {
        // This doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }
        // assumes there is a "Hello" function available
        let request = Lambda.InvocationRequest(functionName: "Hello", logType: .tail, payload: .string("{}"))
        let response = Self.lambda.invoke(request)
        XCTAssertNoThrow(try response.wait())
    }

    func testListFunctions() {
        let response = Self.lambda.listFunctions(.init(maxItems: 10))
        XCTAssertNoThrow(try response.wait())
    }

    func testError() {
        let response = Self.lambda.invoke(.init(functionName: "non-existent-function"))
        XCTAssertThrowsError(try response.wait()) { error in
            switch error {
            case LambdaErrorType.resourceNotFoundException(let message):
                XCTAssertNotNil(message)
            default:
                XCTFail("Wrong error: \(error)")
            }
        }
    }
}
