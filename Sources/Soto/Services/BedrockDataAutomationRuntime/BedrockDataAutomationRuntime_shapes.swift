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

extension BedrockDataAutomationRuntime {
    // MARK: Enums

    public enum AutomationJobStatus: String, CustomStringConvertible, Codable, Sendable, CodingKeyRepresentable {
        case clientError = "ClientError"
        case created = "Created"
        case inProgress = "InProgress"
        case serviceError = "ServiceError"
        case success = "Success"
        public var description: String { return self.rawValue }
    }

    public enum BlueprintStage: String, CustomStringConvertible, Codable, Sendable, CodingKeyRepresentable {
        case development = "DEVELOPMENT"
        case live = "LIVE"
        public var description: String { return self.rawValue }
    }

    public enum DataAutomationStage: String, CustomStringConvertible, Codable, Sendable, CodingKeyRepresentable {
        case development = "DEVELOPMENT"
        case live = "LIVE"
        public var description: String { return self.rawValue }
    }

    // MARK: Shapes

    public struct AssetProcessingConfiguration: AWSEncodableShape {
        /// Video asset processing configuration
        public let video: VideoAssetProcessingConfiguration?

        @inlinable
        public init(video: VideoAssetProcessingConfiguration? = nil) {
            self.video = video
        }

        private enum CodingKeys: String, CodingKey {
            case video = "video"
        }
    }

    public struct Blueprint: AWSEncodableShape {
        /// Arn of blueprint.
        public let blueprintArn: String
        /// Stage of blueprint.
        public let stage: BlueprintStage?
        /// Version of blueprint.
        public let version: String?

        @inlinable
        public init(blueprintArn: String, stage: BlueprintStage? = nil, version: String? = nil) {
            self.blueprintArn = blueprintArn
            self.stage = stage
            self.version = version
        }

        public func validate(name: String) throws {
            try self.validate(self.blueprintArn, name: "blueprintArn", parent: name, max: 128)
            try self.validate(self.blueprintArn, name: "blueprintArn", parent: name, pattern: "^arn:aws(|-cn|-us-gov):bedrock:[a-zA-Z0-9-]*:(aws|[0-9]{12}):blueprint/(bedrock-data-insights-public-[a-zA-Z0-9-_]{1,30}|bedrock-data-automation-public-[a-zA-Z0-9-_]{1,30}|[a-zA-Z0-9-]{12,36})$")
            try self.validate(self.version, name: "version", parent: name, max: 128)
            try self.validate(self.version, name: "version", parent: name, min: 1)
            try self.validate(self.version, name: "version", parent: name, pattern: "^[0-9]*$")
        }

        private enum CodingKeys: String, CodingKey {
            case blueprintArn = "blueprintArn"
            case stage = "stage"
            case version = "version"
        }
    }

    public struct DataAutomationConfiguration: AWSEncodableShape {
        /// Data automation project arn.
        public let dataAutomationProjectArn: String
        /// Data automation stage.
        public let stage: DataAutomationStage?

        @inlinable
        public init(dataAutomationProjectArn: String, stage: DataAutomationStage? = nil) {
            self.dataAutomationProjectArn = dataAutomationProjectArn
            self.stage = stage
        }

        public func validate(name: String) throws {
            try self.validate(self.dataAutomationProjectArn, name: "dataAutomationProjectArn", parent: name, max: 128)
            try self.validate(self.dataAutomationProjectArn, name: "dataAutomationProjectArn", parent: name, min: 1)
            try self.validate(self.dataAutomationProjectArn, name: "dataAutomationProjectArn", parent: name, pattern: "^arn:aws(|-cn|-us-gov):bedrock:[a-zA-Z0-9-]*:(aws|[0-9]{12}):data-automation-project/[a-zA-Z0-9-_]+$")
        }

        private enum CodingKeys: String, CodingKey {
            case dataAutomationProjectArn = "dataAutomationProjectArn"
            case stage = "stage"
        }
    }

    public struct EncryptionConfiguration: AWSEncodableShape {
        /// KMS encryption context.
        public let kmsEncryptionContext: [String: String]?
        /// Customer KMS key used for encryption
        public let kmsKeyId: String

        @inlinable
        public init(kmsEncryptionContext: [String: String]? = nil, kmsKeyId: String) {
            self.kmsEncryptionContext = kmsEncryptionContext
            self.kmsKeyId = kmsKeyId
        }

        public func validate(name: String) throws {
            try self.kmsEncryptionContext?.forEach {
                try validate($0.key, name: "kmsEncryptionContext.key", parent: name, max: 2000)
                try validate($0.key, name: "kmsEncryptionContext.key", parent: name, min: 1)
                try validate($0.key, name: "kmsEncryptionContext.key", parent: name, pattern: "^.*\\S.*$")
                try validate($0.value, name: "kmsEncryptionContext[\"\($0.key)\"]", parent: name, max: 2000)
                try validate($0.value, name: "kmsEncryptionContext[\"\($0.key)\"]", parent: name, min: 1)
                try validate($0.value, name: "kmsEncryptionContext[\"\($0.key)\"]", parent: name, pattern: "^.*\\S.*$")
            }
            try self.validate(self.kmsEncryptionContext, name: "kmsEncryptionContext", parent: name, max: 10)
            try self.validate(self.kmsEncryptionContext, name: "kmsEncryptionContext", parent: name, min: 1)
            try self.validate(self.kmsKeyId, name: "kmsKeyId", parent: name, max: 2048)
            try self.validate(self.kmsKeyId, name: "kmsKeyId", parent: name, min: 1)
            try self.validate(self.kmsKeyId, name: "kmsKeyId", parent: name, pattern: "^[A-Za-z0-9][A-Za-z0-9:_/+=,@.-]+$")
        }

        private enum CodingKeys: String, CodingKey {
            case kmsEncryptionContext = "kmsEncryptionContext"
            case kmsKeyId = "kmsKeyId"
        }
    }

    public struct EventBridgeConfiguration: AWSEncodableShape {
        /// Event bridge flag.
        public let eventBridgeEnabled: Bool

        @inlinable
        public init(eventBridgeEnabled: Bool) {
            self.eventBridgeEnabled = eventBridgeEnabled
        }

        private enum CodingKeys: String, CodingKey {
            case eventBridgeEnabled = "eventBridgeEnabled"
        }
    }

    public struct GetDataAutomationStatusRequest: AWSEncodableShape {
        /// Invocation arn.
        public let invocationArn: String

        @inlinable
        public init(invocationArn: String) {
            self.invocationArn = invocationArn
        }

        public func encode(to encoder: Encoder) throws {
            let request = encoder.userInfo[.awsRequest]! as! RequestEncodingContainer
            _ = encoder.container(keyedBy: CodingKeys.self)
            request.encodePath(self.invocationArn, key: "invocationArn")
        }

        public func validate(name: String) throws {
            try self.validate(self.invocationArn, name: "invocationArn", parent: name, max: 128)
            try self.validate(self.invocationArn, name: "invocationArn", parent: name, min: 1)
            try self.validate(self.invocationArn, name: "invocationArn", parent: name, pattern: "^arn:aws(|-cn|-us-gov):bedrock:[a-zA-Z0-9-]*:[0-9]{12}:(insights-invocation|data-automation-invocation)/[a-zA-Z0-9-_]+$")
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct GetDataAutomationStatusResponse: AWSDecodableShape {
        /// Error Message.
        public let errorMessage: String?
        /// Error Type.
        public let errorType: String?
        /// Output configuration.
        public let outputConfiguration: OutputConfiguration?
        /// Job Status.
        public let status: AutomationJobStatus?

        @inlinable
        public init(errorMessage: String? = nil, errorType: String? = nil, outputConfiguration: OutputConfiguration? = nil, status: AutomationJobStatus? = nil) {
            self.errorMessage = errorMessage
            self.errorType = errorType
            self.outputConfiguration = outputConfiguration
            self.status = status
        }

        private enum CodingKeys: String, CodingKey {
            case errorMessage = "errorMessage"
            case errorType = "errorType"
            case outputConfiguration = "outputConfiguration"
            case status = "status"
        }
    }

    public struct InputConfiguration: AWSEncodableShape {
        /// Asset processing configuration
        public let assetProcessingConfiguration: AssetProcessingConfiguration?
        /// S3 uri.
        public let s3Uri: String

        @inlinable
        public init(assetProcessingConfiguration: AssetProcessingConfiguration? = nil, s3Uri: String) {
            self.assetProcessingConfiguration = assetProcessingConfiguration
            self.s3Uri = s3Uri
        }

        public func validate(name: String) throws {
            try self.validate(self.s3Uri, name: "s3Uri", parent: name, max: 1024)
            try self.validate(self.s3Uri, name: "s3Uri", parent: name, min: 1)
            try self.validate(self.s3Uri, name: "s3Uri", parent: name, pattern: "^s3://[a-z0-9][\\.\\-a-z0-9]{1,61}[a-z0-9](/[^\\x00-\\x1F\\x7F\\{^}%`\\]\">\\[~<#|]*)?$")
        }

        private enum CodingKeys: String, CodingKey {
            case assetProcessingConfiguration = "assetProcessingConfiguration"
            case s3Uri = "s3Uri"
        }
    }

    public struct InvokeDataAutomationAsyncRequest: AWSEncodableShape {
        /// Blueprint list.
        public let blueprints: [Blueprint]?
        /// Idempotency token.
        public let clientToken: String?
        /// Data automation configuration.
        public let dataAutomationConfiguration: DataAutomationConfiguration?
        /// Data automation profile ARN
        public let dataAutomationProfileArn: String
        /// Encryption configuration.
        public let encryptionConfiguration: EncryptionConfiguration?
        /// Input configuration.
        public let inputConfiguration: InputConfiguration
        /// Notification configuration.
        public let notificationConfiguration: NotificationConfiguration?
        /// Output configuration.
        public let outputConfiguration: OutputConfiguration
        /// List of tags.
        public let tags: [Tag]?

        @inlinable
        public init(blueprints: [Blueprint]? = nil, clientToken: String? = InvokeDataAutomationAsyncRequest.idempotencyToken(), dataAutomationConfiguration: DataAutomationConfiguration? = nil, dataAutomationProfileArn: String, encryptionConfiguration: EncryptionConfiguration? = nil, inputConfiguration: InputConfiguration, notificationConfiguration: NotificationConfiguration? = nil, outputConfiguration: OutputConfiguration, tags: [Tag]? = nil) {
            self.blueprints = blueprints
            self.clientToken = clientToken
            self.dataAutomationConfiguration = dataAutomationConfiguration
            self.dataAutomationProfileArn = dataAutomationProfileArn
            self.encryptionConfiguration = encryptionConfiguration
            self.inputConfiguration = inputConfiguration
            self.notificationConfiguration = notificationConfiguration
            self.outputConfiguration = outputConfiguration
            self.tags = tags
        }

        public func validate(name: String) throws {
            try self.blueprints?.forEach {
                try $0.validate(name: "\(name).blueprints[]")
            }
            try self.validate(self.blueprints, name: "blueprints", parent: name, max: 40)
            try self.validate(self.blueprints, name: "blueprints", parent: name, min: 1)
            try self.validate(self.clientToken, name: "clientToken", parent: name, max: 256)
            try self.validate(self.clientToken, name: "clientToken", parent: name, min: 1)
            try self.validate(self.clientToken, name: "clientToken", parent: name, pattern: "^[a-zA-Z0-9](-*[a-zA-Z0-9])*$")
            try self.dataAutomationConfiguration?.validate(name: "\(name).dataAutomationConfiguration")
            try self.validate(self.dataAutomationProfileArn, name: "dataAutomationProfileArn", parent: name, max: 128)
            try self.validate(self.dataAutomationProfileArn, name: "dataAutomationProfileArn", parent: name, min: 1)
            try self.validate(self.dataAutomationProfileArn, name: "dataAutomationProfileArn", parent: name, pattern: "^arn:aws(|-cn|-us-gov):bedrock:[a-zA-Z0-9-]*:(aws|[0-9]{12}):data-automation-profile/[a-zA-Z0-9-_.]+$")
            try self.encryptionConfiguration?.validate(name: "\(name).encryptionConfiguration")
            try self.inputConfiguration.validate(name: "\(name).inputConfiguration")
            try self.outputConfiguration.validate(name: "\(name).outputConfiguration")
            try self.tags?.forEach {
                try $0.validate(name: "\(name).tags[]")
            }
            try self.validate(self.tags, name: "tags", parent: name, max: 200)
        }

        private enum CodingKeys: String, CodingKey {
            case blueprints = "blueprints"
            case clientToken = "clientToken"
            case dataAutomationConfiguration = "dataAutomationConfiguration"
            case dataAutomationProfileArn = "dataAutomationProfileArn"
            case encryptionConfiguration = "encryptionConfiguration"
            case inputConfiguration = "inputConfiguration"
            case notificationConfiguration = "notificationConfiguration"
            case outputConfiguration = "outputConfiguration"
            case tags = "tags"
        }
    }

    public struct InvokeDataAutomationAsyncResponse: AWSDecodableShape {
        /// ARN of the automation job
        public let invocationArn: String

        @inlinable
        public init(invocationArn: String) {
            self.invocationArn = invocationArn
        }

        private enum CodingKeys: String, CodingKey {
            case invocationArn = "invocationArn"
        }
    }

    public struct ListTagsForResourceRequest: AWSEncodableShape {
        public let resourceARN: String

        @inlinable
        public init(resourceARN: String) {
            self.resourceARN = resourceARN
        }

        public func validate(name: String) throws {
            try self.validate(self.resourceARN, name: "resourceARN", parent: name, max: 1011)
            try self.validate(self.resourceARN, name: "resourceARN", parent: name, min: 20)
            try self.validate(self.resourceARN, name: "resourceARN", parent: name, pattern: "^arn:aws(|-cn|-us-gov):bedrock:[a-zA-Z0-9-]*:[0-9]{12}:data-automation-invocation/[a-zA-Z0-9-_]+$")
        }

        private enum CodingKeys: String, CodingKey {
            case resourceARN = "resourceARN"
        }
    }

    public struct ListTagsForResourceResponse: AWSDecodableShape {
        public let tags: [Tag]?

        @inlinable
        public init(tags: [Tag]? = nil) {
            self.tags = tags
        }

        private enum CodingKeys: String, CodingKey {
            case tags = "tags"
        }
    }

    public struct NotificationConfiguration: AWSEncodableShape {
        /// Event bridge configuration.
        public let eventBridgeConfiguration: EventBridgeConfiguration

        @inlinable
        public init(eventBridgeConfiguration: EventBridgeConfiguration) {
            self.eventBridgeConfiguration = eventBridgeConfiguration
        }

        private enum CodingKeys: String, CodingKey {
            case eventBridgeConfiguration = "eventBridgeConfiguration"
        }
    }

    public struct OutputConfiguration: AWSEncodableShape & AWSDecodableShape {
        /// S3 uri.
        public let s3Uri: String

        @inlinable
        public init(s3Uri: String) {
            self.s3Uri = s3Uri
        }

        public func validate(name: String) throws {
            try self.validate(self.s3Uri, name: "s3Uri", parent: name, max: 1024)
            try self.validate(self.s3Uri, name: "s3Uri", parent: name, min: 1)
            try self.validate(self.s3Uri, name: "s3Uri", parent: name, pattern: "^s3://[a-z0-9][\\.\\-a-z0-9]{1,61}[a-z0-9](/[^\\x00-\\x1F\\x7F\\{^}%`\\]\">\\[~<#|]*)?$")
        }

        private enum CodingKeys: String, CodingKey {
            case s3Uri = "s3Uri"
        }
    }

    public struct Tag: AWSEncodableShape & AWSDecodableShape {
        public let key: String
        public let value: String

        @inlinable
        public init(key: String, value: String) {
            self.key = key
            self.value = value
        }

        public func validate(name: String) throws {
            try self.validate(self.key, name: "key", parent: name, max: 128)
            try self.validate(self.key, name: "key", parent: name, min: 1)
            try self.validate(self.key, name: "key", parent: name, pattern: "^(?!aws:)[\\p{L}\\p{Z}\\p{N}_.:/=+\\-@]*$")
            try self.validate(self.value, name: "value", parent: name, max: 256)
            try self.validate(self.value, name: "value", parent: name, pattern: "^([\\p{L}\\p{Z}\\p{N}_.:/=+\\-@]*)$")
        }

        private enum CodingKeys: String, CodingKey {
            case key = "key"
            case value = "value"
        }
    }

    public struct TagResourceRequest: AWSEncodableShape {
        public let resourceARN: String
        public let tags: [Tag]

        @inlinable
        public init(resourceARN: String, tags: [Tag]) {
            self.resourceARN = resourceARN
            self.tags = tags
        }

        public func validate(name: String) throws {
            try self.validate(self.resourceARN, name: "resourceARN", parent: name, max: 1011)
            try self.validate(self.resourceARN, name: "resourceARN", parent: name, min: 20)
            try self.validate(self.resourceARN, name: "resourceARN", parent: name, pattern: "^arn:aws(|-cn|-us-gov):bedrock:[a-zA-Z0-9-]*:[0-9]{12}:data-automation-invocation/[a-zA-Z0-9-_]+$")
            try self.tags.forEach {
                try $0.validate(name: "\(name).tags[]")
            }
            try self.validate(self.tags, name: "tags", parent: name, max: 200)
        }

        private enum CodingKeys: String, CodingKey {
            case resourceARN = "resourceARN"
            case tags = "tags"
        }
    }

    public struct TagResourceResponse: AWSDecodableShape {
        public init() {}
    }

    public struct TimestampSegment: AWSEncodableShape {
        /// End timestamp in milliseconds
        public let endTimeMillis: Int64
        /// Start timestamp in milliseconds
        public let startTimeMillis: Int64

        @inlinable
        public init(endTimeMillis: Int64, startTimeMillis: Int64) {
            self.endTimeMillis = endTimeMillis
            self.startTimeMillis = startTimeMillis
        }

        private enum CodingKeys: String, CodingKey {
            case endTimeMillis = "endTimeMillis"
            case startTimeMillis = "startTimeMillis"
        }
    }

    public struct UntagResourceRequest: AWSEncodableShape {
        public let resourceARN: String
        public let tagKeys: [String]

        @inlinable
        public init(resourceARN: String, tagKeys: [String]) {
            self.resourceARN = resourceARN
            self.tagKeys = tagKeys
        }

        public func validate(name: String) throws {
            try self.validate(self.resourceARN, name: "resourceARN", parent: name, max: 1011)
            try self.validate(self.resourceARN, name: "resourceARN", parent: name, min: 20)
            try self.validate(self.resourceARN, name: "resourceARN", parent: name, pattern: "^arn:aws(|-cn|-us-gov):bedrock:[a-zA-Z0-9-]*:[0-9]{12}:data-automation-invocation/[a-zA-Z0-9-_]+$")
            try self.tagKeys.forEach {
                try validate($0, name: "tagKeys[]", parent: name, max: 128)
                try validate($0, name: "tagKeys[]", parent: name, min: 1)
                try validate($0, name: "tagKeys[]", parent: name, pattern: "^(?!aws:)[\\p{L}\\p{Z}\\p{N}_.:/=+\\-@]*$")
            }
            try self.validate(self.tagKeys, name: "tagKeys", parent: name, max: 200)
        }

        private enum CodingKeys: String, CodingKey {
            case resourceARN = "resourceARN"
            case tagKeys = "tagKeys"
        }
    }

    public struct UntagResourceResponse: AWSDecodableShape {
        public init() {}
    }

    public struct VideoAssetProcessingConfiguration: AWSEncodableShape {
        /// Delimits the segment of the input that will be processed
        public let segmentConfiguration: VideoSegmentConfiguration?

        @inlinable
        public init(segmentConfiguration: VideoSegmentConfiguration? = nil) {
            self.segmentConfiguration = segmentConfiguration
        }

        private enum CodingKeys: String, CodingKey {
            case segmentConfiguration = "segmentConfiguration"
        }
    }

    public struct VideoSegmentConfiguration: AWSEncodableShape {
        /// Timestamp segment
        public let timestampSegment: TimestampSegment?

        @inlinable
        public init(timestampSegment: TimestampSegment? = nil) {
            self.timestampSegment = timestampSegment
        }

        private enum CodingKeys: String, CodingKey {
            case timestampSegment = "timestampSegment"
        }
    }
}

// MARK: - Errors

/// Error enum for BedrockDataAutomationRuntime
public struct BedrockDataAutomationRuntimeErrorType: AWSErrorType {
    enum Code: String {
        case accessDeniedException = "AccessDeniedException"
        case internalServerException = "InternalServerException"
        case resourceNotFoundException = "ResourceNotFoundException"
        case serviceQuotaExceededException = "ServiceQuotaExceededException"
        case throttlingException = "ThrottlingException"
        case validationException = "ValidationException"
    }

    private let error: Code
    public let context: AWSErrorContext?

    /// initialize BedrockDataAutomationRuntime
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

    /// This exception will be thrown when customer does not have access to API.
    public static var accessDeniedException: Self { .init(.accessDeniedException) }
    /// This exception is for any internal un-expected service errors.
    public static var internalServerException: Self { .init(.internalServerException) }
    /// This exception will be thrown when resource provided from customer not found.
    public static var resourceNotFoundException: Self { .init(.resourceNotFoundException) }
    /// This exception will be thrown when service quota is exceeded.
    public static var serviceQuotaExceededException: Self { .init(.serviceQuotaExceededException) }
    /// This exception will be thrown when customer reached API TPS limit.
    public static var throttlingException: Self { .init(.throttlingException) }
    /// This exception will be thrown when customer provided invalid parameters.
    public static var validationException: Self { .init(.validationException) }
}

extension BedrockDataAutomationRuntimeErrorType: Equatable {
    public static func == (lhs: BedrockDataAutomationRuntimeErrorType, rhs: BedrockDataAutomationRuntimeErrorType) -> Bool {
        lhs.error == rhs.error
    }
}

extension BedrockDataAutomationRuntimeErrorType: CustomStringConvertible {
    public var description: String {
        return "\(self.error.rawValue): \(self.message ?? "")"
    }
}
