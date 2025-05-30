//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2024 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// THIS FILE IS AUTOMATICALLY GENERATED by https://github.com/soto-project/soto-codegenerator.
// DO NOT EDIT.

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
@_spi(SotoInternal) import SotoCore

extension SSMGuiConnect {
    // MARK: Enums

    // MARK: Shapes

    public struct ConnectionRecordingPreferences: AWSEncodableShape & AWSDecodableShape {
        /// The ARN of a KMS key that is used to encrypt data while it is being processed by the service. This key must exist in the same Amazon Web Services Region as the node you start an RDP connection to.
        public let kmsKeyArn: String
        /// Determines where recordings of RDP connections are stored.
        public let recordingDestinations: RecordingDestinations

        @inlinable
        public init(kmsKeyArn: String, recordingDestinations: RecordingDestinations) {
            self.kmsKeyArn = kmsKeyArn
            self.recordingDestinations = recordingDestinations
        }

        public func validate(name: String) throws {
            try self.recordingDestinations.validate(name: "\(name).recordingDestinations")
        }

        private enum CodingKeys: String, CodingKey {
            case kmsKeyArn = "KMSKeyArn"
            case recordingDestinations = "RecordingDestinations"
        }
    }

    public struct DeleteConnectionRecordingPreferencesRequest: AWSEncodableShape {
        /// User-provided idempotency token.
        public let clientToken: String?

        @inlinable
        public init(clientToken: String? = DeleteConnectionRecordingPreferencesRequest.idempotencyToken()) {
            self.clientToken = clientToken
        }

        public func validate(name: String) throws {
            try self.validate(self.clientToken, name: "clientToken", parent: name, max: 64)
            try self.validate(self.clientToken, name: "clientToken", parent: name, min: 1)
        }

        private enum CodingKeys: String, CodingKey {
            case clientToken = "ClientToken"
        }
    }

    public struct DeleteConnectionRecordingPreferencesResponse: AWSDecodableShape {
        /// Service-provided idempotency token.
        public let clientToken: String?

        @inlinable
        public init(clientToken: String? = nil) {
            self.clientToken = clientToken
        }

        private enum CodingKeys: String, CodingKey {
            case clientToken = "ClientToken"
        }
    }

    public struct GetConnectionRecordingPreferencesResponse: AWSDecodableShape {
        /// Service-provided idempotency token.
        public let clientToken: String?
        /// The set of preferences used for recording RDP connections in the requesting Amazon Web Services account and Amazon Web Services Region. This includes details such as which S3 bucket recordings are stored in.
        public let connectionRecordingPreferences: ConnectionRecordingPreferences?

        @inlinable
        public init(clientToken: String? = nil, connectionRecordingPreferences: ConnectionRecordingPreferences? = nil) {
            self.clientToken = clientToken
            self.connectionRecordingPreferences = connectionRecordingPreferences
        }

        private enum CodingKeys: String, CodingKey {
            case clientToken = "ClientToken"
            case connectionRecordingPreferences = "ConnectionRecordingPreferences"
        }
    }

    public struct RecordingDestinations: AWSEncodableShape & AWSDecodableShape {
        /// The S3 bucket where RDP connection recordings are stored.
        public let s3Buckets: [S3Bucket]

        @inlinable
        public init(s3Buckets: [S3Bucket]) {
            self.s3Buckets = s3Buckets
        }

        public func validate(name: String) throws {
            try self.s3Buckets.forEach {
                try $0.validate(name: "\(name).s3Buckets[]")
            }
            try self.validate(self.s3Buckets, name: "s3Buckets", parent: name, max: 1)
            try self.validate(self.s3Buckets, name: "s3Buckets", parent: name, min: 1)
        }

        private enum CodingKeys: String, CodingKey {
            case s3Buckets = "S3Buckets"
        }
    }

    public struct S3Bucket: AWSEncodableShape & AWSDecodableShape {
        /// The name of the S3 bucket where RDP connection recordings are stored.
        public let bucketName: String
        /// The Amazon Web Services account number that owns the S3 bucket.
        public let bucketOwner: String

        @inlinable
        public init(bucketName: String, bucketOwner: String) {
            self.bucketName = bucketName
            self.bucketOwner = bucketOwner
        }

        public func validate(name: String) throws {
            try self.validate(self.bucketName, name: "bucketName", parent: name, pattern: "(?=^.{3,63}$)(?!^(\\d+\\.)+\\d+$)(^(([a-z0-9]|[a-z0-9][a-z0-9\\-]*[a-z0-9])\\.)*([a-z0-9]|[a-z0-9][a-z0-9\\-]*[a-z0-9])$)")
            try self.validate(self.bucketOwner, name: "bucketOwner", parent: name, pattern: "^[0-9]{12}$")
        }

        private enum CodingKeys: String, CodingKey {
            case bucketName = "BucketName"
            case bucketOwner = "BucketOwner"
        }
    }

    public struct UpdateConnectionRecordingPreferencesRequest: AWSEncodableShape {
        /// User-provided idempotency token.
        public let clientToken: String?
        /// The set of preferences used for recording RDP connections in the requesting Amazon Web Services account and Amazon Web Services Region. This includes details such as which S3 bucket recordings are stored in.
        public let connectionRecordingPreferences: ConnectionRecordingPreferences

        @inlinable
        public init(clientToken: String? = UpdateConnectionRecordingPreferencesRequest.idempotencyToken(), connectionRecordingPreferences: ConnectionRecordingPreferences) {
            self.clientToken = clientToken
            self.connectionRecordingPreferences = connectionRecordingPreferences
        }

        public func validate(name: String) throws {
            try self.validate(self.clientToken, name: "clientToken", parent: name, max: 64)
            try self.validate(self.clientToken, name: "clientToken", parent: name, min: 1)
            try self.connectionRecordingPreferences.validate(name: "\(name).connectionRecordingPreferences")
        }

        private enum CodingKeys: String, CodingKey {
            case clientToken = "ClientToken"
            case connectionRecordingPreferences = "ConnectionRecordingPreferences"
        }
    }

    public struct UpdateConnectionRecordingPreferencesResponse: AWSDecodableShape {
        /// Service-provided idempotency token.
        public let clientToken: String?
        /// The set of preferences used for recording RDP connections in the requesting Amazon Web Services account and Amazon Web Services Region. This includes details such as which S3 bucket recordings are stored in.
        public let connectionRecordingPreferences: ConnectionRecordingPreferences?

        @inlinable
        public init(clientToken: String? = nil, connectionRecordingPreferences: ConnectionRecordingPreferences? = nil) {
            self.clientToken = clientToken
            self.connectionRecordingPreferences = connectionRecordingPreferences
        }

        private enum CodingKeys: String, CodingKey {
            case clientToken = "ClientToken"
            case connectionRecordingPreferences = "ConnectionRecordingPreferences"
        }
    }
}

// MARK: - Errors

/// Error enum for SSMGuiConnect
public struct SSMGuiConnectErrorType: AWSErrorType {
    enum Code: String {
        case accessDeniedException = "AccessDeniedException"
        case conflictException = "ConflictException"
        case internalServerException = "InternalServerException"
        case resourceNotFoundException = "ResourceNotFoundException"
        case serviceQuotaExceededException = "ServiceQuotaExceededException"
        case throttlingException = "ThrottlingException"
        case validationException = "ValidationException"
    }

    private let error: Code
    public let context: AWSErrorContext?

    /// initialize SSMGuiConnect
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

    /// You do not have sufficient access to perform this action.
    public static var accessDeniedException: Self { .init(.accessDeniedException) }
    /// An error occurred due to a conflict.
    public static var conflictException: Self { .init(.conflictException) }
    /// The request processing has failed because of an unknown error, exception or failure.
    public static var internalServerException: Self { .init(.internalServerException) }
    /// The resource could not be found.
    public static var resourceNotFoundException: Self { .init(.resourceNotFoundException) }
    /// Your request exceeds a service quota.
    public static var serviceQuotaExceededException: Self { .init(.serviceQuotaExceededException) }
    /// The request was denied due to request throttling.
    public static var throttlingException: Self { .init(.throttlingException) }
    /// The input fails to satisfy the constraints specified by an AWS service.
    public static var validationException: Self { .init(.validationException) }
}

extension SSMGuiConnectErrorType: Equatable {
    public static func == (lhs: SSMGuiConnectErrorType, rhs: SSMGuiConnectErrorType) -> Bool {
        lhs.error == rhs.error
    }
}

extension SSMGuiConnectErrorType: CustomStringConvertible {
    public var description: String {
        return "\(self.error.rawValue): \(self.message ?? "")"
    }
}
