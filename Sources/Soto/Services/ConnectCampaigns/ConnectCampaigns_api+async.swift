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
extension ConnectCampaigns {
    // MARK: Async API Calls

    /// Creates a campaign for the specified Amazon Connect account. This API is idempotent.
    public func createCampaign(_ input: CreateCampaignRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> CreateCampaignResponse {
        return try await self.client.execute(operation: "CreateCampaign", path: "/campaigns", httpMethod: .PUT, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Deletes a campaign from the specified Amazon Connect account.
    public func deleteCampaign(_ input: DeleteCampaignRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "DeleteCampaign", path: "/campaigns/{id}", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Deletes a connect instance config from the specified AWS account.
    public func deleteConnectInstanceConfig(_ input: DeleteConnectInstanceConfigRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "DeleteConnectInstanceConfig", path: "/connect-instance/{connectInstanceId}/config", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Delete the Connect Campaigns onboarding job for the specified Amazon Connect instance.
    public func deleteInstanceOnboardingJob(_ input: DeleteInstanceOnboardingJobRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "DeleteInstanceOnboardingJob", path: "/connect-instance/{connectInstanceId}/onboarding", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Describes the specific campaign.
    public func describeCampaign(_ input: DescribeCampaignRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> DescribeCampaignResponse {
        return try await self.client.execute(operation: "DescribeCampaign", path: "/campaigns/{id}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Get state of a campaign for the specified Amazon Connect account.
    public func getCampaignState(_ input: GetCampaignStateRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetCampaignStateResponse {
        return try await self.client.execute(operation: "GetCampaignState", path: "/campaigns/{id}/state", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Get state of campaigns for the specified Amazon Connect account.
    public func getCampaignStateBatch(_ input: GetCampaignStateBatchRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetCampaignStateBatchResponse {
        return try await self.client.execute(operation: "GetCampaignStateBatch", path: "/campaigns-state", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Get the specific Connect instance config.
    public func getConnectInstanceConfig(_ input: GetConnectInstanceConfigRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetConnectInstanceConfigResponse {
        return try await self.client.execute(operation: "GetConnectInstanceConfig", path: "/connect-instance/{connectInstanceId}/config", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Get the specific instance onboarding job status.
    public func getInstanceOnboardingJobStatus(_ input: GetInstanceOnboardingJobStatusRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> GetInstanceOnboardingJobStatusResponse {
        return try await self.client.execute(operation: "GetInstanceOnboardingJobStatus", path: "/connect-instance/{connectInstanceId}/onboarding", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Provides summary information about the campaigns under the specified Amazon Connect account.
    public func listCampaigns(_ input: ListCampaignsRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListCampaignsResponse {
        return try await self.client.execute(operation: "ListCampaigns", path: "/campaigns-summary", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// List tags for a resource.
    public func listTagsForResource(_ input: ListTagsForResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> ListTagsForResourceResponse {
        return try await self.client.execute(operation: "ListTagsForResource", path: "/tags/{arn}", httpMethod: .GET, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Pauses a campaign for the specified Amazon Connect account.
    public func pauseCampaign(_ input: PauseCampaignRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "PauseCampaign", path: "/campaigns/{id}/pause", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Creates dials requests for the specified campaign Amazon Connect account. This API is idempotent.
    public func putDialRequestBatch(_ input: PutDialRequestBatchRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> PutDialRequestBatchResponse {
        return try await self.client.execute(operation: "PutDialRequestBatch", path: "/campaigns/{id}/dial-requests", httpMethod: .PUT, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Stops a campaign for the specified Amazon Connect account.
    public func resumeCampaign(_ input: ResumeCampaignRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "ResumeCampaign", path: "/campaigns/{id}/resume", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Starts a campaign for the specified Amazon Connect account.
    public func startCampaign(_ input: StartCampaignRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "StartCampaign", path: "/campaigns/{id}/start", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Onboard the specific Amazon Connect instance to Connect Campaigns.
    public func startInstanceOnboardingJob(_ input: StartInstanceOnboardingJobRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws -> StartInstanceOnboardingJobResponse {
        return try await self.client.execute(operation: "StartInstanceOnboardingJob", path: "/connect-instance/{connectInstanceId}/onboarding", httpMethod: .PUT, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Stops a campaign for the specified Amazon Connect account.
    public func stopCampaign(_ input: StopCampaignRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "StopCampaign", path: "/campaigns/{id}/stop", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Tag a resource.
    public func tagResource(_ input: TagResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "TagResource", path: "/tags/{arn}", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Untag a resource.
    public func untagResource(_ input: UntagResourceRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "UntagResource", path: "/tags/{arn}", httpMethod: .DELETE, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Updates the dialer config of a campaign. This API is idempotent.
    public func updateCampaignDialerConfig(_ input: UpdateCampaignDialerConfigRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "UpdateCampaignDialerConfig", path: "/campaigns/{id}/dialer-config", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Updates the name of a campaign. This API is idempotent.
    public func updateCampaignName(_ input: UpdateCampaignNameRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "UpdateCampaignName", path: "/campaigns/{id}/name", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }

    /// Updates the outbound call config of a campaign. This API is idempotent.
    public func updateCampaignOutboundCallConfig(_ input: UpdateCampaignOutboundCallConfigRequest, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "UpdateCampaignOutboundCallConfig", path: "/campaigns/{id}/outbound-call-config", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }
}

// MARK: Paginators

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension ConnectCampaigns {
    /// Provides summary information about the campaigns under the specified Amazon Connect account.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listCampaignsPaginator(
        _ input: ListCampaignsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListCampaignsRequest, ListCampaignsResponse> {
        return .init(
            input: input,
            command: self.listCampaigns,
            inputKey: \ListCampaignsRequest.nextToken,
            outputKey: \ListCampaignsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }
}