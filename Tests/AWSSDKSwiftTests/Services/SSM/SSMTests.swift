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

@testable import AWSSSM

enum SSMTestsError: Error {
    case noTopicArn
}

// testing json service

class SSMTests: XCTestCase {

    let client = SSM(
        accessKeyId: "key",
        secretAccessKey: "secret",
        region: .useast1,
        endpoint: ProcessInfo.processInfo.environment["SSM_ENDPOINT"] ?? "http://localhost:4583",
        middlewares: (ProcessInfo.processInfo.environment["AWS_ENABLE_LOGGING"] == "true") ? [AWSLoggingMiddleware()] : []
    )

    class TestData {
        var client: SSM
        var parameterName: String
        var parameterValue: String

        init(_ testName: String, client: SSM) throws {
            self.client = client
            let testName = testName.lowercased().filter { return $0.isLetter || $0.isNumber }
            self.parameterName = "/awssdkswift/\(testName)"
            self.parameterValue = "value:\(testName)"

            let request = SSM.PutParameterRequest(name: parameterName, overwrite: true, type: .string, value: parameterValue)
            _ = try client.putParameter(request).wait()
        }

        deinit {
            attempt {
                let request = SSM.DeleteParameterRequest(name: parameterName)
                _ = try client.deleteParameter(request).wait()
            }
        }
    }

    //MARK: TESTS

    func testGetParameter() {
        attempt {
            let testData = try TestData(#function, client: client)
            let request = SSM.GetParameterRequest(name: testData.parameterName)
            let response = try client.getParameter(request).wait()
            XCTAssertEqual(response.parameter?.name, testData.parameterName)
            XCTAssertEqual(response.parameter?.value, testData.parameterValue)
        }
    }

    func testGetParametersByPath() {
        attempt {
            let testData = try TestData(#function, client: client)
            let request = SSM.GetParametersByPathRequest(path: "/awssdkswift/")
            let response = try client.getParametersByPath(request).wait()
            XCTAssertNotNil(response.parameters?.first { $0.name == testData.parameterName })
        }
    }

    static var allTests: [(String, (SSMTests) -> () throws -> Void)] {
        return [
            ("testGetParametersByPath", testGetParametersByPath),
        ]
    }
}
