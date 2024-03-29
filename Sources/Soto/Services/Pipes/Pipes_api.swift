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

/// Service object for interacting with AWS Pipes service.
///
/// Amazon EventBridge Pipes connects event sources to targets. Pipes reduces the need for specialized knowledge and integration code when developing  event driven architectures. This helps ensures consistency across your company’s applications. With Pipes, the target can be any available EventBridge target.  To set up a pipe, you select the event source, add optional event filtering, define optional enrichment, and select the target for the event data.
public struct Pipes: AWSService {
    // MARK: Member variables

    /// Client used for communication with AWS
    public let client: AWSClient
    /// Service configuration
    public let config: AWSServiceConfig

    // MARK: Initialization

    /// Initialize the Pipes client
    /// - parameters:
    ///     - client: AWSClient used to process requests
    ///     - region: Region of server you want to communicate with. This will override the partition parameter.
    ///     - partition: AWS partition where service resides, standard (.aws), china (.awscn), government (.awsusgov).
    ///     - endpoint: Custom endpoint URL to use instead of standard AWS servers
    ///     - timeout: Timeout value for HTTP requests
    public init(
        client: AWSClient,
        region: SotoCore.Region? = nil,
        partition: AWSPartition = .aws,
        endpoint: String? = nil,
        timeout: TimeAmount? = nil,
        byteBufferAllocator: ByteBufferAllocator = ByteBufferAllocator(),
        options: AWSServiceConfig.Options = []
    ) {
        self.client = client
        self.config = AWSServiceConfig(
            region: region,
            partition: region?.partition ?? partition,
            service: "pipes",
            serviceProtocol: .restjson,
            apiVersion: "2015-10-07",
            endpoint: endpoint,
            errorType: PipesErrorType.self,
            xmlNamespace: "http://events.amazonaws.com/doc/2015-10-07",
            timeout: timeout,
            byteBufferAllocator: byteBufferAllocator,
            options: options
        )
    }

    // MARK: API Calls

    /// Create a pipe. Amazon EventBridge Pipes connect event sources to targets and reduces the need for specialized knowledge and integration code.
    public func createPipe(_ input: CreatePipeRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<CreatePipeResponse> {
        return self.client.execute(operation: "CreatePipe", path: "/v1/pipes/{Name}", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Delete an existing pipe. For more information about pipes, see Amazon EventBridge Pipes in the Amazon EventBridge User Guide.
    public func deletePipe(_ input: DeletePipeRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<DeletePipeResponse> {
        return self.client.execute(operation: "DeletePipe", path: "/v1/pipes/{Name}", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Get the information about an existing pipe. For more information about pipes, see Amazon EventBridge Pipes in the Amazon EventBridge User Guide.
    public func describePipe(_ input: DescribePipeRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<DescribePipeResponse> {
        return self.client.execute(operation: "DescribePipe", path: "/v1/pipes/{Name}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Get the pipes associated with this account. For more information about pipes, see Amazon EventBridge Pipes in the Amazon EventBridge User Guide.
    public func listPipes(_ input: ListPipesRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<ListPipesResponse> {
        return self.client.execute(operation: "ListPipes", path: "/v1/pipes", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Displays the tags associated with a pipe.
    public func listTagsForResource(_ input: ListTagsForResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<ListTagsForResourceResponse> {
        return self.client.execute(operation: "ListTagsForResource", path: "/tags/{resourceArn}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Start an existing pipe.
    public func startPipe(_ input: StartPipeRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<StartPipeResponse> {
        return self.client.execute(operation: "StartPipe", path: "/v1/pipes/{Name}/start", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Stop an existing pipe.
    public func stopPipe(_ input: StopPipeRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<StopPipeResponse> {
        return self.client.execute(operation: "StopPipe", path: "/v1/pipes/{Name}/stop", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Assigns one or more tags (key-value pairs) to the specified pipe. Tags can help you organize and categorize your resources. You can also use them to scope user permissions by granting a user permission to access or change only resources with certain tag values. Tags don't have any semantic meaning to Amazon Web Services and are interpreted strictly as strings of characters. You can use the TagResource action with a pipe that already has tags. If you specify a new tag key, this tag is appended to the list of tags associated with the pipe. If you specify a tag key that is already associated with the pipe, the new tag value that you specify replaces the previous value for that tag. You can associate as many as 50 tags with a pipe.
    public func tagResource(_ input: TagResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<TagResourceResponse> {
        return self.client.execute(operation: "TagResource", path: "/tags/{resourceArn}", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Removes one or more tags from the specified pipes.
    public func untagResource(_ input: UntagResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<UntagResourceResponse> {
        return self.client.execute(operation: "UntagResource", path: "/tags/{resourceArn}", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Update an existing pipe. When you call UpdatePipe, only the fields that are included in the request are changed, the rest are unchanged.  The exception to this is if you modify any Amazon Web Services-service specific fields in the SourceParameters, EnrichmentParameters, or  TargetParameters objects. The fields in these objects are updated atomically as one and override existing values. This is by design and means that  if you don't specify an optional field in one of these Parameters objects, that field will be set to its system-default value after the update. For more information about pipes, see  Amazon EventBridge Pipes in the Amazon EventBridge User Guide.
    public func updatePipe(_ input: UpdatePipeRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<UpdatePipeResponse> {
        return self.client.execute(operation: "UpdatePipe", path: "/v1/pipes/{Name}", httpMethod: .PUT, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }
}

extension Pipes {
    /// Initializer required by `AWSService.with(middlewares:timeout:byteBufferAllocator:options)`. You are not able to use this initializer directly as there are no public
    /// initializers for `AWSServiceConfig.Patch`. Please use `AWSService.with(middlewares:timeout:byteBufferAllocator:options)` instead.
    public init(from: Pipes, patch: AWSServiceConfig.Patch) {
        self.client = from.client
        self.config = from.config.with(patch: patch)
    }
}

// MARK: Paginators

extension Pipes {
    /// Get the pipes associated with this account. For more information about pipes, see Amazon EventBridge Pipes in the Amazon EventBridge User Guide.
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
    public func listPipesPaginator<Result>(
        _ input: ListPipesRequest,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, ListPipesResponse, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return self.client.paginate(
            input: input,
            initialValue: initialValue,
            command: self.listPipes,
            inputKey: \ListPipesRequest.nextToken,
            outputKey: \ListPipesResponse.nextToken,
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
    public func listPipesPaginator(
        _ input: ListPipesRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (ListPipesResponse, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return self.client.paginate(
            input: input,
            command: self.listPipes,
            inputKey: \ListPipesRequest.nextToken,
            outputKey: \ListPipesResponse.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }
}

extension Pipes.ListPipesRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> Pipes.ListPipesRequest {
        return .init(
            currentState: self.currentState,
            desiredState: self.desiredState,
            limit: self.limit,
            namePrefix: self.namePrefix,
            nextToken: token,
            sourcePrefix: self.sourcePrefix,
            targetPrefix: self.targetPrefix
        )
    }
}
