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
import NIO
import SotoCore

extension CognitoIdentity {
    struct IdentityCredentialProvider: CredentialProvider {
        let logins: [String: String]?
        let client: AWSClient
        let cognitoIdentity: CognitoIdentity
        let idPromise: EventLoopPromise<String>

        init(
            identityPoolId: String,
            logins: [String: String]?,
            region: Region,
            httpClient: AWSHTTPClient,
            logger: Logger = AWSClient.loggingDisabled,
            eventLoop: EventLoop
        ) {
            self.client = AWSClient(credentialProvider: .empty, httpClientProvider: .shared(httpClient), logger: logger)
            self.cognitoIdentity = CognitoIdentity(client: self.client, region: region)
            self.logins = logins
            self.idPromise = eventLoop.makePromise(of: String.self)

            // only getId once and store in promise
            let request = CognitoIdentity.GetIdInput(identityPoolId: identityPoolId, logins: logins)
            cognitoIdentity.getId(request, logger: logger, on: eventLoop).flatMapThrowing { response -> String in
                guard let identityId = response.identityId else { throw CredentialProviderError.noProvider }
                return identityId
            }.cascade(to: idPromise)
        }

        func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
            return self.idPromise.futureResult.flatMap { identityId -> EventLoopFuture<GetCredentialsForIdentityResponse> in
                let credentialsRequest = CognitoIdentity.GetCredentialsForIdentityInput(identityId: identityId, logins: self.logins)
                return self.cognitoIdentity.getCredentialsForIdentity(credentialsRequest, logger: logger, on: eventLoop)
            }
            .flatMapThrowing { response in
                guard let credentials = response.credentials,
                      let accessKeyId = credentials.accessKeyId,
                      let secretAccessKey = credentials.secretKey,
                      let sessionToken = credentials.sessionToken,
                      let expiration = credentials.expiration
                else {
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
}

extension CredentialProviderFactory {
    /// Use CognitoIdentity GetId and GetCredentialsForIdentity to provide credentials
    /// - Parameters:
    ///   - identityPoolId: Identity pool to get identity from
    ///   - logins: Optional tokens for authenticating login
    ///   - region: Region where we can find the identity pool
    public static func cognitoIdentity(
        identityPoolId: String,
        logins: [String: String]?,
        region: Region,
        logger: Logger = AWSClient.loggingDisabled
    ) -> CredentialProviderFactory {
        .custom { context in
            let provider = CognitoIdentity.IdentityCredentialProvider(
                identityPoolId: identityPoolId,
                logins: logins,
                region: region,
                httpClient: context.httpClient,
                logger: logger,
                eventLoop: context.eventLoop
            )
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }
}
