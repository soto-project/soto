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

public struct ErrorShape {
    public let name: String
    public let code: String?
    public let httpStatusCode: Int?
    
    public init(name: String, code: String?, httpStatusCode: Int?) {
        self.name = name
        self.code = code
        self.httpStatusCode = httpStatusCode
    }
}

