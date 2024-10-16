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

#if os(Linux) && compiler(<5.10)
// swift-corelibs-foundation hasn't been updated with Sendable conformances
@preconcurrency import Foundation
#else
import Foundation
#endif
@_exported import SotoCore

/// Service object for interacting with AWS IoT1ClickProjects service.
///
/// The AWS IoT 1-Click Projects API Reference
public struct IoT1ClickProjects: AWSService {
    // MARK: Member variables

    /// Client used for communication with AWS
    public let client: AWSClient
    /// Service configuration
    public let config: AWSServiceConfig

    // MARK: Initialization

    /// Initialize the IoT1ClickProjects client
    /// - parameters:
    ///     - client: AWSClient used to process requests
    ///     - region: Region of server you want to communicate with. This will override the partition parameter.
    ///     - partition: AWS partition where service resides, standard (.aws), china (.awscn), government (.awsusgov).
    ///     - endpoint: Custom endpoint URL to use instead of standard AWS servers
    ///     - middleware: Middleware chain used to edit requests before they are sent and responses before they are decoded 
    ///     - timeout: Timeout value for HTTP requests
    ///     - byteBufferAllocator: Allocator for ByteBuffers
    ///     - options: Service options
    public init(
        client: AWSClient,
        region: SotoCore.Region? = nil,
        partition: AWSPartition = .aws,
        endpoint: String? = nil,
        middleware: AWSMiddlewareProtocol? = nil,
        timeout: TimeAmount? = nil,
        byteBufferAllocator: ByteBufferAllocator = ByteBufferAllocator(),
        options: AWSServiceConfig.Options = []
    ) {
        self.client = client
        self.config = AWSServiceConfig(
            region: region,
            partition: region?.partition ?? partition,
            serviceName: "IoT1ClickProjects",
            serviceIdentifier: "projects.iot1click",
            signingName: "iot1click",
            serviceProtocol: .restjson,
            apiVersion: "2018-05-14",
            endpoint: endpoint,
            errorType: IoT1ClickProjectsErrorType.self,
            middleware: middleware,
            timeout: timeout,
            byteBufferAllocator: byteBufferAllocator,
            options: options
        )
    }





    // MARK: API Calls

    /// Associates a physical device with a placement.
    @Sendable
    @inlinable
    public func associateDeviceWithPlacement(_ input: AssociateDeviceWithPlacementRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> AssociateDeviceWithPlacementResponse {
        try await self.client.execute(
            operation: "AssociateDeviceWithPlacement", 
            path: "/projects/{projectName}/placements/{placementName}/devices/{deviceTemplateName}", 
            httpMethod: .PUT, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Associates a physical device with a placement.
    ///
    /// Parameters:
    ///   - deviceId: The ID of the physical device to be associated with the given placement in the project. Note that a mandatory 4 character prefix is required for all deviceId values.
    ///   - deviceTemplateName: The device template name to associate with the device ID.
    ///   - placementName: The name of the placement in which to associate the device.
    ///   - projectName: The name of the project containing the placement in which to associate the device.
    ///   - logger: Logger use during operation
    @inlinable
    public func associateDeviceWithPlacement(
        deviceId: String,
        deviceTemplateName: String,
        placementName: String,
        projectName: String,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> AssociateDeviceWithPlacementResponse {
        let input = AssociateDeviceWithPlacementRequest(
            deviceId: deviceId, 
            deviceTemplateName: deviceTemplateName, 
            placementName: placementName, 
            projectName: projectName
        )
        return try await self.associateDeviceWithPlacement(input, logger: logger)
    }

    /// Creates an empty placement.
    @Sendable
    @inlinable
    public func createPlacement(_ input: CreatePlacementRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> CreatePlacementResponse {
        try await self.client.execute(
            operation: "CreatePlacement", 
            path: "/projects/{projectName}/placements", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Creates an empty placement.
    ///
    /// Parameters:
    ///   - attributes: Optional user-defined key/value pairs providing contextual data (such as location or function) for the placement.
    ///   - placementName: The name of the placement to be created.
    ///   - projectName: The name of the project in which to create the placement.
    ///   - logger: Logger use during operation
    @inlinable
    public func createPlacement(
        attributes: [String: String]? = nil,
        placementName: String,
        projectName: String,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> CreatePlacementResponse {
        let input = CreatePlacementRequest(
            attributes: attributes, 
            placementName: placementName, 
            projectName: projectName
        )
        return try await self.createPlacement(input, logger: logger)
    }

    /// Creates an empty project with a placement template. A project contains zero or more placements that adhere to the placement template defined in the project.
    @Sendable
    @inlinable
    public func createProject(_ input: CreateProjectRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> CreateProjectResponse {
        try await self.client.execute(
            operation: "CreateProject", 
            path: "/projects", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Creates an empty project with a placement template. A project contains zero or more placements that adhere to the placement template defined in the project.
    ///
    /// Parameters:
    ///   - description: An optional description for the project.
    ///   - placementTemplate: The schema defining the placement to be created. A placement template defines placement default attributes and device templates. You cannot add or remove device templates after the project has been created. However, you can update callbackOverrides for the device templates using the UpdateProject API.
    ///   - projectName: The name of the project to create.
    ///   - tags: Optional tags (metadata key/value pairs) to be associated with the project. For example, { {"key1": "value1", "key2": "value2"} }. For more information, see AWS Tagging Strategies.
    ///   - logger: Logger use during operation
    @inlinable
    public func createProject(
        description: String? = nil,
        placementTemplate: PlacementTemplate? = nil,
        projectName: String,
        tags: [String: String]? = nil,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> CreateProjectResponse {
        let input = CreateProjectRequest(
            description: description, 
            placementTemplate: placementTemplate, 
            projectName: projectName, 
            tags: tags
        )
        return try await self.createProject(input, logger: logger)
    }

    /// Deletes a placement. To delete a placement, it must not have any devices associated with it.  When you delete a placement, all associated data becomes irretrievable.
    @Sendable
    @inlinable
    public func deletePlacement(_ input: DeletePlacementRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> DeletePlacementResponse {
        try await self.client.execute(
            operation: "DeletePlacement", 
            path: "/projects/{projectName}/placements/{placementName}", 
            httpMethod: .DELETE, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Deletes a placement. To delete a placement, it must not have any devices associated with it.  When you delete a placement, all associated data becomes irretrievable.
    ///
    /// Parameters:
    ///   - placementName: The name of the empty placement to delete.
    ///   - projectName: The project containing the empty placement to delete.
    ///   - logger: Logger use during operation
    @inlinable
    public func deletePlacement(
        placementName: String,
        projectName: String,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> DeletePlacementResponse {
        let input = DeletePlacementRequest(
            placementName: placementName, 
            projectName: projectName
        )
        return try await self.deletePlacement(input, logger: logger)
    }

    /// Deletes a project. To delete a project, it must not have any placements associated with it.  When you delete a project, all associated data becomes irretrievable.
    @Sendable
    @inlinable
    public func deleteProject(_ input: DeleteProjectRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> DeleteProjectResponse {
        try await self.client.execute(
            operation: "DeleteProject", 
            path: "/projects/{projectName}", 
            httpMethod: .DELETE, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Deletes a project. To delete a project, it must not have any placements associated with it.  When you delete a project, all associated data becomes irretrievable.
    ///
    /// Parameters:
    ///   - projectName: The name of the empty project to delete.
    ///   - logger: Logger use during operation
    @inlinable
    public func deleteProject(
        projectName: String,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> DeleteProjectResponse {
        let input = DeleteProjectRequest(
            projectName: projectName
        )
        return try await self.deleteProject(input, logger: logger)
    }

    /// Describes a placement in a project.
    @Sendable
    @inlinable
    public func describePlacement(_ input: DescribePlacementRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> DescribePlacementResponse {
        try await self.client.execute(
            operation: "DescribePlacement", 
            path: "/projects/{projectName}/placements/{placementName}", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Describes a placement in a project.
    ///
    /// Parameters:
    ///   - placementName: The name of the placement within a project.
    ///   - projectName: The project containing the placement to be described.
    ///   - logger: Logger use during operation
    @inlinable
    public func describePlacement(
        placementName: String,
        projectName: String,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> DescribePlacementResponse {
        let input = DescribePlacementRequest(
            placementName: placementName, 
            projectName: projectName
        )
        return try await self.describePlacement(input, logger: logger)
    }

    /// Returns an object describing a project.
    @Sendable
    @inlinable
    public func describeProject(_ input: DescribeProjectRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> DescribeProjectResponse {
        try await self.client.execute(
            operation: "DescribeProject", 
            path: "/projects/{projectName}", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Returns an object describing a project.
    ///
    /// Parameters:
    ///   - projectName: The name of the project to be described.
    ///   - logger: Logger use during operation
    @inlinable
    public func describeProject(
        projectName: String,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> DescribeProjectResponse {
        let input = DescribeProjectRequest(
            projectName: projectName
        )
        return try await self.describeProject(input, logger: logger)
    }

    /// Removes a physical device from a placement.
    @Sendable
    @inlinable
    public func disassociateDeviceFromPlacement(_ input: DisassociateDeviceFromPlacementRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> DisassociateDeviceFromPlacementResponse {
        try await self.client.execute(
            operation: "DisassociateDeviceFromPlacement", 
            path: "/projects/{projectName}/placements/{placementName}/devices/{deviceTemplateName}", 
            httpMethod: .DELETE, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Removes a physical device from a placement.
    ///
    /// Parameters:
    ///   - deviceTemplateName: The device ID that should be removed from the placement.
    ///   - placementName: The name of the placement that the device should be removed from.
    ///   - projectName: The name of the project that contains the placement.
    ///   - logger: Logger use during operation
    @inlinable
    public func disassociateDeviceFromPlacement(
        deviceTemplateName: String,
        placementName: String,
        projectName: String,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> DisassociateDeviceFromPlacementResponse {
        let input = DisassociateDeviceFromPlacementRequest(
            deviceTemplateName: deviceTemplateName, 
            placementName: placementName, 
            projectName: projectName
        )
        return try await self.disassociateDeviceFromPlacement(input, logger: logger)
    }

    /// Returns an object enumerating the devices in a placement.
    @Sendable
    @inlinable
    public func getDevicesInPlacement(_ input: GetDevicesInPlacementRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> GetDevicesInPlacementResponse {
        try await self.client.execute(
            operation: "GetDevicesInPlacement", 
            path: "/projects/{projectName}/placements/{placementName}/devices", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Returns an object enumerating the devices in a placement.
    ///
    /// Parameters:
    ///   - placementName: The name of the placement to get the devices from.
    ///   - projectName: The name of the project containing the placement.
    ///   - logger: Logger use during operation
    @inlinable
    public func getDevicesInPlacement(
        placementName: String,
        projectName: String,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> GetDevicesInPlacementResponse {
        let input = GetDevicesInPlacementRequest(
            placementName: placementName, 
            projectName: projectName
        )
        return try await self.getDevicesInPlacement(input, logger: logger)
    }

    /// Lists the placement(s) of a project.
    @Sendable
    @inlinable
    public func listPlacements(_ input: ListPlacementsRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> ListPlacementsResponse {
        try await self.client.execute(
            operation: "ListPlacements", 
            path: "/projects/{projectName}/placements", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Lists the placement(s) of a project.
    ///
    /// Parameters:
    ///   - maxResults: The maximum number of results to return per request. If not set, a default value of 100 is used.
    ///   - nextToken: The token to retrieve the next set of results.
    ///   - projectName: The project containing the placements to be listed.
    ///   - logger: Logger use during operation
    @inlinable
    public func listPlacements(
        maxResults: Int? = nil,
        nextToken: String? = nil,
        projectName: String,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> ListPlacementsResponse {
        let input = ListPlacementsRequest(
            maxResults: maxResults, 
            nextToken: nextToken, 
            projectName: projectName
        )
        return try await self.listPlacements(input, logger: logger)
    }

    /// Lists the AWS IoT 1-Click project(s) associated with your AWS account and region.
    @Sendable
    @inlinable
    public func listProjects(_ input: ListProjectsRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> ListProjectsResponse {
        try await self.client.execute(
            operation: "ListProjects", 
            path: "/projects", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Lists the AWS IoT 1-Click project(s) associated with your AWS account and region.
    ///
    /// Parameters:
    ///   - maxResults: The maximum number of results to return per request. If not set, a default value of 100 is used.
    ///   - nextToken: The token to retrieve the next set of results.
    ///   - logger: Logger use during operation
    @inlinable
    public func listProjects(
        maxResults: Int? = nil,
        nextToken: String? = nil,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> ListProjectsResponse {
        let input = ListProjectsRequest(
            maxResults: maxResults, 
            nextToken: nextToken
        )
        return try await self.listProjects(input, logger: logger)
    }

    /// Lists the tags (metadata key/value pairs) which you have assigned to the resource.
    @Sendable
    @inlinable
    public func listTagsForResource(_ input: ListTagsForResourceRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> ListTagsForResourceResponse {
        try await self.client.execute(
            operation: "ListTagsForResource", 
            path: "/tags/{resourceArn}", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Lists the tags (metadata key/value pairs) which you have assigned to the resource.
    ///
    /// Parameters:
    ///   - resourceArn: The ARN of the resource whose tags you want to list.
    ///   - logger: Logger use during operation
    @inlinable
    public func listTagsForResource(
        resourceArn: String,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> ListTagsForResourceResponse {
        let input = ListTagsForResourceRequest(
            resourceArn: resourceArn
        )
        return try await self.listTagsForResource(input, logger: logger)
    }

    /// Creates or modifies tags for a resource. Tags are key/value pairs (metadata) that can be used to manage a resource. For more information, see AWS Tagging Strategies.
    @Sendable
    @inlinable
    public func tagResource(_ input: TagResourceRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> TagResourceResponse {
        try await self.client.execute(
            operation: "TagResource", 
            path: "/tags/{resourceArn}", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Creates or modifies tags for a resource. Tags are key/value pairs (metadata) that can be used to manage a resource. For more information, see AWS Tagging Strategies.
    ///
    /// Parameters:
    ///   - resourceArn: The ARN of the resouce for which tag(s) should be added or modified.
    ///   - tags: The new or modifying tag(s) for the resource. See AWS IoT 1-Click Service Limits for the maximum number of tags allowed per resource.
    ///   - logger: Logger use during operation
    @inlinable
    public func tagResource(
        resourceArn: String,
        tags: [String: String],
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> TagResourceResponse {
        let input = TagResourceRequest(
            resourceArn: resourceArn, 
            tags: tags
        )
        return try await self.tagResource(input, logger: logger)
    }

    /// Removes one or more tags (metadata key/value pairs) from a resource.
    @Sendable
    @inlinable
    public func untagResource(_ input: UntagResourceRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> UntagResourceResponse {
        try await self.client.execute(
            operation: "UntagResource", 
            path: "/tags/{resourceArn}", 
            httpMethod: .DELETE, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Removes one or more tags (metadata key/value pairs) from a resource.
    ///
    /// Parameters:
    ///   - resourceArn: The ARN of the resource whose tag you want to remove.
    ///   - tagKeys: The keys of those tags which you want to remove.
    ///   - logger: Logger use during operation
    @inlinable
    public func untagResource(
        resourceArn: String,
        tagKeys: [String],
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> UntagResourceResponse {
        let input = UntagResourceRequest(
            resourceArn: resourceArn, 
            tagKeys: tagKeys
        )
        return try await self.untagResource(input, logger: logger)
    }

    /// Updates a placement with the given attributes. To clear an attribute, pass an empty value (i.e., "").
    @Sendable
    @inlinable
    public func updatePlacement(_ input: UpdatePlacementRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> UpdatePlacementResponse {
        try await self.client.execute(
            operation: "UpdatePlacement", 
            path: "/projects/{projectName}/placements/{placementName}", 
            httpMethod: .PUT, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Updates a placement with the given attributes. To clear an attribute, pass an empty value (i.e., "").
    ///
    /// Parameters:
    ///   - attributes: The user-defined object of attributes used to update the placement. The maximum number of key/value pairs is 50.
    ///   - placementName: The name of the placement to update.
    ///   - projectName: The name of the project containing the placement to be updated.
    ///   - logger: Logger use during operation
    @inlinable
    public func updatePlacement(
        attributes: [String: String]? = nil,
        placementName: String,
        projectName: String,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> UpdatePlacementResponse {
        let input = UpdatePlacementRequest(
            attributes: attributes, 
            placementName: placementName, 
            projectName: projectName
        )
        return try await self.updatePlacement(input, logger: logger)
    }

    /// Updates a project associated with your AWS account and region. With the exception of device template names, you can pass just the values that need to be updated because the update request will change only the values that are provided. To clear a value, pass the empty string (i.e., "").
    @Sendable
    @inlinable
    public func updateProject(_ input: UpdateProjectRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> UpdateProjectResponse {
        try await self.client.execute(
            operation: "UpdateProject", 
            path: "/projects/{projectName}", 
            httpMethod: .PUT, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Updates a project associated with your AWS account and region. With the exception of device template names, you can pass just the values that need to be updated because the update request will change only the values that are provided. To clear a value, pass the empty string (i.e., "").
    ///
    /// Parameters:
    ///   - description: An optional user-defined description for the project.
    ///   - placementTemplate: An object defining the project update. Once a project has been created, you cannot add device template names to the project. However, for a given placementTemplate, you can update the associated callbackOverrides for the device definition using this API.
    ///   - projectName: The name of the project to be updated.
    ///   - logger: Logger use during operation
    @inlinable
    public func updateProject(
        description: String? = nil,
        placementTemplate: PlacementTemplate? = nil,
        projectName: String,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> UpdateProjectResponse {
        let input = UpdateProjectRequest(
            description: description, 
            placementTemplate: placementTemplate, 
            projectName: projectName
        )
        return try await self.updateProject(input, logger: logger)
    }
}

extension IoT1ClickProjects {
    /// Initializer required by `AWSService.with(middlewares:timeout:byteBufferAllocator:options)`. You are not able to use this initializer directly as there are not public
    /// initializers for `AWSServiceConfig.Patch`. Please use `AWSService.with(middlewares:timeout:byteBufferAllocator:options)` instead.
    public init(from: IoT1ClickProjects, patch: AWSServiceConfig.Patch) {
        self.client = from.client
        self.config = from.config.with(patch: patch)
    }
}

// MARK: Paginators

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension IoT1ClickProjects {
    /// Return PaginatorSequence for operation ``listPlacements(_:logger:)``.
    ///
    /// - Parameters:
    ///   - input: Input for operation
    ///   - logger: Logger used for logging
    @inlinable
    public func listPlacementsPaginator(
        _ input: ListPlacementsRequest,
        logger: Logger = AWSClient.loggingDisabled
    ) -> AWSClient.PaginatorSequence<ListPlacementsRequest, ListPlacementsResponse> {
        return .init(
            input: input,
            command: self.listPlacements,
            inputKey: \ListPlacementsRequest.nextToken,
            outputKey: \ListPlacementsResponse.nextToken,
            logger: logger
        )
    }
    /// Return PaginatorSequence for operation ``listPlacements(_:logger:)``.
    ///
    /// - Parameters:
    ///   - maxResults: The maximum number of results to return per request. If not set, a default value of 100 is used.
    ///   - projectName: The project containing the placements to be listed.
    ///   - logger: Logger used for logging
    @inlinable
    public func listPlacementsPaginator(
        maxResults: Int? = nil,
        projectName: String,
        logger: Logger = AWSClient.loggingDisabled        
    ) -> AWSClient.PaginatorSequence<ListPlacementsRequest, ListPlacementsResponse> {
        let input = ListPlacementsRequest(
            maxResults: maxResults, 
            projectName: projectName
        )
        return self.listPlacementsPaginator(input, logger: logger)
    }

    /// Return PaginatorSequence for operation ``listProjects(_:logger:)``.
    ///
    /// - Parameters:
    ///   - input: Input for operation
    ///   - logger: Logger used for logging
    @inlinable
    public func listProjectsPaginator(
        _ input: ListProjectsRequest,
        logger: Logger = AWSClient.loggingDisabled
    ) -> AWSClient.PaginatorSequence<ListProjectsRequest, ListProjectsResponse> {
        return .init(
            input: input,
            command: self.listProjects,
            inputKey: \ListProjectsRequest.nextToken,
            outputKey: \ListProjectsResponse.nextToken,
            logger: logger
        )
    }
    /// Return PaginatorSequence for operation ``listProjects(_:logger:)``.
    ///
    /// - Parameters:
    ///   - maxResults: The maximum number of results to return per request. If not set, a default value of 100 is used.
    ///   - logger: Logger used for logging
    @inlinable
    public func listProjectsPaginator(
        maxResults: Int? = nil,
        logger: Logger = AWSClient.loggingDisabled        
    ) -> AWSClient.PaginatorSequence<ListProjectsRequest, ListProjectsResponse> {
        let input = ListProjectsRequest(
            maxResults: maxResults
        )
        return self.listProjectsPaginator(input, logger: logger)
    }
}

extension IoT1ClickProjects.ListPlacementsRequest: AWSPaginateToken {
    @inlinable
    public func usingPaginationToken(_ token: String) -> IoT1ClickProjects.ListPlacementsRequest {
        return .init(
            maxResults: self.maxResults,
            nextToken: token,
            projectName: self.projectName
        )
    }
}

extension IoT1ClickProjects.ListProjectsRequest: AWSPaginateToken {
    @inlinable
    public func usingPaginationToken(_ token: String) -> IoT1ClickProjects.ListProjectsRequest {
        return .init(
            maxResults: self.maxResults,
            nextToken: token
        )
    }
}
