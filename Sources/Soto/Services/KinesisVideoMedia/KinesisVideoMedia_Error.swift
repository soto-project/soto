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

/// Error enum for KinesisVideoMedia
public struct KinesisVideoMediaErrorType: AWSErrorType {
    enum Code: String {
        case clientLimitExceededException = "ClientLimitExceededException"
        case connectionLimitExceededException = "ConnectionLimitExceededException"
        case invalidArgumentException = "InvalidArgumentException"
        case invalidEndpointException = "InvalidEndpointException"
        case notAuthorizedException = "NotAuthorizedException"
        case resourceNotFoundException = "ResourceNotFoundException"
    }

    private let error: Code
    public let context: AWSErrorContext?

    /// initialize KinesisVideoMedia
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

    /// Kinesis Video Streams has throttled the request because you have exceeded the limit of allowed client calls. Try making the call later.
    public static var clientLimitExceededException: Self { .init(.clientLimitExceededException) }
    /// Kinesis Video Streams has throttled the request because you have exceeded the limit of allowed client connections.
    public static var connectionLimitExceededException: Self { .init(.connectionLimitExceededException) }
    /// The value for this input parameter is invalid.
    public static var invalidArgumentException: Self { .init(.invalidArgumentException) }
    ///  Status Code: 400, Caller used wrong endpoint to write data to a stream. On receiving such an exception, the user must call GetDataEndpoint with AccessMode set to "READ" and use the endpoint Kinesis Video returns in the next GetMedia call.
    public static var invalidEndpointException: Self { .init(.invalidEndpointException) }
    /// Status Code: 403, The caller is not authorized to perform an operation on the given stream, or the token has expired.
    public static var notAuthorizedException: Self { .init(.notAuthorizedException) }
    /// Status Code: 404, The stream with the given name does not exist.
    public static var resourceNotFoundException: Self { .init(.resourceNotFoundException) }
}

extension KinesisVideoMediaErrorType: Equatable {
    public static func == (lhs: KinesisVideoMediaErrorType, rhs: KinesisVideoMediaErrorType) -> Bool {
        lhs.error == rhs.error
    }
}

extension KinesisVideoMediaErrorType: CustomStringConvertible {
    public var description: String {
        return "\(self.error.rawValue): \(self.message ?? "")"
    }
}