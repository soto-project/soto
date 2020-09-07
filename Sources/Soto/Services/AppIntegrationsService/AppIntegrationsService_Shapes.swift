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

import Foundation
import SotoCore

extension AppIntegrationsService {
    // MARK: Enums

    // MARK: Shapes

    public struct CreateEventIntegrationRequest: AWSEncodableShape {
        /// A unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
        public let clientToken: String?
        /// The description of the event integration.
        public let description: String?
        /// The Eventbridge bus.
        public let eventBridgeBus: String
        /// The event filter.
        public let eventFilter: EventFilter
        /// The name of the event integration.
        public let name: String
        /// One or more tags.
        public let tags: [String: String]?

        public init(clientToken: String? = CreateEventIntegrationRequest.idempotencyToken(), description: String? = nil, eventBridgeBus: String, eventFilter: EventFilter, name: String, tags: [String: String]? = nil) {
            self.clientToken = clientToken
            self.description = description
            self.eventBridgeBus = eventBridgeBus
            self.eventFilter = eventFilter
            self.name = name
            self.tags = tags
        }

        public func validate(name: String) throws {
            try self.validate(self.clientToken, name: "clientToken", parent: name, max: 2048)
            try self.validate(self.clientToken, name: "clientToken", parent: name, min: 1)
            try self.validate(self.clientToken, name: "clientToken", parent: name, pattern: ".*")
            try self.validate(self.description, name: "description", parent: name, max: 1000)
            try self.validate(self.description, name: "description", parent: name, min: 1)
            try self.validate(self.description, name: "description", parent: name, pattern: ".*")
            try self.validate(self.eventBridgeBus, name: "eventBridgeBus", parent: name, max: 255)
            try self.validate(self.eventBridgeBus, name: "eventBridgeBus", parent: name, min: 1)
            try self.validate(self.eventBridgeBus, name: "eventBridgeBus", parent: name, pattern: "^[a-zA-Z0-9\\/\\._\\-]+$")
            try self.eventFilter.validate(name: "\(name).eventFilter")
            try self.validate(self.name, name: "name", parent: name, max: 255)
            try self.validate(self.name, name: "name", parent: name, min: 1)
            try self.validate(self.name, name: "name", parent: name, pattern: "^[a-zA-Z0-9\\/\\._\\-]+$")
            try self.tags?.forEach {
                try validate($0.key, name: "tags.key", parent: name, max: 128)
                try validate($0.key, name: "tags.key", parent: name, min: 1)
                try validate($0.key, name: "tags.key", parent: name, pattern: "^(?!aws:)[a-zA-Z+-=._:/]+$")
                try validate($0.value, name: "tags[\"\($0.key)\"]", parent: name, max: 256)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case clientToken = "ClientToken"
            case description = "Description"
            case eventBridgeBus = "EventBridgeBus"
            case eventFilter = "EventFilter"
            case name = "Name"
            case tags = "Tags"
        }
    }

    public struct CreateEventIntegrationResponse: AWSDecodableShape {
        /// The Amazon Resource Name (ARN) of the event integration.
        public let eventIntegrationArn: String?

        public init(eventIntegrationArn: String? = nil) {
            self.eventIntegrationArn = eventIntegrationArn
        }

        private enum CodingKeys: String, CodingKey {
            case eventIntegrationArn = "EventIntegrationArn"
        }
    }

    public struct DeleteEventIntegrationRequest: AWSEncodableShape {
        public static var _encoding = [
            AWSMemberEncoding(label: "name", location: .uri(locationName: "Name"))
        ]

        /// The name of the event integration.
        public let name: String

        public init(name: String) {
            self.name = name
        }

        public func validate(name: String) throws {
            try self.validate(self.name, name: "name", parent: name, max: 255)
            try self.validate(self.name, name: "name", parent: name, min: 1)
            try self.validate(self.name, name: "name", parent: name, pattern: "^[a-zA-Z0-9\\/\\._\\-]+$")
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct DeleteEventIntegrationResponse: AWSDecodableShape {
        public init() {}
    }

    public struct EventFilter: AWSEncodableShape & AWSDecodableShape {
        /// The source of the events.
        public let source: String

        public init(source: String) {
            self.source = source
        }

        public func validate(name: String) throws {
            try self.validate(self.source, name: "source", parent: name, max: 256)
            try self.validate(self.source, name: "source", parent: name, min: 1)
            try self.validate(self.source, name: "source", parent: name, pattern: "^aws\\.partner\\/.*$")
        }

        private enum CodingKeys: String, CodingKey {
            case source = "Source"
        }
    }

    public struct EventIntegration: AWSDecodableShape {
        /// The event integration description.
        public let description: String?
        /// The Amazon Eventbridge bus for the event integration.
        public let eventBridgeBus: String?
        /// The event integration filter.
        public let eventFilter: EventFilter?
        /// The Amazon Resource Name (ARN) of the event integration.
        public let eventIntegrationArn: String?
        /// The name of the event integration.
        public let name: String?
        /// The tags.
        public let tags: [String: String]?

        public init(description: String? = nil, eventBridgeBus: String? = nil, eventFilter: EventFilter? = nil, eventIntegrationArn: String? = nil, name: String? = nil, tags: [String: String]? = nil) {
            self.description = description
            self.eventBridgeBus = eventBridgeBus
            self.eventFilter = eventFilter
            self.eventIntegrationArn = eventIntegrationArn
            self.name = name
            self.tags = tags
        }

        private enum CodingKeys: String, CodingKey {
            case description = "Description"
            case eventBridgeBus = "EventBridgeBus"
            case eventFilter = "EventFilter"
            case eventIntegrationArn = "EventIntegrationArn"
            case name = "Name"
            case tags = "Tags"
        }
    }

    public struct EventIntegrationAssociation: AWSDecodableShape {
        /// The metadata associated with the client.
        public let clientAssociationMetadata: [String: String]?
        /// The identifier for the client that is associated with the event integration.
        public let clientId: String?
        /// The name of the Eventbridge rule.
        public let eventBridgeRuleName: String?
        /// The Amazon Resource Name (ARN) for the event integration association.
        public let eventIntegrationAssociationArn: String?
        /// The identifier for the event integration association.
        public let eventIntegrationAssociationId: String?
        /// The name of the event integration.
        public let eventIntegrationName: String?

        public init(clientAssociationMetadata: [String: String]? = nil, clientId: String? = nil, eventBridgeRuleName: String? = nil, eventIntegrationAssociationArn: String? = nil, eventIntegrationAssociationId: String? = nil, eventIntegrationName: String? = nil) {
            self.clientAssociationMetadata = clientAssociationMetadata
            self.clientId = clientId
            self.eventBridgeRuleName = eventBridgeRuleName
            self.eventIntegrationAssociationArn = eventIntegrationAssociationArn
            self.eventIntegrationAssociationId = eventIntegrationAssociationId
            self.eventIntegrationName = eventIntegrationName
        }

        private enum CodingKeys: String, CodingKey {
            case clientAssociationMetadata = "ClientAssociationMetadata"
            case clientId = "ClientId"
            case eventBridgeRuleName = "EventBridgeRuleName"
            case eventIntegrationAssociationArn = "EventIntegrationAssociationArn"
            case eventIntegrationAssociationId = "EventIntegrationAssociationId"
            case eventIntegrationName = "EventIntegrationName"
        }
    }

    public struct GetEventIntegrationRequest: AWSEncodableShape {
        public static var _encoding = [
            AWSMemberEncoding(label: "name", location: .uri(locationName: "Name"))
        ]

        /// The name of the event integration.
        public let name: String

        public init(name: String) {
            self.name = name
        }

        public func validate(name: String) throws {
            try self.validate(self.name, name: "name", parent: name, max: 255)
            try self.validate(self.name, name: "name", parent: name, min: 1)
            try self.validate(self.name, name: "name", parent: name, pattern: "^[a-zA-Z0-9\\/\\._\\-]+$")
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct GetEventIntegrationResponse: AWSDecodableShape {
        /// The description of the event integration.
        public let description: String?
        /// The Eventbridge bus.
        public let eventBridgeBus: String?
        /// The event filter.
        public let eventFilter: EventFilter?
        /// The Amazon Resource Name (ARN) for the event integration.
        public let eventIntegrationArn: String?
        /// The name of the event integration.
        public let name: String?
        /// One or more tags.
        public let tags: [String: String]?

        public init(description: String? = nil, eventBridgeBus: String? = nil, eventFilter: EventFilter? = nil, eventIntegrationArn: String? = nil, name: String? = nil, tags: [String: String]? = nil) {
            self.description = description
            self.eventBridgeBus = eventBridgeBus
            self.eventFilter = eventFilter
            self.eventIntegrationArn = eventIntegrationArn
            self.name = name
            self.tags = tags
        }

        private enum CodingKeys: String, CodingKey {
            case description = "Description"
            case eventBridgeBus = "EventBridgeBus"
            case eventFilter = "EventFilter"
            case eventIntegrationArn = "EventIntegrationArn"
            case name = "Name"
            case tags = "Tags"
        }
    }

    public struct ListEventIntegrationAssociationsRequest: AWSEncodableShape {
        public static var _encoding = [
            AWSMemberEncoding(label: "eventIntegrationName", location: .uri(locationName: "Name")),
            AWSMemberEncoding(label: "maxResults", location: .querystring(locationName: "maxResults")),
            AWSMemberEncoding(label: "nextToken", location: .querystring(locationName: "nextToken"))
        ]

        /// The name of the event integration.
        public let eventIntegrationName: String
        /// The maximum number of results to return per page.
        public let maxResults: Int?
        /// The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
        public let nextToken: String?

        public init(eventIntegrationName: String, maxResults: Int? = nil, nextToken: String? = nil) {
            self.eventIntegrationName = eventIntegrationName
            self.maxResults = maxResults
            self.nextToken = nextToken
        }

        public func validate(name: String) throws {
            try self.validate(self.eventIntegrationName, name: "eventIntegrationName", parent: name, max: 255)
            try self.validate(self.eventIntegrationName, name: "eventIntegrationName", parent: name, min: 1)
            try self.validate(self.eventIntegrationName, name: "eventIntegrationName", parent: name, pattern: "^[a-zA-Z0-9\\/\\._\\-]+$")
            try self.validate(self.maxResults, name: "maxResults", parent: name, max: 50)
            try self.validate(self.maxResults, name: "maxResults", parent: name, min: 1)
            try self.validate(self.nextToken, name: "nextToken", parent: name, max: 1000)
            try self.validate(self.nextToken, name: "nextToken", parent: name, min: 1)
            try self.validate(self.nextToken, name: "nextToken", parent: name, pattern: ".*")
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct ListEventIntegrationAssociationsResponse: AWSDecodableShape {
        /// The event integration associations.
        public let eventIntegrationAssociations: [EventIntegrationAssociation]?
        /// If there are additional results, this is the token for the next set of results.
        public let nextToken: String?

        public init(eventIntegrationAssociations: [EventIntegrationAssociation]? = nil, nextToken: String? = nil) {
            self.eventIntegrationAssociations = eventIntegrationAssociations
            self.nextToken = nextToken
        }

        private enum CodingKeys: String, CodingKey {
            case eventIntegrationAssociations = "EventIntegrationAssociations"
            case nextToken = "NextToken"
        }
    }

    public struct ListEventIntegrationsRequest: AWSEncodableShape {
        public static var _encoding = [
            AWSMemberEncoding(label: "maxResults", location: .querystring(locationName: "maxResults")),
            AWSMemberEncoding(label: "nextToken", location: .querystring(locationName: "nextToken"))
        ]

        /// The maximum number of results to return per page.
        public let maxResults: Int?
        /// The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
        public let nextToken: String?

        public init(maxResults: Int? = nil, nextToken: String? = nil) {
            self.maxResults = maxResults
            self.nextToken = nextToken
        }

        public func validate(name: String) throws {
            try self.validate(self.maxResults, name: "maxResults", parent: name, max: 50)
            try self.validate(self.maxResults, name: "maxResults", parent: name, min: 1)
            try self.validate(self.nextToken, name: "nextToken", parent: name, max: 1000)
            try self.validate(self.nextToken, name: "nextToken", parent: name, min: 1)
            try self.validate(self.nextToken, name: "nextToken", parent: name, pattern: ".*")
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct ListEventIntegrationsResponse: AWSDecodableShape {
        /// The event integrations.
        public let eventIntegrations: [EventIntegration]?
        /// If there are additional results, this is the token for the next set of results.
        public let nextToken: String?

        public init(eventIntegrations: [EventIntegration]? = nil, nextToken: String? = nil) {
            self.eventIntegrations = eventIntegrations
            self.nextToken = nextToken
        }

        private enum CodingKeys: String, CodingKey {
            case eventIntegrations = "EventIntegrations"
            case nextToken = "NextToken"
        }
    }

    public struct ListTagsForResourceRequest: AWSEncodableShape {
        public static var _encoding = [
            AWSMemberEncoding(label: "resourceArn", location: .uri(locationName: "resourceArn"))
        ]

        /// The Amazon Resource Name (ARN) of the resource.
        public let resourceArn: String

        public init(resourceArn: String) {
            self.resourceArn = resourceArn
        }

        public func validate(name: String) throws {
            try self.validate(self.resourceArn, name: "resourceArn", parent: name, max: 2048)
            try self.validate(self.resourceArn, name: "resourceArn", parent: name, min: 1)
            try self.validate(self.resourceArn, name: "resourceArn", parent: name, pattern: "^arn:aws:[A-Za-z0-9][A-Za-z0-9_/.-]{0,62}:[A-Za-z0-9_/.-]{0,63}:[A-Za-z0-9_/.-]{0,63}:[A-Za-z0-9][A-Za-z0-9:_/+=,@.-]{0,1023}$")
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct ListTagsForResourceResponse: AWSDecodableShape {
        /// Information about the tags.
        public let tags: [String: String]?

        public init(tags: [String: String]? = nil) {
            self.tags = tags
        }

        private enum CodingKeys: String, CodingKey {
            case tags
        }
    }

    public struct TagResourceRequest: AWSEncodableShape {
        public static var _encoding = [
            AWSMemberEncoding(label: "resourceArn", location: .uri(locationName: "resourceArn"))
        ]

        /// The Amazon Resource Name (ARN) of the resource.
        public let resourceArn: String
        /// One or more tags.
        public let tags: [String: String]

        public init(resourceArn: String, tags: [String: String]) {
            self.resourceArn = resourceArn
            self.tags = tags
        }

        public func validate(name: String) throws {
            try self.validate(self.resourceArn, name: "resourceArn", parent: name, max: 2048)
            try self.validate(self.resourceArn, name: "resourceArn", parent: name, min: 1)
            try self.validate(self.resourceArn, name: "resourceArn", parent: name, pattern: "^arn:aws:[A-Za-z0-9][A-Za-z0-9_/.-]{0,62}:[A-Za-z0-9_/.-]{0,63}:[A-Za-z0-9_/.-]{0,63}:[A-Za-z0-9][A-Za-z0-9:_/+=,@.-]{0,1023}$")
            try self.tags.forEach {
                try validate($0.key, name: "tags.key", parent: name, max: 128)
                try validate($0.key, name: "tags.key", parent: name, min: 1)
                try validate($0.key, name: "tags.key", parent: name, pattern: "^(?!aws:)[a-zA-Z+-=._:/]+$")
                try validate($0.value, name: "tags[\"\($0.key)\"]", parent: name, max: 256)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case tags
        }
    }

    public struct TagResourceResponse: AWSDecodableShape {
        public init() {}
    }

    public struct UntagResourceRequest: AWSEncodableShape {
        public static var _encoding = [
            AWSMemberEncoding(label: "resourceArn", location: .uri(locationName: "resourceArn")),
            AWSMemberEncoding(label: "tagKeys", location: .querystring(locationName: "tagKeys"))
        ]

        /// The Amazon Resource Name (ARN) of the resource.
        public let resourceArn: String
        /// The tag keys.
        public let tagKeys: [String]

        public init(resourceArn: String, tagKeys: [String]) {
            self.resourceArn = resourceArn
            self.tagKeys = tagKeys
        }

        public func validate(name: String) throws {
            try self.validate(self.resourceArn, name: "resourceArn", parent: name, max: 2048)
            try self.validate(self.resourceArn, name: "resourceArn", parent: name, min: 1)
            try self.validate(self.resourceArn, name: "resourceArn", parent: name, pattern: "^arn:aws:[A-Za-z0-9][A-Za-z0-9_/.-]{0,62}:[A-Za-z0-9_/.-]{0,63}:[A-Za-z0-9_/.-]{0,63}:[A-Za-z0-9][A-Za-z0-9:_/+=,@.-]{0,1023}$")
            try self.tagKeys.forEach {
                try validate($0, name: "tagKeys[]", parent: name, max: 128)
                try validate($0, name: "tagKeys[]", parent: name, min: 1)
                try validate($0, name: "tagKeys[]", parent: name, pattern: "^(?!aws:)[a-zA-Z+-=._:/]+$")
            }
            try self.validate(self.tagKeys, name: "tagKeys", parent: name, max: 200)
            try self.validate(self.tagKeys, name: "tagKeys", parent: name, min: 1)
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct UntagResourceResponse: AWSDecodableShape {
        public init() {}
    }

    public struct UpdateEventIntegrationRequest: AWSEncodableShape {
        public static var _encoding = [
            AWSMemberEncoding(label: "name", location: .uri(locationName: "Name"))
        ]

        /// The description of the event inegration.
        public let description: String?
        /// The name of the event integration.
        public let name: String

        public init(description: String? = nil, name: String) {
            self.description = description
            self.name = name
        }

        public func validate(name: String) throws {
            try self.validate(self.description, name: "description", parent: name, max: 1000)
            try self.validate(self.description, name: "description", parent: name, min: 1)
            try self.validate(self.description, name: "description", parent: name, pattern: ".*")
            try self.validate(self.name, name: "name", parent: name, max: 255)
            try self.validate(self.name, name: "name", parent: name, min: 1)
            try self.validate(self.name, name: "name", parent: name, pattern: "^[a-zA-Z0-9\\/\\._\\-]+$")
        }

        private enum CodingKeys: String, CodingKey {
            case description = "Description"
        }
    }

    public struct UpdateEventIntegrationResponse: AWSDecodableShape {
        public init() {}
    }
}