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

/// Error enum for Connect
public struct ConnectErrorType: AWSErrorType {
    enum Code: String {
        case contactFlowNotPublishedException = "ContactFlowNotPublishedException"
        case contactNotFoundException = "ContactNotFoundException"
        case destinationNotAllowedException = "DestinationNotAllowedException"
        case duplicateResourceException = "DuplicateResourceException"
        case internalServiceException = "InternalServiceException"
        case invalidContactFlowException = "InvalidContactFlowException"
        case invalidParameterException = "InvalidParameterException"
        case invalidRequestException = "InvalidRequestException"
        case limitExceededException = "LimitExceededException"
        case outboundContactNotPermittedException = "OutboundContactNotPermittedException"
        case resourceNotFoundException = "ResourceNotFoundException"
        case throttlingException = "ThrottlingException"
        case userNotFoundException = "UserNotFoundException"
    }

    private let error: Code
    public let context: AWSErrorContext?

    /// initialize Connect
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

    /// The contact flow has not been published.
    public static var contactFlowNotPublishedException: Self { .init(.contactFlowNotPublishedException) }
    /// The contact with the specified ID is not active or does not exist.
    public static var contactNotFoundException: Self { .init(.contactNotFoundException) }
    /// Outbound calls to the destination number are not allowed.
    public static var destinationNotAllowedException: Self { .init(.destinationNotAllowedException) }
    /// A resource with the specified name already exists.
    public static var duplicateResourceException: Self { .init(.duplicateResourceException) }
    /// Request processing failed due to an error or failure with the service.
    public static var internalServiceException: Self { .init(.internalServiceException) }
    /// The contact flow is not valid.
    public static var invalidContactFlowException: Self { .init(.invalidContactFlowException) }
    /// One or more of the specified parameters are not valid.
    public static var invalidParameterException: Self { .init(.invalidParameterException) }
    /// The request is not valid.
    public static var invalidRequestException: Self { .init(.invalidRequestException) }
    /// The allowed limit for the resource has been exceeded.
    public static var limitExceededException: Self { .init(.limitExceededException) }
    /// The contact is not permitted.
    public static var outboundContactNotPermittedException: Self { .init(.outboundContactNotPermittedException) }
    /// The specified resource was not found.
    public static var resourceNotFoundException: Self { .init(.resourceNotFoundException) }
    /// The throttling limit has been exceeded.
    public static var throttlingException: Self { .init(.throttlingException) }
    /// No user with the specified credentials was found in the Amazon Connect instance.
    public static var userNotFoundException: Self { .init(.userNotFoundException) }
}

extension ConnectErrorType: Equatable {
    public static func == (lhs: ConnectErrorType, rhs: ConnectErrorType) -> Bool {
        lhs.error == rhs.error
    }
}

extension ConnectErrorType: CustomStringConvertible {
    public var description: String {
        return "\(self.error.rawValue): \(self.message ?? "")"
    }
}