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

import struct Foundation.CharacterSet
import struct Foundation.URL
import struct Foundation.URLComponents
import struct Foundation.URLQueryItem
import AWSSDKSwiftCore

public struct S3ControlMiddleware: AWSServiceMiddleware {

    public init () {}

    /// edit request before sending to S3
    public func chain(request: AWSRequest) throws -> AWSRequest {
        var request = request

        virtualAddressFixup(request: &request)

        return request
    }

    func virtualAddressFixup(request: inout AWSRequest) {
        /// process URL into form ${account-id}.s3control.${region}.amazon.com
        guard let accountId = request.httpHeaders["x-amz-account-id"] else { return }
        guard let host = request.url.host else { return }
        let urlHost = "\(accountId).\(host)"
        var urlPath = "\(urlHost)\(request.url.path)"
        // add percent encoding back into path as converting from URL to String has removed it
        urlPath = urlPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? urlPath
        var urlString = "\(request.url.scheme ?? "https")://\(urlPath)"
        if let query = request.url.query {
            urlString += "?\(query)"
        }
        request.url = URL(string: urlString)!
    }
}

