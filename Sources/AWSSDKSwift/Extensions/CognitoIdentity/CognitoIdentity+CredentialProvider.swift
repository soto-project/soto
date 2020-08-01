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
import NIO

extension CognitoIdentity {
    struct RotatingCredential: ExpiringCredential {
        func isExpiring(within interval: TimeInterval) -> Bool {
            return self.expiration.timeIntervalSinceNow < interval
        }

        let accessKeyId: String
        let secretAccessKey: String
        let sessionToken: String?
        let expiration: Date
    }

    struct IdentityCredentialProvider: CredentialProvider {
        let logins: [String: String]?
        let client: AWSClient
        let cognitoIdentity: CognitoIdentity
        let idPromise: EventLoopPromise<String>

        init(identityPoolId: String, logins: [String: String]?, region: Region, eventLoop: EventLoop, httpClient: AWSHTTPClient) {
            self.client = AWSClient(credentialProvider: .empty, httpClientProvider: .shared(httpClient))
            self.cognitoIdentity = CognitoIdentity(client: self.client, region: region)
            self.logins = logins
            self.idPromise = eventLoop.makePromise(of: String.self)

            // only getId once and store in promise
            let request = CognitoIdentity.GetIdInput(identityPoolId: identityPoolId, logins: logins)
            cognitoIdentity.getId(request, on: eventLoop).flatMapThrowing { response -> String in
                guard let identityId = response.identityId else { throw CredentialProviderError.noProvider }
                return identityId
            }.cascade(to: idPromise)
        }

        func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
            return self.idPromise.futureResult.flatMap { identityId -> EventLoopFuture<GetCredentialsForIdentityResponse> in
                let credentialsRequest = CognitoIdentity.GetCredentialsForIdentityInput(identityId: identityId, logins: self.logins)
                return self.cognitoIdentity.getCredentialsForIdentity(credentialsRequest, on: eventLoop)
            }
            .flatMapThrowing { response in
                guard let credentials = response.credentials,
                    let accessKeyId = credentials.accessKeyId,
                    let secretAccessKey = credentials.secretKey,
                    let sessionToken = credentials.sessionToken,
                    let expiration = credentials.expiration?.dateValue else {
                        throw CredentialProviderError.noProvider
                }
                return RotatingCredential(
                    accessKeyId: accessKeyId,
                    secretAccessKey: secretAccessKey,
                    sessionToken: sessionToken,
                    expiration: expiration
                )
            }
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
    /// Use CognitoIdentity GetId and GetCredentialsForIdentity to provide credentials
    /// - Parameters:
    ///   - identityPoolId: Identity pool to get identity from
    ///   - logins: Optional tokens for authenticating login
    ///   - region: Region where we can find the identity pool
    public static func cognitoIdentity(identityPoolId: String, logins: [String: String]?, region: Region) -> CredentialProviderFactory {
        .custom { context in
            let provider = CognitoIdentity.IdentityCredentialProvider(
                identityPoolId: identityPoolId,
                logins: logins,
                region: region,
                eventLoop: context.eventLoop,
                httpClient: context.httpClient
            )
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

}
