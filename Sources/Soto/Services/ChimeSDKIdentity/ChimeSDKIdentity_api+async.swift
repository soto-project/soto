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

import SotoCore

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension ChimeSDKIdentity {
    // MARK: Async API Calls

    /// Creates an Amazon Chime SDK messaging AppInstance under an AWS account. Only SDK messaging customers use this API. CreateAppInstance supports idempotency behavior as described in the AWS API Standard. identity
    public func createAppInstance(_ input: CreateAppInstanceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CreateAppInstanceResponse {
        return try await self.client.execute(operation: "CreateAppInstance", path: "/app-instances", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Promotes an AppInstanceUser or AppInstanceBot to an  AppInstanceAdmin. The promoted entity can perform the following actions.     ChannelModerator actions across all channels in the AppInstance.    DeleteChannelMessage actions.   Only an AppInstanceUser and AppInstanceBot can be promoted to an AppInstanceAdmin role.
    public func createAppInstanceAdmin(_ input: CreateAppInstanceAdminRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CreateAppInstanceAdminResponse {
        return try await self.client.execute(operation: "CreateAppInstanceAdmin", path: "/app-instances/{AppInstanceArn}/admins", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Creates a bot under an Amazon Chime AppInstance. The request consists of a  unique Configuration and Name for that bot.
    public func createAppInstanceBot(_ input: CreateAppInstanceBotRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CreateAppInstanceBotResponse {
        return try await self.client.execute(operation: "CreateAppInstanceBot", path: "/app-instance-bots", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Creates a user under an Amazon Chime AppInstance. The request consists of a unique appInstanceUserId and Name for that user.
    public func createAppInstanceUser(_ input: CreateAppInstanceUserRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CreateAppInstanceUserResponse {
        return try await self.client.execute(operation: "CreateAppInstanceUser", path: "/app-instance-users", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Deletes an AppInstance and all associated data asynchronously.
    public func deleteAppInstance(_ input: DeleteAppInstanceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "DeleteAppInstance", path: "/app-instances/{AppInstanceArn}", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Demotes an AppInstanceAdmin to an AppInstanceUser or  AppInstanceBot. This action does not delete the user.
    public func deleteAppInstanceAdmin(_ input: DeleteAppInstanceAdminRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "DeleteAppInstanceAdmin", path: "/app-instances/{AppInstanceArn}/admins/{AppInstanceAdminArn}", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Deletes an AppInstanceBot.
    public func deleteAppInstanceBot(_ input: DeleteAppInstanceBotRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "DeleteAppInstanceBot", path: "/app-instance-bots/{AppInstanceBotArn}", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Deletes an AppInstanceUser.
    public func deleteAppInstanceUser(_ input: DeleteAppInstanceUserRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "DeleteAppInstanceUser", path: "/app-instance-users/{AppInstanceUserArn}", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Deregisters an AppInstanceUserEndpoint.
    public func deregisterAppInstanceUserEndpoint(_ input: DeregisterAppInstanceUserEndpointRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "DeregisterAppInstanceUserEndpoint", path: "/app-instance-users/{AppInstanceUserArn}/endpoints/{EndpointId}", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Returns the full details of an AppInstance.
    public func describeAppInstance(_ input: DescribeAppInstanceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> DescribeAppInstanceResponse {
        return try await self.client.execute(operation: "DescribeAppInstance", path: "/app-instances/{AppInstanceArn}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Returns the full details of an AppInstanceAdmin.
    public func describeAppInstanceAdmin(_ input: DescribeAppInstanceAdminRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> DescribeAppInstanceAdminResponse {
        return try await self.client.execute(operation: "DescribeAppInstanceAdmin", path: "/app-instances/{AppInstanceArn}/admins/{AppInstanceAdminArn}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// The AppInstanceBot's information.
    public func describeAppInstanceBot(_ input: DescribeAppInstanceBotRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> DescribeAppInstanceBotResponse {
        return try await self.client.execute(operation: "DescribeAppInstanceBot", path: "/app-instance-bots/{AppInstanceBotArn}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Returns the full details of an AppInstanceUser.
    public func describeAppInstanceUser(_ input: DescribeAppInstanceUserRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> DescribeAppInstanceUserResponse {
        return try await self.client.execute(operation: "DescribeAppInstanceUser", path: "/app-instance-users/{AppInstanceUserArn}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Returns the full details of an AppInstanceUserEndpoint.
    public func describeAppInstanceUserEndpoint(_ input: DescribeAppInstanceUserEndpointRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> DescribeAppInstanceUserEndpointResponse {
        return try await self.client.execute(operation: "DescribeAppInstanceUserEndpoint", path: "/app-instance-users/{AppInstanceUserArn}/endpoints/{EndpointId}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Gets the retention settings for an AppInstance.
    public func getAppInstanceRetentionSettings(_ input: GetAppInstanceRetentionSettingsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetAppInstanceRetentionSettingsResponse {
        return try await self.client.execute(operation: "GetAppInstanceRetentionSettings", path: "/app-instances/{AppInstanceArn}/retention-settings", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Returns a list of the administrators in the AppInstance.
    public func listAppInstanceAdmins(_ input: ListAppInstanceAdminsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListAppInstanceAdminsResponse {
        return try await self.client.execute(operation: "ListAppInstanceAdmins", path: "/app-instances/{AppInstanceArn}/admins", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Lists all AppInstanceBots created under a single AppInstance.
    public func listAppInstanceBots(_ input: ListAppInstanceBotsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListAppInstanceBotsResponse {
        return try await self.client.execute(operation: "ListAppInstanceBots", path: "/app-instance-bots", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Lists all the AppInstanceUserEndpoints created under a single AppInstanceUser.
    public func listAppInstanceUserEndpoints(_ input: ListAppInstanceUserEndpointsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListAppInstanceUserEndpointsResponse {
        return try await self.client.execute(operation: "ListAppInstanceUserEndpoints", path: "/app-instance-users/{AppInstanceUserArn}/endpoints", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// List all AppInstanceUsers created under a single AppInstance.
    public func listAppInstanceUsers(_ input: ListAppInstanceUsersRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListAppInstanceUsersResponse {
        return try await self.client.execute(operation: "ListAppInstanceUsers", path: "/app-instance-users", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Lists all Amazon Chime AppInstances created under a single AWS account.
    public func listAppInstances(_ input: ListAppInstancesRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListAppInstancesResponse {
        return try await self.client.execute(operation: "ListAppInstances", path: "/app-instances", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Lists the tags applied to an Amazon Chime SDK identity resource.
    public func listTagsForResource(_ input: ListTagsForResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListTagsForResourceResponse {
        return try await self.client.execute(operation: "ListTagsForResource", path: "/tags", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Sets the amount of time in days that a given AppInstance retains data.
    public func putAppInstanceRetentionSettings(_ input: PutAppInstanceRetentionSettingsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> PutAppInstanceRetentionSettingsResponse {
        return try await self.client.execute(operation: "PutAppInstanceRetentionSettings", path: "/app-instances/{AppInstanceArn}/retention-settings", httpMethod: .PUT, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Sets the number of days before the AppInstanceUser is automatically deleted.  A background process deletes expired AppInstanceUsers within 6 hours of expiration.  Actual deletion times may vary. Expired AppInstanceUsers that have not yet been deleted appear as active, and you can update  their expiration settings. The system honors the new settings.
    public func putAppInstanceUserExpirationSettings(_ input: PutAppInstanceUserExpirationSettingsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> PutAppInstanceUserExpirationSettingsResponse {
        return try await self.client.execute(operation: "PutAppInstanceUserExpirationSettings", path: "/app-instance-users/{AppInstanceUserArn}/expiration-settings", httpMethod: .PUT, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Registers an endpoint under an Amazon Chime AppInstanceUser. The endpoint receives messages for a user. For push notifications, the endpoint is a mobile device used to receive mobile push notifications for a user.
    public func registerAppInstanceUserEndpoint(_ input: RegisterAppInstanceUserEndpointRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> RegisterAppInstanceUserEndpointResponse {
        return try await self.client.execute(operation: "RegisterAppInstanceUserEndpoint", path: "/app-instance-users/{AppInstanceUserArn}/endpoints", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Applies the specified tags to the specified Amazon Chime SDK identity resource.
    public func tagResource(_ input: TagResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "TagResource", path: "/tags?operation=tag-resource", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Removes the specified tags from the specified Amazon Chime SDK identity resource.
    public func untagResource(_ input: UntagResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "UntagResource", path: "/tags?operation=untag-resource", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Updates AppInstance metadata.
    public func updateAppInstance(_ input: UpdateAppInstanceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> UpdateAppInstanceResponse {
        return try await self.client.execute(operation: "UpdateAppInstance", path: "/app-instances/{AppInstanceArn}", httpMethod: .PUT, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Updates the name and metadata of an AppInstanceBot.
    public func updateAppInstanceBot(_ input: UpdateAppInstanceBotRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> UpdateAppInstanceBotResponse {
        return try await self.client.execute(operation: "UpdateAppInstanceBot", path: "/app-instance-bots/{AppInstanceBotArn}", httpMethod: .PUT, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Updates the details of an AppInstanceUser. You can update names and metadata.
    public func updateAppInstanceUser(_ input: UpdateAppInstanceUserRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> UpdateAppInstanceUserResponse {
        return try await self.client.execute(operation: "UpdateAppInstanceUser", path: "/app-instance-users/{AppInstanceUserArn}", httpMethod: .PUT, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Updates the details of an AppInstanceUserEndpoint. You can update the name and AllowMessage values.
    public func updateAppInstanceUserEndpoint(_ input: UpdateAppInstanceUserEndpointRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> UpdateAppInstanceUserEndpointResponse {
        return try await self.client.execute(operation: "UpdateAppInstanceUserEndpoint", path: "/app-instance-users/{AppInstanceUserArn}/endpoints/{EndpointId}", httpMethod: .PUT, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }
}

// MARK: Paginators

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension ChimeSDKIdentity {
    /// Returns a list of the administrators in the AppInstance.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listAppInstanceAdminsPaginator(
        _ input: ListAppInstanceAdminsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListAppInstanceAdminsRequest, ListAppInstanceAdminsResponse> {
        return .init(
            input: input,
            command: self.listAppInstanceAdmins,
            inputKey: \ListAppInstanceAdminsRequest.nextToken,
            outputKey: \ListAppInstanceAdminsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Lists all AppInstanceBots created under a single AppInstance.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listAppInstanceBotsPaginator(
        _ input: ListAppInstanceBotsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListAppInstanceBotsRequest, ListAppInstanceBotsResponse> {
        return .init(
            input: input,
            command: self.listAppInstanceBots,
            inputKey: \ListAppInstanceBotsRequest.nextToken,
            outputKey: \ListAppInstanceBotsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Lists all the AppInstanceUserEndpoints created under a single AppInstanceUser.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listAppInstanceUserEndpointsPaginator(
        _ input: ListAppInstanceUserEndpointsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListAppInstanceUserEndpointsRequest, ListAppInstanceUserEndpointsResponse> {
        return .init(
            input: input,
            command: self.listAppInstanceUserEndpoints,
            inputKey: \ListAppInstanceUserEndpointsRequest.nextToken,
            outputKey: \ListAppInstanceUserEndpointsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// List all AppInstanceUsers created under a single AppInstance.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listAppInstanceUsersPaginator(
        _ input: ListAppInstanceUsersRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListAppInstanceUsersRequest, ListAppInstanceUsersResponse> {
        return .init(
            input: input,
            command: self.listAppInstanceUsers,
            inputKey: \ListAppInstanceUsersRequest.nextToken,
            outputKey: \ListAppInstanceUsersResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Lists all Amazon Chime AppInstances created under a single AWS account.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listAppInstancesPaginator(
        _ input: ListAppInstancesRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListAppInstancesRequest, ListAppInstancesResponse> {
        return .init(
            input: input,
            command: self.listAppInstances,
            inputKey: \ListAppInstancesRequest.nextToken,
            outputKey: \ListAppInstancesResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }
}