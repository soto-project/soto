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

import XCTest

@testable import SotoSSM

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

        self.client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middleware: TestEnvironment.middlewares)
        self.ssm = SSM(
            client: SSMTests.client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
    }

    override class func tearDown() {
        XCTAssertNoThrow(try self.client.syncShutdown())
    }

    /// put parameter, test it, delete it
    func testParameter(name: String, value: String, test: @escaping (String) async throws -> Void) async throws {
        try await XCTTestAsset {
            let request = SSM.PutParameterRequest(name: name, overwrite: true, type: .string, value: value)
            _ = try await Self.ssm.putParameter(request)
            return name
        } test: {
            try await test($0)
        } delete: {
            let request = SSM.DeleteParameterRequest(name: $0)
            _ = try await Self.ssm.deleteParameter(request)
        }
    }

    // MARK: TESTS

    func testGetParameter() async throws {
        // parameter names cannot begin wih "aws"
        let name = "test" + TestEnvironment.generateResourceName()
        try await self.testParameter(name: name, value: "testdata") { name in
            let request = SSM.GetParameterRequest(name: name)
            let response = try await Self.ssm.getParameter(request)
            let parameter = try XCTUnwrap(response.parameter)
            XCTAssertEqual(parameter.name, name)
            XCTAssertEqual(parameter.value, "testdata")
        }
    }

    func testGetParametersByPath() async throws {
        let name = TestEnvironment.generateResourceName()
        let fullname = "/\(name)/\(name)"
        try await self.testParameter(name: fullname, value: "testdata2") { parameterName in
            try await Task.sleep(nanoseconds: 500_000_000)
            let request = SSM.GetParametersByPathRequest(path: "/\(name)/")
            let response = try await Self.ssm.getParametersByPath(request)
            let parameter = try XCTUnwrap(response.parameters?.first { $0.name == parameterName })
            XCTAssertEqual(parameter.value, "testdata2")
        }
    }

    func testError() async throws {
        // This doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }
        await XCTAsyncExpectError(SSMErrorType.invalidDocument) {
            _ = try await Self.ssm.describeDocument(.init(name: "non-existent-document"))
        }
    }
}
