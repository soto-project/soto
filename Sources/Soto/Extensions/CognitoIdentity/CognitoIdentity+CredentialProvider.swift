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
import SotoCore

import struct Foundation.Date
import typealias Foundation.TimeInterval

extension CognitoIdentity {
    struct IdentityCredentialProvider: CredentialProvider {
        let client: AWSClient
        let cognitoIdentity: CognitoIdentity
        let identityProvider: IdentityProvider
        let identityPoolId: String

        init(
            identityPoolId: String,
            identityProvider: IdentityProviderFactory,
            region: Region,
            httpClient: any AWSHTTPClient,
            logger: Logger = AWSClient.loggingDisabled
        ) {
            self.client = AWSClient(credentialProvider: .empty, httpClient: httpClient, logger: logger)
            self.cognitoIdentity = CognitoIdentity(client: self.client, region: region)
            self.identityPoolId = identityPoolId
            let context = IdentityProviderFactory.Context(cognitoIdentity: self.cognitoIdentity, identityPoolId: identityPoolId, logger: logger)
            self.identityProvider = identityProvider.createProvider(context: context)
        }

        func getCredential(logger: Logger) async throws -> Credential {
            let identity = try await self.identityProvider.getIdentity(logger: logger)
            let credentialsRequest = CognitoIdentity.GetCredentialsForIdentityInput(identityId: identity.id, logins: identity.logins)
            let response = try await self.cognitoIdentity.getCredentialsForIdentity(credentialsRequest, logger: logger)
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

        func shutdown() async throws {
            try await self.identityProvider.shutdown()
            try await self.client.shutdown()
        }
    }
}

extension CredentialProviderFactory {
    /// Use CognitoIdentity GetId and GetCredentialsForIdentity to provide credentials
    /// - Parameters:
    ///   - identityPoolId: Identity pool to get identity from
    ///   - logins: Optional tokens for authenticating login
    ///   - region: Region where we can find the identity pool
    ///   - logger: Logger
    public static func cognitoIdentity(
        identityPoolId: String,
        logins: [String: String]?,
        region: Region,
        logger: Logger = AWSClient.loggingDisabled
    ) -> CredentialProviderFactory {
        .custom { context in
            let provider = CognitoIdentity.IdentityCredentialProvider(
                identityPoolId: identityPoolId,
                identityProvider: .static(logins: logins),
                region: region,
                httpClient: context.httpClient,
                logger: logger
            )
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }

    /// Uses `GetCredentialsForIdentity` to provide credentials. `identityProvider` object is used to supply the `login` and `IdentityId`
    /// parameters required by `GetCredentialsForIdentity`.
    ///
    /// For the `identityProvider` parameter construct a struct conforming to `IdentityProvider` as follows
    /// ```
    /// struct MyIdentityProvider: IdentityProvider {
    ///     func getIdentity(logger: Logger) async throws -> CognitoIdentity.IdentityParams {
    ///         // code to call backend to return the identity id and token. When backend call completes fill out a
    ///         // `CognitoIdentity.IdentityParams` struct with the details.
    ///     }
    /// }
    /// ```
    /// The `identityProvider` parameter should be as follows
    /// ```
    /// identityProvider: .custom { context in MyIdentityProvider(context: context) }
    /// ```
    /// The context struct is a `IdentityProviderFactory.Context`which includes a `CognitoIdentity` service object holding an `AWSClient` which
    /// has a reference to an `HTTPClient` if you need one for communicating with your backend.
    ///
    ///
    /// - Parameters:
    ///   - identityPoolId: Identity pool to get identity from
    ///   - identityProvider: Identiy Provider object
    ///   - region: Region where we can find the identity pool
    ///   - logger: Logger
    public static func cognitoIdentity(
        identityPoolId: String,
        identityProvider: IdentityProviderFactory,
        region: Region,
        logger: Logger = AWSClient.loggingDisabled
    ) -> CredentialProviderFactory {
        .custom { context in
            let provider = CognitoIdentity.IdentityCredentialProvider(
                identityPoolId: identityPoolId,
                identityProvider: identityProvider,
                region: region,
                httpClient: context.httpClient,
                logger: logger
            )
            return RotatingCredentialProvider(context: context, provider: provider)
        }
    }
}
