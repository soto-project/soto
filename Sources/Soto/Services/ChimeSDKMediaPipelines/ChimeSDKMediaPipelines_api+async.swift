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
extension ChimeSDKMediaPipelines {
    // MARK: Async API Calls

    /// Creates a media pipeline.
    public func createMediaCapturePipeline(_ input: CreateMediaCapturePipelineRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CreateMediaCapturePipelineResponse {
        return try await self.client.execute(operation: "CreateMediaCapturePipeline", path: "/sdk-media-capture-pipelines", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Creates a media concatenation pipeline.
    public func createMediaConcatenationPipeline(_ input: CreateMediaConcatenationPipelineRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CreateMediaConcatenationPipelineResponse {
        return try await self.client.execute(operation: "CreateMediaConcatenationPipeline", path: "/sdk-media-concatenation-pipelines", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Creates a media insights pipeline.
    public func createMediaInsightsPipeline(_ input: CreateMediaInsightsPipelineRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CreateMediaInsightsPipelineResponse {
        return try await self.client.execute(operation: "CreateMediaInsightsPipeline", path: "/media-insights-pipelines", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// A structure that contains the static configurations for a media insights pipeline.
    public func createMediaInsightsPipelineConfiguration(_ input: CreateMediaInsightsPipelineConfigurationRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CreateMediaInsightsPipelineConfigurationResponse {
        return try await self.client.execute(operation: "CreateMediaInsightsPipelineConfiguration", path: "/media-insights-pipeline-configurations", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Creates a media live connector pipeline in an Amazon Chime SDK meeting.
    public func createMediaLiveConnectorPipeline(_ input: CreateMediaLiveConnectorPipelineRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CreateMediaLiveConnectorPipelineResponse {
        return try await self.client.execute(operation: "CreateMediaLiveConnectorPipeline", path: "/sdk-media-live-connector-pipelines", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Deletes the media pipeline.
    public func deleteMediaCapturePipeline(_ input: DeleteMediaCapturePipelineRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "DeleteMediaCapturePipeline", path: "/sdk-media-capture-pipelines/{MediaPipelineId}", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Deletes the specified configuration settings.
    public func deleteMediaInsightsPipelineConfiguration(_ input: DeleteMediaInsightsPipelineConfigurationRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "DeleteMediaInsightsPipelineConfiguration", path: "/media-insights-pipeline-configurations/{Identifier}", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Deletes the media pipeline.
    public func deleteMediaPipeline(_ input: DeleteMediaPipelineRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "DeleteMediaPipeline", path: "/sdk-media-pipelines/{MediaPipelineId}", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Gets an existing media pipeline.
    public func getMediaCapturePipeline(_ input: GetMediaCapturePipelineRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetMediaCapturePipelineResponse {
        return try await self.client.execute(operation: "GetMediaCapturePipeline", path: "/sdk-media-capture-pipelines/{MediaPipelineId}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Gets the configuration settings for a media insights pipeline.
    public func getMediaInsightsPipelineConfiguration(_ input: GetMediaInsightsPipelineConfigurationRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetMediaInsightsPipelineConfigurationResponse {
        return try await self.client.execute(operation: "GetMediaInsightsPipelineConfiguration", path: "/media-insights-pipeline-configurations/{Identifier}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Gets an existing media pipeline.
    public func getMediaPipeline(_ input: GetMediaPipelineRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetMediaPipelineResponse {
        return try await self.client.execute(operation: "GetMediaPipeline", path: "/sdk-media-pipelines/{MediaPipelineId}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Returns a list of media pipelines.
    public func listMediaCapturePipelines(_ input: ListMediaCapturePipelinesRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListMediaCapturePipelinesResponse {
        return try await self.client.execute(operation: "ListMediaCapturePipelines", path: "/sdk-media-capture-pipelines", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Lists the available media insights pipeline configurations.
    public func listMediaInsightsPipelineConfigurations(_ input: ListMediaInsightsPipelineConfigurationsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListMediaInsightsPipelineConfigurationsResponse {
        return try await self.client.execute(operation: "ListMediaInsightsPipelineConfigurations", path: "/media-insights-pipeline-configurations", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Returns a list of media pipelines.
    public func listMediaPipelines(_ input: ListMediaPipelinesRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListMediaPipelinesResponse {
        return try await self.client.execute(operation: "ListMediaPipelines", path: "/sdk-media-pipelines", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Lists the tags available for a media pipeline.
    public func listTagsForResource(_ input: ListTagsForResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListTagsForResourceResponse {
        return try await self.client.execute(operation: "ListTagsForResource", path: "/tags", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// The ARN of the media pipeline that you want to tag. Consists of the pipeline's endpoint region, resource ID, and pipeline ID.
    public func tagResource(_ input: TagResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> TagResourceResponse {
        return try await self.client.execute(operation: "TagResource", path: "/tags?operation=tag-resource", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Removes any tags from a media pipeline.
    public func untagResource(_ input: UntagResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> UntagResourceResponse {
        return try await self.client.execute(operation: "UntagResource", path: "/tags?operation=untag-resource", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Updates the media insights pipeline's configuration settings.
    public func updateMediaInsightsPipelineConfiguration(_ input: UpdateMediaInsightsPipelineConfigurationRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> UpdateMediaInsightsPipelineConfigurationResponse {
        return try await self.client.execute(operation: "UpdateMediaInsightsPipelineConfiguration", path: "/media-insights-pipeline-configurations/{Identifier}", httpMethod: .PUT, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Updates the status of a media insights pipeline.
    public func updateMediaInsightsPipelineStatus(_ input: UpdateMediaInsightsPipelineStatusRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "UpdateMediaInsightsPipelineStatus", path: "/media-insights-pipeline-status/{Identifier}", httpMethod: .PUT, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }
}

// MARK: Paginators

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension ChimeSDKMediaPipelines {
    /// Returns a list of media pipelines.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listMediaCapturePipelinesPaginator(
        _ input: ListMediaCapturePipelinesRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListMediaCapturePipelinesRequest, ListMediaCapturePipelinesResponse> {
        return .init(
            input: input,
            command: self.listMediaCapturePipelines,
            inputKey: \ListMediaCapturePipelinesRequest.nextToken,
            outputKey: \ListMediaCapturePipelinesResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Lists the available media insights pipeline configurations.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listMediaInsightsPipelineConfigurationsPaginator(
        _ input: ListMediaInsightsPipelineConfigurationsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListMediaInsightsPipelineConfigurationsRequest, ListMediaInsightsPipelineConfigurationsResponse> {
        return .init(
            input: input,
            command: self.listMediaInsightsPipelineConfigurations,
            inputKey: \ListMediaInsightsPipelineConfigurationsRequest.nextToken,
            outputKey: \ListMediaInsightsPipelineConfigurationsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    /// Returns a list of media pipelines.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listMediaPipelinesPaginator(
        _ input: ListMediaPipelinesRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListMediaPipelinesRequest, ListMediaPipelinesResponse> {
        return .init(
            input: input,
            command: self.listMediaPipelines,
            inputKey: \ListMediaPipelinesRequest.nextToken,
            outputKey: \ListMediaPipelinesResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }
}