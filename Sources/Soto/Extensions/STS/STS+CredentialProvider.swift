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
    enum RequestProvider<Request> {
        case `static`(Request)
        case dynamic((EventLoop) -> EventLoopFuture<Request>)

        func request(on eventLoop: EventLoop) -> EventLoopFuture<Request> {
            switch self {
            case .static(let request):
                return eventLoop.makeSucceededFuture(request)
            case .dynamic(let requestFunction):
                return requestFunction(eventLoop)
            }
        }
    }

    struct AssumeRoleCredentialProvider: CredentialProviderWithClient {
        let requestProvider: RequestProvider<STS.AssumeRoleRequest>
        let client: AWSClient
        let sts: STS

        init(
            requestProvider: RequestProvider<STS.AssumeRoleRequest>,
            credentialProvider: CredentialProviderFactory,
            region: Region,
            httpClient: AWSHTTPClient
        ) {
            self.client = AWSClient(credentialProvider: credentialProvider, httpClientProvider: .shared(httpClient))
            self.sts = STS(client: self.client, region: region)
            self.requestProvider = requestProvider
        }

        func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
            return requestProvider.request(on: eventLoop).flatMap { request in
                self.sts.assumeRole(request, logger: logger, on: eventLoop)
            }.flatMapThrowing { response in
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

    struct AssumeRoleWithSAMLCredentialProvider: CredentialProviderWithClient {
        let requestProvider: RequestProvider<STS.AssumeRoleWithSAMLRequest>
        let client: AWSClient
        let sts: STS

        init(requestProvider: RequestProvider<STS.AssumeRoleWithSAMLRequest>, region: Region, httpClient: AWSHTTPClient) {
            self.client = AWSClient(credentialProvider: .empty, httpClientProvider: .shared(httpClient))
            self.sts = STS(client: self.client, region: region)
            self.requestProvider = requestProvider
        }

        func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
            return requestProvider.request(on: eventLoop).flatMap { request in
                self.sts.assumeRoleWithSAML(request, logger: logger, on: eventLoop)
            }.flatMapThrowing { response in
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

    struct AssumeRoleWithWebIdentityCredentialProvider: CredentialProviderWithClient {
        let requestProvider: RequestProvider<STS.AssumeRoleWithWebIdentityRequest>
        let client: AWSClient
        let sts: STS

        init(requestProvider: RequestProvider<STS.AssumeRoleWithWebIdentityRequest>, region: Region, httpClient: AWSHTTPClient) {
            self.client = AWSClient(credentialProvider: .empty, httpClientProvider: .shared(httpClient))
            self.sts = STS(client: self.client, region: region)
            self.requestProvider = requestProvider
        }

        func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
            return requestProvider.request(on: eventLoop).flatMap { request in
                self.sts.assumeRoleWithWebIdentity(request, logger: logger, on: eventLoop)
            }.flatMapThrowing { response in
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

    struct FederatedTokenCredentialProvider: CredentialProviderWithClient {
        let requestProvider: RequestProvider<STS.GetFederationTokenRequest>
        let client: AWSClient
        let sts: STS

        init(requestProvider: RequestProvider<STS.GetFederationTokenRequest>, credentialProvider: CredentialProviderFactory, region: Region, httpClient: AWSHTTPClient) {
            self.client = AWSClient(credentialProvider: credentialProvider, httpClientProvider: .shared(httpClient))
            self.sts = STS(client: self.client, region: region)
            self.requestProvider = requestProvider
        }

        func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
            return requestProvider.request(on: eventLoop).flatMap { request in
                self.sts.getFederationToken(request, logger: logger, on: eventLoop)
            }.flatMapThrowing { response in
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

    struct SessionTokenCredentialProvider: CredentialProviderWithClient {
        let requestProvider: RequestProvider<STS.GetSessionTokenRequest>
        let client: AWSClient
        let sts: STS

        init(requestProvider: RequestProvider<STS.GetSessionTokenRequest>, credentialProvider: CredentialProviderFactory, region: Region, httpClient: AWSHTTPClient) {
            self.client = AWSClient(credentialProvider: credentialProvider, httpClientProvider: .shared(httpClient))
            self.sts = STS(client: self.client, region: region)
            self.requestProvider = requestProvider
        }

        func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
            return requestProvider.request(on: eventLoop).flatMap { request in
                self.sts.getSessionToken(request, logger: logger, on: eventLoop)
            }.flatMapThrowing { response in
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
                requestProvider: .static(request),
                credentialProvider: credentialProvider,
                region: region,
                httpClient: context.httpClient
            )
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

    /// Use AssumeRole to provide credentials
    /// - Parameters:
    ///   - request: Function that returns a EventLoopFuture to be fulfillled with an AssumeRole request structure
    ///   - credentialProvider: Credential provider used in client that runs the AssumeRole operation
    ///   - region: Region to run request in
    public static func stsAssumeRole(
        credentialProvider: CredentialProviderFactory = .default,
        region: Region,
        requestProvider: @escaping (EventLoop) -> EventLoopFuture<STS.AssumeRoleRequest>
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
    /// - Parameters:
    ///   - requestProvider: Function that returns a EventLoopFuture to be fulfillled with an AssumeRoleWithSAML request struct
    ///   - region: Region to run request in
    public static func stsSAML(
        region: Region,
        requestProvider: @escaping (EventLoop) -> EventLoopFuture<STS.AssumeRoleWithSAMLRequest>
    ) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.AssumeRoleWithSAMLCredentialProvider(requestProvider: .dynamic(requestProvider), region: region, httpClient: context.httpClient)
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

    /// Use AssumeRoleWithWebIdentity to provide credentials
    /// - Parameters:
    ///   - request: AssumeRoleWithWebIdentity request struct
    ///   - region: Region to run request in
    public static func stsWebIdentity(request: STS.AssumeRoleWithWebIdentityRequest, region: Region) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.AssumeRoleWithWebIdentityCredentialProvider(requestProvider: .static(request), region: region, httpClient: context.httpClient)
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

    /// Use AssumeRoleWithWebIdentity to provide credentials
    /// - Parameters:
    ///   - requestProvider: Function that returns a EventLoopFuture to be fulfillled with an AssumeRoleWithWebIdentity request struct
    ///   - region: Region to run request in
    public static func stsWebIdentity(
        region: Region,
        requestProvider: @escaping (EventLoop) -> EventLoopFuture<STS.AssumeRoleWithWebIdentityRequest>
    ) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.AssumeRoleWithWebIdentityCredentialProvider(requestProvider: .dynamic(requestProvider), region: region, httpClient: context.httpClient)
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
                requestProvider: .static(request),
                credentialProvider: credentialProvider,
                region: region,
                httpClient: context.httpClient
            )
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

    /// Use GetSessionToken to provide credentials
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
    /// - Parameters:
    ///   - requestProvider: Function that returns a EventLoopFuture to be fulfillled with a SessionToken request structure
    ///   - credentialProvider: Credential provider used in client that runs the GetSessionToken operation
    ///   - region: Region to run request in
    public static func stsSessionToken(
        credentialProvider: CredentialProviderFactory = .default,
        region: Region,
        requestProvider: @escaping (EventLoop) -> EventLoopFuture<STS.GetSessionTokenRequest>
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
