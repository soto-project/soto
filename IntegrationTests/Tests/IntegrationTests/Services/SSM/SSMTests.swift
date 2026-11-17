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

import Testing

@testable import SotoSSM

// testing json service

@Suite(.awsClient())
class SSMTests {
    /// put parameter, test it, delete it
    func testParameter(name: String, value: String, ssm: SSM, test: @escaping (String) async throws -> Void) async throws {
        try await testAsset {
            let request = SSM.PutParameterRequest(name: name, overwrite: true, type: .string, value: value)
            _ = try await ssm.putParameter(request)
            return name
        } test: {
            try await test($0)
        } delete: {
            let request = SSM.DeleteParameterRequest(name: $0)
            _ = try await ssm.deleteParameter(request)
        }
    }

    // MARK: TESTS

    @Test func testGetParameter() async throws {
        let ssm = SSM(client: AWSClientTrait.client, region: .useast1)
        // parameter names cannot begin wih "aws"
        let name = "test" + TestEnvironment.generateResourceName()
        try await self.testParameter(name: name, value: "testdata", ssm: ssm) { name in
            let request = SSM.GetParameterRequest(name: name)
            let response = try await ssm.getParameter(request)
            let parameter = try #require(response.parameter)
            #expect(parameter.name == name)
            #expect(parameter.value == "testdata")
        }
    }

    @Test func testGetParametersByPath() async throws {
        let ssm = SSM(client: AWSClientTrait.client, region: .useast1)
        let name = TestEnvironment.generateResourceName()
        let fullname = "/\(name)/\(name)"
        try await self.testParameter(name: fullname, value: "testdata2", ssm: ssm) { parameterName in
            try await Task.sleep(nanoseconds: 500_000_000)
            let request = SSM.GetParametersByPathRequest(path: "/\(name)/")
            let response = try await ssm.getParametersByPath(request)
            let parameter = try #require(response.parameters?.first { $0.name == parameterName })
            #expect(parameter.value == "testdata2")
        }
    }

    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Doesn't work with localstack"))
    func testError() async throws {
        let ssm = SSM(client: AWSClientTrait.client, region: .useast1)
        let error = await #expect(throws: SSMErrorType.self) {
            _ = try await ssm.describeDocument(.init(name: "non-existent-document"))
        }
        switch error?.error {
        case .invalidDocument:
            break
        default:
            Issue.record()
        }
    }
}
