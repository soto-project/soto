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
extension Braket {
    // MARK: Async API Calls

    /// Cancels an Amazon Braket job.
    public func cancelJob(_ input: CancelJobRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CancelJobResponse {
        return try await self.client.execute(operation: "CancelJob", path: "/job/{jobArn}/cancel", httpMethod: .PUT, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Cancels the specified task.
    public func cancelQuantumTask(_ input: CancelQuantumTaskRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CancelQuantumTaskResponse {
        return try await self.client.execute(operation: "CancelQuantumTask", path: "/quantum-task/{quantumTaskArn}/cancel", httpMethod: .PUT, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Creates an Amazon Braket job.
    public func createJob(_ input: CreateJobRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CreateJobResponse {
        return try await self.client.execute(operation: "CreateJob", path: "/job", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Creates a quantum task.
    public func createQuantumTask(_ input: CreateQuantumTaskRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CreateQuantumTaskResponse {
        return try await self.client.execute(operation: "CreateQuantumTask", path: "/quantum-task", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Retrieves the devices available in Amazon Braket.  For backwards compatibility with older versions of BraketSchemas, OpenQASM information is omitted from GetDevice API calls. To get this information the user-agent needs to present a recent version of the BraketSchemas (1.8.0 or later). The Braket SDK automatically reports this for you. If you do not see OpenQASM results in the GetDevice response when using a Braket SDK, you may need to set AWS_EXECUTION_ENV environment variable to configure user-agent. See the code examples provided below for how to do this for the AWS CLI, Boto3, and the Go, Java, and JavaScript/TypeScript SDKs.
    public func getDevice(_ input: GetDeviceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetDeviceResponse {
        return try await self.client.execute(operation: "GetDevice", path: "/device/{deviceArn}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Retrieves the specified Amazon Braket job.
    public func getJob(_ input: GetJobRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetJobResponse {
        return try await self.client.execute(operation: "GetJob", path: "/job/{jobArn}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Retrieves the specified quantum task.
    public func getQuantumTask(_ input: GetQuantumTaskRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetQuantumTaskResponse {
        return try await self.client.execute(operation: "GetQuantumTask", path: "/quantum-task/{quantumTaskArn}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Shows the tags associated with this resource.
    public func listTagsForResource(_ input: ListTagsForResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListTagsForResourceResponse {
        return try await self.client.execute(operation: "ListTagsForResource", path: "/tags/{resourceArn}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Searches for devices using the specified filters.
    public func searchDevices(_ input: SearchDevicesRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> SearchDevicesResponse {
        return try await self.client.execute(operation: "SearchDevices", path: "/devices", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Searches for Amazon Braket jobs that match the specified filter values.
    public func searchJobs(_ input: SearchJobsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> SearchJobsResponse {
        return try await self.client.execute(operation: "SearchJobs", path: "/jobs", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Searches for tasks that match the specified filter values.
    public func searchQuantumTasks(_ input: SearchQuantumTasksRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> SearchQuantumTasksResponse {
        return try await self.client.execute(operation: "SearchQuantumTasks", path: "/quantum-tasks", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Add a tag to the specified resource.
    public func tagResource(_ input: TagResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> TagResourceResponse {
        return try await self.client.execute(operation: "TagResource", path: "/tags/{resourceArn}", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Remove tags from a resource.
    public func untagResource(_ input: UntagResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> UntagResourceResponse {
        return try await self.client.execute(operation: "UntagResource", path: "/tags/{resourceArn}", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }
}

// MARK: Paginators

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Braket {
    /// Searches for devices using the specified filters.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func searchDevicesPaginator(
        _ input: SearchDevicesRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<SearchDevicesRequest, SearchDevicesResponse> {
        return .init(
            input: input,
            command: self.searchDevices,
            inputKey: \SearchDevicesRequest.nextToken,
            outputKey: \SearchDevicesResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Searches for Amazon Braket jobs that match the specified filter values.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func searchJobsPaginator(
        _ input: SearchJobsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<SearchJobsRequest, SearchJobsResponse> {
        return .init(
            input: input,
            command: self.searchJobs,
            inputKey: \SearchJobsRequest.nextToken,
            outputKey: \SearchJobsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Searches for tasks that match the specified filter values.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func searchQuantumTasksPaginator(
        _ input: SearchQuantumTasksRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<SearchQuantumTasksRequest, SearchQuantumTasksResponse> {
        return .init(
            input: input,
            command: self.searchQuantumTasks,
            inputKey: \SearchQuantumTasksRequest.nextToken,
            outputKey: \SearchQuantumTasksResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }
}