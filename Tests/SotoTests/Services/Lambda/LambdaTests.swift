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
import XCTest

// testing query service

class LambdaTests: XCTestCase {
    var client: AWSClient!
    var lambda: Lambda!
    var iam: IAM!

    let functionName: String = TestEnvironment.generateResourceName("UnitTestSotoLambda")
    let functionExecutionRoleName: String = TestEnvironment.generateResourceName("UnitTestSotoLambdaRole")

    /*
    
     The testing code for the AWS Lambda function is created with the following commands:
    
     echo "exports.handler = async (event) => { return \"hello world\" };" > lambda.js
     zip lambda.zip lambda.js
     cat lambda.zip | base64
     rm lambda.zip
     rm lambda.js
    
     */
    func createLambdaFunction(roleArn: String) async throws {
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
        _ = try await self.lambda.createFunction(cfr)
        try await self.lambda.waitUntilFunctionActive(.init(functionName: self.functionName))
    }

    func deleteLambdaFunction() async throws {
        print("Deleting Lambda function \(self.functionName)")
        let dfr = Lambda.DeleteFunctionRequest(functionName: self.functionName)
        try await self.lambda.deleteFunction(dfr)
    }

    func createIAMRole() async throws -> IAM.CreateRoleResponse {
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
            roleName: self.functionExecutionRoleName
        )
        // no policies are required, create an empty role

        print("Creating IAM Role : \(self.functionExecutionRoleName)")
        let response = try await self.iam.createRole(crr)
        try await self.iam.waitUntilRoleExists(.init(roleName: self.functionExecutionRoleName))
        return response
    }

    func deleteIAMRole() async throws {
        print("Deleting IAM Role : \(self.functionExecutionRoleName)")
        let drr = IAM.DeleteRoleRequest(roleName: self.functionExecutionRoleName)
        try await self.iam.deleteRole(drr)
    }

    override func setUp() async throws {
        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }

        self.client = AWSClient(
            credentialProvider: TestEnvironment.credentialProvider,
            middleware: TestEnvironment.middlewares
        )
        self.lambda = Lambda(
            client: self.client,
            region: .euwest1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        ).with(middleware: TestEnvironment.middlewares)
        self.iam = IAM(
            client: self.client,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        ).with(middleware: TestEnvironment.middlewares)

        // This doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }

        // create an IAM role
        await XCTAsyncAssertNoThrow {
            let arn: String
            do {
                let response = try await self.createIAMRole()
                // IAM needs some time after Role creation,
                // before the role can be attached to a Lambda function
                // https://stackoverflow.com/a/37438525/663360
                print("Sleeping 20 secs, waiting for IAM Role to be ready")
                try await Task.sleep(nanoseconds: 20_000_000_000)
                arn = response.role.arn
            } catch let error as IAMErrorType where error == .entityAlreadyExistsException {
                let response = try await self.iam.getRole(roleName: self.functionExecutionRoleName)
                arn = response.role.arn
            }
            try await self.createLambdaFunction(roleArn: arn)
        }
    }

    override func tearDown() async throws {
        // Role and lambda function are not created with Localstack
        await XCTAsyncAssertNoThrow {
            if !TestEnvironment.isUsingLocalstack {
                try await self.deleteLambdaFunction()
                try await self.deleteIAMRole()
            }
            try await self.client.shutdown()
        }
    }

    // MARK: TESTS

    func testInvoke() async throws {
        // This doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }

        // invoke the Lambda function created by setUp()
        let request = Lambda.InvocationRequest(functionName: self.functionName, logType: .tail, payload: .init(string: "{}"))
        let response = try await self.lambda.invoke(request)
        // is there an function execution error returned by the service?
        XCTAssertNil(response.functionError)

        // check the payload matches the one from the Lambda function
        let payloadBuffer = try await response.payload.collect(upTo: .max)
        let payload = String(buffer: payloadBuffer)
        XCTAssertEqual(payload, "\"hello world\"")
    }

    func testInvokeWithEventStream() async throws {
        // This doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }

        // invoke the Lambda function created by setUp()
        let request = Lambda.InvokeWithResponseStreamRequest(functionName: self.functionName, logType: .tail, payload: .init(string: "{}"))
        let response = try await self.lambda.invokeWithResponseStream(request)

        for try await event in response.eventStream {
            switch event {
            case .payloadChunk(let update):
                XCTAssertEqual(String(buffer: update.payload.buffer), "\"hello world\"")
            case .invokeComplete(let complete):
                print(complete)
            }
        }
    }

    func testListFunctions() async throws {
        _ = try await self.lambda.listFunctions(.init(maxItems: 10))
    }

    func testError() async throws {
        await XCTAsyncExpectError(LambdaErrorType.resourceNotFoundException) {
            _ = try await self.lambda.invoke(.init(functionName: "non-existent-function"))
        }
    }
}
