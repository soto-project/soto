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

import struct Foundation.Date
import typealias Foundation.TimeInterval
import SotoCore

/// Credential Provider that holds an AWSClient
protocol CredentialProviderWithClient: CredentialProvider {
    var client: AWSClient { get }
}

extension CredentialProviderWithClient {
    /// shutdown credential provider and client
    func shutdown(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        // shutdown AWSClient
        let promise = eventLoop.makePromise(of: Void.self)
        client.shutdown { error in
            if let error = error {
                promise.completeWith(.failure(error))
            } else {
                promise.completeWith(.success(()))
            }
        }
        return promise.futureResult
    }
}

extension STS {
    struct RotatingCredential: ExpiringCredential {
        func isExpiring(within interval: TimeInterval) -> Bool {
            return self.expiration.timeIntervalSinceNow < interval
        }

        let accessKeyId: String
        let secretAccessKey: String
        let sessionToken: String?
        let expiration: Date
    }

    struct AssumeRoleCredentialProvider: CredentialProviderWithClient {
        let request: STS.AssumeRoleRequest
        let client: AWSClient
        let sts: STS

        init(request: STS.AssumeRoleRequest, credentialProvider: CredentialProviderFactory, region: Region, httpClient: AWSHTTPClient) {
            self.client = AWSClient(credentialProvider: credentialProvider, httpClientProvider: .shared(httpClient))
            self.sts = STS(client: self.client, region: region)
            self.request = request
        }

        func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
            return sts.assumeRole(request, on: eventLoop).flatMapThrowing { response in
                guard let credentials = response.credentials else { throw CredentialProviderError.noProvider }
                return RotatingCredential(
                    accessKeyId: credentials.accessKeyId,
                    secretAccessKey: credentials.secretAccessKey,
                    sessionToken: credentials.sessionToken,
                    expiration: credentials.expiration.dateValue
                )
            }
        }
    }

    struct AssumeRoleWithSAMLCredentialProvider: CredentialProviderWithClient {
        let request: STS.AssumeRoleWithSAMLRequest
        let client: AWSClient
        let sts: STS

        init(request: STS.AssumeRoleWithSAMLRequest, region: Region, httpClient: AWSHTTPClient) {
            self.client = AWSClient(credentialProvider: .empty, httpClientProvider: .shared(httpClient))
            self.sts = STS(client: self.client, region: region)
            self.request = request
        }

        func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
            return sts.assumeRoleWithSAML(request, on: eventLoop).flatMapThrowing { response in
                guard let credentials = response.credentials else { throw CredentialProviderError.noProvider }
                return RotatingCredential(
                    accessKeyId: credentials.accessKeyId,
                    secretAccessKey: credentials.secretAccessKey,
                    sessionToken: credentials.sessionToken,
                    expiration: credentials.expiration.dateValue
                )
            }
        }
    }

    struct AssumeRoleWithWebIdentityCredentialProvider: CredentialProviderWithClient {
        let request: STS.AssumeRoleWithWebIdentityRequest
        let client: AWSClient
        let sts: STS

        init(request: STS.AssumeRoleWithWebIdentityRequest, region: Region, httpClient: AWSHTTPClient) {
            self.client = AWSClient(credentialProvider: .empty, httpClientProvider: .shared(httpClient))
            self.sts = STS(client: self.client, region: region)
            self.request = request
        }

        func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
            return sts.assumeRoleWithWebIdentity(request, on: eventLoop).flatMapThrowing { response in
                guard let credentials = response.credentials else { throw CredentialProviderError.noProvider }
                return RotatingCredential(
                    accessKeyId: credentials.accessKeyId,
                    secretAccessKey: credentials.secretAccessKey,
                    sessionToken: credentials.sessionToken,
                    expiration: credentials.expiration.dateValue
                )
            }
        }
    }

    struct FederatedTokenCredentialProvider: CredentialProviderWithClient {
        let request: STS.GetFederationTokenRequest
        let client: AWSClient
        let sts: STS

        init(request: STS.GetFederationTokenRequest, credentialProvider: CredentialProviderFactory, region: Region, httpClient: AWSHTTPClient) {
            self.client = AWSClient(credentialProvider: credentialProvider, httpClientProvider: .shared(httpClient))
            self.sts = STS(client: self.client, region: region)
            self.request = request
        }

        func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
            return sts.getFederationToken(request, on: eventLoop).flatMapThrowing { response in
                guard let credentials = response.credentials else { throw CredentialProviderError.noProvider }
                return RotatingCredential(
                    accessKeyId: credentials.accessKeyId,
                    secretAccessKey: credentials.secretAccessKey,
                    sessionToken: credentials.sessionToken,
                    expiration: credentials.expiration.dateValue
                )
            }
        }
    }

    struct SessionTokenCredentialProvider: CredentialProviderWithClient {
        let request: STS.GetSessionTokenRequest
        let client: AWSClient
        let sts: STS

        init(request: STS.GetSessionTokenRequest, credentialProvider: CredentialProviderFactory, region: Region, httpClient: AWSHTTPClient) {
            self.client = AWSClient(credentialProvider: credentialProvider, httpClientProvider: .shared(httpClient))
            self.sts = STS(client: self.client, region: region)
            self.request = request
        }

        func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
            return sts.getSessionToken(request, on: eventLoop).flatMapThrowing { response in
                guard let credentials = response.credentials else { throw CredentialProviderError.noProvider }
                return RotatingCredential(
                    accessKeyId: credentials.accessKeyId,
                    secretAccessKey: credentials.secretAccessKey,
                    sessionToken: credentials.sessionToken,
                    expiration: credentials.expiration.dateValue
                )
            }
        }
    }
}

extension CredentialProviderFactory {
    /// Use AssumeRole to provide credentials
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
                request: request,
                credentialProvider: credentialProvider,
                region: region,
                httpClient: context.httpClient
            )
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

    /// Use AssumeRoleWithSAML to provide credentials
    /// - Parameters:
    ///   - request: AssumeRoleWithSAML request struct
    ///   - region: Region to run request in
    public static func stsSAML(request: STS.AssumeRoleWithSAMLRequest, region: Region) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.AssumeRoleWithSAMLCredentialProvider(request: request, region: region, httpClient: context.httpClient)
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

    /// Use AssumeRoleWithWebIdentity to provide credentials
    /// - Parameters:
    ///   - request: AssumeRoleWithWebIdentity request struct
    ///   - region: Region to run request in
    public static func stsWebIdentity(request: STS.AssumeRoleWithWebIdentityRequest, region: Region) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.AssumeRoleWithWebIdentityCredentialProvider(request: request, region: region, httpClient: context.httpClient)
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

    /// Use GetFederationToken to provide credentials
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
                request: request,
                credentialProvider: credentialProvider,
                region: region,
                httpClient: context.httpClient
            )
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

    /// Use GetSessionToken to provide credentials
    /// - Parameters:
    ///   - request: AssumeRole request structure
    ///   - credentialProvider: Credential provider used in client that runs the GetSessionToken operation
    ///   - region: Region to run request in
    public static func stsSessionToken(
        request: STS.GetSessionTokenRequest,
        credentialProvider: CredentialProviderFactory = .default,
        region: Region
    ) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.SessionTokenCredentialProvider(
                request: request,
                credentialProvider: credentialProvider,
                region: region,
                httpClient: context.httpClient
            )
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }
}
