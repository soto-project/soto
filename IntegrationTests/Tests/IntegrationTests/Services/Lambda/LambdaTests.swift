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

import SotoIAM
import SotoLambda
import Testing

/// Creates a lambda function to be used by a test suite
///
/// This trait expects an AWSClientTrait to have already been declared
struct LambdaTrait: TestScoping, SuiteTrait {
    @TaskLocal
    static var _functionName: String?

    static var functionName: String {
        guard let _functionName else { fatalError("Test requires a lambda trait to run") }
        return _functionName
    }

    let functionName: String = TestEnvironment.generateResourceName("UnitTestSotoLambda")
    let roleName: String = TestEnvironment.generateResourceName("UnitTestSotoLambdaRole")

    /*

     The testing code for the AWS Lambda function is created with the following commands:

     echo "exports.handler = async (event) => { return \"hello world\" };" > lambda.js
     zip lambda.zip lambda.js
     cat lambda.zip | base64
     rm lambda.zip
     rm lambda.js

     */
    func createLambdaFunction(roleArn: String, lambda: Lambda) async throws {
        // Base64 and Zipped version of "exports.handler = async (event) => { return \"hello world\" };"
        let code =
            "UEsDBAoAAAAAAPFWXFGfGXl5PQAAAD0AAAAJABwAbGFtYmRhLmpzVVQJAAMVQJlfuD+ZX3V4CwABBC8Om1YEzHsDcWV4cG9ydHMuaGFuZGxlciA9IGFzeW5jIChldmVudCkgPT4geyByZXR1cm4gImhlbGxvIHdvcmxkIiB9OwpQSwECHgMKAAAAAADxVlxRnxl5eT0AAAA9AAAACQAYAAAAAAABAAAApIEAAAAAbGFtYmRhLmpzVVQFAAMVQJlfdXgLAAEELw6bVgTMewNxUEsFBgAAAAABAAEATwAAAIAAAAAAAA=="
        let functionCode = Lambda.FunctionCode(zipFile: .base64(code))
        let functionRuntime = Lambda.Runtime.nodejs18x
        let functionHandler = "lambda.handler"
        let cfr = Lambda.CreateFunctionRequest(
            code: functionCode,
            functionName: self.functionName,
            handler: functionHandler,
            role: roleArn,
            runtime: functionRuntime
        )
        print("Creating Lambda Function : \(self.functionName)")
        _ = try await lambda.createFunction(cfr)
        try await lambda.waitUntilFunctionActive(.init(functionName: self.functionName))
    }

    func deleteLambdaFunction(lambda: Lambda) async throws {
        print("Deleting Lambda function \(functionName)")
        _ = try await lambda.deleteFunction(functionName: self.functionName)
    }

    func createIAMRole(iam: IAM) async throws -> IAM.Role {
        // as documented at https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html
        let assumeRolePolicyDocument = """
            {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Action": "sts:AssumeRole",
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "lambda.amazonaws.com"
                        }
                    }
                ]
            }
            """
        let crr = IAM.CreateRoleRequest(
            assumeRolePolicyDocument: assumeRolePolicyDocument,
            roleName: self.roleName
        )
        // no policies are required, create an empty role

        print("Creating IAM Role : \(self.roleName)")
        do {
            let response = try await iam.createRole(crr)
            try await iam.waitUntilRoleExists(.init(roleName: self.roleName))
            // IAM needs some time after Role creation,
            // before the role can be attached to a Lambda function
            // https://stackoverflow.com/a/37438525/663360
            print("Sleeping 20 secs, waiting for IAM Role to be ready")
            try await Task.sleep(nanoseconds: 20_000_000_000)
            return response.role
        } catch let error as IAMErrorType {
            switch error.error {
            case .entityAlreadyExistsException:
                let response = try await iam.getRole(roleName: self.roleName)
                return response.role
            default:
                throw error
            }
        }
    }

    func deleteIAMRole(iam: IAM) async throws {
        print("Deleting IAM Role : \(roleName)")
        try await iam.deleteRole(roleName: self.roleName)
    }

    func provideScope(for test: Test, testCase: Test.Case?, performing function: @concurrent @Sendable () async throws -> Void) async throws {
        let lambda = Lambda(client: AWSClientTrait.client, region: .euwest1)
        let iam = IAM(client: AWSClientTrait.client)

        try await testAsset {
            try await self.createIAMRole(iam: iam).arn
        } test: { arn in
            try await testAsset {
                try await self.createLambdaFunction(roleArn: arn, lambda: lambda)
            } test: {
                try await Self.$_functionName.withValue(self.functionName) {
                    try await function()
                }
            } delete: {
                try await self.deleteLambdaFunction(lambda: lambda)
            }
        } delete: { arn in
            try await self.deleteIAMRole(iam: iam)
        }
    }
}

@Suite(
    .disabled(if: TestEnvironment.isUsingLocalstack, "Lambda tests don't work with localstack"),
    .awsClient(),
    LambdaTrait()
)
struct LambdaTests {

    // MARK: TESTS

    @Test
    func testInvoke() async throws {
        let lambda = Lambda(client: AWSClientTrait.client, region: .euwest1)
        // invoke the Lambda function created by the LambdaTrait
        let request = Lambda.InvocationRequest(functionName: LambdaTrait.functionName, logType: .tail, payload: .init(string: "{}"))
        let response = try await lambda.invoke(request)
        // is there an function execution error returned by the service?
        #expect(response.functionError == nil)

        // check the payload matches the one from the Lambda function
        let payloadBuffer = try await response.payload.collect(upTo: .max)
        let payload = String(buffer: payloadBuffer)
        #expect(payload == "\"hello world\"")
    }

    @Test(.disabled(if: TestEnvironment.isUsingLocalstack, "Lambda tests don't work with localstack"))
    func testInvokeWithEventStream() async throws {
        let lambda = Lambda(client: AWSClientTrait.client, region: .euwest1)
        // invoke the Lambda function created by setUp()
        let request = Lambda.InvokeWithResponseStreamRequest(functionName: LambdaTrait.functionName, logType: .tail, payload: .init(string: "{}"))
        let response = try await lambda.invokeWithResponseStream(request)

        for try await event in response.eventStream {
            switch event {
            case .payloadChunk(let update):
                #expect(String(buffer: update.payload.buffer) == "\"hello world\"")
            case .invokeComplete(let complete):
                print(complete)
            }
        }
    }

    @Test func testListFunctions() async throws {
        let lambda = Lambda(client: AWSClientTrait.client, region: .euwest1)
        let functions = try await lambda.listFunctions(.init(maxItems: 100))
        #expect(functions.functions?.contains { $0.functionName == LambdaTrait.functionName } == true)
    }

    @Test func testError() async throws {
        let lambda = Lambda(client: AWSClientTrait.client, region: .euwest1)
        let error = await #expect(throws: LambdaErrorType.self) {
            _ = try await lambda.invoke(.init(functionName: "non-existent-function"))
        }
        switch error?.error {
        case .resourceNotFoundException:
            break
        default:
            Issue.record("Expected resourceNotFoundException, got \(String(describing: error?.error))")
        }
    }
}
