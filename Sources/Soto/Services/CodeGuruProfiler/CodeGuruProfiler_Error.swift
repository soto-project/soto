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

// THIS FILE IS AUTOMATICALLY GENERATED by https://github.com/soto-project/soto/tree/main/CodeGenerator. DO NOT EDIT.

import SotoCore

/// Error enum for CodeGuruProfiler
public struct CodeGuruProfilerErrorType: AWSErrorType {
    enum Code: String {
        case conflictException = "ConflictException"
        case internalServerException = "InternalServerException"
        case resourceNotFoundException = "ResourceNotFoundException"
        case serviceQuotaExceededException = "ServiceQuotaExceededException"
        case throttlingException = "ThrottlingException"
        case validationException = "ValidationException"
    }

    private let error: Code
    public let context: AWSErrorContext?

    /// initialize CodeGuruProfiler
    public init?(errorCode: String, context: AWSErrorContext) {
        guard let error = Code(rawValue: errorCode) else { return nil }
        self.error = error
        self.context = context
    }

    internal init(_ error: Code) {
        self.error = error
        self.context = nil
    }

    /// return error code string
    public var errorCode: String { self.error.rawValue }

    /// The requested operation would cause a conflict with the current state of a service resource associated with the request. Resolve the conflict before retrying this request.
    public static var conflictException: Self { .init(.conflictException) }
    /// The server encountered an internal error and is unable to complete the request.
    public static var internalServerException: Self { .init(.internalServerException) }
    /// The resource specified in the request does not exist.
    public static var resourceNotFoundException: Self { .init(.resourceNotFoundException) }
    /// You have exceeded your service quota. To perform the requested action, remove some of the relevant resources, or use Service Quotas to request a service quota increase.
    public static var serviceQuotaExceededException: Self { .init(.serviceQuotaExceededException) }
    /// The request was denied due to request throttling.
    public static var throttlingException: Self { .init(.throttlingException) }
    /// The parameter is not valid.
    public static var validationException: Self { .init(.validationException) }
}

extension CodeGuruProfilerErrorType: Equatable {
    public static func == (lhs: CodeGuruProfilerErrorType, rhs: CodeGuruProfilerErrorType) -> Bool {
        lhs.error == rhs.error
    }
}

extension CodeGuruProfilerErrorType: CustomStringConvertible {
    public var description: String {
        return "\(self.error.rawValue): \(self.message ?? "")"
    }
}