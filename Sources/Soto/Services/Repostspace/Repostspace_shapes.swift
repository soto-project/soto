//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2023 the Soto project authors
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

#if os(Linux) && compiler(<5.10)
// swift-corelibs-foundation hasn't been updated with Sendable conformances
@preconcurrency import Foundation
#else
import Foundation
#endif
@_spi(SotoInternal) import SotoCore

extension Repostspace {
    // MARK: Enums

    public enum ConfigurationStatus: String, CustomStringConvertible, Codable, Sendable, CodingKeyRepresentable {
        case configured = "CONFIGURED"
        case unconfigured = "UNCONFIGURED"
        public var description: String { return self.rawValue }
    }

    public enum TierLevel: String, CustomStringConvertible, Codable, Sendable, CodingKeyRepresentable {
        case basic = "BASIC"
        case standard = "STANDARD"
        public var description: String { return self.rawValue }
    }

    public enum VanityDomainStatus: String, CustomStringConvertible, Codable, Sendable, CodingKeyRepresentable {
        case approved = "APPROVED"
        case pending = "PENDING"
        case unapproved = "UNAPPROVED"
        public var description: String { return self.rawValue }
    }

    // MARK: Shapes

    public struct CreateSpaceInput: AWSEncodableShape {
        /// A description for the private re:Post. This is used only to help you identify this private re:Post.
        public let description: String?
        /// The name for the private re:Post. This must be unique in your account.
        public let name: String
        /// The IAM role that grants permissions to the private re:Post to convert unanswered questions into AWS support tickets.
        public let roleArn: String?
        /// The subdomain that you use to access your AWS re:Post Private private re:Post. All custom subdomains must be approved by AWS before use. In addition to your custom subdomain, all private re:Posts are issued an AWS generated subdomain for immediate use.
        public let subdomain: String
        /// The list of tags associated with the private re:Post.
        public let tags: [String: String]?
        /// The pricing tier for the private re:Post.
        public let tier: TierLevel
        /// The AWS KMS key ARN that’s used for the AWS KMS encryption. If you don't provide a key, your data is encrypted by default with a key that AWS owns and manages for you.
        public let userKMSKey: String?

        public init(description: String? = nil, name: String, roleArn: String? = nil, subdomain: String, tags: [String: String]? = nil, tier: TierLevel, userKMSKey: String? = nil) {
            self.description = description
            self.name = name
            self.roleArn = roleArn
            self.subdomain = subdomain
            self.tags = tags
            self.tier = tier
            self.userKMSKey = userKMSKey
        }

        public func validate(name: String) throws {
            try self.validate(self.description, name: "description", parent: name, max: 255)
            try self.validate(self.description, name: "description", parent: name, min: 1)
            try self.validate(self.name, name: "name", parent: name, max: 30)
            try self.validate(self.name, name: "name", parent: name, min: 1)
            try self.validate(self.roleArn, name: "roleArn", parent: name, max: 2048)
            try self.validate(self.roleArn, name: "roleArn", parent: name, min: 20)
            try self.validate(self.subdomain, name: "subdomain", parent: name, max: 63)
            try self.validate(self.subdomain, name: "subdomain", parent: name, min: 1)
            try self.tags?.forEach {
                try validate($0.key, name: "tags.key", parent: name, max: 128)
                try validate($0.key, name: "tags.key", parent: name, min: 1)
                try validate($0.key, name: "tags.key", parent: name, pattern: "^(?!aws:)[a-zA-Z+-=._:/]+$")
                try validate($0.value, name: "tags[\"\($0.key)\"]", parent: name, max: 256)
                try validate($0.value, name: "tags[\"\($0.key)\"]", parent: name, min: 1)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case description = "description"
            case name = "name"
            case roleArn = "roleArn"
            case subdomain = "subdomain"
            case tags = "tags"
            case tier = "tier"
            case userKMSKey = "userKMSKey"
        }
    }

    public struct CreateSpaceOutput: AWSDecodableShape {
        /// The unique ID of the private re:Post.
        public let spaceId: String

        public init(spaceId: String) {
            self.spaceId = spaceId
        }

        private enum CodingKeys: String, CodingKey {
            case spaceId = "spaceId"
        }
    }

    public struct DeleteSpaceInput: AWSEncodableShape {
        /// The unique ID of the private re:Post.
        public let spaceId: String

        public init(spaceId: String) {
            self.spaceId = spaceId
        }

        public func encode(to encoder: Encoder) throws {
            let request = encoder.userInfo[.awsRequest]! as! RequestEncodingContainer
            _ = encoder.container(keyedBy: CodingKeys.self)
            request.encodePath(self.spaceId, key: "spaceId")
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct DeregisterAdminInput: AWSEncodableShape {
        /// The ID of the admin to remove.
        public let adminId: String
        /// The ID of the private re:Post to remove the admin from.
        public let spaceId: String

        public init(adminId: String, spaceId: String) {
            self.adminId = adminId
            self.spaceId = spaceId
        }

        public func encode(to encoder: Encoder) throws {
            let request = encoder.userInfo[.awsRequest]! as! RequestEncodingContainer
            _ = encoder.container(keyedBy: CodingKeys.self)
            request.encodePath(self.adminId, key: "adminId")
            request.encodePath(self.spaceId, key: "spaceId")
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct GetSpaceInput: AWSEncodableShape {
        /// The ID of the private re:Post.
        public let spaceId: String

        public init(spaceId: String) {
            self.spaceId = spaceId
        }

        public func encode(to encoder: Encoder) throws {
            let request = encoder.userInfo[.awsRequest]! as! RequestEncodingContainer
            _ = encoder.container(keyedBy: CodingKeys.self)
            request.encodePath(self.spaceId, key: "spaceId")
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct GetSpaceOutput: AWSDecodableShape {
        /// The ARN of the private re:Post.
        public let arn: String
        /// The Identity Center identifier for the Application Instance.
        public let clientId: String
        /// The configuration status of the private re:Post.
        public let configurationStatus: ConfigurationStatus
        /// The content size of the private re:Post.
        public let contentSize: Int64?
        /// The date when the private re:Post was created.
        public let createDateTime: Date
        /// The IAM role that grants permissions to the private re:Post to convert unanswered questions into AWS support tickets.
        public let customerRoleArn: String?
        /// The date when the private re:Post was deleted.
        public let deleteDateTime: Date?
        /// The description of the private re:Post.
        public let description: String?
        /// The list of groups that are administrators of the private re:Post.
        public let groupAdmins: [String]?
        /// The name of the private re:Post.
        public let name: String
        /// The AWS generated subdomain of the private re:Post
        public let randomDomain: String
        /// The unique ID of the private re:Post.
        public let spaceId: String
        /// The creation or deletion status of the private re:Post.
        public let status: String
        /// The storage limit of the private re:Post.
        public let storageLimit: Int64
        /// The pricing tier of the private re:Post.
        public let tier: TierLevel
        /// The list of users that are administrators of the private re:Post.
        public let userAdmins: [String]?
        /// The number of users that have onboarded to the private re:Post.
        public let userCount: Int?
        /// The custom AWS KMS key ARN that’s used for the AWS KMS encryption.
        public let userKMSKey: String?
        /// The custom subdomain that you use to access your private re:Post. All custom subdomains must be approved by AWS before use.
        public let vanityDomain: String
        /// The approval status of the custom subdomain.
        public let vanityDomainStatus: VanityDomainStatus

        public init(arn: String, clientId: String, configurationStatus: ConfigurationStatus, contentSize: Int64? = nil, createDateTime: Date, customerRoleArn: String? = nil, deleteDateTime: Date? = nil, description: String? = nil, groupAdmins: [String]? = nil, name: String, randomDomain: String, spaceId: String, status: String, storageLimit: Int64, tier: TierLevel, userAdmins: [String]? = nil, userCount: Int? = nil, userKMSKey: String? = nil, vanityDomain: String, vanityDomainStatus: VanityDomainStatus) {
            self.arn = arn
            self.clientId = clientId
            self.configurationStatus = configurationStatus
            self.contentSize = contentSize
            self.createDateTime = createDateTime
            self.customerRoleArn = customerRoleArn
            self.deleteDateTime = deleteDateTime
            self.description = description
            self.groupAdmins = groupAdmins
            self.name = name
            self.randomDomain = randomDomain
            self.spaceId = spaceId
            self.status = status
            self.storageLimit = storageLimit
            self.tier = tier
            self.userAdmins = userAdmins
            self.userCount = userCount
            self.userKMSKey = userKMSKey
            self.vanityDomain = vanityDomain
            self.vanityDomainStatus = vanityDomainStatus
        }

        private enum CodingKeys: String, CodingKey {
            case arn = "arn"
            case clientId = "clientId"
            case configurationStatus = "configurationStatus"
            case contentSize = "contentSize"
            case createDateTime = "createDateTime"
            case customerRoleArn = "customerRoleArn"
            case deleteDateTime = "deleteDateTime"
            case description = "description"
            case groupAdmins = "groupAdmins"
            case name = "name"
            case randomDomain = "randomDomain"
            case spaceId = "spaceId"
            case status = "status"
            case storageLimit = "storageLimit"
            case tier = "tier"
            case userAdmins = "userAdmins"
            case userCount = "userCount"
            case userKMSKey = "userKMSKey"
            case vanityDomain = "vanityDomain"
            case vanityDomainStatus = "vanityDomainStatus"
        }
    }

    public struct ListSpacesInput: AWSEncodableShape {
        /// The maximum number of private re:Posts to include in the results.
        public let maxResults: Int?
        /// The token for the next set of private re:Posts to return. You receive this token from a previous ListSpaces operation.
        public let nextToken: String?

        public init(maxResults: Int? = nil, nextToken: String? = nil) {
            self.maxResults = maxResults
            self.nextToken = nextToken
        }

        public func encode(to encoder: Encoder) throws {
            let request = encoder.userInfo[.awsRequest]! as! RequestEncodingContainer
            _ = encoder.container(keyedBy: CodingKeys.self)
            request.encodeQuery(self.maxResults, key: "maxResults")
            request.encodeQuery(self.nextToken, key: "nextToken")
        }

        public func validate(name: String) throws {
            try self.validate(self.maxResults, name: "maxResults", parent: name, max: 100)
            try self.validate(self.maxResults, name: "maxResults", parent: name, min: 1)
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct ListSpacesOutput: AWSDecodableShape {
        /// The token that you use when you request the next set of private re:Posts.
        public let nextToken: String?
        /// An array of structures that contain some information about the private re:Posts in the account.
        public let spaces: [SpaceData]

        public init(nextToken: String? = nil, spaces: [SpaceData]) {
            self.nextToken = nextToken
            self.spaces = spaces
        }

        private enum CodingKeys: String, CodingKey {
            case nextToken = "nextToken"
            case spaces = "spaces"
        }
    }

    public struct ListTagsForResourceRequest: AWSEncodableShape {
        /// The ARN of the resource that the tags are associated with.
        public let resourceArn: String

        public init(resourceArn: String) {
            self.resourceArn = resourceArn
        }

        public func encode(to encoder: Encoder) throws {
            let request = encoder.userInfo[.awsRequest]! as! RequestEncodingContainer
            _ = encoder.container(keyedBy: CodingKeys.self)
            request.encodePath(self.resourceArn, key: "resourceArn")
        }

        public func validate(name: String) throws {
            try self.validate(self.resourceArn, name: "resourceArn", parent: name, max: 2048)
            try self.validate(self.resourceArn, name: "resourceArn", parent: name, min: 20)
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct ListTagsForResourceResponse: AWSDecodableShape {
        /// The list of tags that are associated with the resource.
        public let tags: [String: String]?

        public init(tags: [String: String]? = nil) {
            self.tags = tags
        }

        private enum CodingKeys: String, CodingKey {
            case tags = "tags"
        }
    }

    public struct RegisterAdminInput: AWSEncodableShape {
        /// The ID of the administrator.
        public let adminId: String
        /// The ID of the private re:Post.
        public let spaceId: String

        public init(adminId: String, spaceId: String) {
            self.adminId = adminId
            self.spaceId = spaceId
        }

        public func encode(to encoder: Encoder) throws {
            let request = encoder.userInfo[.awsRequest]! as! RequestEncodingContainer
            _ = encoder.container(keyedBy: CodingKeys.self)
            request.encodePath(self.adminId, key: "adminId")
            request.encodePath(self.spaceId, key: "spaceId")
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct SendInvitesInput: AWSEncodableShape {
        /// The array of identifiers for the users and groups.
        public let accessorIds: [String]
        /// The body of the invite.
        public let body: String
        /// The ID of the private re:Post.
        public let spaceId: String
        /// The title of the invite.
        public let title: String

        public init(accessorIds: [String], body: String, spaceId: String, title: String) {
            self.accessorIds = accessorIds
            self.body = body
            self.spaceId = spaceId
            self.title = title
        }

        public func encode(to encoder: Encoder) throws {
            let request = encoder.userInfo[.awsRequest]! as! RequestEncodingContainer
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.accessorIds, forKey: .accessorIds)
            try container.encode(self.body, forKey: .body)
            request.encodePath(self.spaceId, key: "spaceId")
            try container.encode(self.title, forKey: .title)
        }

        public func validate(name: String) throws {
            try self.validate(self.accessorIds, name: "accessorIds", parent: name, max: 1000)
            try self.validate(self.body, name: "body", parent: name, max: 600)
            try self.validate(self.body, name: "body", parent: name, min: 1)
            try self.validate(self.title, name: "title", parent: name, max: 200)
            try self.validate(self.title, name: "title", parent: name, min: 1)
        }

        private enum CodingKeys: String, CodingKey {
            case accessorIds = "accessorIds"
            case body = "body"
            case title = "title"
        }
    }

    public struct SpaceData: AWSDecodableShape {
        /// The ARN of the private re:Post.
        public let arn: String
        /// The configuration status of the private re:Post.
        public let configurationStatus: ConfigurationStatus
        /// The content size of the private re:Post.
        public let contentSize: Int64?
        /// The date when the private re:Post was created.
        public let createDateTime: Date
        /// The date when the private re:Post was deleted.
        public let deleteDateTime: Date?
        /// The description for the private re:Post. This is used only to help you identify this private re:Post.
        public let description: String?
        /// The name for the private re:Post.
        public let name: String
        /// The AWS generated subdomain of the private re:Post.
        public let randomDomain: String
        /// The unique ID of the private re:Post.
        public let spaceId: String
        /// The creation/deletion status of the private re:Post.
        public let status: String
        /// The storage limit of the private re:Post.
        public let storageLimit: Int64
        /// The pricing tier of the private re:Post.
        public let tier: TierLevel
        /// The number of onboarded users to the private re:Post.
        public let userCount: Int?
        /// The custom AWS KMS key ARN that’s used for the AWS KMS encryption.
        public let userKMSKey: String?
        /// This custom subdomain that you use to access your private re:Post. All custom subdomains must be approved by AWS before use.
        public let vanityDomain: String
        /// This approval status of the custom subdomain.
        public let vanityDomainStatus: VanityDomainStatus

        public init(arn: String, configurationStatus: ConfigurationStatus, contentSize: Int64? = nil, createDateTime: Date, deleteDateTime: Date? = nil, description: String? = nil, name: String, randomDomain: String, spaceId: String, status: String, storageLimit: Int64, tier: TierLevel, userCount: Int? = nil, userKMSKey: String? = nil, vanityDomain: String, vanityDomainStatus: VanityDomainStatus) {
            self.arn = arn
            self.configurationStatus = configurationStatus
            self.contentSize = contentSize
            self.createDateTime = createDateTime
            self.deleteDateTime = deleteDateTime
            self.description = description
            self.name = name
            self.randomDomain = randomDomain
            self.spaceId = spaceId
            self.status = status
            self.storageLimit = storageLimit
            self.tier = tier
            self.userCount = userCount
            self.userKMSKey = userKMSKey
            self.vanityDomain = vanityDomain
            self.vanityDomainStatus = vanityDomainStatus
        }

        private enum CodingKeys: String, CodingKey {
            case arn = "arn"
            case configurationStatus = "configurationStatus"
            case contentSize = "contentSize"
            case createDateTime = "createDateTime"
            case deleteDateTime = "deleteDateTime"
            case description = "description"
            case name = "name"
            case randomDomain = "randomDomain"
            case spaceId = "spaceId"
            case status = "status"
            case storageLimit = "storageLimit"
            case tier = "tier"
            case userCount = "userCount"
            case userKMSKey = "userKMSKey"
            case vanityDomain = "vanityDomain"
            case vanityDomainStatus = "vanityDomainStatus"
        }
    }

    public struct TagResourceRequest: AWSEncodableShape {
        /// The ARN of the resource that the tag is associated with.
        public let resourceArn: String
        /// The list of tag keys and values that must be associated with the resource. You can associate tag keys only, tags (key and values) only, or a combination of tag keys and tags.
        public let tags: [String: String]

        public init(resourceArn: String, tags: [String: String]) {
            self.resourceArn = resourceArn
            self.tags = tags
        }

        public func encode(to encoder: Encoder) throws {
            let request = encoder.userInfo[.awsRequest]! as! RequestEncodingContainer
            var container = encoder.container(keyedBy: CodingKeys.self)
            request.encodePath(self.resourceArn, key: "resourceArn")
            try container.encode(self.tags, forKey: .tags)
        }

        public func validate(name: String) throws {
            try self.validate(self.resourceArn, name: "resourceArn", parent: name, max: 2048)
            try self.validate(self.resourceArn, name: "resourceArn", parent: name, min: 20)
            try self.tags.forEach {
                try validate($0.key, name: "tags.key", parent: name, max: 128)
                try validate($0.key, name: "tags.key", parent: name, min: 1)
                try validate($0.key, name: "tags.key", parent: name, pattern: "^(?!aws:)[a-zA-Z+-=._:/]+$")
                try validate($0.value, name: "tags[\"\($0.key)\"]", parent: name, max: 256)
                try validate($0.value, name: "tags[\"\($0.key)\"]", parent: name, min: 1)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case tags = "tags"
        }
    }

    public struct TagResourceResponse: AWSDecodableShape {
        public init() {}
    }

    public struct UntagResourceRequest: AWSEncodableShape {
        /// The ARN of the resource.
        public let resourceArn: String
        /// The key values of the tag.
        public let tagKeys: [String]

        public init(resourceArn: String, tagKeys: [String]) {
            self.resourceArn = resourceArn
            self.tagKeys = tagKeys
        }

        public func encode(to encoder: Encoder) throws {
            let request = encoder.userInfo[.awsRequest]! as! RequestEncodingContainer
            _ = encoder.container(keyedBy: CodingKeys.self)
            request.encodePath(self.resourceArn, key: "resourceArn")
            request.encodeQuery(self.tagKeys, key: "tagKeys")
        }

        public func validate(name: String) throws {
            try self.validate(self.resourceArn, name: "resourceArn", parent: name, max: 2048)
            try self.validate(self.resourceArn, name: "resourceArn", parent: name, min: 20)
            try self.tagKeys.forEach {
                try validate($0, name: "tagKeys[]", parent: name, max: 128)
                try validate($0, name: "tagKeys[]", parent: name, min: 1)
                try validate($0, name: "tagKeys[]", parent: name, pattern: "^(?!aws:)[a-zA-Z+-=._:/]+$")
            }
            try self.validate(self.tagKeys, name: "tagKeys", parent: name, max: 50)
            try self.validate(self.tagKeys, name: "tagKeys", parent: name, min: 1)
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct UntagResourceResponse: AWSDecodableShape {
        public init() {}
    }

    public struct UpdateSpaceInput: AWSEncodableShape {
        /// A description for the private re:Post. This is used only to help you identify this private re:Post.
        public let description: String?
        /// The IAM role that grants permissions to the private re:Post to convert unanswered questions into AWS support tickets.
        public let roleArn: String?
        /// The unique ID of this private re:Post.
        public let spaceId: String
        /// The pricing tier of this private re:Post.
        public let tier: TierLevel?

        public init(description: String? = nil, roleArn: String? = nil, spaceId: String, tier: TierLevel? = nil) {
            self.description = description
            self.roleArn = roleArn
            self.spaceId = spaceId
            self.tier = tier
        }

        public func encode(to encoder: Encoder) throws {
            let request = encoder.userInfo[.awsRequest]! as! RequestEncodingContainer
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(self.description, forKey: .description)
            try container.encodeIfPresent(self.roleArn, forKey: .roleArn)
            request.encodePath(self.spaceId, key: "spaceId")
            try container.encodeIfPresent(self.tier, forKey: .tier)
        }

        public func validate(name: String) throws {
            try self.validate(self.description, name: "description", parent: name, max: 255)
            try self.validate(self.description, name: "description", parent: name, min: 1)
            try self.validate(self.roleArn, name: "roleArn", parent: name, max: 2048)
            try self.validate(self.roleArn, name: "roleArn", parent: name, min: 20)
        }

        private enum CodingKeys: String, CodingKey {
            case description = "description"
            case roleArn = "roleArn"
            case tier = "tier"
        }
    }
}

// MARK: - Errors

/// Error enum for Repostspace
public struct RepostspaceErrorType: AWSErrorType {
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

    /// initialize Repostspace
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

    /// User does not have sufficient access to perform this action.
    public static var accessDeniedException: Self { .init(.accessDeniedException) }
    /// Updating or deleting a resource can cause an inconsistent state.
    public static var conflictException: Self { .init(.conflictException) }
    /// Unexpected error during processing of request.
    public static var internalServerException: Self { .init(.internalServerException) }
    /// Request references a resource which does not exist.
    public static var resourceNotFoundException: Self { .init(.resourceNotFoundException) }
    /// Request would cause a service quota to be exceeded.
    public static var serviceQuotaExceededException: Self { .init(.serviceQuotaExceededException) }
    /// Request was denied due to request throttling.
    public static var throttlingException: Self { .init(.throttlingException) }
    /// The input fails to satisfy the constraints specified by an AWS service.
    public static var validationException: Self { .init(.validationException) }
}

extension RepostspaceErrorType: Equatable {
    public static func == (lhs: RepostspaceErrorType, rhs: RepostspaceErrorType) -> Bool {
        lhs.error == rhs.error
    }
}

extension RepostspaceErrorType: CustomStringConvertible {
    public var description: String {
        return "\(self.error.rawValue): \(self.message ?? "")"
    }
}