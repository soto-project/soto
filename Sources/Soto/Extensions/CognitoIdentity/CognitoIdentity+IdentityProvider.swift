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

import Logging
import NIOCore
import SotoCore

/// Protocol providing a Cognito Identity id and tokens
public protocol IdentityProvider: Sendable {
    func getIdentity(logger: Logger) async throws -> CognitoIdentity.IdentityParams
    func shutdown() async throws
}

extension IdentityProvider {
    public func shutdown() async throws {}
}

/// A helper struct to defer the creation of an `IdentityProvider` until after the `IdentityCredentialProvider` has been created.
public struct IdentityProviderFactory: Sendable {
    /// The initialization context for a `IdentityProvider`
    public struct Context: Sendable {
        public let cognitoIdentity: CognitoIdentity
        public let identityPoolId: String
        public let logger: Logger
    }

    private let cb: @Sendable (Context) -> IdentityProvider

    private init(cb: @escaping @Sendable (Context) -> IdentityProvider) {
        self.cb = cb
    }

    func createProvider(context: Context) -> IdentityProvider {
        self.cb(context)
    }
}

extension CognitoIdentity {
    public struct IdentityParams: Sendable {
        let id: String
        let logins: [String: String]?

        public init(id: String, logins: [String: String]?) {
            self.id = id
            self.logins = logins
        }
    }

    struct StaticIdentityProvider: IdentityProvider {
        let logins: [String: String]?
        let getIdentityIdTask: Task<String, Error>

        init(logins: [String: String]?, context: IdentityProviderFactory.Context) {
            self.logins = logins
            self.getIdentityIdTask = Task {
                do {
                    let request = CognitoIdentity.GetIdInput(identityPoolId: context.identityPoolId, logins: logins)
                    let response = try await context.cognitoIdentity.getId(request, logger: context.logger)
                    guard let identityId = response.identityId else {
                        throw CredentialProviderError.noProvider
                    }
                    return identityId
                } catch {
                    throw CredentialProviderError.noProvider
                }
            }
        }

        func shutdown() async throws {
            self.getIdentityIdTask.cancel()
        }

        func getIdentity(logger: Logger) async throws -> IdentityParams {
            let identityId = try await getIdentityIdTask.value
            return .init(id: identityId, logins: self.logins)
        }
    }

    /// Protocol providing Cognito Identity id and tokens
    public struct ExternalIdentityProvider: IdentityProvider {
        typealias LoginProvider = @Sendable (Context) async throws -> [String: String]
        /// The context passed to the logins provider closure
        public struct Context: Sendable {
            public let client: AWSClient
            public let region: Region
            public let identityPoolId: String
            public let logger: Logger
        }

        let loginsProvider: LoginProvider
        let identityProviderContext: IdentityProviderFactory.Context

        init(
            context: IdentityProviderFactory.Context,
            _ loginsProvider: @escaping LoginProvider
        ) {
            self.loginsProvider = loginsProvider
            self.identityProviderContext = context
        }

        /// Get Identity from external identity provider and get Cognito Identity from this
        public func getIdentity(logger: Logger) async throws -> IdentityParams {
            let context = Context(
                client: self.identityProviderContext.cognitoIdentity.client,
                region: self.identityProviderContext.cognitoIdentity.region,
                identityPoolId: self.identityProviderContext.identityPoolId,
                logger: logger
            )

            let logins = try await self.loginsProvider(context)
            let request = CognitoIdentity.GetIdInput(identityPoolId: context.identityPoolId, logins: logins)
            let response = try await self.identityProviderContext.cognitoIdentity.getId(request, logger: context.logger)
            guard let identityId = response.identityId else { throw CredentialProviderError.noProvider }
            return IdentityParams(id: identityId, logins: logins)
        }
    }
}

extension IdentityProviderFactory {
    /// Create your owncustom `IdentityProvider` given the IdentityProvider Context
    public static func custom(_ factory: @escaping @Sendable (Context) -> IdentityProvider) -> Self {
        Self(cb: factory)
    }

    /// Create `StaticIdentityProvider` which attempts to use the same `logins` map on each call to `getIdentity`.
    public static func `static`(logins: [String: String]?) -> Self {
        Self { context in
            CognitoIdentity.StaticIdentityProvider(logins: logins, context: context)
        }
    }

    /// Create `IdentityProvider` which attempts to use an external identity provider for authentication.
    ///
    /// The token provider closure is used to return a set of name-value pairs that map provider names to provider tokens
    /// See https://docs.aws.amazon.com/cognitoidentity/latest/APIReference/API_GetId.html
    /// and https://docs.aws.amazon.com/cognito/latest/developerguide/external-identity-providers.html
    /// for details on what to return from the tokenProvider closure
    ///
    /// Below is an example using a Cognito UserPool to authenticate.
    /// ```
    /// let credentialProvider: CredentialProviderFactory = .cognitoIdentity(
    ///     identityPoolId: "my-identiy-pool-id",
    ///     identityProvider: .externalIdentityProvider(tokenProvider: { context in
    ///         let userPoolIdentityProvider = "cognito-idp.\(context.region).amazonaws.com/\(userPoolId)"
    ///         let cognitoIdentityProvider = CognitoIdentityProvider(client: context.client, region: context.region)
    ///         let request = CognitoIdentityProvider.InitiateAuthRequest(
    ///             authFlow: .userPasswordAuth,
    ///             authParameters: ["USERNAME": "my-username", "PASSWORD": "my-password"],
    ///             clientId: "my-client-id"
    ///         )
    ///         return cognitoIdentityProvider.initiateAuth(request, logger: context.logger)
    ///             .flatMapThrowing { response in
    ///                 guard let idToken = response.authenticationResult?.idToken else { throw CredentialProviderError.noProvider }
    ///                 return [userPoolIdentityProvider: idToken]
    ///             }
    ///     }),
    ///     region: .euwest1
    /// )
    /// ```
    public static func externalIdentityProvider(
        tokenProvider: @escaping @Sendable (CognitoIdentity.ExternalIdentityProvider.Context) async throws -> [String: String]
    ) -> Self {
        Self { context in
            CognitoIdentity.ExternalIdentityProvider(context: context) { context in
                try await tokenProvider(context)
            }
        }
    }
}
