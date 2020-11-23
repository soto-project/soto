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

import Foundation
import NIO
@testable import SotoCore
import XCTest

extension EventLoopFuture {
    /// When EventLoopFuture has any result the callback is called with the Result. The callback returns an EventLoopFuture<>
    /// which should be completed before result is passed on
    func flatAlways<NewValue>(file: StaticString = #file, line: UInt = #line, _ callback: @escaping (Result<Value, Error>) -> EventLoopFuture<NewValue>) -> EventLoopFuture<NewValue> {
        let next = eventLoop.makePromise(of: NewValue.self)
        self.whenComplete { result in
            switch result {
            case .success:
                callback(result).cascade(to: next)
            case .failure(let error):
                _ = callback(result).always { _ in next.fail(error) }
            }
        }
        return next.futureResult
    }
}

/// Provide various test environment variables
enum TestEnvironment {
    /// are we using Localstack to test. Also return use localstack if we are running a github action and don't have an access key if
    static var isUsingLocalstack: Bool {
        return Environment["AWS_DISABLE_LOCALSTACK"] != "true" ||
            (Environment["GITHUB_ACTIONS"] == "true" && Environment["AWS_ACCESS_KEY_ID"] == "")
    }

    static var credentialProvider: CredentialProviderFactory { return isUsingLocalstack ? .static(accessKeyId: "foo", secretAccessKey: "bar") : .default }

    /// current list of middleware
    static var middlewares: [AWSServiceMiddleware] {
        return (Environment["AWS_ENABLE_LOGGING"] == "true") ? [AWSLoggingMiddleware()] : []
    }

    /// return endpoint
    static func getEndPoint(environment: String) -> String? {
        guard self.isUsingLocalstack == true else { return nil }
        return Environment[environment] ?? "http://localhost:4566"
    }

    /// get name to use for AWS resource
    static func generateResourceName(_ function: String = #function) -> String {
        let prefix = Environment["AWS_TEST_RESOURCE_PREFIX"] ?? ""
        return "soto-" + (prefix + function).filter { $0.isLetter || $0.isNumber }.lowercased()
    }

    public static var logger: Logger = {
        if let loggingLevel = Environment["AWS_LOG_LEVEL"] {
            if let logLevel = Logger.Level(rawValue: loggingLevel.lowercased()) {
                var logger = Logger(label: "soto")
                logger.logLevel = logLevel
                return logger
            }
        }
        return AWSClient.loggingDisabled
    }()
}
