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

import AWSSDKSwiftCore
import Foundation
import NIO
import XCTest

extension EventLoopFuture {
    /// When EventLoopFuture has any result the callback is called with the Result. The callback returns an EventLoopFuture<>
    /// which should be completed before result is passed on
    func flatAlways<NewValue>(file: StaticString = #file, line: UInt = #line, _ callback: @escaping (Result<Value, Error>) -> EventLoopFuture<NewValue>) -> EventLoopFuture<NewValue> {
        let next = eventLoop.makePromise(of: NewValue.self)
        self.whenComplete { result in
            switch result {
            case .success(_):
                callback(result).cascade(to: next)
            case .failure(let error):
                _ = callback(result).always { _ in next.fail(error) }
            }
        }
        return next.futureResult
    }
}

/// Provide various test environment variables
struct TestEnvironment {
    /// are we using Localstack to test
    static var isUsingLocalstack: Bool { return ProcessInfo.processInfo.environment["AWS_DISABLE_LOCALSTACK"] != "true" }
    
    /// current list of middleware
    static var middlewares: [AWSServiceMiddleware] {
        return (ProcessInfo.processInfo.environment["AWS_ENABLE_LOGGING"] == "true") ? [AWSLoggingMiddleware()] : []
    }
    
    /// return endpoint
    static func getEndPoint(environment: String, default: String) -> String? {
        guard isUsingLocalstack == true else { return nil }
        return ProcessInfo.processInfo.environment[environment] ?? `default`
    }
    
    /// get name to use for AWS resource
    static func generateResourceName(_ function: String = #function) -> String {
        return "awssdkswift-" + function.filter { $0.isLetter }
    }
}
