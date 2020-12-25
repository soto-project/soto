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

public protocol IdentityProvider {
    func getIdentity(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<CognitoIdentity.IdentityParams>
    func shutdown(on eventLoop: EventLoop) -> EventLoopFuture<Void>
}

extension IdentityProvider {
    public func shutdown(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        return eventLoop.makeSucceededFuture(())
    }
}

extension CognitoIdentity {
    public struct IdentityParams {
        let id: String
        let logins: [String: String]?
    }

    struct StaticIdentityProvider: IdentityProvider {
        let identityPoolId: String
        let logins: [String: String]?
        let cognitoIdentity: CognitoIdentity

        func getIdentity(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<IdentityParams> {
            let request = CognitoIdentity.GetIdInput(identityPoolId: identityPoolId, logins: logins)
            return cognitoIdentity.getId(request, logger: logger, on: eventLoop).flatMapThrowing { response -> IdentityParams in
                guard let identityId = response.identityId else { throw CredentialProviderError.noProvider }
                return .init(id: identityId, logins: logins)
            }
        }
    }
}

/// A helper struct to defer the creation of an `IdentityProvider` until after the `IdentityCredentialProvider` has been created.
public struct IdentityProviderFactory {
    /// The initialization context for a `IdentityProvider`
    public struct Context {
        public let cognitoIdentity: CognitoIdentity
        public let identityPoolId: String
    }

    private let cb: (Context) -> IdentityProvider

    private init(cb: @escaping (Context) -> IdentityProvider) {
        self.cb = cb
    }

    internal func createProvider(context: Context) -> IdentityProvider {
        self.cb(context)
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
            return CognitoIdentity.StaticIdentityProvider(identityPoolId: context.identityPoolId, logins: logins, cognitoIdentity: context.cognitoIdentity)
        }
    }
}
