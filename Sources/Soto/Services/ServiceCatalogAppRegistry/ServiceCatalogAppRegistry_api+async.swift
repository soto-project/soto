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
extension ServiceCatalogAppRegistry {
    // MARK: Async API Calls

    /// Associates an attribute group with an application to augment the application's metadata with the group's attributes. This feature enables applications to be described with user-defined details that are machine-readable, such as third-party integrations.
    public func associateAttributeGroup(_ input: AssociateAttributeGroupRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> AssociateAttributeGroupResponse {
        return try await self.client.execute(operation: "AssociateAttributeGroup", path: "/applications/{application}/attribute-groups/{attributeGroup}", httpMethod: .PUT, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    ///  Associates a resource  with an application.  The resource can be specified  by its ARN or name.  The application can be specified  by ARN, ID, or name.
    public func associateResource(_ input: AssociateResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> AssociateResourceResponse {
        return try await self.client.execute(operation: "AssociateResource", path: "/applications/{application}/resources/{resourceType}/{resource}", httpMethod: .PUT, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Creates a new application that is the top-level node in a hierarchy of related cloud resource abstractions.
    public func createApplication(_ input: CreateApplicationRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CreateApplicationResponse {
        return try await self.client.execute(operation: "CreateApplication", path: "/applications", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Creates a new attribute group as a container for user-defined attributes. This feature enables users to have full control over their cloud application's metadata in a rich machine-readable format to facilitate integration with automated workflows and third-party tools.
    public func createAttributeGroup(_ input: CreateAttributeGroupRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CreateAttributeGroupResponse {
        return try await self.client.execute(operation: "CreateAttributeGroup", path: "/attribute-groups", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Deletes an application that is specified either by its application ID, name, or ARN. All associated attribute groups and resources must be disassociated from it before deleting an application.
    public func deleteApplication(_ input: DeleteApplicationRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> DeleteApplicationResponse {
        return try await self.client.execute(operation: "DeleteApplication", path: "/applications/{application}", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Deletes an attribute group, specified either by its attribute group ID, name, or ARN.
    public func deleteAttributeGroup(_ input: DeleteAttributeGroupRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> DeleteAttributeGroupResponse {
        return try await self.client.execute(operation: "DeleteAttributeGroup", path: "/attribute-groups/{attributeGroup}", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Disassociates an attribute group from an application to remove the extra attributes contained in the attribute group from the application's metadata. This operation reverts AssociateAttributeGroup.
    public func disassociateAttributeGroup(_ input: DisassociateAttributeGroupRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> DisassociateAttributeGroupResponse {
        return try await self.client.execute(operation: "DisassociateAttributeGroup", path: "/applications/{application}/attribute-groups/{attributeGroup}", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Disassociates a resource from application. Both the resource and the application can be specified either by ID or name.
    public func disassociateResource(_ input: DisassociateResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> DisassociateResourceResponse {
        return try await self.client.execute(operation: "DisassociateResource", path: "/applications/{application}/resources/{resourceType}/{resource}", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    ///  Retrieves metadata information  about one  of your applications.  The application can be specified  by its ARN, ID, or name  (which is unique  within one account  in one region  at a given point  in time).  Specify  by ARN or ID  in automated workflows  if you want  to make sure  that the exact same application is returned or a ResourceNotFoundException is thrown,  avoiding the ABA addressing problem.
    public func getApplication(_ input: GetApplicationRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetApplicationResponse {
        return try await self.client.execute(operation: "GetApplication", path: "/applications/{application}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Gets the resource associated with the application.
    public func getAssociatedResource(_ input: GetAssociatedResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetAssociatedResourceResponse {
        return try await self.client.execute(operation: "GetAssociatedResource", path: "/applications/{application}/resources/{resourceType}/{resource}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    ///  Retrieves an attribute group by its ARN, ID, or name.  The attribute group can be specified  by its ARN, ID, or name.
    public func getAttributeGroup(_ input: GetAttributeGroupRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetAttributeGroupResponse {
        return try await self.client.execute(operation: "GetAttributeGroup", path: "/attribute-groups/{attributeGroup}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    ///  Retrieves a TagKey configuration from an account.
    public func getConfiguration(logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetConfigurationResponse {
        return try await self.client.execute(operation: "GetConfiguration", path: "/configuration", httpMethod: .GET, serviceConfig: self.config, logger: logger, on: eventLoop)
    }

    /// Retrieves a list of all of your applications. Results are paginated.
    public func listApplications(_ input: ListApplicationsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListApplicationsResponse {
        return try await self.client.execute(operation: "ListApplications", path: "/applications", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Lists all attribute groups that are associated with specified application.  Results are paginated.
    public func listAssociatedAttributeGroups(_ input: ListAssociatedAttributeGroupsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListAssociatedAttributeGroupsResponse {
        return try await self.client.execute(operation: "ListAssociatedAttributeGroups", path: "/applications/{application}/attribute-groups", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    ///  Lists all  of the resources  that are associated  with the specified application. Results are paginated.    If you share an application,  and a consumer account associates a tag query  to the application,  all of the users  who can access the application  can also view the tag values  in all accounts  that are associated  with it  using this API.
    public func listAssociatedResources(_ input: ListAssociatedResourcesRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListAssociatedResourcesResponse {
        return try await self.client.execute(operation: "ListAssociatedResources", path: "/applications/{application}/resources", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Lists all attribute groups which you have access to. Results are paginated.
    public func listAttributeGroups(_ input: ListAttributeGroupsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListAttributeGroupsResponse {
        return try await self.client.execute(operation: "ListAttributeGroups", path: "/attribute-groups", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Lists the details of all attribute groups associated with a specific application. The results display in pages.
    public func listAttributeGroupsForApplication(_ input: ListAttributeGroupsForApplicationRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListAttributeGroupsForApplicationResponse {
        return try await self.client.execute(operation: "ListAttributeGroupsForApplication", path: "/applications/{application}/attribute-group-details", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Lists all of the tags on the resource.
    public func listTagsForResource(_ input: ListTagsForResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListTagsForResourceResponse {
        return try await self.client.execute(operation: "ListTagsForResource", path: "/tags/{resourceArn}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    ///  Associates a TagKey configuration  to an account.
    public func putConfiguration(_ input: PutConfigurationRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "PutConfiguration", path: "/configuration", httpMethod: .PUT, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Syncs the resource with current AppRegistry records. Specifically, the resource’s AppRegistry system tags sync with its associated application. We remove the resource's AppRegistry system tags if it does not associate with the application. The caller must have permissions to read and update the resource.
    public func syncResource(_ input: SyncResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> SyncResourceResponse {
        return try await self.client.execute(operation: "SyncResource", path: "/sync/{resourceType}/{resource}", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Assigns one or more tags (key-value pairs) to the specified resource. Each tag consists of a key and an optional value. If a tag with the same key is already associated with the resource, this action updates its value. This operation returns an empty response if the call was successful.
    public func tagResource(_ input: TagResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> TagResourceResponse {
        return try await self.client.execute(operation: "TagResource", path: "/tags/{resourceArn}", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Removes tags from a resource. This operation returns an empty response if the call was successful.
    public func untagResource(_ input: UntagResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> UntagResourceResponse {
        return try await self.client.execute(operation: "UntagResource", path: "/tags/{resourceArn}", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Updates an existing application with new attributes.
    public func updateApplication(_ input: UpdateApplicationRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> UpdateApplicationResponse {
        return try await self.client.execute(operation: "UpdateApplication", path: "/applications/{application}", httpMethod: .PATCH, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Updates an existing attribute group with new details.
    public func updateAttributeGroup(_ input: UpdateAttributeGroupRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> UpdateAttributeGroupResponse {
        return try await self.client.execute(operation: "UpdateAttributeGroup", path: "/attribute-groups/{attributeGroup}", httpMethod: .PATCH, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }
}

// MARK: Paginators

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension ServiceCatalogAppRegistry {
    /// Retrieves a list of all of your applications. Results are paginated.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listApplicationsPaginator(
        _ input: ListApplicationsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListApplicationsRequest, ListApplicationsResponse> {
        return .init(
            input: input,
            command: self.listApplications,
            inputKey: \ListApplicationsRequest.nextToken,
            outputKey: \ListApplicationsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Lists all attribute groups that are associated with specified application.  Results are paginated.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listAssociatedAttributeGroupsPaginator(
        _ input: ListAssociatedAttributeGroupsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListAssociatedAttributeGroupsRequest, ListAssociatedAttributeGroupsResponse> {
        return .init(
            input: input,
            command: self.listAssociatedAttributeGroups,
            inputKey: \ListAssociatedAttributeGroupsRequest.nextToken,
            outputKey: \ListAssociatedAttributeGroupsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    ///  Lists all  of the resources  that are associated  with the specified application. Results are paginated.    If you share an application,  and a consumer account associates a tag query  to the application,  all of the users  who can access the application  can also view the tag values  in all accounts  that are associated  with it  using this API.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listAssociatedResourcesPaginator(
        _ input: ListAssociatedResourcesRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListAssociatedResourcesRequest, ListAssociatedResourcesResponse> {
        return .init(
            input: input,
            command: self.listAssociatedResources,
            inputKey: \ListAssociatedResourcesRequest.nextToken,
            outputKey: \ListAssociatedResourcesResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Lists all attribute groups which you have access to. Results are paginated.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listAttributeGroupsPaginator(
        _ input: ListAttributeGroupsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListAttributeGroupsRequest, ListAttributeGroupsResponse> {
        return .init(
            input: input,
            command: self.listAttributeGroups,
            inputKey: \ListAttributeGroupsRequest.nextToken,
            outputKey: \ListAttributeGroupsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Lists the details of all attribute groups associated with a specific application. The results display in pages.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listAttributeGroupsForApplicationPaginator(
        _ input: ListAttributeGroupsForApplicationRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListAttributeGroupsForApplicationRequest, ListAttributeGroupsForApplicationResponse> {
        return .init(
            input: input,
            command: self.listAttributeGroupsForApplication,
            inputKey: \ListAttributeGroupsForApplicationRequest.nextToken,
            outputKey: \ListAttributeGroupsForApplicationResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }
}