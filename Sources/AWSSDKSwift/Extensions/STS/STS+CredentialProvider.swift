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
        let client: STS
        
        func getCredential(on eventLoop: EventLoop) -> EventLoopFuture<Credential> {
            return client.assumeRole(request).flatMapThrowing { response in
                guard let credentials = response.credentials else { throw CredentialProviderError.noProvider }
                return RotatingCredential(
                    accessKeyId: credentials.accessKeyId,
                    secretAccessKey: credentials.secretAccessKey,
                    sessionToken: credentials.sessionToken,
                    expiration: credentials.expiration.dateValue
                )
            }.hop(to: eventLoop)
        }
    }
    
    struct AssumeRoleWithSAMLCredentialProvider: CredentialProvider {
        let request: STS.AssumeRoleWithSAMLRequest
        let client: STS
        
        func getCredential(on eventLoop: EventLoop) -> EventLoopFuture<Credential> {
            return client.assumeRoleWithSAML(request).flatMapThrowing { response in
                guard let credentials = response.credentials else { throw CredentialProviderError.noProvider }
                return RotatingCredential(
                    accessKeyId: credentials.accessKeyId,
                    secretAccessKey: credentials.secretAccessKey,
                    sessionToken: credentials.sessionToken,
                    expiration: credentials.expiration.dateValue
                )
            }.hop(to: eventLoop)
        }
    }
    
    struct AssumeRoleWithWebIdentityCredentialProvider: CredentialProvider {
        let request: STS.AssumeRoleWithWebIdentityRequest
        let client: STS
        
        func getCredential(on eventLoop: EventLoop) -> EventLoopFuture<Credential> {
            return client.assumeRoleWithWebIdentity(request).flatMapThrowing { response in
                guard let credentials = response.credentials else { throw CredentialProviderError.noProvider }
                return RotatingCredential(
                    accessKeyId: credentials.accessKeyId,
                    secretAccessKey: credentials.secretAccessKey,
                    sessionToken: credentials.sessionToken,
                    expiration: credentials.expiration.dateValue
                )
            }.hop(to: eventLoop)
        }
    }
}

extension CredentialProviderFactory {
    public static func assumeRole(request: STS.AssumeRoleRequest, client: STS) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.AssumeRoleCredentialProvider(request: request, client: client)
            return RotatingCredentialProvider(eventLoop: context.eventLoop, client: provider)
        }
    }
    
    public static func saml(request: STS.AssumeRoleWithSAMLRequest, client: STS) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.AssumeRoleWithSAMLCredentialProvider(request: request, client: client)
            return RotatingCredentialProvider(eventLoop: context.eventLoop, client: provider)
        }
    }
    
    public static func webIdentity(request: STS.AssumeRoleWithWebIdentityRequest, client: STS) -> CredentialProviderFactory {
        .custom { context in
            let provider = STS.AssumeRoleWithWebIdentityCredentialProvider(request: request, client: client)
            return RotatingCredentialProvider(eventLoop: context.eventLoop, client: provider)
        }
    }
}
