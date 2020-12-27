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
import NIO

/// Protocol providing a Cognito Identity id and token
public protocol IdentityProvider {
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
    public struct Context {
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
    public struct IdentityParams {
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
}
