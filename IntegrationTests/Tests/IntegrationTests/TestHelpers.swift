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
import Logging
import NIOCore
import Testing

@testable import SotoCore

/// Provide various test environment variables
enum TestEnvironment {
    /// are we using Localstack to test. Also return use localstack if we are running a github action and don't have an access key if
    static var isUsingLocalstack: Bool {
        Environment["AWS_ENDPOINT_URL"] == "http://localhost:4566" || Environment["AWS_ENDPOINT_URL"] == "http://localstack:4566"
    }

    static var credentialProvider: CredentialProviderFactory {
        isUsingLocalstack ? .static(accessKeyId: "foo", secretAccessKey: "bar") : .default
    }

    /// current list of middleware
    static var middlewares: AWSMiddlewareProtocol {
        (Environment["AWS_ENABLE_LOGGING"] == "true")
            ? AWSLoggingMiddleware(logger: TestEnvironment.logger, logLevel: .info)
            : AWSMiddleware { request, context, next in
                try await next(request, context)
            }
    }

    /// get name to use for AWS resource
    static func generateResourceName(_ function: String = #function) -> String {
        let prefix = Environment["AWS_TEST_RESOURCE_PREFIX"] ?? ""
        return "soto-" + (prefix + function).filter { $0.isLetter || $0.isNumber }.lowercased()
    }

    static var logLevel: Logger.Level {
        if let loggingLevel = Environment["AWS_LOG_LEVEL"], let logLevel = Logger.Level(rawValue: loggingLevel.lowercased()) {
            return logLevel
        }
        return .info
    }

    static var logger: Logger {
        var logger = Logger(label: "soto")
        logger.logLevel = self.logLevel
        return logger
    }
}

/// Create asset, run some code using it and delete the asset
func testAsset<T>(
    create: () async throws -> T,
    test: (T) async throws -> Void,
    delete: (T) async throws -> Void,
    sourceLocation: SourceLocation = #_sourceLocation
) async throws {
    let asset = try await create()
    await #expect(throws: Never.self, sourceLocation: sourceLocation) { try await test(asset) }
    try await delete(asset)
}

/// Test trait that manages the lifecycle of AWSClient for test or test suit
struct AWSClientTrait: TestScoping, SuiteTrait, TestTrait {
    @TaskLocal
    private static var _client: AWSClient?

    static var client: AWSClient {
        guard let client = AWSClientTrait._client else {
            preconditionFailure("Test or TestSuite requires the .awsClient trait")
        }
        return client
    }

    let createClient: @Sendable (String) -> AWSClient

    init(credentialProvider: CredentialProviderFactory = TestEnvironment.credentialProvider) {
        self.createClient = {
            var logger = Logger(label: $0)
            logger.logLevel = TestEnvironment.logLevel
            return AWSClient(credentialProvider: credentialProvider, middleware: TestEnvironment.middlewares, logger: logger)
        }
    }

    func provideScope(for test: Test, testCase: Test.Case?, performing function: @concurrent @Sendable () async throws -> Void) async throws {
        let client = self.createClient(test.name)
        do {
            try await AWSClientTrait.$_client.withValue(client) {
                try await function()
            }
        } catch {
            try? await client.shutdown()
            throw error
        }
        try await client.shutdown()
    }
}

extension SuiteTrait where Self == AWSClientTrait {
    static func awsClient(credentialProvider: CredentialProviderFactory = TestEnvironment.credentialProvider) -> AWSClientTrait {
        if TestEnvironment.isUsingLocalstack {
            print("Connecting to Localstack")
        } else {
            print("Connecting to AWS")
        }
        return AWSClientTrait(credentialProvider: credentialProvider)
    }
}

extension TestTrait where Self == AWSClientTrait {
    static func awsClient(credentialProvider: CredentialProviderFactory = .default) -> AWSClientTrait {
        AWSClientTrait(credentialProvider: credentialProvider)
    }
}

func createRandomBuffer(size: Int) -> ByteBuffer {
    // create buffer
    var data = [UInt8](repeating: 0, count: size)
    for i in 0..<size {
        data[i] = UInt8.random(in: 0...255)
    }
    return ByteBuffer(bytes: data)
}
