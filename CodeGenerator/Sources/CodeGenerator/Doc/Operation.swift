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

public struct Operation {
    public let name: String
    public let operationName: String
    public let httpMethod: String
    public let path: String
    public let inputShape: Shape?
    public let outputShape: Shape?
    public let deprecatedMessage: String?

    public init(
        name: String,
        operationName: String,
        httpMethod: String,
        path: String,
        inputShape: Shape?,
        outputShape: Shape?,
        deprecatedMessage : String? = nil
    ) {
        self.name = name
        self.operationName = operationName
        self.httpMethod = httpMethod
        self.path = path
        self.inputShape = inputShape
        self.outputShape = outputShape
        self.deprecatedMessage = deprecatedMessage
    }
}
