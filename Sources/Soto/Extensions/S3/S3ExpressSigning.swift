//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2024 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Logging
import SotoCore

/// S3 express credential provider
struct S3ExpressCredentialProvider: CredentialProvider {
    let s3: S3
    let bucket: String
    let ownsClient: Bool

    init(
        bucket: String,
        region: Region,
        credentialProvider: CredentialProviderFactory,
        httpClient: any AWSHTTPClient,
        logger: Logger = AWSClient.loggingDisabled
    ) {
        let client = AWSClient(credentialProvider: credentialProvider, httpClient: httpClient, logger: logger)
        self.s3 = S3(client: client, region: region)
        self.bucket = bucket
        self.ownsClient = true
    }

    init(
        bucket: String,
        s3: S3
    ) {
        self.s3 = s3
        self.bucket = bucket
        self.ownsClient = false
    }

    func getCredential(logger: Logger) async throws -> any Credential {
        let session = try await s3.createSession(bucket: bucket)
        return RotatingCredential(
            accessKeyId: session.credentials.accessKeyId,
            secretAccessKey: session.credentials.secretAccessKey,
            sessionToken: session.credentials.sessionToken,
            expiration: session.credentials.expiration
        )
    }

    func shutdown() async throws {
        if self.ownsClient {
            try await self.s3.client.shutdown()
        }
    }
}

/// Middleware for fixing up request to be in a form S3 express understands
public struct S3ExpressSigningFixupMiddleware: AWSMiddlewareProtocol {
    public init() {}

    public func handle(
        _ request: AWSHTTPRequest,
        context: AWSMiddlewareContext,
        next: (AWSHTTPRequest, AWSMiddlewareContext) async throws -> AWSHTTPResponse
    ) async throws -> AWSHTTPResponse {
        if let sessionToken = context.credential.sessionToken {
            var context = context
            var request = request
            request.headers.replaceOrAdd(name: "x-amz-s3session-token", value: sessionToken)
            context.credential = StaticCredential(accessKeyId: context.credential.accessKeyId, secretAccessKey: context.credential.secretAccessKey)
            return try await next(request, context)
        } else {
            return try await next(request, context)
        }
    }
}

extension CredentialProviderFactory {
    /// S3 express credential provider. Use this in conjunction with the S3ExpressSigningFixupMiddleware middleware
    /// to setup S3 express access
    ///
    /// ```
    /// let client = AWSClient(
    ///     credentialProvider: .s3Express(bucket: "MyBucket", region: .euwest1)),
    ///     middleware: S3ExpressSigningFixupMiddleware()
    /// )
    /// let s3 = S3(client: client, region: region)
    /// ```
    public static func s3Express(
        bucket: String,
        region: Region,
        credentialProvider: CredentialProviderFactory = .default
    ) -> CredentialProviderFactory {
        .custom { context in
            let provider = S3ExpressCredentialProvider(
                bucket: bucket,
                region: region,
                credentialProvider: credentialProvider,
                httpClient: context.httpClient,
                logger: context.logger
            )
            return RotatingCredentialProvider(context: context, provider: provider, remainingTokenLifetimeForUse: 30)
        }
    }

    /// S3 express credential provider. Use this in conjunction with the S3ExpressSigningFixupMiddleware middleware
    /// to setup S3 express access
    ///
    /// ```
    /// let client = AWSClient(
    ///     credentialProvider: .s3Express(bucket: "MyBucket", s3: s3)),
    ///     middleware: S3ExpressSigningFixupMiddleware()
    /// )
    /// let s3 = S3(client: client, region: region)
    /// ```
    public static func s3Express(
        bucket: String,
        s3: S3
    ) -> CredentialProviderFactory {
        .custom { context in
            let provider = S3ExpressCredentialProvider(
                bucket: bucket,
                s3: s3
            )
            return RotatingCredentialProvider(context: context, provider: provider, remainingTokenLifetimeForUse: 30)
        }
    }
}

extension S3 {
    /// Create AWSClient and S3 service for accessing S3 express one directory bucket
    /// - Parameter bucket: bucket name
    /// - Returns: AWSClient and S3 service
    public func createS3ExpressClientAndService(bucket: String) -> (AWSClient, S3) {
        let client = AWSClient(
            credentialProvider: .s3Express(bucket: bucket, s3: self),
            httpClient: self.client.httpClient,
            logger: self.client.logger
        )
        let s3 = S3(client: client, region: self.region, timeout: self.config.timeout, options: self.config.options)
            .with(middleware: S3ExpressSigningFixupMiddleware())
        return (client, s3)
    }
}
