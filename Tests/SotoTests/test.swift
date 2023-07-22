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

import Dispatch
import Foundation
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

@available(*, noasync, message: "runAndWait() can block indefinitely")
func runThrowingTask<T>(on eventLoop: EventLoop, _ task: @escaping @Sendable () async throws -> T) throws -> T {
    let promise = eventLoop.makePromise(of: T.self)
    Task {
        do {
            let result = try await task()
            promise.succeed(result)
        } catch {
            promise.fail(error)
        }
    }
    return try promise.futureResult.wait()
}

@available(*, noasync, message: "runAndWait() can block indefinitely")
func runTask<T>(on eventLoop: EventLoop, _ task: @escaping @Sendable () async -> T) -> T {
    let promise = eventLoop.makePromise(of: T.self)
    Task {
        let result = await task()
        promise.succeed(result)
    }
    return try! promise.futureResult.wait()
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
    public static var middlewares: AWSMiddlewareProtocol {
        return (Environment["AWS_ENABLE_LOGGING"] == "true") ? AWSLoggingMiddleware(logger: TestEnvironment.logger, logLevel: .info) : PassThruMiddleware()
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

/// Run some test code for a specific asset
func XCTTestAsset<T>(
    create: () async throws -> T,
    test: (T) async throws -> Void,
    delete: (T) async throws -> Void
) async throws {
    let asset = try await create()
    do {
        try await test(asset)
    } catch {
        XCTFail("\(error)")
    }
    try await delete(asset)
}

/// Test for specific error being thrown when running some code
func XCTAsyncExpectError<E: Error & Equatable>(
    _ expectedError: E,
    _ expression: () async throws -> Void,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("\(file):\(line) was expected to throw an error but it didn't")
    } catch let error as E where error == expectedError {
    } catch {
        XCTFail("\(file):\(line) expected error \(expectedError) but got \(error)")
    }
}

/// An AsyncSequence that reports every element that is returned by its iterator
struct ReportAsyncSequence<Base: AsyncSequence>: AsyncSequence {
    typealias Element = Base.Element

    let base: Base
    let process: @Sendable (Element) throws -> Void

    struct AsyncIterator: AsyncIteratorProtocol {
        @usableFromInline
        var iterator: Base.AsyncIterator
        @usableFromInline
        let process: @Sendable (Element) throws -> Void

        @usableFromInline
        init(iterator: Base.AsyncIterator, process: @Sendable @escaping (Element) throws -> Void) {
            self.iterator = iterator
            self.process = process
        }

        @inlinable
        public mutating func next() async throws -> Element? {
            if let element = try await self.iterator.next() {
                try self.process(element)
                return element
            }
            return nil
        }
    }

    /// Make async iterator
    __consuming func makeAsyncIterator() -> AsyncIterator {
        return AsyncIterator(iterator: self.base.makeAsyncIterator(), process: self.process)
    }
}

extension ReportAsyncSequence: Sendable where Base: Sendable {}

extension AsyncSequence where Element == ByteBuffer {
    /// Return an AsyncSequence that sends every element it process to a report function
    /// - Parameter chunkSize: Size of each chunk
    func report(_ process: @Sendable @escaping (Element) throws -> Void) -> ReportAsyncSequence<Self> {
        return .init(base: self, process: process)
    }
}
