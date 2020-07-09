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
import struct Foundation.Date
import typealias Foundation.TimeInterval

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
    
    struct AssumeRoleCredentialProvider: CredentialProvider {
        let request: STS.AssumeRoleRequest
        let client: AWSClient
        let sts: STS

        init(request: STS.AssumeRoleRequest, credentialProvider: CredentialProviderFactory, region: Region, httpClient: AWSHTTPClient) {
            self.client = AWSClient(credentialProvider: credentialProvider, httpClientProvider: .shared(httpClient))
            self.sts = STS(client: self.client, region: region)
            self.request = request
        }
        
        func getCredential(on eventLoop: EventLoop) -> EventLoopFuture<Credential> {
            return sts.assumeRole(request).flatMapThrowing { response in
                guard let credentials = response.credentials else { throw CredentialProviderError.noProvider }
                return RotatingCredential(
                    accessKeyId: credentials.accessKeyId,
                    secretAccessKey: credentials.secretAccessKey,
                    sessionToken: credentials.sessionToken,
                    expiration: credentials.expiration.dateValue
                )
            }.hop(to: eventLoop)
        }

        func shutdown(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
            // can call client.syncShutdown here as we have shutdown the credential provider and the
            // client uses the http client supplied at initialisation.
            return client.credentialProvider.shutdown(on: eventLoop).flatMapThrowing { _ in try self.client.syncShutdown() }
        }
    }
    
    struct AssumeRoleWithSAMLCredentialProvider: CredentialProvider {
        let request: STS.AssumeRoleWithSAMLRequest
        let client: AWSClient
        let sts: STS
        
        init(request: STS.AssumeRoleWithSAMLRequest, region: Region, httpClient: AWSHTTPClient) {
            self.client = AWSClient(credentialProvider: .empty, httpClientProvider: .shared(httpClient))
            self.sts = STS(client: self.client, region: region)
            self.request = request
        }

        func getCredential(on eventLoop: EventLoop) -> EventLoopFuture<Credential> {
            return sts.assumeRoleWithSAML(request).flatMapThrowing { response in
                guard let credentials = response.credentials else { throw CredentialProviderError.noProvider }
                return RotatingCredential(
                    accessKeyId: credentials.accessKeyId,
                    secretAccessKey: credentials.secretAccessKey,
                    sessionToken: credentials.sessionToken,
                    expiration: credentials.expiration.dateValue
                )
            }.hop(to: eventLoop)
        }

        func shutdown(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
            // can call client.syncShutdown here as it has an empty credential provider and
            // uses the http client supplied at initialisation.
            do {
                try client.syncShutdown()
                return eventLoop.makeSucceededFuture(())
            } catch {
                return eventLoop.makeFailedFuture(error)
            }
        }
    }
    
    struct AssumeRoleWithWebIdentityCredentialProvider: CredentialProvider {
        let request: STS.AssumeRoleWithWebIdentityRequest
        let client: AWSClient
        let sts: STS

        init(request: STS.AssumeRoleWithWebIdentityRequest, region: Region, httpClient: AWSHTTPClient) {
            self.client = AWSClient(credentialProvider: .empty, httpClientProvider: .shared(httpClient))
            self.sts = STS(client: self.client, region: region)
            self.request = request
        }

        func getCredential(on eventLoop: EventLoop) -> EventLoopFuture<Credential> {
            return sts.assumeRoleWithWebIdentity(request).flatMapThrowing { response in
                guard let credentials = response.credentials else { throw CredentialProviderError.noProvider }
                return RotatingCredential(
                    accessKeyId: credentials.accessKeyId,
                    secretAccessKey: credentials.secretAccessKey,
                    sessionToken: credentials.sessionToken,
                    expiration: credentials.expiration.dateValue
                )
            }.hop(to: eventLoop)
        }

        func shutdown(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
            // can call client.syncShutdown here as it has an empty credential provider and
            // uses the http client supplied at initialisation.
            do {
                try client.syncShutdown()
                return eventLoop.makeSucceededFuture(())
            } catch {
                return eventLoop.makeFailedFuture(error)
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
            return RotatingCredentialProvider(eventLoop: context.eventLoop, provider: provider)
        }
    }
    
    /// Use AssumeRoleWithSAML to provide credentials
    /// - Parameters:
    ///   - request: AssumeRoleWithSAML request struct
    ///   - region: Region to run request in
    public static func stsSAML(request: STS.AssumeRoleWithSAMLRequest, region: Region) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.AssumeRoleWithSAMLCredentialProvider(request: request, region: region, httpClient: context.httpClient)
            return RotatingCredentialProvider(eventLoop: context.eventLoop, provider: provider)
        }
    }

    /// Use AssumeRoleWithWebIdentity to provide credentials
    /// - Parameters:
    ///   - request: AssumeRoleWithWebIdentity request struct
    ///   - region: Region to run request in
    public static func stsWebIdentity(request: STS.AssumeRoleWithWebIdentityRequest, region: Region) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.AssumeRoleWithWebIdentityCredentialProvider(request: request, region: region, httpClient: context.httpClient)
            return RotatingCredentialProvider(eventLoop: context.eventLoop, provider: provider)
        }
    }
}
