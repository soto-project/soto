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
import NIOCore
import XCTest

@testable import SotoCore

/// Internal class used by syncAwait
private class SendableBox<Value>: @unchecked Sendable {
    var value: Value?
}

extension Task where Failure == Error {
    /// Performs an async task in a sync context and wait for result.
    ///
    /// Not to be used in production code.
    ///
    /// - Note: This function blocks the thread until the given operation is finished. The caller is responsible for managing multithreading.
    @available(*, noasync, message: "synchronous() can block indefinitely")
    func syncAwait() throws -> Success {
        let semaphore = DispatchSemaphore(value: 0)
        let resultBox = SendableBox<Result<Success, Failure>>()

        Task<Void, Never> {
            resultBox.value = await self.result
            semaphore.signal()
        }

        semaphore.wait()
        switch resultBox.value! {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}

extension Task where Failure == Never {
    /// Performs an async task in a sync context and wait for result.
    ///
    /// Not to be used in production code.
    ///
    /// - Note: This function blocks the thread until the given operation is finished. The caller is responsible for managing multithreading.
    @available(*, noasync, message: "synchronous() can block indefinitely")
    func syncAwait() -> Success {
        let semaphore = DispatchSemaphore(value: 0)
        let resultBox = SendableBox<Success>()

        Task<Void, Never> {
            resultBox.value = await self.value
            semaphore.signal()
        }

        semaphore.wait()
        return resultBox.value!
    }
}

/// Provide various test environment variables
enum TestEnvironment {
    /// are we using Localstack to test. Also return use localstack if we are running a github action and don't have an access key if
    static var isUsingLocalstack: Bool {
        Environment["AWS_DISABLE_LOCALSTACK"] != "true" || (Environment["GITHUB_ACTIONS"] == "true" && Environment["AWS_ACCESS_KEY_ID"] == "")
    }

    static var credentialProvider: CredentialProviderFactory { isUsingLocalstack ? .static(accessKeyId: "foo", secretAccessKey: "bar") : .default }

    /// current list of middleware
    public static var middlewares: AWSMiddlewareProtocol {
        (Environment["AWS_ENABLE_LOGGING"] == "true")
            ? AWSLoggingMiddleware(logger: TestEnvironment.logger, logLevel: .info)
            : AWSMiddleware { request, context, next in
                try await next(request, context)
            }
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

func XCTAsyncAssertNoThrow(
    _ expression: () async throws -> Void,
    _ message: @autoclosure @escaping () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
    } catch {
        XCTFail("\(file):\(line) \(message()) Threw error \(error)")
    }
}

/// Test for specific error being thrown when running some code
func XCTAsyncExpectError<E: Error & Equatable>(
    _ expectedError: E,
    _ expression: () async throws -> Void,
    _ message: @autoclosure @escaping () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("\(file):\(line) \(message()) Expected to throw an error but it didn't")
    } catch let error as E where error == expectedError {
    } catch {
        XCTFail("\(file):\(line) \(message()) Expected error \(expectedError) but got \(error)")
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
        AsyncIterator(iterator: self.base.makeAsyncIterator(), process: self.process)
    }
}

extension ReportAsyncSequence: Sendable where Base: Sendable {}

extension AsyncSequence where Element == ByteBuffer {
    /// Return an AsyncSequence that sends every element it process to a report function
    /// - Parameter chunkSize: Size of each chunk
    func report(_ process: @Sendable @escaping (Element) throws -> Void) -> ReportAsyncSequence<Self> {
        .init(base: self, process: process)
    }
}

func withTeardown<Value>(_ process: () async throws -> Value, teardown: () async -> Void) async throws -> Value {
    let result: Value
    do {
        result = try await process()
    } catch {
        await teardown()
        throw error
    }
    await teardown()
    return result
}
