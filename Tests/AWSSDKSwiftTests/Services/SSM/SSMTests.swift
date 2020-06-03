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
@testable import AWSSSM

// testing json service

class SSMTests: XCTestCase {

    let ssm = SSM(
        region: .useast1,
        endpoint: TestEnvironment.getEndPoint(environment: "SSM_ENDPOINT", default: "http://localhost:4566"),
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

    func putParameter(name: String, value: String) -> EventLoopFuture<Void> {
        let request = SSM.PutParameterRequest(name: name, overwrite: true, type: .string, value: value)
        return ssm.putParameter(request).map { _ in }
    }
    
    func deleteParameter(name: String) -> EventLoopFuture<Void> {
        let request = SSM.DeleteParameterRequest(name: name)
        return ssm.deleteParameter(request).map { _ in }
    }
    
    //MARK: TESTS

    func testGetParameter() {
        // parameter names cannot begin wih "aws"
        let name = "test" + TestEnvironment.generateResourceName()
        let response = putParameter(name: name, value: "testdata")
            .flatMap { (_) -> EventLoopFuture<SSM.GetParameterResult> in
                let request = SSM.GetParameterRequest(name: name)
                return self.ssm.getParameter(request)
        }
        .flatMapThrowing { response in
            let parameter = try XCTUnwrap(response.parameter)
            XCTAssertEqual(parameter.name, name)
            XCTAssertEqual(parameter.value, "testdata")
        }
        .flatAlways { _ in
            return self.deleteParameter(name: name)
        }
        XCTAssertNoThrow(try response.wait())
    }

    func testGetParametersByPath() {
        let name = "/test/" + TestEnvironment.generateResourceName()
        let response = putParameter(name: name, value: "testdata2")
            .flatMap { (_) -> EventLoopFuture<SSM.GetParametersByPathResult> in
                let request = SSM.GetParametersByPathRequest(path: "/test/")
                return self.ssm.getParametersByPath(request)
        }
        .flatMapThrowing { response in
            let parameter = try XCTUnwrap(response.parameters?.first)
            XCTAssertEqual(parameter.name,  name)
            XCTAssertEqual(parameter.value, "testdata2")
        }
        .flatAlways { _ in
            return self.deleteParameter(name: name)
        }
        XCTAssertNoThrow(try response.wait())
    }

    static var allTests: [(String, (SSMTests) -> () throws -> Void)] {
        return [
            ("testGetParameter", testGetParameter),
            ("testGetParametersByPath", testGetParametersByPath),
        ]
    }
}
