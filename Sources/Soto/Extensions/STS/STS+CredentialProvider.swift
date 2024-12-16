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

import AsyncHTTPClient
import NIOCore
import NIOPosix
import SotoCore

import struct Foundation.Date
import typealias Foundation.TimeInterval
import struct Foundation.UUID

/// Credential Provider that holds an AWSClient
protocol CredentialProviderWithClient: CredentialProvider {
    var client: AWSClient { get }
}

extension CredentialProviderWithClient {
    /// shutdown credential provider and client
    func shutdown() async throws {
        try await client.shutdown()
    }
}

extension STS {
    /// Enumeration for provided a Request structure to a credential provider
    enum RequestProvider<Request: Sendable>: Sendable {
        case `static`(Request)
        case dynamic(@Sendable () async throws -> Request)

        func request() async throws -> Request {
            switch self {
            case .static(let request):
                return request
            case .dynamic(let requestFunction):
                return try await requestFunction()
            }
        }
    }

    /// Credential Provider using `AssumeRole` to provide credentials
    struct AssumeRoleCredentialProvider: CredentialProviderWithClient {
        let requestProvider: RequestProvider<STS.AssumeRoleRequest>
        let client: AWSClient
        let sts: STS

        init(
            requestProvider: RequestProvider<STS.AssumeRoleRequest>,
            credentialProvider: CredentialProviderFactory,
            region: Region,
            httpClient: any AWSHTTPClient
        ) {
            self.client = AWSClient(credentialProvider: credentialProvider, httpClient: httpClient)
            self.sts = STS(client: self.client, region: region)
            self.requestProvider = requestProvider
        }

        func getCredential(logger: Logger) async throws -> Credential {
            let request = try await requestProvider.request()
            let response = try await self.sts.assumeRole(request, logger: logger)
            guard let credentials = response.credentials else { throw CredentialProviderError.noProvider }
            return RotatingCredential(
                accessKeyId: credentials.accessKeyId,
                secretAccessKey: credentials.secretAccessKey,
                sessionToken: credentials.sessionToken,
                expiration: credentials.expiration
            )
        }
    }

    /// Credential Provider using `AssumeRoleWithSAML` to provide credentials
    struct AssumeRoleWithSAMLCredentialProvider: CredentialProviderWithClient {
        let requestProvider: RequestProvider<STS.AssumeRoleWithSAMLRequest>
        let client: AWSClient
        let sts: STS

        init(requestProvider: RequestProvider<STS.AssumeRoleWithSAMLRequest>, region: Region, httpClient: any AWSHTTPClient) {
            self.client = AWSClient(credentialProvider: .empty, httpClient: httpClient)
            self.sts = STS(client: self.client, region: region)
            self.requestProvider = requestProvider
        }

        func getCredential(logger: Logger) async throws -> Credential {
            let request = try await requestProvider.request()
            let response = try await self.sts.assumeRoleWithSAML(request, logger: logger)
            guard let credentials = response.credentials else { throw CredentialProviderError.noProvider }
            return RotatingCredential(
                accessKeyId: credentials.accessKeyId,
                secretAccessKey: credentials.secretAccessKey,
                sessionToken: credentials.sessionToken,
                expiration: credentials.expiration
            )
        }
    }

    /// Credential Provider using `AssumeRoleWebIdentity` to provide credentials
    struct AssumeRoleWithWebIdentityCredentialProvider: CredentialProviderWithClient {
        let requestProvider: RequestProvider<STS.AssumeRoleWithWebIdentityRequest>
        let client: AWSClient
        let sts: STS

        init(requestProvider: RequestProvider<STS.AssumeRoleWithWebIdentityRequest>, region: Region, httpClient: any AWSHTTPClient) {
            self.client = AWSClient(credentialProvider: .empty, httpClient: httpClient)
            self.sts = STS(client: self.client, region: region)
            self.requestProvider = requestProvider
        }

        func getCredential(logger: Logger) async throws -> Credential {
            let request = try await requestProvider.request()
            let response = try await self.sts.assumeRoleWithWebIdentity(request, logger: logger)
            guard let credentials = response.credentials else { throw CredentialProviderError.noProvider }
            return RotatingCredential(
                accessKeyId: credentials.accessKeyId,
                secretAccessKey: credentials.secretAccessKey,
                sessionToken: credentials.sessionToken,
                expiration: credentials.expiration
            )
        }
    }

    /// Credential Provider using `AssumeRoleWebIdentity` to provide credentials. Uses environment variables to setup request structure. Used
    /// by Amazon EKS Clusters.
    struct AssumeRoleWithWebIdentityTokenFileCredentialProvider: CredentialProvider {
        let webIdentityProvider: AssumeRoleWithWebIdentityCredentialProvider

        init?(region: Region, context: CredentialProviderFactory.Context) {
            guard let tokenFile = Environment["AWS_WEB_IDENTITY_TOKEN_FILE"] else { return nil }
            guard let roleArn = Environment["AWS_ROLE_ARN"] else { return nil }
            let sessionName = Environment["AWS_ROLE_SESSION_NAME"]

            self.webIdentityProvider = AssumeRoleWithWebIdentityCredentialProvider(
                requestProvider: .dynamic {
                    let token = try await Self.loadTokenFile(tokenFile)
                    return STS.AssumeRoleWithWebIdentityRequest(
                        roleArn: roleArn,
                        roleSessionName: sessionName ?? UUID().uuidString,
                        webIdentityToken: token
                    )
                },
                region: region,
                httpClient: context.httpClient
            )
        }

        func shutdown() async throws {
            try await self.webIdentityProvider.shutdown()
        }

        /// get credentials
        func getCredential(logger: Logger) async throws -> Credential {
            try await self.webIdentityProvider.getCredential(logger: logger)
        }

        /// Load web identity token file
        static func loadTokenFile(_ tokenFile: String) async throws -> String {
            let threadPool = NIOThreadPool(numberOfThreads: 1)
            threadPool.start()
            defer { threadPool.shutdownGracefully { _ in } }
            let fileIO = NonBlockingFileIO(threadPool: threadPool)

            let fileBuffer = try await loadFile(path: tokenFile, using: fileIO)
            let token = String(buffer: fileBuffer)
            return token
        }

        /// Load a file from disk without blocking the current thread
        /// - Returns: file contents in a byte-buffer
        static func loadFile(path: String, using fileIO: NonBlockingFileIO) async throws -> ByteBuffer {
            try await fileIO.withFileRegion(path: path) { region in
                try await fileIO.read(fileRegion: region, allocator: ByteBufferAllocator())
            }
        }
    }

    /// Credential provider using Federation Tokens
    struct FederatedTokenCredentialProvider: CredentialProviderWithClient {
        let requestProvider: RequestProvider<STS.GetFederationTokenRequest>
        let client: AWSClient
        let sts: STS

        init(
            requestProvider: RequestProvider<STS.GetFederationTokenRequest>,
            credentialProvider: CredentialProviderFactory,
            region: Region,
            httpClient: any AWSHTTPClient
        ) {
            self.client = AWSClient(credentialProvider: credentialProvider, httpClient: httpClient)
            self.sts = STS(client: self.client, region: region)
            self.requestProvider = requestProvider
        }

        func getCredential(logger: Logger) async throws -> Credential {
            let request = try await requestProvider.request()
            let response = try await self.sts.getFederationToken(request, logger: logger)
            guard let credentials = response.credentials else { throw CredentialProviderError.noProvider }
            return RotatingCredential(
                accessKeyId: credentials.accessKeyId,
                secretAccessKey: credentials.secretAccessKey,
                sessionToken: credentials.sessionToken,
                expiration: credentials.expiration
            )
        }
    }

    /// Credential provider using session tokens
    struct SessionTokenCredentialProvider: CredentialProviderWithClient {
        let requestProvider: RequestProvider<STS.GetSessionTokenRequest>
        let client: AWSClient
        let sts: STS

        init(
            requestProvider: RequestProvider<STS.GetSessionTokenRequest>,
            credentialProvider: CredentialProviderFactory,
            region: Region,
            httpClient: any AWSHTTPClient
        ) {
            self.client = AWSClient(credentialProvider: credentialProvider, httpClient: httpClient)
            self.sts = STS(client: self.client, region: region)
            self.requestProvider = requestProvider
        }

        func getCredential(logger: Logger) async throws -> Credential {
            let request = try await requestProvider.request()
            let response = try await self.sts.getSessionToken(request, logger: logger)
            guard let credentials = response.credentials else { throw CredentialProviderError.noProvider }
            return RotatingCredential(
                accessKeyId: credentials.accessKeyId,
                secretAccessKey: credentials.secretAccessKey,
                sessionToken: credentials.sessionToken,
                expiration: credentials.expiration
            )
        }
    }
}

extension CredentialProviderFactory {
    /// Use AssumeRole to provide credentials
    ///
    /// See [AWS Documention](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerole)
    ///
    /// - Parameters:
    ///   - request: AssumeRole request structure
    ///   - credentialProvider: Credential provider used in client that runs the AssumeRole operation
    ///   - region: Region to run request in
    public static func stsAssumeRole(
        request: STS.AssumeRoleRequest,
        credentialProvider: CredentialProviderFactory = .default,
        region: Region
    ) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.AssumeRoleCredentialProvider(
                requestProvider: .static(request),
                credentialProvider: credentialProvider,
                region: region,
                httpClient: context.httpClient
            )
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

    /// Use AssumeRole to provide credentials
    ///
    /// See [AWS Documention](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerole)
    ///
    /// - Parameters:
    ///   - credentialProvider: Credential provider used in client that runs the AssumeRole operation
    ///   - region: Region to run request in
    ///   - requestProvider: Function that returns an AssumeRole request struct
    public static func stsAssumeRole(
        credentialProvider: CredentialProviderFactory = .default,
        region: Region,
        requestProvider: @escaping @Sendable () async throws -> STS.AssumeRoleRequest
    ) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.AssumeRoleCredentialProvider(
                requestProvider: .dynamic(requestProvider),
                credentialProvider: credentialProvider,
                region: region,
                httpClient: context.httpClient
            )
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

    /// Use AssumeRoleWithSAML to provide credentials
    ///
    /// See [AWS Documention](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithsaml)
    ///
    /// - Parameters:
    ///   - request: AssumeRoleWithSAML request struct
    ///   - region: Region to run request in
    public static func stsSAML(request: STS.AssumeRoleWithSAMLRequest, region: Region) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.AssumeRoleWithSAMLCredentialProvider(requestProvider: .static(request), region: region, httpClient: context.httpClient)
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

    /// Use AssumeRoleWithSAML to provide credentials
    ///
    /// See [AWS Documention](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithsaml)
    ///
    /// - Parameters:
    ///   - region: Region to run request in
    ///   - requestProvider: Function that returns an AssumeRoleWithSAML request struct
    public static func stsSAML(
        region: Region,
        requestProvider: @escaping @Sendable () async throws -> STS.AssumeRoleWithSAMLRequest
    ) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.AssumeRoleWithSAMLCredentialProvider(
                requestProvider: .dynamic(requestProvider),
                region: region,
                httpClient: context.httpClient
            )
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

    /// Use AssumeRoleWithWebIdentity to provide credentials
    ///
    /// See [AWS Documention](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity)
    ///
    /// - Parameters:
    ///   - request: AssumeRoleWithWebIdentity request struct
    ///   - region: Region to run request in
    public static func stsWebIdentity(request: STS.AssumeRoleWithWebIdentityRequest, region: Region) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.AssumeRoleWithWebIdentityCredentialProvider(
                requestProvider: .static(request),
                region: region,
                httpClient: context.httpClient
            )
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

    /// Use AssumeRoleWithWebIdentity to provide credentials
    ///
    /// See [AWS Documention](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity)
    ///
    /// - Parameters:
    ///   - region: Region to run request in
    ///   - requestProvider: Function that returns an AssumeRoleWithWebIdentity request struct
    public static func stsWebIdentity(
        region: Region,
        requestProvider: @escaping @Sendable () async throws -> STS.AssumeRoleWithWebIdentityRequest
    ) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.AssumeRoleWithWebIdentityCredentialProvider(
                requestProvider: .dynamic(requestProvider),
                region: region,
                httpClient: context.httpClient
            )
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

    /// Use AssumeRoleWithWebIdentity to provide credentials for EKS clusters. Uses environment variables `AWS_WEB_IDENTITY_TOKEN_FILE`,
    /// `AWS_ROLE_ARN`, and `AWS_ROLE_SESSION_NAME`. The web identity token can be found in the file pointed to by `AWS_WEB_IDENTITY_TOKEN_FILE`.
    ///
    /// See [AWS Documention](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts-technical-overview.html#pod-configuration)
    ///
    /// - Parameters:
    ///   - region: Region to run request in
    public static func stsWebIdentityTokenFile(
        region: Region
    ) -> CredentialProviderFactory {
        .custom { context in
            guard let provider = STS.AssumeRoleWithWebIdentityTokenFileCredentialProvider(region: region, context: context) else {
                return NullCredentialProvider()
            }
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

    /// Use GetFederationToken to provide credentials
    ///
    /// See [AWS Documention](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getfederationtoken)
    ///
    /// - Parameters:
    ///   - request: AssumeRole request structure
    ///   - credentialProvider: Credential provider used in client that runs the GetFederationToken operation
    ///   - region: Region to run request in
    public static func stsFederationToken(
        request: STS.GetFederationTokenRequest,
        credentialProvider: CredentialProviderFactory = .default,
        region: Region
    ) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.FederatedTokenCredentialProvider(
                requestProvider: .static(request),
                credentialProvider: credentialProvider,
                region: region,
                httpClient: context.httpClient
            )
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

    /// Use GetSessionToken to provide credentials
    ///
    /// See [AWS Documention](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getsessiontoken)
    ///
    /// - Parameters:
    ///   - request: SessionToken request structure
    ///   - credentialProvider: Credential provider used in client that runs the GetSessionToken operation
    ///   - region: Region to run request in
    public static func stsSessionToken(
        request: STS.GetSessionTokenRequest,
        credentialProvider: CredentialProviderFactory = .default,
        region: Region
    ) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.SessionTokenCredentialProvider(
                requestProvider: .static(request),
                credentialProvider: credentialProvider,
                region: region,
                httpClient: context.httpClient
            )
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

    /// Use GetSessionToken to provide credentials
    ///
    /// See [AWS Documention](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getsessiontoken)
    ///
    /// - Parameters:
    ///   - credentialProvider: Credential provider used in client that runs the GetSessionToken operation
    ///   - region: Region to run request in
    ///   - requestProvider: Function that returns a SessionToken request structure
    public static func stsSessionToken(
        credentialProvider: CredentialProviderFactory = .default,
        region: Region,
        requestProvider: @escaping @Sendable () async throws -> STS.GetSessionTokenRequest
    ) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.SessionTokenCredentialProvider(
                requestProvider: .dynamic(requestProvider),
                credentialProvider: credentialProvider,
                region: region,
                httpClient: context.httpClient
            )
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }
}
