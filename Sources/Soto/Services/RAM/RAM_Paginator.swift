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

// MARK: Paginators

extension RAM {
    ///  Gets the policies for the specified resources that you own and have shared.
    ///
    /// Provide paginated results to closure `onPage` for it to combine them into one result.
    /// This works in a similar manner to `Array.reduce<Result>(_:_:) -> Result`.
    ///
    /// Parameters:
    ///   - input: Input for request
    ///   - initialValue: The value to use as the initial accumulating value. `initialValue` is passed to `onPage` the first time it is called.
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    ///   - onPage: closure called with each paginated response. It combines an accumulating result with the contents of response. This combined result is then returned
    ///         along with a boolean indicating if the paginate operation should continue.
    public func getResourcePoliciesPaginator<Result>(
        _ input: GetResourcePoliciesRequest,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, GetResourcePoliciesResponse, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: getResourcePolicies,
            tokenKey: \GetResourcePoliciesResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    /// Provide paginated results to closure `onPage`.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    ///   - onPage: closure called with each block of entries. Returns boolean indicating whether we should continue.
    public func getResourcePoliciesPaginator(
        _ input: GetResourcePoliciesRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (GetResourcePoliciesResponse, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: getResourcePolicies,
            tokenKey: \GetResourcePoliciesResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///  Gets the resources or principals for the resource shares that you own.
    ///
    /// Provide paginated results to closure `onPage` for it to combine them into one result.
    /// This works in a similar manner to `Array.reduce<Result>(_:_:) -> Result`.
    ///
    /// Parameters:
    ///   - input: Input for request
    ///   - initialValue: The value to use as the initial accumulating value. `initialValue` is passed to `onPage` the first time it is called.
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    ///   - onPage: closure called with each paginated response. It combines an accumulating result with the contents of response. This combined result is then returned
    ///         along with a boolean indicating if the paginate operation should continue.
    public func getResourceShareAssociationsPaginator<Result>(
        _ input: GetResourceShareAssociationsRequest,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, GetResourceShareAssociationsResponse, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: getResourceShareAssociations,
            tokenKey: \GetResourceShareAssociationsResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    /// Provide paginated results to closure `onPage`.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    ///   - onPage: closure called with each block of entries. Returns boolean indicating whether we should continue.
    public func getResourceShareAssociationsPaginator(
        _ input: GetResourceShareAssociationsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (GetResourceShareAssociationsResponse, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: getResourceShareAssociations,
            tokenKey: \GetResourceShareAssociationsResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///  Gets the invitations for resource sharing that you've received.
    ///
    /// Provide paginated results to closure `onPage` for it to combine them into one result.
    /// This works in a similar manner to `Array.reduce<Result>(_:_:) -> Result`.
    ///
    /// Parameters:
    ///   - input: Input for request
    ///   - initialValue: The value to use as the initial accumulating value. `initialValue` is passed to `onPage` the first time it is called.
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    ///   - onPage: closure called with each paginated response. It combines an accumulating result with the contents of response. This combined result is then returned
    ///         along with a boolean indicating if the paginate operation should continue.
    public func getResourceShareInvitationsPaginator<Result>(
        _ input: GetResourceShareInvitationsRequest,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, GetResourceShareInvitationsResponse, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: getResourceShareInvitations,
            tokenKey: \GetResourceShareInvitationsResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    /// Provide paginated results to closure `onPage`.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    ///   - onPage: closure called with each block of entries. Returns boolean indicating whether we should continue.
    public func getResourceShareInvitationsPaginator(
        _ input: GetResourceShareInvitationsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (GetResourceShareInvitationsResponse, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: getResourceShareInvitations,
            tokenKey: \GetResourceShareInvitationsResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///  Gets the resource shares that you own or the resource shares that are shared with you.
    ///
    /// Provide paginated results to closure `onPage` for it to combine them into one result.
    /// This works in a similar manner to `Array.reduce<Result>(_:_:) -> Result`.
    ///
    /// Parameters:
    ///   - input: Input for request
    ///   - initialValue: The value to use as the initial accumulating value. `initialValue` is passed to `onPage` the first time it is called.
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    ///   - onPage: closure called with each paginated response. It combines an accumulating result with the contents of response. This combined result is then returned
    ///         along with a boolean indicating if the paginate operation should continue.
    public func getResourceSharesPaginator<Result>(
        _ input: GetResourceSharesRequest,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, GetResourceSharesResponse, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: getResourceShares,
            tokenKey: \GetResourceSharesResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    /// Provide paginated results to closure `onPage`.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    ///   - onPage: closure called with each block of entries. Returns boolean indicating whether we should continue.
    public func getResourceSharesPaginator(
        _ input: GetResourceSharesRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (GetResourceSharesResponse, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: getResourceShares,
            tokenKey: \GetResourceSharesResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///  Lists the resources in a resource share that is shared with you but that the invitation is still pending for.
    ///
    /// Provide paginated results to closure `onPage` for it to combine them into one result.
    /// This works in a similar manner to `Array.reduce<Result>(_:_:) -> Result`.
    ///
    /// Parameters:
    ///   - input: Input for request
    ///   - initialValue: The value to use as the initial accumulating value. `initialValue` is passed to `onPage` the first time it is called.
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    ///   - onPage: closure called with each paginated response. It combines an accumulating result with the contents of response. This combined result is then returned
    ///         along with a boolean indicating if the paginate operation should continue.
    public func listPendingInvitationResourcesPaginator<Result>(
        _ input: ListPendingInvitationResourcesRequest,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, ListPendingInvitationResourcesResponse, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: listPendingInvitationResources,
            tokenKey: \ListPendingInvitationResourcesResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    /// Provide paginated results to closure `onPage`.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    ///   - onPage: closure called with each block of entries. Returns boolean indicating whether we should continue.
    public func listPendingInvitationResourcesPaginator(
        _ input: ListPendingInvitationResourcesRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (ListPendingInvitationResourcesResponse, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listPendingInvitationResources,
            tokenKey: \ListPendingInvitationResourcesResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///  Lists the principals that you have shared resources with or that have shared resources with you.
    ///
    /// Provide paginated results to closure `onPage` for it to combine them into one result.
    /// This works in a similar manner to `Array.reduce<Result>(_:_:) -> Result`.
    ///
    /// Parameters:
    ///   - input: Input for request
    ///   - initialValue: The value to use as the initial accumulating value. `initialValue` is passed to `onPage` the first time it is called.
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    ///   - onPage: closure called with each paginated response. It combines an accumulating result with the contents of response. This combined result is then returned
    ///         along with a boolean indicating if the paginate operation should continue.
    public func listPrincipalsPaginator<Result>(
        _ input: ListPrincipalsRequest,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, ListPrincipalsResponse, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: listPrincipals,
            tokenKey: \ListPrincipalsResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    /// Provide paginated results to closure `onPage`.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    ///   - onPage: closure called with each block of entries. Returns boolean indicating whether we should continue.
    public func listPrincipalsPaginator(
        _ input: ListPrincipalsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (ListPrincipalsResponse, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listPrincipals,
            tokenKey: \ListPrincipalsResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///  Lists the resources that you added to a resource shares or the resources that are shared with you.
    ///
    /// Provide paginated results to closure `onPage` for it to combine them into one result.
    /// This works in a similar manner to `Array.reduce<Result>(_:_:) -> Result`.
    ///
    /// Parameters:
    ///   - input: Input for request
    ///   - initialValue: The value to use as the initial accumulating value. `initialValue` is passed to `onPage` the first time it is called.
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    ///   - onPage: closure called with each paginated response. It combines an accumulating result with the contents of response. This combined result is then returned
    ///         along with a boolean indicating if the paginate operation should continue.
    public func listResourcesPaginator<Result>(
        _ input: ListResourcesRequest,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, ListResourcesResponse, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: listResources,
            tokenKey: \ListResourcesResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    /// Provide paginated results to closure `onPage`.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    ///   - onPage: closure called with each block of entries. Returns boolean indicating whether we should continue.
    public func listResourcesPaginator(
        _ input: ListResourcesRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
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
}

extension RAM.GetResourcePoliciesRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> RAM.GetResourcePoliciesRequest {
        return .init(
            maxResults: self.maxResults,
            nextToken: token,
            principal: self.principal,
            resourceArns: self.resourceArns
        )
    }
}

extension RAM.GetResourceShareAssociationsRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> RAM.GetResourceShareAssociationsRequest {
        return .init(
            associationStatus: self.associationStatus,
            associationType: self.associationType,
            maxResults: self.maxResults,
            nextToken: token,
            principal: self.principal,
            resourceArn: self.resourceArn,
            resourceShareArns: self.resourceShareArns
        )
    }
}

extension RAM.GetResourceShareInvitationsRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> RAM.GetResourceShareInvitationsRequest {
        return .init(
            maxResults: self.maxResults,
            nextToken: token,
            resourceShareArns: self.resourceShareArns,
            resourceShareInvitationArns: self.resourceShareInvitationArns
        )
    }
}

extension RAM.GetResourceSharesRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> RAM.GetResourceSharesRequest {
        return .init(
            maxResults: self.maxResults,
            name: self.name,
            nextToken: token,
            resourceOwner: self.resourceOwner,
            resourceShareArns: self.resourceShareArns,
            resourceShareStatus: self.resourceShareStatus,
            tagFilters: self.tagFilters
        )
    }
}

extension RAM.ListPendingInvitationResourcesRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> RAM.ListPendingInvitationResourcesRequest {
        return .init(
            maxResults: self.maxResults,
            nextToken: token,
            resourceShareInvitationArn: self.resourceShareInvitationArn
        )
    }
}

extension RAM.ListPrincipalsRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> RAM.ListPrincipalsRequest {
        return .init(
            maxResults: self.maxResults,
            nextToken: token,
            principals: self.principals,
            resourceArn: self.resourceArn,
            resourceOwner: self.resourceOwner,
            resourceShareArns: self.resourceShareArns,
            resourceType: self.resourceType
        )
    }
}

extension RAM.ListResourcesRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> RAM.ListResourcesRequest {
        return .init(
            maxResults: self.maxResults,
            nextToken: token,
            principal: self.principal,
            resourceArns: self.resourceArns,
            resourceOwner: self.resourceOwner,
            resourceShareArns: self.resourceShareArns,
            resourceType: self.resourceType
        )
    }
}