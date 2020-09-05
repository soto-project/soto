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

public struct APIGatewayMiddleware: AWSServiceMiddleware {
    public func chain(request: AWSRequest, context: AWSMiddlewareContext) throws -> AWSRequest {
        var request = request
        // have to set Accept header to application/json otherwise errors are not returned correctly
        if request.httpHeaders["Accept"].first == nil {
            request.httpHeaders.replaceOrAdd(name: "Accept", value: "application/json")
        }
        return request
    }
}
