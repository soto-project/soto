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
import struct Foundation.UUID
import NIO
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
    /// Enumeration for provided a Request structure to a credential provider
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

    /// Credential Provider using `AssumeRole` to provide credentials
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

    /// Credential Provider using `AssumeRoleWithSAML` to provide credentials
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

    /// Credential Provider using `AssumeRoleWebIdentity` to provide credentials
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

    /// Credential Provider using `AssumeRoleWebIdentity` to provide credentials. Uses environment variables to setup request structure. Used
    /// by Amazon EKS Clusters.
    struct AssumeRoleWithWebIdentityTokenFileCredentialProvider: CredentialProvider {
        let webIdentityProvider: AssumeRoleWithWebIdentityCredentialProvider

        init?(region: Region, context: CredentialProviderFactory.Context) {
            guard let tokenFile = Environment["AWS_WEB_IDENTITY_TOKEN_FILE"] else { return nil }
            guard let roleArn = Environment["AWS_ROLE_ARN"] else { return nil }
            let sessionName = Environment["AWS_ROLE_SESSION_NAME"]

            self.webIdentityProvider = AssumeRoleWithWebIdentityCredentialProvider(
                requestProvider: .dynamic { _ in
                    return Self.loadTokenFile(tokenFile, on: context.eventLoop).map { token in
                        STS.AssumeRoleWithWebIdentityRequest(
                            roleArn: roleArn,
                            roleSessionName: sessionName ?? UUID().uuidString,
                            webIdentityToken: token
                        )
                    }
                },
                region: region,
                httpClient: context.httpClient
            )
        }

        func shutdown(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
            return webIdentityProvider.shutdown(on: eventLoop)
        }

        /// get credentials
        func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
            return webIdentityProvider.getCredential(on: eventLoop, logger: logger)
        }

        /// Load web identity token file
        static func loadTokenFile(_ tokenFile: String, on eventLoop: EventLoop) -> EventLoopFuture<String> {
            let threadPool = NIOThreadPool(numberOfThreads: 1)
            threadPool.start()
            let fileIO = NonBlockingFileIO(threadPool: threadPool)

            return loadFile(path: tokenFile, on: eventLoop, using: fileIO).map { byteBuffer in
                var byteBuffer = byteBuffer
                return byteBuffer.readString(length: byteBuffer.readableBytes) ?? ""
            }
            .always { _ in
                // shutdown the threadpool async
                threadPool.shutdownGracefully { _ in }
            }
        }

        /// Load a file from disk without blocking the current thread
        /// - Returns: Event loop future with file contents in a byte-buffer
        static func loadFile(path: String, on eventLoop: EventLoop, using fileIO: NonBlockingFileIO) -> EventLoopFuture<ByteBuffer> {
            return fileIO.openFile(path: path, eventLoop: eventLoop)
                .flatMap { handle, region in
                    fileIO.read(fileRegion: region, allocator: ByteBufferAllocator(), eventLoop: eventLoop)
                        .flatMapErrorThrowing { error in
                            try? handle.close()
                            throw error
                        }
                        .flatMapThrowing { byteBuffer in
                            try handle.close()
                            return byteBuffer
                        }
                }
        }
    }

    /// Credential provider using Federation Tokens
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

    /// Credential provider using session tokens
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
    ///   - requestProvider: Function that returns a EventLoopFuture to be fulfillled with an AssumeRole request struct
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
    ///   - requestProvider: Function that returns a EventLoopFuture to be fulfillled with an AssumeRoleWithSAML request struct
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
    ///
    /// See [AWS Documention](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity)
    ///
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
    ///
    /// See [AWS Documention](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity)
    ///
    /// - Parameters:
    ///   - region: Region to run request in
    ///   - requestProvider: Function that returns a EventLoopFuture to be fulfillled with an AssumeRoleWithWebIdentity request struct
    public static func stsWebIdentity(
        region: Region,
        requestProvider: @escaping (EventLoop) -> EventLoopFuture<STS.AssumeRoleWithWebIdentityRequest>
    ) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.AssumeRoleWithWebIdentityCredentialProvider(requestProvider: .dynamic(requestProvider), region: region, httpClient: context.httpClient)
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
    ///   - requestProvider: Function that returns a EventLoopFuture to be fulfillled with a SessionToken request structure
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
