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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
@_exported import SotoCore

/// Service object for interacting with AWS AutoScalingPlans service.
///
/// AWS Auto Scaling
///   Use AWS Auto Scaling to create scaling plans for your applications to automatically scale your scalable AWS resources.   API Summary  You can use the AWS Auto Scaling service API to accomplish the following tasks:   Create and manage scaling plans   Define target tracking scaling policies to dynamically scale your resources based on utilization   Scale Amazon EC2 Auto Scaling groups using predictive scaling and dynamic scaling to scale your Amazon EC2 capacity faster   Set minimum and maximum capacity limits   Retrieve information on existing scaling plans   Access current forecast data and historical forecast data for up to 56 days previous    To learn more about AWS Auto Scaling, including information about granting IAM users required permissions for AWS Auto Scaling actions, see the AWS Auto Scaling User Guide.
public struct AutoScalingPlans: AWSService {
    // MARK: Member variables

    /// Client used for communication with AWS
    public let client: AWSClient
    /// Service configuration
    public let config: AWSServiceConfig

    // MARK: Initialization

    /// Initialize the AutoScalingPlans client
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
            amzTarget: "AnyScaleScalingPlannerFrontendService",
            serviceName: "AutoScalingPlans",
            serviceIdentifier: "autoscaling-plans",
            serviceProtocol: .json(version: "1.1"),
            apiVersion: "2018-01-06",
            endpoint: endpoint,
            variantEndpoints: Self.variantEndpoints,
            errorType: AutoScalingPlansErrorType.self,
            middleware: middleware,
            timeout: timeout,
            byteBufferAllocator: byteBufferAllocator,
            options: options
        )
    }




    /// FIPS and dualstack endpoints
    static var variantEndpoints: [EndpointVariantType: AWSServiceConfig.EndpointVariant] {[
        [.fips]: .init(endpoints: [
            "us-gov-east-1": "autoscaling-plans.us-gov-east-1.amazonaws.com",
            "us-gov-west-1": "autoscaling-plans.us-gov-west-1.amazonaws.com"
        ])
    ]}

    // MARK: API Calls

    /// Creates a scaling plan.
    @Sendable
    @inlinable
    public func createScalingPlan(_ input: CreateScalingPlanRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> CreateScalingPlanResponse {
        try await self.client.execute(
            operation: "CreateScalingPlan", 
            path: "/", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Creates a scaling plan.
    ///
    /// Parameters:
    ///   - applicationSource: A CloudFormation stack or set of tags. You can create one scaling plan per application source. For more information, see ApplicationSource in the AWS Auto Scaling API Reference.
    ///   - scalingInstructions: The scaling instructions. For more information, see ScalingInstruction in the AWS Auto Scaling API Reference.
    ///   - scalingPlanName: The name of the scaling plan. Names cannot contain vertical bars, colons, or forward slashes.
    ///   - logger: Logger use during operation
    @inlinable
    public func createScalingPlan(
        applicationSource: ApplicationSource,
        scalingInstructions: [ScalingInstruction],
        scalingPlanName: String,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> CreateScalingPlanResponse {
        let input = CreateScalingPlanRequest(
            applicationSource: applicationSource, 
            scalingInstructions: scalingInstructions, 
            scalingPlanName: scalingPlanName
        )
        return try await self.createScalingPlan(input, logger: logger)
    }

    /// Deletes the specified scaling plan. Deleting a scaling plan deletes the underlying ScalingInstruction for all of the scalable resources that are covered by the plan. If the plan has launched resources or has scaling activities in progress, you must delete those resources separately.
    @Sendable
    @inlinable
    public func deleteScalingPlan(_ input: DeleteScalingPlanRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> DeleteScalingPlanResponse {
        try await self.client.execute(
            operation: "DeleteScalingPlan", 
            path: "/", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Deletes the specified scaling plan. Deleting a scaling plan deletes the underlying ScalingInstruction for all of the scalable resources that are covered by the plan. If the plan has launched resources or has scaling activities in progress, you must delete those resources separately.
    ///
    /// Parameters:
    ///   - scalingPlanName: The name of the scaling plan.
    ///   - scalingPlanVersion: The version number of the scaling plan. Currently, the only valid value is 1.
    ///   - logger: Logger use during operation
    @inlinable
    public func deleteScalingPlan(
        scalingPlanName: String,
        scalingPlanVersion: Int64,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> DeleteScalingPlanResponse {
        let input = DeleteScalingPlanRequest(
            scalingPlanName: scalingPlanName, 
            scalingPlanVersion: scalingPlanVersion
        )
        return try await self.deleteScalingPlan(input, logger: logger)
    }

    /// Describes the scalable resources in the specified scaling plan.
    @Sendable
    @inlinable
    public func describeScalingPlanResources(_ input: DescribeScalingPlanResourcesRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> DescribeScalingPlanResourcesResponse {
        try await self.client.execute(
            operation: "DescribeScalingPlanResources", 
            path: "/", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Describes the scalable resources in the specified scaling plan.
    ///
    /// Parameters:
    ///   - maxResults: The maximum number of scalable resources to return. The value must be between 1 and 50. The default value is 50.
    ///   - nextToken: The token for the next set of results.
    ///   - scalingPlanName: The name of the scaling plan.
    ///   - scalingPlanVersion: The version number of the scaling plan. Currently, the only valid value is 1.
    ///   - logger: Logger use during operation
    @inlinable
    public func describeScalingPlanResources(
        maxResults: Int? = nil,
        nextToken: String? = nil,
        scalingPlanName: String,
        scalingPlanVersion: Int64,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> DescribeScalingPlanResourcesResponse {
        let input = DescribeScalingPlanResourcesRequest(
            maxResults: maxResults, 
            nextToken: nextToken, 
            scalingPlanName: scalingPlanName, 
            scalingPlanVersion: scalingPlanVersion
        )
        return try await self.describeScalingPlanResources(input, logger: logger)
    }

    /// Describes one or more of your scaling plans.
    @Sendable
    @inlinable
    public func describeScalingPlans(_ input: DescribeScalingPlansRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> DescribeScalingPlansResponse {
        try await self.client.execute(
            operation: "DescribeScalingPlans", 
            path: "/", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Describes one or more of your scaling plans.
    ///
    /// Parameters:
    ///   - applicationSources: The sources for the applications (up to 10). If you specify scaling plan names, you cannot specify application sources.
    ///   - maxResults: The maximum number of scalable resources to return. This value can be between 1 and 50. The default value is 50.
    ///   - nextToken: The token for the next set of results.
    ///   - scalingPlanNames: The names of the scaling plans (up to 10). If you specify application sources, you cannot specify scaling plan names.
    ///   - scalingPlanVersion: The version number of the scaling plan. Currently, the only valid value is 1.  If you specify a scaling plan version, you must also specify a scaling plan name.
    ///   - logger: Logger use during operation
    @inlinable
    public func describeScalingPlans(
        applicationSources: [ApplicationSource]? = nil,
        maxResults: Int? = nil,
        nextToken: String? = nil,
        scalingPlanNames: [String]? = nil,
        scalingPlanVersion: Int64? = nil,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> DescribeScalingPlansResponse {
        let input = DescribeScalingPlansRequest(
            applicationSources: applicationSources, 
            maxResults: maxResults, 
            nextToken: nextToken, 
            scalingPlanNames: scalingPlanNames, 
            scalingPlanVersion: scalingPlanVersion
        )
        return try await self.describeScalingPlans(input, logger: logger)
    }

    /// Retrieves the forecast data for a scalable resource. Capacity forecasts are represented as predicted values, or data points, that are calculated using historical data points from a specified CloudWatch load metric. Data points are available for up to 56 days.
    @Sendable
    @inlinable
    public func getScalingPlanResourceForecastData(_ input: GetScalingPlanResourceForecastDataRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> GetScalingPlanResourceForecastDataResponse {
        try await self.client.execute(
            operation: "GetScalingPlanResourceForecastData", 
            path: "/", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Retrieves the forecast data for a scalable resource. Capacity forecasts are represented as predicted values, or data points, that are calculated using historical data points from a specified CloudWatch load metric. Data points are available for up to 56 days.
    ///
    /// Parameters:
    ///   - endTime: The exclusive end time of the time range for the forecast data to get. The maximum time duration between the start and end time is seven days.  Although this parameter can accept a date and time that is more than two days in the future, the availability of forecast data has limits. AWS Auto Scaling only issues forecasts for periods of two days in advance.
    ///   - forecastDataType: The type of forecast data to get.    LoadForecast: The load metric forecast.     CapacityForecast: The capacity forecast.     ScheduledActionMinCapacity: The minimum capacity for each scheduled scaling action. This data is calculated as the larger of two values: the capacity forecast or the minimum capacity in the scaling instruction.    ScheduledActionMaxCapacity: The maximum capacity for each scheduled scaling action. The calculation used is determined by the predictive scaling maximum capacity behavior setting in the scaling instruction.
    ///   - resourceId: The ID of the resource. This string consists of a prefix (autoScalingGroup) followed by the name of a specified Auto Scaling group (my-asg). Example: autoScalingGroup/my-asg.
    ///   - scalableDimension: The scalable dimension for the resource. The only valid value is autoscaling:autoScalingGroup:DesiredCapacity.
    ///   - scalingPlanName: The name of the scaling plan.
    ///   - scalingPlanVersion: The version number of the scaling plan. Currently, the only valid value is 1.
    ///   - serviceNamespace: The namespace of the AWS service. The only valid value is autoscaling.
    ///   - startTime: The inclusive start time of the time range for the forecast data to get. The date and time can be at most 56 days before the current date and time.
    ///   - logger: Logger use during operation
    @inlinable
    public func getScalingPlanResourceForecastData(
        endTime: Date,
        forecastDataType: ForecastDataType,
        resourceId: String,
        scalableDimension: ScalableDimension,
        scalingPlanName: String,
        scalingPlanVersion: Int64,
        serviceNamespace: ServiceNamespace,
        startTime: Date,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> GetScalingPlanResourceForecastDataResponse {
        let input = GetScalingPlanResourceForecastDataRequest(
            endTime: endTime, 
            forecastDataType: forecastDataType, 
            resourceId: resourceId, 
            scalableDimension: scalableDimension, 
            scalingPlanName: scalingPlanName, 
            scalingPlanVersion: scalingPlanVersion, 
            serviceNamespace: serviceNamespace, 
            startTime: startTime
        )
        return try await self.getScalingPlanResourceForecastData(input, logger: logger)
    }

    /// Updates the specified scaling plan. You cannot update a scaling plan if it is in the process of being created, updated, or deleted.
    @Sendable
    @inlinable
    public func updateScalingPlan(_ input: UpdateScalingPlanRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> UpdateScalingPlanResponse {
        try await self.client.execute(
            operation: "UpdateScalingPlan", 
            path: "/", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Updates the specified scaling plan. You cannot update a scaling plan if it is in the process of being created, updated, or deleted.
    ///
    /// Parameters:
    ///   - applicationSource: A CloudFormation stack or set of tags. For more information, see ApplicationSource in the AWS Auto Scaling API Reference.
    ///   - scalingInstructions: The scaling instructions. For more information, see ScalingInstruction in the AWS Auto Scaling API Reference.
    ///   - scalingPlanName: The name of the scaling plan.
    ///   - scalingPlanVersion: The version number of the scaling plan. The only valid value is 1. Currently, you cannot have multiple scaling plan versions.
    ///   - logger: Logger use during operation
    @inlinable
    public func updateScalingPlan(
        applicationSource: ApplicationSource? = nil,
        scalingInstructions: [ScalingInstruction]? = nil,
        scalingPlanName: String,
        scalingPlanVersion: Int64,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> UpdateScalingPlanResponse {
        let input = UpdateScalingPlanRequest(
            applicationSource: applicationSource, 
            scalingInstructions: scalingInstructions, 
            scalingPlanName: scalingPlanName, 
            scalingPlanVersion: scalingPlanVersion
        )
        return try await self.updateScalingPlan(input, logger: logger)
    }
}

extension AutoScalingPlans {
    /// Initializer required by `AWSService.with(middlewares:timeout:byteBufferAllocator:options)`. You are not able to use this initializer directly as there are not public
    /// initializers for `AWSServiceConfig.Patch`. Please use `AWSService.with(middlewares:timeout:byteBufferAllocator:options)` instead.
    public init(from: AutoScalingPlans, patch: AWSServiceConfig.Patch) {
        self.client = from.client
        self.config = from.config.with(patch: patch)
    }
}
