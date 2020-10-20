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

@testable import SotoSSM
import XCTest

// testing json service

class SSMTests: XCTestCase {
    static var client: AWSClient!
    static var ssm: SSM!

    override class func setUp() {
        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }

        Self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middlewares: TestEnvironment.middlewares, httpClientProvider: .createNew)
        Self.ssm = SSM(
            client: SSMTests.client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
    }

    override class func tearDown() {
        XCTAssertNoThrow(try Self.client.syncShutdown())
    }

    func putParameter(name: String, value: String) -> EventLoopFuture<Void> {
        let request = SSM.PutParameterRequest(name: name, overwrite: true, type: .string, value: value)
        return Self.ssm.putParameter(request).map { _ in }
    }

    func deleteParameter(name: String) -> EventLoopFuture<Void> {
        let request = SSM.DeleteParameterRequest(name: name)
        return Self.ssm.deleteParameter(request).map { _ in }
    }

    // MARK: TESTS

    func testGetParameter() {
        // parameter names cannot begin wih "aws"
        let name = "test" + TestEnvironment.generateResourceName()
        let response = self.putParameter(name: name, value: "testdata")
            .flatMap { (_) -> EventLoopFuture<SSM.GetParameterResult> in
                let request = SSM.GetParameterRequest(name: name)
                return Self.ssm.getParameter(request)
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
        let name = TestEnvironment.generateResourceName()
        let fullname = "/\(name)/\(name)"
        let response = self.putParameter(name: fullname, value: "testdata2")
            .flatMap { (_) -> EventLoopFuture<SSM.GetParametersByPathResult> in
                let request = SSM.GetParametersByPathRequest(path: "/\(name)/")
                return Self.ssm.getParametersByPath(request)
            }
            .flatMapThrowing { response in
                let parameter = try XCTUnwrap(response.parameters?.first { $0.name == fullname })
                XCTAssertEqual(parameter.value, "testdata2")
            }
            .flatAlways { _ in
                return self.deleteParameter(name: fullname)
            }
        XCTAssertNoThrow(try response.wait())
    }

    func testError() {
        // This doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }
        let response = Self.ssm.describeDocument(.init(name: "non-existent-document"))
        XCTAssertThrowsError(try response.wait()) { error in
            switch error {
            case let error as SSMErrorType where error == .invalidDocument:
                XCTAssertNotNil(error.message)
            default:
                XCTFail("Wrong error: \(error)")
            }
        }
    }
}
