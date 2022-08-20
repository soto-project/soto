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
public protocol IdentityProvider: _SotoSendableProtocol {
    func getIdentity(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<CognitoIdentity.IdentityParams>
    func shutdown(on eventLoop: EventLoop) -> EventLoopFuture<Void>
}

extension IdentityProvider {
    public func shutdown(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        return eventLoop.makeSucceededFuture(())
    }
}

/// A helper struct to defer the creation of an `IdentityProvider` until after the `IdentityCredentialProvider` has been created.
public struct IdentityProviderFactory {
    /// The initialization context for a `IdentityProvider`
    public struct Context: _SotoSendable {
        public let cognitoIdentity: CognitoIdentity
        public let identityPoolId: String
        public let logger: Logger
    }

    private let cb: (Context) -> IdentityProvider

    private init(cb: @escaping (Context) -> IdentityProvider) {
        self.cb = cb
    }

    internal func createProvider(context: Context) -> IdentityProvider {
        self.cb(context)
    }
}

extension CognitoIdentity {
    public struct IdentityParams: _SotoSendable {
        let id: String
        let logins: [String: String]?

        public init(id: String, logins: [String: String]?) {
            self.id = id
            self.logins = logins
        }
    }

    struct StaticIdentityProvider: IdentityProvider {
        let logins: [String: String]?
        let identityIdPromise: EventLoopPromise<String>

        init(logins: [String: String]?, context: IdentityProviderFactory.Context) {
            self.logins = logins
            // create identity id promise
            let eventLoop = context.cognitoIdentity.client.eventLoopGroup.next()
            let identityIdPromise = eventLoop.makePromise(of: String.self)
            self.identityIdPromise = identityIdPromise
            // request identity id and fulfill promise on completion
            let request = CognitoIdentity.GetIdInput(identityPoolId: context.identityPoolId, logins: logins)
            context.cognitoIdentity.getId(request, logger: context.logger, on: eventLoop).whenComplete { result in
                switch result {
                case .failure:
                    identityIdPromise.fail(CredentialProviderError.noProvider)
                case .success(let response):
                    guard let identityId = response.identityId else {
                        identityIdPromise.fail(CredentialProviderError.noProvider)
                        return
                    }
                    identityIdPromise.succeed(identityId)
                }
            }
        }

        func shutdown(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
            return self.identityIdPromise.futureResult.map { _ in }.hop(to: eventLoop)
        }

        func getIdentity(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<IdentityParams> {
            return self.identityIdPromise.futureResult.map { identityId in
                return .init(id: identityId, logins: self.logins)
            }.hop(to: eventLoop)
        }
    }

    /// Protocol providing Cognito Identity id and tokens
    public struct ExternalIdentityProvider: IdentityProvider {
        #if compiler(>=5.6)
        typealias LoginProvider = @Sendable (Context) -> EventLoopFuture<[String: String]>
        #else
        typealias LoginProvider = (Context) -> EventLoopFuture<[String: String]>
        #endif
        /// The context passed to the logins provider closure
        public struct Context: _SotoSendable {
            public let client: AWSClient
            public let region: Region
            public let identityPoolId: String
            public let eventLoop: EventLoop
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
        public func getIdentity(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<IdentityParams> {
            let context = Context(
                client: self.identityProviderContext.cognitoIdentity.client,
                region: self.identityProviderContext.cognitoIdentity.region,
                identityPoolId: self.identityProviderContext.identityPoolId,
                eventLoop: eventLoop,
                logger: logger
            )
            return self.loginsProvider(context)
                .flatMap { logins in
                    let request = CognitoIdentity.GetIdInput(identityPoolId: context.identityPoolId, logins: logins)
                    return self.identityProviderContext.cognitoIdentity.getId(request, logger: context.logger, on: eventLoop).map { (logins: logins, response: $0) }
                }
                .flatMapThrowing { (result: (logins: [String: String], response: GetIdResponse)) -> IdentityParams in
                    guard let identityId = result.response.identityId else { throw CredentialProviderError.noProvider }
                    return IdentityParams(id: identityId, logins: result.logins)
                }
                .hop(to: eventLoop)
        }
    }
}

extension IdentityProviderFactory {
    /// Create your owncustom `IdentityProvider` given the IdentityProvider Context
    public static func custom(_ factory: @escaping (Context) -> IdentityProvider) -> Self {
        Self(cb: factory)
    }

    /// Create `StaticIdentityProvider` which attempts to use the same `logins` map on each call to `getIdentity`.
    public static func `static`(logins: [String: String]?) -> Self {
        return Self { context in
            return CognitoIdentity.StaticIdentityProvider(logins: logins, context: context)
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
    ///         return cognitoIdentityProvider.initiateAuth(request, logger: context.logger, on: context.eventLoop)
    ///             .flatMapThrowing { response in
    ///                 guard let idToken = response.authenticationResult?.idToken else { throw CredentialProviderError.noProvider }
    ///                 return [userPoolIdentityProvider: idToken]
    ///             }
    ///     }),
    ///     region: .euwest1
    /// )
    /// ```
    public static func externalIdentityProvider(
        tokenProvider: @escaping (CognitoIdentity.ExternalIdentityProvider.Context) -> EventLoopFuture<[String: String]>
    ) -> Self {
        return Self { context in
            return CognitoIdentity.ExternalIdentityProvider(context: context) { context in
                return tokenProvider(context)
            }
        }
    }
}
