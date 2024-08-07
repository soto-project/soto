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

@_exported import SotoCore

/// Service object for interacting with AWS NeptuneGraph service.
///
/// Neptune Analytics is a new analytics database engine for Amazon Neptune that helps customers get to  insights faster by quickly processing large amounts of graph data, invoking popular graph analytic  algorithms in low-latency queries, and getting analytics results in seconds.
public struct NeptuneGraph: AWSService {
    // MARK: Member variables

    /// Client used for communication with AWS
    public let client: AWSClient
    /// Service configuration
    public let config: AWSServiceConfig

    // MARK: Initialization

    /// Initialize the NeptuneGraph client
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
            serviceName: "NeptuneGraph",
            serviceIdentifier: "neptune-graph",
            serviceProtocol: .restjson,
            apiVersion: "2023-11-29",
            endpoint: endpoint,
            errorType: NeptuneGraphErrorType.self,
            middleware: middleware,
            timeout: timeout,
            byteBufferAllocator: byteBufferAllocator,
            options: options
        )
    }





    // MARK: API Calls

    /// Deletes the specified import task.
    @Sendable
    public func cancelImportTask(_ input: CancelImportTaskInput, logger: Logger = AWSClient.loggingDisabled) async throws -> CancelImportTaskOutput {
        return try await self.client.execute(
            operation: "CancelImportTask", 
            path: "/importtasks/{taskIdentifier}", 
            httpMethod: .DELETE, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Cancels a specified query.
    @Sendable
    public func cancelQuery(_ input: CancelQueryInput, logger: Logger = AWSClient.loggingDisabled) async throws {
        return try await self.client.execute(
            operation: "CancelQuery", 
            path: "/queries/{queryId}", 
            httpMethod: .DELETE, 
            serviceConfig: self.config, 
            input: input, 
            hostPrefix: "{graphIdentifier}.", 
            logger: logger
        )
    }

    /// Creates a new Neptune Analytics graph.
    @Sendable
    public func createGraph(_ input: CreateGraphInput, logger: Logger = AWSClient.loggingDisabled) async throws -> CreateGraphOutput {
        return try await self.client.execute(
            operation: "CreateGraph", 
            path: "/graphs", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Creates a snapshot of the specific graph.
    @Sendable
    public func createGraphSnapshot(_ input: CreateGraphSnapshotInput, logger: Logger = AWSClient.loggingDisabled) async throws -> CreateGraphSnapshotOutput {
        return try await self.client.execute(
            operation: "CreateGraphSnapshot", 
            path: "/snapshots", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Creates a new Neptune Analytics graph and imports data into it, either from Amazon Simple Storage Service (S3) or from a Neptune database or a Neptune database snapshot. The data can be loaded from files in S3 that in either the Gremlin CSV format or the openCypher load format.
    @Sendable
    public func createGraphUsingImportTask(_ input: CreateGraphUsingImportTaskInput, logger: Logger = AWSClient.loggingDisabled) async throws -> CreateGraphUsingImportTaskOutput {
        return try await self.client.execute(
            operation: "CreateGraphUsingImportTask", 
            path: "/importtasks", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Create a private graph endpoint to allow private access from to the graph from within a VPC. You can attach security groups to the private graph endpoint.  VPC endpoint charges apply.
    @Sendable
    public func createPrivateGraphEndpoint(_ input: CreatePrivateGraphEndpointInput, logger: Logger = AWSClient.loggingDisabled) async throws -> CreatePrivateGraphEndpointOutput {
        return try await self.client.execute(
            operation: "CreatePrivateGraphEndpoint", 
            path: "/graphs/{graphIdentifier}/endpoints/", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Deletes the specified graph. Graphs cannot be deleted if delete-protection is enabled.
    @Sendable
    public func deleteGraph(_ input: DeleteGraphInput, logger: Logger = AWSClient.loggingDisabled) async throws -> DeleteGraphOutput {
        return try await self.client.execute(
            operation: "DeleteGraph", 
            path: "/graphs/{graphIdentifier}", 
            httpMethod: .DELETE, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Deletes the specifed graph snapshot.
    @Sendable
    public func deleteGraphSnapshot(_ input: DeleteGraphSnapshotInput, logger: Logger = AWSClient.loggingDisabled) async throws -> DeleteGraphSnapshotOutput {
        return try await self.client.execute(
            operation: "DeleteGraphSnapshot", 
            path: "/snapshots/{snapshotIdentifier}", 
            httpMethod: .DELETE, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Deletes a private graph endpoint.
    @Sendable
    public func deletePrivateGraphEndpoint(_ input: DeletePrivateGraphEndpointInput, logger: Logger = AWSClient.loggingDisabled) async throws -> DeletePrivateGraphEndpointOutput {
        return try await self.client.execute(
            operation: "DeletePrivateGraphEndpoint", 
            path: "/graphs/{graphIdentifier}/endpoints/{vpcId}", 
            httpMethod: .DELETE, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Execute an openCypher query.  When invoking this operation in a Neptune Analytics cluster, the IAM user or role making the request must have a policy attached  that allows one of the following IAM actions in that cluster, depending on the query:    neptune-graph:ReadDataViaQuery   neptune-graph:WriteDataViaQuery   neptune-graph:DeleteDataViaQuery
    @Sendable
    public func executeQuery(_ input: ExecuteQueryInput, logger: Logger = AWSClient.loggingDisabled) async throws -> ExecuteQueryOutput {
        return try await self.client.execute(
            operation: "ExecuteQuery", 
            path: "/queries", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            hostPrefix: "{graphIdentifier}.", 
            logger: logger
        )
    }

    /// Gets information about a specified graph.
    @Sendable
    public func getGraph(_ input: GetGraphInput, logger: Logger = AWSClient.loggingDisabled) async throws -> GetGraphOutput {
        return try await self.client.execute(
            operation: "GetGraph", 
            path: "/graphs/{graphIdentifier}", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Retrieves a specified graph snapshot.
    @Sendable
    public func getGraphSnapshot(_ input: GetGraphSnapshotInput, logger: Logger = AWSClient.loggingDisabled) async throws -> GetGraphSnapshotOutput {
        return try await self.client.execute(
            operation: "GetGraphSnapshot", 
            path: "/snapshots/{snapshotIdentifier}", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Gets a graph summary for a property graph.
    @Sendable
    public func getGraphSummary(_ input: GetGraphSummaryInput, logger: Logger = AWSClient.loggingDisabled) async throws -> GetGraphSummaryOutput {
        return try await self.client.execute(
            operation: "GetGraphSummary", 
            path: "/summary", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            hostPrefix: "{graphIdentifier}.", 
            logger: logger
        )
    }

    /// Retrieves a specified import task.
    @Sendable
    public func getImportTask(_ input: GetImportTaskInput, logger: Logger = AWSClient.loggingDisabled) async throws -> GetImportTaskOutput {
        return try await self.client.execute(
            operation: "GetImportTask", 
            path: "/importtasks/{taskIdentifier}", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Retrieves information about a specified private endpoint.
    @Sendable
    public func getPrivateGraphEndpoint(_ input: GetPrivateGraphEndpointInput, logger: Logger = AWSClient.loggingDisabled) async throws -> GetPrivateGraphEndpointOutput {
        return try await self.client.execute(
            operation: "GetPrivateGraphEndpoint", 
            path: "/graphs/{graphIdentifier}/endpoints/{vpcId}", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Retrieves the status of a specified query.   When invoking this operation in a Neptune Analytics cluster, the IAM user or role making the request must have the  neptune-graph:GetQueryStatus IAM action attached.
    @Sendable
    public func getQuery(_ input: GetQueryInput, logger: Logger = AWSClient.loggingDisabled) async throws -> GetQueryOutput {
        return try await self.client.execute(
            operation: "GetQuery", 
            path: "/queries/{queryId}", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            hostPrefix: "{graphIdentifier}.", 
            logger: logger
        )
    }

    /// Lists available snapshots of a specified Neptune Analytics graph.
    @Sendable
    public func listGraphSnapshots(_ input: ListGraphSnapshotsInput, logger: Logger = AWSClient.loggingDisabled) async throws -> ListGraphSnapshotsOutput {
        return try await self.client.execute(
            operation: "ListGraphSnapshots", 
            path: "/snapshots", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Lists available Neptune Analytics graphs.
    @Sendable
    public func listGraphs(_ input: ListGraphsInput, logger: Logger = AWSClient.loggingDisabled) async throws -> ListGraphsOutput {
        return try await self.client.execute(
            operation: "ListGraphs", 
            path: "/graphs", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Lists import tasks.
    @Sendable
    public func listImportTasks(_ input: ListImportTasksInput, logger: Logger = AWSClient.loggingDisabled) async throws -> ListImportTasksOutput {
        return try await self.client.execute(
            operation: "ListImportTasks", 
            path: "/importtasks", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Lists private endpoints for a specified Neptune Analytics graph.
    @Sendable
    public func listPrivateGraphEndpoints(_ input: ListPrivateGraphEndpointsInput, logger: Logger = AWSClient.loggingDisabled) async throws -> ListPrivateGraphEndpointsOutput {
        return try await self.client.execute(
            operation: "ListPrivateGraphEndpoints", 
            path: "/graphs/{graphIdentifier}/endpoints/", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Lists active openCypher queries.
    @Sendable
    public func listQueries(_ input: ListQueriesInput, logger: Logger = AWSClient.loggingDisabled) async throws -> ListQueriesOutput {
        return try await self.client.execute(
            operation: "ListQueries", 
            path: "/queries", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            hostPrefix: "{graphIdentifier}.", 
            logger: logger
        )
    }

    /// Lists tags associated with a specified resource.
    @Sendable
    public func listTagsForResource(_ input: ListTagsForResourceInput, logger: Logger = AWSClient.loggingDisabled) async throws -> ListTagsForResourceOutput {
        return try await self.client.execute(
            operation: "ListTagsForResource", 
            path: "/tags/{resourceArn}", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Empties the data from a specified Neptune Analytics graph.
    @Sendable
    public func resetGraph(_ input: ResetGraphInput, logger: Logger = AWSClient.loggingDisabled) async throws -> ResetGraphOutput {
        return try await self.client.execute(
            operation: "ResetGraph", 
            path: "/graphs/{graphIdentifier}", 
            httpMethod: .PUT, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Restores a graph from a snapshot.
    @Sendable
    public func restoreGraphFromSnapshot(_ input: RestoreGraphFromSnapshotInput, logger: Logger = AWSClient.loggingDisabled) async throws -> RestoreGraphFromSnapshotOutput {
        return try await self.client.execute(
            operation: "RestoreGraphFromSnapshot", 
            path: "/snapshots/{snapshotIdentifier}/restore", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Import data into existing Neptune Analytics graph from Amazon Simple Storage Service (S3). The graph needs to be empty and in the AVAILABLE state.
    @Sendable
    public func startImportTask(_ input: StartImportTaskInput, logger: Logger = AWSClient.loggingDisabled) async throws -> StartImportTaskOutput {
        return try await self.client.execute(
            operation: "StartImportTask", 
            path: "/graphs/{graphIdentifier}/importtasks", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Adds tags to the specified resource.
    @Sendable
    public func tagResource(_ input: TagResourceInput, logger: Logger = AWSClient.loggingDisabled) async throws -> TagResourceOutput {
        return try await self.client.execute(
            operation: "TagResource", 
            path: "/tags/{resourceArn}", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Removes the specified tags from the specified resource.
    @Sendable
    public func untagResource(_ input: UntagResourceInput, logger: Logger = AWSClient.loggingDisabled) async throws -> UntagResourceOutput {
        return try await self.client.execute(
            operation: "UntagResource", 
            path: "/tags/{resourceArn}", 
            httpMethod: .DELETE, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Updates the configuration of a specified Neptune Analytics graph
    @Sendable
    public func updateGraph(_ input: UpdateGraphInput, logger: Logger = AWSClient.loggingDisabled) async throws -> UpdateGraphOutput {
        return try await self.client.execute(
            operation: "UpdateGraph", 
            path: "/graphs/{graphIdentifier}", 
            httpMethod: .PATCH, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
}

extension NeptuneGraph {
    /// Initializer required by `AWSService.with(middlewares:timeout:byteBufferAllocator:options)`. You are not able to use this initializer directly as there are not public
    /// initializers for `AWSServiceConfig.Patch`. Please use `AWSService.with(middlewares:timeout:byteBufferAllocator:options)` instead.
    public init(from: NeptuneGraph, patch: AWSServiceConfig.Patch) {
        self.client = from.client
        self.config = from.config.with(patch: patch)
    }
}

// MARK: Paginators

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension NeptuneGraph {
    /// Lists available snapshots of a specified Neptune Analytics graph.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    public func listGraphSnapshotsPaginator(
        _ input: ListGraphSnapshotsInput,
        logger: Logger = AWSClient.loggingDisabled
    ) -> AWSClient.PaginatorSequence<ListGraphSnapshotsInput, ListGraphSnapshotsOutput> {
        return .init(
            input: input,
            command: self.listGraphSnapshots,
            inputKey: \ListGraphSnapshotsInput.nextToken,
            outputKey: \ListGraphSnapshotsOutput.nextToken,
            logger: logger
        )
    }

    /// Lists available Neptune Analytics graphs.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    public func listGraphsPaginator(
        _ input: ListGraphsInput,
        logger: Logger = AWSClient.loggingDisabled
    ) -> AWSClient.PaginatorSequence<ListGraphsInput, ListGraphsOutput> {
        return .init(
            input: input,
            command: self.listGraphs,
            inputKey: \ListGraphsInput.nextToken,
            outputKey: \ListGraphsOutput.nextToken,
            logger: logger
        )
    }

    /// Lists import tasks.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    public func listImportTasksPaginator(
        _ input: ListImportTasksInput,
        logger: Logger = AWSClient.loggingDisabled
    ) -> AWSClient.PaginatorSequence<ListImportTasksInput, ListImportTasksOutput> {
        return .init(
            input: input,
            command: self.listImportTasks,
            inputKey: \ListImportTasksInput.nextToken,
            outputKey: \ListImportTasksOutput.nextToken,
            logger: logger
        )
    }

    /// Lists private endpoints for a specified Neptune Analytics graph.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    public func listPrivateGraphEndpointsPaginator(
        _ input: ListPrivateGraphEndpointsInput,
        logger: Logger = AWSClient.loggingDisabled
    ) -> AWSClient.PaginatorSequence<ListPrivateGraphEndpointsInput, ListPrivateGraphEndpointsOutput> {
        return .init(
            input: input,
            command: self.listPrivateGraphEndpoints,
            inputKey: \ListPrivateGraphEndpointsInput.nextToken,
            outputKey: \ListPrivateGraphEndpointsOutput.nextToken,
            logger: logger
        )
    }
}

extension NeptuneGraph.ListGraphSnapshotsInput: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> NeptuneGraph.ListGraphSnapshotsInput {
        return .init(
            graphIdentifier: self.graphIdentifier,
            maxResults: self.maxResults,
            nextToken: token
        )
    }
}

extension NeptuneGraph.ListGraphsInput: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> NeptuneGraph.ListGraphsInput {
        return .init(
            maxResults: self.maxResults,
            nextToken: token
        )
    }
}

extension NeptuneGraph.ListImportTasksInput: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> NeptuneGraph.ListImportTasksInput {
        return .init(
            maxResults: self.maxResults,
            nextToken: token
        )
    }
}

extension NeptuneGraph.ListPrivateGraphEndpointsInput: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> NeptuneGraph.ListPrivateGraphEndpointsInput {
        return .init(
            graphIdentifier: self.graphIdentifier,
            maxResults: self.maxResults,
            nextToken: token
        )
    }
}

// MARK: Waiters

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension NeptuneGraph {
    public func waitUntilGraphAvailable(
        _ input: GetGraphInput,
        maxWaitTime: TimeAmount? = nil,
        logger: Logger = AWSClient.loggingDisabled
    ) async throws {
        let waiter = AWSClient.Waiter(
            acceptors: [
                .init(state: .failure, matcher: try! JMESPathMatcher("status", expected: "DELETING")),
                .init(state: .failure, matcher: try! JMESPathMatcher("status", expected: "FAILED")),
                .init(state: .success, matcher: try! JMESPathMatcher("status", expected: "AVAILABLE")),
            ],
            minDelayTime: .seconds(60),
            maxDelayTime: .seconds(28800),
            command: self.getGraph
        )
        return try await self.client.waitUntil(input, waiter: waiter, maxWaitTime: maxWaitTime, logger: logger)
    }

    public func waitUntilGraphDeleted(
        _ input: GetGraphInput,
        maxWaitTime: TimeAmount? = nil,
        logger: Logger = AWSClient.loggingDisabled
    ) async throws {
        let waiter = AWSClient.Waiter(
            acceptors: [
                .init(state: .failure, matcher: try! JMESPathMatcher("status != 'deletinG'", expected: "true")),
                .init(state: .success, matcher: AWSErrorCodeMatcher("ResourceNotFoundException")),
            ],
            minDelayTime: .seconds(60),
            maxDelayTime: .seconds(3600),
            command: self.getGraph
        )
        return try await self.client.waitUntil(input, waiter: waiter, maxWaitTime: maxWaitTime, logger: logger)
    }

    public func waitUntilGraphSnapshotAvailable(
        _ input: GetGraphSnapshotInput,
        maxWaitTime: TimeAmount? = nil,
        logger: Logger = AWSClient.loggingDisabled
    ) async throws {
        let waiter = AWSClient.Waiter(
            acceptors: [
                .init(state: .failure, matcher: try! JMESPathMatcher("status", expected: "DELETING")),
                .init(state: .failure, matcher: try! JMESPathMatcher("status", expected: "FAILED")),
                .init(state: .success, matcher: try! JMESPathMatcher("status", expected: "AVAILABLE")),
            ],
            minDelayTime: .seconds(60),
            maxDelayTime: .seconds(7200),
            command: self.getGraphSnapshot
        )
        return try await self.client.waitUntil(input, waiter: waiter, maxWaitTime: maxWaitTime, logger: logger)
    }

    public func waitUntilGraphSnapshotDeleted(
        _ input: GetGraphSnapshotInput,
        maxWaitTime: TimeAmount? = nil,
        logger: Logger = AWSClient.loggingDisabled
    ) async throws {
        let waiter = AWSClient.Waiter(
            acceptors: [
                .init(state: .failure, matcher: try! JMESPathMatcher("status != 'deletinG'", expected: "true")),
                .init(state: .success, matcher: AWSErrorCodeMatcher("ResourceNotFoundException")),
            ],
            minDelayTime: .seconds(60),
            maxDelayTime: .seconds(3600),
            command: self.getGraphSnapshot
        )
        return try await self.client.waitUntil(input, waiter: waiter, maxWaitTime: maxWaitTime, logger: logger)
    }

    public func waitUntilImportTaskCancelled(
        _ input: GetImportTaskInput,
        maxWaitTime: TimeAmount? = nil,
        logger: Logger = AWSClient.loggingDisabled
    ) async throws {
        let waiter = AWSClient.Waiter(
            acceptors: [
                .init(state: .failure, matcher: try! JMESPathMatcher("status != 'cancellinG' && status != 'cancelleD'", expected: "true")),
                .init(state: .success, matcher: try! JMESPathMatcher("status", expected: "CANCELLED")),
            ],
            minDelayTime: .seconds(60),
            maxDelayTime: .seconds(3600),
            command: self.getImportTask
        )
        return try await self.client.waitUntil(input, waiter: waiter, maxWaitTime: maxWaitTime, logger: logger)
    }

    public func waitUntilImportTaskSuccessful(
        _ input: GetImportTaskInput,
        maxWaitTime: TimeAmount? = nil,
        logger: Logger = AWSClient.loggingDisabled
    ) async throws {
        let waiter = AWSClient.Waiter(
            acceptors: [
                .init(state: .failure, matcher: try! JMESPathMatcher("status", expected: "CANCELLING")),
                .init(state: .failure, matcher: try! JMESPathMatcher("status", expected: "CANCELLED")),
                .init(state: .failure, matcher: try! JMESPathMatcher("status", expected: "ROLLING_BACK")),
                .init(state: .failure, matcher: try! JMESPathMatcher("status", expected: "FAILED")),
                .init(state: .success, matcher: try! JMESPathMatcher("status", expected: "SUCCEEDED")),
            ],
            minDelayTime: .seconds(60),
            maxDelayTime: .seconds(28800),
            command: self.getImportTask
        )
        return try await self.client.waitUntil(input, waiter: waiter, maxWaitTime: maxWaitTime, logger: logger)
    }

    public func waitUntilPrivateGraphEndpointAvailable(
        _ input: GetPrivateGraphEndpointInput,
        maxWaitTime: TimeAmount? = nil,
        logger: Logger = AWSClient.loggingDisabled
    ) async throws {
        let waiter = AWSClient.Waiter(
            acceptors: [
                .init(state: .failure, matcher: try! JMESPathMatcher("status", expected: "DELETING")),
                .init(state: .failure, matcher: try! JMESPathMatcher("status", expected: "FAILED")),
                .init(state: .success, matcher: try! JMESPathMatcher("status", expected: "AVAILABLE")),
            ],
            minDelayTime: .seconds(10),
            maxDelayTime: .seconds(1800),
            command: self.getPrivateGraphEndpoint
        )
        return try await self.client.waitUntil(input, waiter: waiter, maxWaitTime: maxWaitTime, logger: logger)
    }

    public func waitUntilPrivateGraphEndpointDeleted(
        _ input: GetPrivateGraphEndpointInput,
        maxWaitTime: TimeAmount? = nil,
        logger: Logger = AWSClient.loggingDisabled
    ) async throws {
        let waiter = AWSClient.Waiter(
            acceptors: [
                .init(state: .failure, matcher: try! JMESPathMatcher("status != 'deletinG'", expected: "true")),
                .init(state: .success, matcher: AWSErrorCodeMatcher("ResourceNotFoundException")),
            ],
            minDelayTime: .seconds(10),
            maxDelayTime: .seconds(1800),
            command: self.getPrivateGraphEndpoint
        )
        return try await self.client.waitUntil(input, waiter: waiter, maxWaitTime: maxWaitTime, logger: logger)
    }
}
