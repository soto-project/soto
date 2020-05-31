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

func attempt(function: () throws -> Void) {
    do {
        try function()
    } catch let error as AWSErrorType {
        XCTFail("\(error)")
    } catch DecodingError.typeMismatch(let type, let context) {
        print(type, context)
        XCTFail()
    } catch let error as NIO.ChannelError {
        XCTFail("\(error)")
    } catch {
        XCTFail("\(error)")
    }
}

func endpoint(environment: String, default: String) -> String? {
    guard ProcessInfo.processInfo.environment["AWS_DISABLE_LOCALSTACK"] != "true" else { return nil }
    return ProcessInfo.processInfo.environment[environment] ?? `default`
}

func middlewares() -> [AWSServiceMiddleware] {
    return (ProcessInfo.processInfo.environment["AWS_ENABLE_LOGGING"] == "true") ? [AWSLoggingMiddleware()] : []
}

extension EventLoopFuture {
    // When EventLoopFuture has any result the callback is called with the Result. The callback returns an EventLoopFuture<>
    // which should be completed before result is passed on
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
