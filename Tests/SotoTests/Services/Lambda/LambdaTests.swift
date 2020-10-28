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

/*

 The testing code for the AWS Lambda function is created with the following commands:

 echo "exports.handler = async (event) => { return \"hello world\" };" > lambda.js
 zip lambda.zip lambda.js
 cat lambda.zip | base64
 rm lambda.zip
 rm lambda.js

 */

import NIO
import XCTest

@testable import SotoIAM
@testable import SotoLambda

// testing query service

class LambdaTests: XCTestCase {
    static var client: AWSClient!
    static var lambda: Lambda!
    static var iam: IAM!

    static var functionName: String!
    static var functionExecutionRoleName: String!

    class func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }

    class func createLambdaFunction(roleArn: String) -> EventLoopFuture<Lambda.FunctionConfiguration> {
        // create a "UnitTestSotoLambda-xxxx" function
        // use pseudo random name to avoid name conflicts
        self.functionName = "UnitTestSotoLambda-" + Self.randomString(length: 5)

        // ZIPped version of "exports.handler = async (event) => { return \"hello world\" };"
        let code = "UEsDBAoAAAAAAPFWXFGfGXl5PQAAAD0AAAAJABwAbGFtYmRhLmpzVVQJAAMVQJlfuD+ZX3V4CwABBC8Om1YEzHsDcWV4cG9ydHMuaGFuZGxlciA9IGFzeW5jIChldmVudCkgPT4geyByZXR1cm4gImhlbGxvIHdvcmxkIiB9OwpQSwECHgMKAAAAAADxVlxRnxl5eT0AAAA9AAAACQAYAAAAAAABAAAApIEAAAAAbGFtYmRhLmpzVVQFAAMVQJlfdXgLAAEELw6bVgTMewNxUEsFBgAAAAABAAEATwAAAIAAAAAAAA=="
        let functionCode = Lambda.FunctionCode(zipFile: Data(base64Encoded: code))
        let functionRuntime = Lambda.Runtime.nodejs12X
        let functionHandler = "lambda.handler"
        let cfr = Lambda.CreateFunctionRequest(
            code: functionCode,
            functionName: self.functionName,
            handler: functionHandler,
            role: roleArn,
            runtime: functionRuntime
        )
        print("Creating Lambda Function : \(self.functionName!)")
        return Self.lambda.createFunction(cfr)
    }

    class func deleteLambdaFunction() -> EventLoopFuture<Void> {
        let dfr = Lambda.DeleteFunctionRequest(functionName: self.functionName)
        print("Deleting Lambda function \(self.functionName!)")
        return Self.lambda.deleteFunction(dfr)
    }

    class func createIAMRole() -> EventLoopFuture<IAM.CreateRoleResponse> {
        self.functionExecutionRoleName = "lambda_execution_role-" + Self.randomString(length: 5)

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

        print("Creating IAM Role : \(self.functionExecutionRoleName!)")
        return Self.iam.createRole(crr)
    }

    class func deleteIAMRole() -> EventLoopFuture<Void> {
        let drr = IAM.DeleteRoleRequest(roleName: self.functionExecutionRoleName)
        print("Deleting IAM Role : \(self.functionExecutionRoleName!)")
        return Self.iam.deleteRole(drr)
    }

    override class func setUp() {
        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }

        Self.client = AWSClient(
            credentialProvider: TestEnvironment.credentialProvider,
            middlewares: TestEnvironment.middlewares,
            httpClientProvider: .createNew
        )
        Self.lambda = Lambda(
            client: LambdaTests.client,
            region: .euwest1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )
        Self.iam = IAM(
            client: Self.client,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        )

        // create a lambda function to test invoke()
        do {
            let response = try Self.createIAMRole().wait()
            // IAM needs some time after Role creation, before the role can be attached to a Lambda function
            // https://stackoverflow.com/a/37438525/663360
            print("Sleeping 15 secs, waiting for IAM Role to be created")
            sleep(15)
            _ = try Self.createLambdaFunction(roleArn: response.role.arn).wait()
        } catch {
            XCTFail("Can not create prerequisites resources in the cloud, before to execute the tests: \(error)")
        }
    }

    override class func tearDown() {
        do {
            try Self.deleteIAMRole().wait()
            try Self.deleteLambdaFunction().wait()
        } catch {
            XCTFail("Can not delete testing resources in the cloud: \(error)")
        }

        XCTAssertNoThrow(try Self.client.syncShutdown())
    }

    // MARK: TESTS

    func testInvoke() {
        // This doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }
        // assumes there is a "Hello" function available
        let request = Lambda.InvocationRequest(functionName: Self.functionName, logType: .tail, payload: .string("{}"))
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
            case let error as LambdaErrorType where error == .resourceNotFoundException:
                XCTAssertNotNil(error.message)
            default:
                XCTFail("Wrong error: \(error)")
            }
        }
    }
}
