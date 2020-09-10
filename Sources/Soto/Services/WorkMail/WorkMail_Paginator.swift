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

// THIS FILE IS AUTOMATICALLY GENERATED by https://github.com/soto-project/soto/blob/main/CodeGenerator/Sources/CodeGenerator/main.swift. DO NOT EDIT.

import SotoCore

// MARK: Paginators

extension WorkMail {

    ///  Creates a paginated call to list the aliases associated with a given entity.
    public func listAliasesPaginator(
        _ input: ListAliasesRequest,
        on eventLoop: EventLoop? = nil,
        logger: Logger = AWSClient.loggingDisabled,
        onPage: @escaping (ListAliasesResponse, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listAliases,
            tokenKey: \ListAliasesResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///  Returns an overview of the members of a group. Users and groups can be members of a group.
    public func listGroupMembersPaginator(
        _ input: ListGroupMembersRequest,
        on eventLoop: EventLoop? = nil,
        logger: Logger = AWSClient.loggingDisabled,
        onPage: @escaping (ListGroupMembersResponse, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listGroupMembers,
            tokenKey: \ListGroupMembersResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///  Returns summaries of the organization's groups.
    public func listGroupsPaginator(
        _ input: ListGroupsRequest,
        on eventLoop: EventLoop? = nil,
        logger: Logger = AWSClient.loggingDisabled,
        onPage: @escaping (ListGroupsResponse, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listGroups,
            tokenKey: \ListGroupsResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///  Lists the mailbox permissions associated with a user, group, or resource mailbox.
    public func listMailboxPermissionsPaginator(
        _ input: ListMailboxPermissionsRequest,
        on eventLoop: EventLoop? = nil,
        logger: Logger = AWSClient.loggingDisabled,
        onPage: @escaping (ListMailboxPermissionsResponse, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listMailboxPermissions,
            tokenKey: \ListMailboxPermissionsResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///  Returns summaries of the customer's organizations.
    public func listOrganizationsPaginator(
        _ input: ListOrganizationsRequest,
        on eventLoop: EventLoop? = nil,
        logger: Logger = AWSClient.loggingDisabled,
        onPage: @escaping (ListOrganizationsResponse, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listOrganizations,
            tokenKey: \ListOrganizationsResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///  Lists the delegates associated with a resource. Users and groups can be resource delegates and answer requests on behalf of the resource.
    public func listResourceDelegatesPaginator(
        _ input: ListResourceDelegatesRequest,
        on eventLoop: EventLoop? = nil,
        logger: Logger = AWSClient.loggingDisabled,
        onPage: @escaping (ListResourceDelegatesResponse, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listResourceDelegates,
            tokenKey: \ListResourceDelegatesResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///  Returns summaries of the organization's resources.
    public func listResourcesPaginator(
        _ input: ListResourcesRequest,
        on eventLoop: EventLoop? = nil,
        logger: Logger = AWSClient.loggingDisabled,
        onPage: @escaping (ListResourcesResponse, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listResources,
            tokenKey: \ListResourcesResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///  Returns summaries of the organization's users.
    public func listUsersPaginator(
        _ input: ListUsersRequest,
        on eventLoop: EventLoop? = nil,
        logger: Logger = AWSClient.loggingDisabled,
        onPage: @escaping (ListUsersResponse, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listUsers,
            tokenKey: \ListUsersResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

}

extension WorkMail.ListAliasesRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> WorkMail.ListAliasesRequest {
        return .init(
            entityId: self.entityId,
            maxResults: self.maxResults,
            nextToken: token,
            organizationId: self.organizationId
        )

    }
}

extension WorkMail.ListGroupMembersRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> WorkMail.ListGroupMembersRequest {
        return .init(
            groupId: self.groupId,
            maxResults: self.maxResults,
            nextToken: token,
            organizationId: self.organizationId
        )

    }
}

extension WorkMail.ListGroupsRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> WorkMail.ListGroupsRequest {
        return .init(
            maxResults: self.maxResults,
            nextToken: token,
            organizationId: self.organizationId
        )

    }
}

extension WorkMail.ListMailboxPermissionsRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> WorkMail.ListMailboxPermissionsRequest {
        return .init(
            entityId: self.entityId,
            maxResults: self.maxResults,
            nextToken: token,
            organizationId: self.organizationId
        )

    }
}

extension WorkMail.ListOrganizationsRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> WorkMail.ListOrganizationsRequest {
        return .init(
            maxResults: self.maxResults,
            nextToken: token
        )

    }
}

extension WorkMail.ListResourceDelegatesRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> WorkMail.ListResourceDelegatesRequest {
        return .init(
            maxResults: self.maxResults,
            nextToken: token,
            organizationId: self.organizationId,
            resourceId: self.resourceId
        )

    }
}

extension WorkMail.ListResourcesRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> WorkMail.ListResourcesRequest {
        return .init(
            maxResults: self.maxResults,
            nextToken: token,
            organizationId: self.organizationId
        )

    }
}

extension WorkMail.ListUsersRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> WorkMail.ListUsersRequest {
        return .init(
            maxResults: self.maxResults,
            nextToken: token,
            organizationId: self.organizationId
        )

    }
}
