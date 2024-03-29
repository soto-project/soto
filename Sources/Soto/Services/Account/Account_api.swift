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

@_exported import SotoCore

/// Service object for interacting with AWS Account service.
///
/// Operations for Amazon Web Services Account Management
public struct Account: AWSService {
    // MARK: Member variables

    /// Client used for communication with AWS
    public let client: AWSClient
    /// Service configuration
    public let config: AWSServiceConfig

    // MARK: Initialization

    /// Initialize the Account client
    /// - parameters:
    ///     - client: AWSClient used to process requests
    ///     - partition: AWS partition where service resides, standard (.aws), china (.awscn), government (.awsusgov).
    ///     - endpoint: Custom endpoint URL to use instead of standard AWS servers
    ///     - timeout: Timeout value for HTTP requests
    public init(
        client: AWSClient,
        partition: AWSPartition = .aws,
        endpoint: String? = nil,
        timeout: TimeAmount? = nil,
        byteBufferAllocator: ByteBufferAllocator = ByteBufferAllocator(),
        options: AWSServiceConfig.Options = []
    ) {
        self.client = client
        self.config = AWSServiceConfig(
            region: nil,
            partition: partition,
            service: "account",
            serviceProtocol: .restjson,
            apiVersion: "2021-02-01",
            endpoint: endpoint,
            serviceEndpoints: [
                "aws-cn-global": "account.cn-northwest-1.amazonaws.com.cn",
                "aws-global": "account.us-east-1.amazonaws.com"
            ],
            partitionEndpoints: [
                .aws: (endpoint: "aws-global", region: .useast1),
                .awscn: (endpoint: "aws-cn-global", region: .cnnorthwest1)
            ],
            errorType: AccountErrorType.self,
            timeout: timeout,
            byteBufferAllocator: byteBufferAllocator,
            options: options
        )
    }

    // MARK: API Calls

    /// Deletes the specified alternate contact from an Amazon Web Services account. For complete details about how to use the alternate contact operations, see Access or updating the alternate contacts.  Before you can update the alternate contact information for an  Amazon Web Services account that is managed by Organizations, you must first enable integration between Amazon Web Services Account Management and Organizations.  For more information, see Enabling trusted access for  Amazon Web Services Account Management.
    @discardableResult public func deleteAlternateContact(_ input: DeleteAlternateContactRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<Void> {
        return self.client.execute(operation: "DeleteAlternateContact", path: "/deleteAlternateContact", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Disables (opts-out) a particular Region for an account.
    @discardableResult public func disableRegion(_ input: DisableRegionRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<Void> {
        return self.client.execute(operation: "DisableRegion", path: "/disableRegion", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Enables (opts-in) a particular Region for an account.
    @discardableResult public func enableRegion(_ input: EnableRegionRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<Void> {
        return self.client.execute(operation: "EnableRegion", path: "/enableRegion", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Retrieves the specified alternate contact attached to an Amazon Web Services account. For complete details about how to use the alternate contact operations, see Access or updating the alternate contacts.  Before you can update the alternate contact information for an  Amazon Web Services account that is managed by Organizations, you must first enable integration between Amazon Web Services Account Management and Organizations.  For more information, see Enabling trusted access for  Amazon Web Services Account Management.
    public func getAlternateContact(_ input: GetAlternateContactRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<GetAlternateContactResponse> {
        return self.client.execute(operation: "GetAlternateContact", path: "/getAlternateContact", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Retrieves the primary contact information of an Amazon Web Services account. For complete details about how to use the primary contact operations, see Update the primary and alternate contact information.
    public func getContactInformation(_ input: GetContactInformationRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<GetContactInformationResponse> {
        return self.client.execute(operation: "GetContactInformation", path: "/getContactInformation", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Retrieves the opt-in status of a particular Region.
    public func getRegionOptStatus(_ input: GetRegionOptStatusRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<GetRegionOptStatusResponse> {
        return self.client.execute(operation: "GetRegionOptStatus", path: "/getRegionOptStatus", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Lists all the Regions for a given account and their respective opt-in statuses. Optionally, this list can be filtered by the region-opt-status-contains parameter.
    public func listRegions(_ input: ListRegionsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<ListRegionsResponse> {
        return self.client.execute(operation: "ListRegions", path: "/listRegions", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Modifies the specified alternate contact attached to an Amazon Web Services account. For complete details about how to use the alternate contact operations, see Access or updating the alternate contacts.  Before you can update the alternate contact information for an  Amazon Web Services account that is managed by Organizations, you must first enable integration between Amazon Web Services Account Management and Organizations.  For more information, see Enabling trusted access for  Amazon Web Services Account Management.
    @discardableResult public func putAlternateContact(_ input: PutAlternateContactRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<Void> {
        return self.client.execute(operation: "PutAlternateContact", path: "/putAlternateContact", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Updates the primary contact information of an Amazon Web Services account. For complete details about how to use the primary contact operations, see Update the primary and alternate contact information.
    @discardableResult public func putContactInformation(_ input: PutContactInformationRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<Void> {
        return self.client.execute(operation: "PutContactInformation", path: "/putContactInformation", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }
}

extension Account {
    /// Initializer required by `AWSService.with(middlewares:timeout:byteBufferAllocator:options)`. You are not able to use this initializer directly as there are no public
    /// initializers for `AWSServiceConfig.Patch`. Please use `AWSService.with(middlewares:timeout:byteBufferAllocator:options)` instead.
    public init(from: Account, patch: AWSServiceConfig.Patch) {
        self.client = from.client
        self.config = from.config.with(patch: patch)
    }
}

// MARK: Paginators

extension Account {
    /// Lists all the Regions for a given account and their respective opt-in statuses. Optionally, this list can be filtered by the region-opt-status-contains parameter.
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
    public func listRegionsPaginator<Result>(
        _ input: ListRegionsRequest,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, ListRegionsResponse, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return self.client.paginate(
            input: input,
            initialValue: initialValue,
            command: self.listRegions,
            inputKey: \ListRegionsRequest.nextToken,
            outputKey: \ListRegionsResponse.nextToken,
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
    public func listRegionsPaginator(
        _ input: ListRegionsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (ListRegionsResponse, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return self.client.paginate(
            input: input,
            command: self.listRegions,
            inputKey: \ListRegionsRequest.nextToken,
            outputKey: \ListRegionsResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }
}

extension Account.ListRegionsRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> Account.ListRegionsRequest {
        return .init(
            accountId: self.accountId,
            maxResults: self.maxResults,
            nextToken: token,
            regionOptStatusContains: self.regionOptStatusContains
        )
    }
}
