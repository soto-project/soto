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
extension RAM {
    // MARK: Async API Calls

    /// Accepts an invitation to a resource share from another Amazon Web Services account. After you accept the invitation, the resources included in the resource share are available to interact with in the relevant Amazon Web Services Management Consoles and tools.
    public func acceptResourceShareInvitation(_ input: AcceptResourceShareInvitationRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> AcceptResourceShareInvitationResponse {
        return try await self.client.execute(operation: "AcceptResourceShareInvitation", path: "/acceptresourceshareinvitation", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Adds the specified list of principals and list of resources to a resource share. Principals that already have access to this resource share immediately receive access to the added resources. Newly added principals immediately receive access to the resources shared in this resource share.
    public func associateResourceShare(_ input: AssociateResourceShareRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> AssociateResourceShareResponse {
        return try await self.client.execute(operation: "AssociateResourceShare", path: "/associateresourceshare", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Adds or replaces the RAM permission for a resource type included in a resource share. You can have exactly one permission associated with each resource type in the resource share. You can add a new RAM permission only if there are currently no resources of that resource type currently in the resource share.
    public func associateResourceSharePermission(_ input: AssociateResourceSharePermissionRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> AssociateResourceSharePermissionResponse {
        return try await self.client.execute(operation: "AssociateResourceSharePermission", path: "/associateresourcesharepermission", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Creates a customer managed permission for a specified resource type that you can attach to resource shares. It is created in the Amazon Web Services Region in which you call the operation.
    public func createPermission(_ input: CreatePermissionRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CreatePermissionResponse {
        return try await self.client.execute(operation: "CreatePermission", path: "/createpermission", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Creates a new version of the specified customer managed permission. The new version is automatically set as the default version of the customer managed permission. New resource shares automatically use the default permission. Existing resource shares continue to use their original permission versions, but you can use ReplacePermissionAssociations to update them. If the specified customer managed permission already has the maximum of 5 versions, then you must delete one of the existing versions before you can create a new one.
    public func createPermissionVersion(_ input: CreatePermissionVersionRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CreatePermissionVersionResponse {
        return try await self.client.execute(operation: "CreatePermissionVersion", path: "/createpermissionversion", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Creates a resource share. You can provide a list of the Amazon Resource Names (ARNs) for the resources that you want to share, a list of principals you want to share the resources with, and the permissions to grant those principals.  Sharing a resource makes it available for use by principals outside of the Amazon Web Services account that created the resource. Sharing doesn't change any permissions or quotas that apply to the resource in the account that created it.
    public func createResourceShare(_ input: CreateResourceShareRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CreateResourceShareResponse {
        return try await self.client.execute(operation: "CreateResourceShare", path: "/createresourceshare", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Deletes the specified customer managed permission in the Amazon Web Services Region in which you call this operation. You can delete a customer managed permission only if it isn't attached to any resource share. The operation deletes all versions associated with the customer managed permission.
    public func deletePermission(_ input: DeletePermissionRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> DeletePermissionResponse {
        return try await self.client.execute(operation: "DeletePermission", path: "/deletepermission", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Deletes one version of a customer managed permission. The version you specify must not be attached to any resource share and must not be the default version for the permission. If a customer managed permission has the maximum of 5 versions, then you must delete at least one version before you can create another.
    public func deletePermissionVersion(_ input: DeletePermissionVersionRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> DeletePermissionVersionResponse {
        return try await self.client.execute(operation: "DeletePermissionVersion", path: "/deletepermissionversion", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Deletes the specified resource share.  This doesn't delete any of the resources that were associated with the resource share; it only stops the sharing of those resources through this resource share.
    public func deleteResourceShare(_ input: DeleteResourceShareRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> DeleteResourceShareResponse {
        return try await self.client.execute(operation: "DeleteResourceShare", path: "/deleteresourceshare", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Removes the specified principals or resources from participating in the specified resource share.
    public func disassociateResourceShare(_ input: DisassociateResourceShareRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> DisassociateResourceShareResponse {
        return try await self.client.execute(operation: "DisassociateResourceShare", path: "/disassociateresourceshare", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Removes a managed permission from a resource share. Permission changes take effect immediately. You can remove a managed permission from a resource share only if there are currently no resources of the relevant resource type currently attached to the resource share.
    public func disassociateResourceSharePermission(_ input: DisassociateResourceSharePermissionRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> DisassociateResourceSharePermissionResponse {
        return try await self.client.execute(operation: "DisassociateResourceSharePermission", path: "/disassociateresourcesharepermission", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Enables resource sharing within your organization in Organizations. This operation creates a service-linked role called AWSServiceRoleForResourceAccessManager that has the IAM managed policy named AWSResourceAccessManagerServiceRolePolicy attached. This role permits RAM to retrieve information about the organization and its structure. This lets you share resources with all of the accounts in the calling account's organization by specifying the organization ID, or all of the accounts in an organizational unit (OU) by specifying the OU ID. Until you enable sharing within the organization, you can specify only individual Amazon Web Services accounts, or for supported resource types, IAM roles and users. You must call this operation from an IAM role or user in the organization's management account.
    public func enableSharingWithAwsOrganization(_ input: EnableSharingWithAwsOrganizationRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> EnableSharingWithAwsOrganizationResponse {
        return try await self.client.execute(operation: "EnableSharingWithAwsOrganization", path: "/enablesharingwithawsorganization", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Retrieves the contents of a managed permission in JSON format.
    public func getPermission(_ input: GetPermissionRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetPermissionResponse {
        return try await self.client.execute(operation: "GetPermission", path: "/getpermission", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Retrieves the resource policies for the specified resources that you own and have shared.
    public func getResourcePolicies(_ input: GetResourcePoliciesRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetResourcePoliciesResponse {
        return try await self.client.execute(operation: "GetResourcePolicies", path: "/getresourcepolicies", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Retrieves the lists of resources and principals that associated for resource shares that you own.
    public func getResourceShareAssociations(_ input: GetResourceShareAssociationsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetResourceShareAssociationsResponse {
        return try await self.client.execute(operation: "GetResourceShareAssociations", path: "/getresourceshareassociations", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Retrieves details about invitations that you have received for resource shares.
    public func getResourceShareInvitations(_ input: GetResourceShareInvitationsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetResourceShareInvitationsResponse {
        return try await self.client.execute(operation: "GetResourceShareInvitations", path: "/getresourceshareinvitations", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Retrieves details about the resource shares that you own or that are shared with you.
    public func getResourceShares(_ input: GetResourceSharesRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetResourceSharesResponse {
        return try await self.client.execute(operation: "GetResourceShares", path: "/getresourceshares", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Lists the resources in a resource share that is shared with you but for which the invitation is still PENDING. That means that you haven't accepted or rejected the invitation and the invitation hasn't expired.
    public func listPendingInvitationResources(_ input: ListPendingInvitationResourcesRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListPendingInvitationResourcesResponse {
        return try await self.client.execute(operation: "ListPendingInvitationResources", path: "/listpendinginvitationresources", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Lists information about the managed permission and its associations to any resource shares that use this managed permission. This lets you see which resource shares use which versions of the specified managed permission.
    public func listPermissionAssociations(_ input: ListPermissionAssociationsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListPermissionAssociationsResponse {
        return try await self.client.execute(operation: "ListPermissionAssociations", path: "/listpermissionassociations", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Lists the available versions of the specified RAM permission.
    public func listPermissionVersions(_ input: ListPermissionVersionsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListPermissionVersionsResponse {
        return try await self.client.execute(operation: "ListPermissionVersions", path: "/listpermissionversions", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Retrieves a list of available RAM permissions that you can use for the supported resource types.
    public func listPermissions(_ input: ListPermissionsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListPermissionsResponse {
        return try await self.client.execute(operation: "ListPermissions", path: "/listpermissions", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Lists the principals that you are sharing resources with or that are sharing resources with you.
    public func listPrincipals(_ input: ListPrincipalsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListPrincipalsResponse {
        return try await self.client.execute(operation: "ListPrincipals", path: "/listprincipals", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Retrieves the current status of the asynchronous tasks performed by RAM when you perform the ReplacePermissionAssociationsWork operation.
    public func listReplacePermissionAssociationsWork(_ input: ListReplacePermissionAssociationsWorkRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListReplacePermissionAssociationsWorkResponse {
        return try await self.client.execute(operation: "ListReplacePermissionAssociationsWork", path: "/listreplacepermissionassociationswork", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Lists the RAM permissions that are associated with a resource share.
    public func listResourceSharePermissions(_ input: ListResourceSharePermissionsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListResourceSharePermissionsResponse {
        return try await self.client.execute(operation: "ListResourceSharePermissions", path: "/listresourcesharepermissions", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Lists the resource types that can be shared by RAM.
    public func listResourceTypes(_ input: ListResourceTypesRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListResourceTypesResponse {
        return try await self.client.execute(operation: "ListResourceTypes", path: "/listresourcetypes", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Lists the resources that you added to a resource share or the resources that are shared with you.
    public func listResources(_ input: ListResourcesRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListResourcesResponse {
        return try await self.client.execute(operation: "ListResources", path: "/listresources", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// When you attach a resource-based policy to a resource, RAM automatically creates a resource share of featureSet=CREATED_FROM_POLICY with a managed permission that has the same IAM permissions as the original resource-based policy. However, this type of managed permission is visible to only the resource share owner, and the associated resource share can't be modified by using RAM. This operation creates a separate, fully manageable customer managed permission that has the same IAM permissions as the original resource-based policy. You can associate this customer managed permission to any resource shares. Before you use PromoteResourceShareCreatedFromPolicy, you should first run this operation to ensure that you have an appropriate customer managed permission that can be associated with the promoted resource share.    The original CREATED_FROM_POLICY policy isn't deleted, and resource shares using that original policy aren't automatically updated.   You can't modify a CREATED_FROM_POLICY resource share so you can't associate the new customer managed permission by using ReplacePermsissionAssociations. However, if you use PromoteResourceShareCreatedFromPolicy, that operation automatically associates the fully manageable customer managed permission to the newly promoted STANDARD resource share.   After you promote a resource share, if the original CREATED_FROM_POLICY managed permission has no other associations to A resource share, then RAM automatically deletes it.
    public func promotePermissionCreatedFromPolicy(_ input: PromotePermissionCreatedFromPolicyRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> PromotePermissionCreatedFromPolicyResponse {
        return try await self.client.execute(operation: "PromotePermissionCreatedFromPolicy", path: "/promotepermissioncreatedfrompolicy", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// When you attach a resource-based policy to a resource, RAM automatically creates a resource share of featureSet=CREATED_FROM_POLICY with a managed permission that has the same IAM permissions as the original resource-based policy. However, this type of managed permission is visible to only the resource share owner, and the associated resource share can't be modified by using RAM. This operation promotes the resource share to a STANDARD resource share that is fully manageable in RAM. When you promote a resource share, you can then manage the resource share in RAM and it becomes visible to all of the principals you shared it with.  Before you perform this operation, you should first run PromotePermissionCreatedFromPolicyto ensure that you have an appropriate customer managed permission that can be associated with this resource share after its is promoted. If this operation can't find a managed permission that exactly matches the existing CREATED_FROM_POLICY permission, then this operation fails.
    public func promoteResourceShareCreatedFromPolicy(_ input: PromoteResourceShareCreatedFromPolicyRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> PromoteResourceShareCreatedFromPolicyResponse {
        return try await self.client.execute(operation: "PromoteResourceShareCreatedFromPolicy", path: "/promoteresourcesharecreatedfrompolicy", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Rejects an invitation to a resource share from another Amazon Web Services account.
    public func rejectResourceShareInvitation(_ input: RejectResourceShareInvitationRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> RejectResourceShareInvitationResponse {
        return try await self.client.execute(operation: "RejectResourceShareInvitation", path: "/rejectresourceshareinvitation", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Updates all resource shares that use a managed permission to a different managed permission. This operation always applies the default version of the target managed permission. You can optionally specify that the update applies to only resource shares that currently use a specified version. This enables you to update to the latest version, without changing the which managed permission is used. You can use this operation to update all of your resource shares to use the current default version of the permission by specifying the same value for the fromPermissionArn and toPermissionArn parameters. You can use the optional fromPermissionVersion parameter to update only those resources that use a specified version of the managed permission to the new managed permission.  To successfully perform this operation, you must have permission to update the resource-based policy on all affected resource types.
    public func replacePermissionAssociations(_ input: ReplacePermissionAssociationsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ReplacePermissionAssociationsResponse {
        return try await self.client.execute(operation: "ReplacePermissionAssociations", path: "/replacepermissionassociations", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Designates the specified version number as the default version for the specified customer managed permission. New resource shares automatically use this new default permission. Existing resource shares continue to use their original permission version, but you can use ReplacePermissionAssociations to update them.
    public func setDefaultPermissionVersion(_ input: SetDefaultPermissionVersionRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> SetDefaultPermissionVersionResponse {
        return try await self.client.execute(operation: "SetDefaultPermissionVersion", path: "/setdefaultpermissionversion", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Adds the specified tag keys and values to a resource share or managed permission. If you choose a resource share, the tags are attached to only the resource share, not to the resources that are in the resource share. The tags on a managed permission are the same for all versions of the managed permission.
    public func tagResource(_ input: TagResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> TagResourceResponse {
        return try await self.client.execute(operation: "TagResource", path: "/tagresource", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Removes the specified tag key and value pairs from the specified resource share or managed permission.
    public func untagResource(_ input: UntagResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> UntagResourceResponse {
        return try await self.client.execute(operation: "UntagResource", path: "/untagresource", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Modifies some of the properties of the specified resource share.
    public func updateResourceShare(_ input: UpdateResourceShareRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> UpdateResourceShareResponse {
        return try await self.client.execute(operation: "UpdateResourceShare", path: "/updateresourceshare", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }
}

// MARK: Paginators

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension RAM {
    /// Retrieves the resource policies for the specified resources that you own and have shared.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func getResourcePoliciesPaginator(
        _ input: GetResourcePoliciesRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<GetResourcePoliciesRequest, GetResourcePoliciesResponse> {
        return .init(
            input: input,
            command: self.getResourcePolicies,
            inputKey: \GetResourcePoliciesRequest.nextToken,
            outputKey: \GetResourcePoliciesResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Retrieves the lists of resources and principals that associated for resource shares that you own.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func getResourceShareAssociationsPaginator(
        _ input: GetResourceShareAssociationsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<GetResourceShareAssociationsRequest, GetResourceShareAssociationsResponse> {
        return .init(
            input: input,
            command: self.getResourceShareAssociations,
            inputKey: \GetResourceShareAssociationsRequest.nextToken,
            outputKey: \GetResourceShareAssociationsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Retrieves details about invitations that you have received for resource shares.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func getResourceShareInvitationsPaginator(
        _ input: GetResourceShareInvitationsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<GetResourceShareInvitationsRequest, GetResourceShareInvitationsResponse> {
        return .init(
            input: input,
            command: self.getResourceShareInvitations,
            inputKey: \GetResourceShareInvitationsRequest.nextToken,
            outputKey: \GetResourceShareInvitationsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Retrieves details about the resource shares that you own or that are shared with you.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func getResourceSharesPaginator(
        _ input: GetResourceSharesRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<GetResourceSharesRequest, GetResourceSharesResponse> {
        return .init(
            input: input,
            command: self.getResourceShares,
            inputKey: \GetResourceSharesRequest.nextToken,
            outputKey: \GetResourceSharesResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Lists the resources in a resource share that is shared with you but for which the invitation is still PENDING. That means that you haven't accepted or rejected the invitation and the invitation hasn't expired.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listPendingInvitationResourcesPaginator(
        _ input: ListPendingInvitationResourcesRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListPendingInvitationResourcesRequest, ListPendingInvitationResourcesResponse> {
        return .init(
            input: input,
            command: self.listPendingInvitationResources,
            inputKey: \ListPendingInvitationResourcesRequest.nextToken,
            outputKey: \ListPendingInvitationResourcesResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Lists information about the managed permission and its associations to any resource shares that use this managed permission. This lets you see which resource shares use which versions of the specified managed permission.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listPermissionAssociationsPaginator(
        _ input: ListPermissionAssociationsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListPermissionAssociationsRequest, ListPermissionAssociationsResponse> {
        return .init(
            input: input,
            command: self.listPermissionAssociations,
            inputKey: \ListPermissionAssociationsRequest.nextToken,
            outputKey: \ListPermissionAssociationsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Lists the available versions of the specified RAM permission.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listPermissionVersionsPaginator(
        _ input: ListPermissionVersionsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListPermissionVersionsRequest, ListPermissionVersionsResponse> {
        return .init(
            input: input,
            command: self.listPermissionVersions,
            inputKey: \ListPermissionVersionsRequest.nextToken,
            outputKey: \ListPermissionVersionsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Retrieves a list of available RAM permissions that you can use for the supported resource types.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listPermissionsPaginator(
        _ input: ListPermissionsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListPermissionsRequest, ListPermissionsResponse> {
        return .init(
            input: input,
            command: self.listPermissions,
            inputKey: \ListPermissionsRequest.nextToken,
            outputKey: \ListPermissionsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Lists the principals that you are sharing resources with or that are sharing resources with you.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listPrincipalsPaginator(
        _ input: ListPrincipalsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListPrincipalsRequest, ListPrincipalsResponse> {
        return .init(
            input: input,
            command: self.listPrincipals,
            inputKey: \ListPrincipalsRequest.nextToken,
            outputKey: \ListPrincipalsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Retrieves the current status of the asynchronous tasks performed by RAM when you perform the ReplacePermissionAssociationsWork operation.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listReplacePermissionAssociationsWorkPaginator(
        _ input: ListReplacePermissionAssociationsWorkRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListReplacePermissionAssociationsWorkRequest, ListReplacePermissionAssociationsWorkResponse> {
        return .init(
            input: input,
            command: self.listReplacePermissionAssociationsWork,
            inputKey: \ListReplacePermissionAssociationsWorkRequest.nextToken,
            outputKey: \ListReplacePermissionAssociationsWorkResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Lists the RAM permissions that are associated with a resource share.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listResourceSharePermissionsPaginator(
        _ input: ListResourceSharePermissionsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListResourceSharePermissionsRequest, ListResourceSharePermissionsResponse> {
        return .init(
            input: input,
            command: self.listResourceSharePermissions,
            inputKey: \ListResourceSharePermissionsRequest.nextToken,
            outputKey: \ListResourceSharePermissionsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Lists the resource types that can be shared by RAM.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listResourceTypesPaginator(
        _ input: ListResourceTypesRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListResourceTypesRequest, ListResourceTypesResponse> {
        return .init(
            input: input,
            command: self.listResourceTypes,
            inputKey: \ListResourceTypesRequest.nextToken,
            outputKey: \ListResourceTypesResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Lists the resources that you added to a resource share or the resources that are shared with you.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listResourcesPaginator(
        _ input: ListResourcesRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListResourcesRequest, ListResourcesResponse> {
        return .init(
            input: input,
            command: self.listResources,
            inputKey: \ListResourcesRequest.nextToken,
            outputKey: \ListResourcesResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }
}
