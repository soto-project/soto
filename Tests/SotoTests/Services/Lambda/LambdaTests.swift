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
import XCTest

import SotoIAM
import SotoLambda

// testing query service

class LambdaTests: XCTestCase {
    static var client: AWSClient!
    static var lambda: Lambda!
    static var iam: IAM!

    static let functionName: String = TestEnvironment.generateResourceName("UnitTestSotoLambda")
    static let functionExecutionRoleName: String = TestEnvironment.generateResourceName("UnitTestSotoLambdaRole")

    /*

     The testing code for the AWS Lambda function is created with the following commands:

     echo "exports.handler = async (event) => { return \"hello world\" };" > lambda.js
     zip lambda.zip lambda.js
     cat lambda.zip | base64
     rm lambda.zip
     rm lambda.js

     */
    class func createLambdaFunction(roleArn: String) -> EventLoopFuture<Void> {
        // Zipped version of "exports.handler = async (event) => { return \"hello world\" };"
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
        print("Creating Lambda Function : \(self.functionName)")
        return Self.lambda.createFunction(cfr)
            .flatMap { _ in
                Self.lambda.waitUntilFunctionExists(.init(functionName: self.functionName))
            }
    }

    class func deleteLambdaFunction() -> EventLoopFuture<Void> {
        let dfr = Lambda.DeleteFunctionRequest(functionName: self.functionName)
        print("Deleting Lambda function \(self.functionName)")
        return Self.lambda.deleteFunction(dfr)
    }

    class func createIAMRole() -> EventLoopFuture<IAM.CreateRoleResponse> {
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
        return Self.iam.createRole(crr)
            .flatMap { response in
                Self.iam.waitUntilRoleExists(.init(roleName: self.functionExecutionRoleName))
                    .map { _ in response }
            }
    }

    class func deleteIAMRole() -> EventLoopFuture<Void> {
        let drr = IAM.DeleteRoleRequest(roleName: self.functionExecutionRoleName)
        print("Deleting IAM Role : \(self.functionExecutionRoleName)")
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

        // create an IAM role
        let response = Self.createIAMRole()
            .flatMap { response -> EventLoopFuture<Void> in
                let eventLoop = Self.client.eventLoopGroup.next()

                // IAM needs some time after Role creation,
                // before the role can be attached to a Lambda function
                // https://stackoverflow.com/a/37438525/663360
                print("Sleeping 20 secs, waiting for IAM Role to be ready")
                let scheduled = eventLoop.flatScheduleTask(in: .seconds(20)) {
                    // create a Lambda function
                    Self.createLambdaFunction(roleArn: response.role.arn)
                }
                return scheduled.futureResult
            }
        XCTAssertNoThrow(try response.wait())
    }

    override class func tearDown() {
        let response = Self.deleteIAMRole()
            .flatMap { _ -> EventLoopFuture<Void> in
                Self.deleteLambdaFunction()
            }

        XCTAssertNoThrow(try response.wait())

        XCTAssertNoThrow(try Self.client.syncShutdown())
    }

    // MARK: TESTS

    func testInvoke() {
        // This doesnt work with LocalStack
        guard !TestEnvironment.isUsingLocalstack else { return }

        // invoke the Lambda function created by setUp()
        let request = Lambda.InvocationRequest(functionName: Self.functionName, logType: .tail, payload: .string("{}"))
        let eventLoop = Self.lambda.invoke(request)
        XCTAssertNoThrow(try eventLoop.wait())

        _ = eventLoop.always { result in

            switch result {
            case .success(let response):
                // is there an function execution error returned by the service?
                XCTAssertNil(response.functionError)

                // check the payload matches the one from the Lambda function
                guard let payload = response.payload?.asString() else {
                    XCTFail("Lambda function should return a payload")
                    return
                }
                XCTAssertEqual(payload, "\"hello world\"")
            case .failure(let error):
                XCTFail("Lambda invocation returned an error : \(error)")
            }
        }
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
