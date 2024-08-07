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

/// Service object for interacting with AWS M2 service.
///
/// Amazon Web Services Mainframe Modernization provides tools and resources to help you plan and implement migration and modernization from mainframes to Amazon Web Services managed runtime environments. It provides tools for analyzing existing mainframe applications, developing or updating mainframe applications using COBOL or PL/I, and implementing an automated pipeline for continuous integration and continuous delivery (CI/CD) of the applications.
public struct M2: AWSService {
    // MARK: Member variables

    /// Client used for communication with AWS
    public let client: AWSClient
    /// Service configuration
    public let config: AWSServiceConfig

    // MARK: Initialization

    /// Initialize the M2 client
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
            serviceName: "M2",
            serviceIdentifier: "m2",
            serviceProtocol: .restjson,
            apiVersion: "2021-04-28",
            endpoint: endpoint,
            variantEndpoints: Self.variantEndpoints,
            errorType: M2ErrorType.self,
            middleware: middleware,
            timeout: timeout,
            byteBufferAllocator: byteBufferAllocator,
            options: options
        )
    }




    /// FIPS and dualstack endpoints
    static var variantEndpoints: [EndpointVariantType: AWSServiceConfig.EndpointVariant] {[
        [.fips]: .init(endpoints: [
            "ca-central-1": "m2-fips.ca-central-1.amazonaws.com",
            "us-east-1": "m2-fips.us-east-1.amazonaws.com",
            "us-east-2": "m2-fips.us-east-2.amazonaws.com",
            "us-gov-east-1": "m2-fips.us-gov-east-1.amazonaws.com",
            "us-gov-west-1": "m2-fips.us-gov-west-1.amazonaws.com",
            "us-west-1": "m2-fips.us-west-1.amazonaws.com",
            "us-west-2": "m2-fips.us-west-2.amazonaws.com"
        ])
    ]}

    // MARK: API Calls

    /// Cancels the running of a specific batch job execution.
    @Sendable
    public func cancelBatchJobExecution(_ input: CancelBatchJobExecutionRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> CancelBatchJobExecutionResponse {
        return try await self.client.execute(
            operation: "CancelBatchJobExecution", 
            path: "/applications/{applicationId}/batch-job-executions/{executionId}/cancel", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Creates a new application with given parameters. Requires an existing runtime environment and application definition file.
    @Sendable
    public func createApplication(_ input: CreateApplicationRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> CreateApplicationResponse {
        return try await self.client.execute(
            operation: "CreateApplication", 
            path: "/applications", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Starts a data set import task for a specific application.
    @Sendable
    public func createDataSetImportTask(_ input: CreateDataSetImportTaskRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> CreateDataSetImportTaskResponse {
        return try await self.client.execute(
            operation: "CreateDataSetImportTask", 
            path: "/applications/{applicationId}/dataset-import-task", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Creates and starts a deployment to deploy an application into a runtime environment.
    @Sendable
    public func createDeployment(_ input: CreateDeploymentRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> CreateDeploymentResponse {
        return try await self.client.execute(
            operation: "CreateDeployment", 
            path: "/applications/{applicationId}/deployments", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Creates a runtime environment for a given runtime engine.
    @Sendable
    public func createEnvironment(_ input: CreateEnvironmentRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> CreateEnvironmentResponse {
        return try await self.client.execute(
            operation: "CreateEnvironment", 
            path: "/environments", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Deletes a specific application. You cannot delete a running application.
    @Sendable
    public func deleteApplication(_ input: DeleteApplicationRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> DeleteApplicationResponse {
        return try await self.client.execute(
            operation: "DeleteApplication", 
            path: "/applications/{applicationId}", 
            httpMethod: .DELETE, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Deletes a specific application from the specific runtime environment where it was previously deployed. You cannot delete a runtime environment using DeleteEnvironment if any application has ever been deployed to it. This API removes the association of the application with the runtime environment so you can delete the environment smoothly.
    @Sendable
    public func deleteApplicationFromEnvironment(_ input: DeleteApplicationFromEnvironmentRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> DeleteApplicationFromEnvironmentResponse {
        return try await self.client.execute(
            operation: "DeleteApplicationFromEnvironment", 
            path: "/applications/{applicationId}/environment/{environmentId}", 
            httpMethod: .DELETE, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Deletes a specific runtime environment. The environment cannot contain deployed applications. If it does, you must delete those applications before you delete the environment.
    @Sendable
    public func deleteEnvironment(_ input: DeleteEnvironmentRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> DeleteEnvironmentResponse {
        return try await self.client.execute(
            operation: "DeleteEnvironment", 
            path: "/environments/{environmentId}", 
            httpMethod: .DELETE, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Describes the details of a specific application.
    @Sendable
    public func getApplication(_ input: GetApplicationRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> GetApplicationResponse {
        return try await self.client.execute(
            operation: "GetApplication", 
            path: "/applications/{applicationId}", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Returns details about a specific version of a specific application.
    @Sendable
    public func getApplicationVersion(_ input: GetApplicationVersionRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> GetApplicationVersionResponse {
        return try await self.client.execute(
            operation: "GetApplicationVersion", 
            path: "/applications/{applicationId}/versions/{applicationVersion}", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Gets the details of a specific batch job execution for a specific application.
    @Sendable
    public func getBatchJobExecution(_ input: GetBatchJobExecutionRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> GetBatchJobExecutionResponse {
        return try await self.client.execute(
            operation: "GetBatchJobExecution", 
            path: "/applications/{applicationId}/batch-job-executions/{executionId}", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Gets the details of a specific data set.
    @Sendable
    public func getDataSetDetails(_ input: GetDataSetDetailsRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> GetDataSetDetailsResponse {
        return try await self.client.execute(
            operation: "GetDataSetDetails", 
            path: "/applications/{applicationId}/datasets/{dataSetName}", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Gets the status of a data set import task initiated with the CreateDataSetImportTask operation.
    @Sendable
    public func getDataSetImportTask(_ input: GetDataSetImportTaskRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> GetDataSetImportTaskResponse {
        return try await self.client.execute(
            operation: "GetDataSetImportTask", 
            path: "/applications/{applicationId}/dataset-import-tasks/{taskId}", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Gets details of a specific deployment with a given deployment identifier.
    @Sendable
    public func getDeployment(_ input: GetDeploymentRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> GetDeploymentResponse {
        return try await self.client.execute(
            operation: "GetDeployment", 
            path: "/applications/{applicationId}/deployments/{deploymentId}", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Describes a specific runtime environment.
    @Sendable
    public func getEnvironment(_ input: GetEnvironmentRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> GetEnvironmentResponse {
        return try await self.client.execute(
            operation: "GetEnvironment", 
            path: "/environments/{environmentId}", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Gets a single sign-on URL that can be used to connect to AWS Blu Insights.
    @Sendable
    public func getSignedBluinsightsUrl(logger: Logger = AWSClient.loggingDisabled) async throws -> GetSignedBluinsightsUrlResponse {
        return try await self.client.execute(
            operation: "GetSignedBluinsightsUrl", 
            path: "/signed-bi-url", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            logger: logger
        )
    }

    /// Returns a list of the application versions for a specific application.
    @Sendable
    public func listApplicationVersions(_ input: ListApplicationVersionsRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> ListApplicationVersionsResponse {
        return try await self.client.execute(
            operation: "ListApplicationVersions", 
            path: "/applications/{applicationId}/versions", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Lists the applications associated with a specific Amazon Web Services account. You can provide the unique identifier of a specific runtime environment in a query parameter to see all applications associated with that environment.
    @Sendable
    public func listApplications(_ input: ListApplicationsRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> ListApplicationsResponse {
        return try await self.client.execute(
            operation: "ListApplications", 
            path: "/applications", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Lists all the available batch job definitions based on the batch job resources uploaded during the application creation. You can use the batch job definitions in the list to start a batch job.
    @Sendable
    public func listBatchJobDefinitions(_ input: ListBatchJobDefinitionsRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> ListBatchJobDefinitionsResponse {
        return try await self.client.execute(
            operation: "ListBatchJobDefinitions", 
            path: "/applications/{applicationId}/batch-job-definitions", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Lists historical, current, and scheduled batch job executions for a specific application.
    @Sendable
    public func listBatchJobExecutions(_ input: ListBatchJobExecutionsRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> ListBatchJobExecutionsResponse {
        return try await self.client.execute(
            operation: "ListBatchJobExecutions", 
            path: "/applications/{applicationId}/batch-job-executions", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Lists all the job steps for JCL files to restart a batch job. This is only applicable for Micro Focus engine with versions 8.0.6 and above.
    @Sendable
    public func listBatchJobRestartPoints(_ input: ListBatchJobRestartPointsRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> ListBatchJobRestartPointsResponse {
        return try await self.client.execute(
            operation: "ListBatchJobRestartPoints", 
            path: "/applications/{applicationId}/batch-job-executions/{executionId}/steps", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Lists the data set imports for the specified application.
    @Sendable
    public func listDataSetImportHistory(_ input: ListDataSetImportHistoryRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> ListDataSetImportHistoryResponse {
        return try await self.client.execute(
            operation: "ListDataSetImportHistory", 
            path: "/applications/{applicationId}/dataset-import-tasks", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Lists the data sets imported for a specific application. In Amazon Web Services Mainframe Modernization, data sets are associated with applications deployed on runtime environments. This is known as importing data sets. Currently, Amazon Web Services Mainframe Modernization can import data sets into catalogs using CreateDataSetImportTask.
    @Sendable
    public func listDataSets(_ input: ListDataSetsRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> ListDataSetsResponse {
        return try await self.client.execute(
            operation: "ListDataSets", 
            path: "/applications/{applicationId}/datasets", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Returns a list of all deployments of a specific application. A deployment is a combination of a specific application and a specific version of that application. Each deployment is mapped to a particular application version.
    @Sendable
    public func listDeployments(_ input: ListDeploymentsRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> ListDeploymentsResponse {
        return try await self.client.execute(
            operation: "ListDeployments", 
            path: "/applications/{applicationId}/deployments", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Lists the available engine versions.
    @Sendable
    public func listEngineVersions(_ input: ListEngineVersionsRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> ListEngineVersionsResponse {
        return try await self.client.execute(
            operation: "ListEngineVersions", 
            path: "/engine-versions", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Lists the runtime environments.
    @Sendable
    public func listEnvironments(_ input: ListEnvironmentsRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> ListEnvironmentsResponse {
        return try await self.client.execute(
            operation: "ListEnvironments", 
            path: "/environments", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Lists the tags for the specified resource.
    @Sendable
    public func listTagsForResource(_ input: ListTagsForResourceRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> ListTagsForResourceResponse {
        return try await self.client.execute(
            operation: "ListTagsForResource", 
            path: "/tags/{resourceArn}", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Starts an application that is currently stopped.
    @Sendable
    public func startApplication(_ input: StartApplicationRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> StartApplicationResponse {
        return try await self.client.execute(
            operation: "StartApplication", 
            path: "/applications/{applicationId}/start", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Starts a batch job and returns the unique identifier of this execution of the batch job. The associated application must be running in order to start the batch job.
    @Sendable
    public func startBatchJob(_ input: StartBatchJobRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> StartBatchJobResponse {
        return try await self.client.execute(
            operation: "StartBatchJob", 
            path: "/applications/{applicationId}/batch-job", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Stops a running application.
    @Sendable
    public func stopApplication(_ input: StopApplicationRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> StopApplicationResponse {
        return try await self.client.execute(
            operation: "StopApplication", 
            path: "/applications/{applicationId}/stop", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Adds one or more tags to the specified resource.
    @Sendable
    public func tagResource(_ input: TagResourceRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> TagResourceResponse {
        return try await self.client.execute(
            operation: "TagResource", 
            path: "/tags/{resourceArn}", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Removes one or more tags from the specified resource.
    @Sendable
    public func untagResource(_ input: UntagResourceRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> UntagResourceResponse {
        return try await self.client.execute(
            operation: "UntagResource", 
            path: "/tags/{resourceArn}", 
            httpMethod: .DELETE, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Updates an application and creates a new version.
    @Sendable
    public func updateApplication(_ input: UpdateApplicationRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> UpdateApplicationResponse {
        return try await self.client.execute(
            operation: "UpdateApplication", 
            path: "/applications/{applicationId}", 
            httpMethod: .PATCH, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Updates the configuration details for a specific runtime environment.
    @Sendable
    public func updateEnvironment(_ input: UpdateEnvironmentRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> UpdateEnvironmentResponse {
        return try await self.client.execute(
            operation: "UpdateEnvironment", 
            path: "/environments/{environmentId}", 
            httpMethod: .PATCH, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
}

extension M2 {
    /// Initializer required by `AWSService.with(middlewares:timeout:byteBufferAllocator:options)`. You are not able to use this initializer directly as there are not public
    /// initializers for `AWSServiceConfig.Patch`. Please use `AWSService.with(middlewares:timeout:byteBufferAllocator:options)` instead.
    public init(from: M2, patch: AWSServiceConfig.Patch) {
        self.client = from.client
        self.config = from.config.with(patch: patch)
    }
}

// MARK: Paginators

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension M2 {
    /// Returns a list of the application versions for a specific application.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    public func listApplicationVersionsPaginator(
        _ input: ListApplicationVersionsRequest,
        logger: Logger = AWSClient.loggingDisabled
    ) -> AWSClient.PaginatorSequence<ListApplicationVersionsRequest, ListApplicationVersionsResponse> {
        return .init(
            input: input,
            command: self.listApplicationVersions,
            inputKey: \ListApplicationVersionsRequest.nextToken,
            outputKey: \ListApplicationVersionsResponse.nextToken,
            logger: logger
        )
    }

    /// Lists the applications associated with a specific Amazon Web Services account. You can provide the unique identifier of a specific runtime environment in a query parameter to see all applications associated with that environment.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    public func listApplicationsPaginator(
        _ input: ListApplicationsRequest,
        logger: Logger = AWSClient.loggingDisabled
    ) -> AWSClient.PaginatorSequence<ListApplicationsRequest, ListApplicationsResponse> {
        return .init(
            input: input,
            command: self.listApplications,
            inputKey: \ListApplicationsRequest.nextToken,
            outputKey: \ListApplicationsResponse.nextToken,
            logger: logger
        )
    }

    /// Lists all the available batch job definitions based on the batch job resources uploaded during the application creation. You can use the batch job definitions in the list to start a batch job.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    public func listBatchJobDefinitionsPaginator(
        _ input: ListBatchJobDefinitionsRequest,
        logger: Logger = AWSClient.loggingDisabled
    ) -> AWSClient.PaginatorSequence<ListBatchJobDefinitionsRequest, ListBatchJobDefinitionsResponse> {
        return .init(
            input: input,
            command: self.listBatchJobDefinitions,
            inputKey: \ListBatchJobDefinitionsRequest.nextToken,
            outputKey: \ListBatchJobDefinitionsResponse.nextToken,
            logger: logger
        )
    }

    /// Lists historical, current, and scheduled batch job executions for a specific application.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    public func listBatchJobExecutionsPaginator(
        _ input: ListBatchJobExecutionsRequest,
        logger: Logger = AWSClient.loggingDisabled
    ) -> AWSClient.PaginatorSequence<ListBatchJobExecutionsRequest, ListBatchJobExecutionsResponse> {
        return .init(
            input: input,
            command: self.listBatchJobExecutions,
            inputKey: \ListBatchJobExecutionsRequest.nextToken,
            outputKey: \ListBatchJobExecutionsResponse.nextToken,
            logger: logger
        )
    }

    /// Lists the data set imports for the specified application.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    public func listDataSetImportHistoryPaginator(
        _ input: ListDataSetImportHistoryRequest,
        logger: Logger = AWSClient.loggingDisabled
    ) -> AWSClient.PaginatorSequence<ListDataSetImportHistoryRequest, ListDataSetImportHistoryResponse> {
        return .init(
            input: input,
            command: self.listDataSetImportHistory,
            inputKey: \ListDataSetImportHistoryRequest.nextToken,
            outputKey: \ListDataSetImportHistoryResponse.nextToken,
            logger: logger
        )
    }

    /// Lists the data sets imported for a specific application. In Amazon Web Services Mainframe Modernization, data sets are associated with applications deployed on runtime environments. This is known as importing data sets. Currently, Amazon Web Services Mainframe Modernization can import data sets into catalogs using CreateDataSetImportTask.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    public func listDataSetsPaginator(
        _ input: ListDataSetsRequest,
        logger: Logger = AWSClient.loggingDisabled
    ) -> AWSClient.PaginatorSequence<ListDataSetsRequest, ListDataSetsResponse> {
        return .init(
            input: input,
            command: self.listDataSets,
            inputKey: \ListDataSetsRequest.nextToken,
            outputKey: \ListDataSetsResponse.nextToken,
            logger: logger
        )
    }

    /// Returns a list of all deployments of a specific application. A deployment is a combination of a specific application and a specific version of that application. Each deployment is mapped to a particular application version.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    public func listDeploymentsPaginator(
        _ input: ListDeploymentsRequest,
        logger: Logger = AWSClient.loggingDisabled
    ) -> AWSClient.PaginatorSequence<ListDeploymentsRequest, ListDeploymentsResponse> {
        return .init(
            input: input,
            command: self.listDeployments,
            inputKey: \ListDeploymentsRequest.nextToken,
            outputKey: \ListDeploymentsResponse.nextToken,
            logger: logger
        )
    }

    /// Lists the available engine versions.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    public func listEngineVersionsPaginator(
        _ input: ListEngineVersionsRequest,
        logger: Logger = AWSClient.loggingDisabled
    ) -> AWSClient.PaginatorSequence<ListEngineVersionsRequest, ListEngineVersionsResponse> {
        return .init(
            input: input,
            command: self.listEngineVersions,
            inputKey: \ListEngineVersionsRequest.nextToken,
            outputKey: \ListEngineVersionsResponse.nextToken,
            logger: logger
        )
    }

    /// Lists the runtime environments.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    public func listEnvironmentsPaginator(
        _ input: ListEnvironmentsRequest,
        logger: Logger = AWSClient.loggingDisabled
    ) -> AWSClient.PaginatorSequence<ListEnvironmentsRequest, ListEnvironmentsResponse> {
        return .init(
            input: input,
            command: self.listEnvironments,
            inputKey: \ListEnvironmentsRequest.nextToken,
            outputKey: \ListEnvironmentsResponse.nextToken,
            logger: logger
        )
    }
}

extension M2.ListApplicationVersionsRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> M2.ListApplicationVersionsRequest {
        return .init(
            applicationId: self.applicationId,
            maxResults: self.maxResults,
            nextToken: token
        )
    }
}

extension M2.ListApplicationsRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> M2.ListApplicationsRequest {
        return .init(
            environmentId: self.environmentId,
            maxResults: self.maxResults,
            names: self.names,
            nextToken: token
        )
    }
}

extension M2.ListBatchJobDefinitionsRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> M2.ListBatchJobDefinitionsRequest {
        return .init(
            applicationId: self.applicationId,
            maxResults: self.maxResults,
            nextToken: token,
            prefix: self.prefix
        )
    }
}

extension M2.ListBatchJobExecutionsRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> M2.ListBatchJobExecutionsRequest {
        return .init(
            applicationId: self.applicationId,
            executionIds: self.executionIds,
            jobName: self.jobName,
            maxResults: self.maxResults,
            nextToken: token,
            startedAfter: self.startedAfter,
            startedBefore: self.startedBefore,
            status: self.status
        )
    }
}

extension M2.ListDataSetImportHistoryRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> M2.ListDataSetImportHistoryRequest {
        return .init(
            applicationId: self.applicationId,
            maxResults: self.maxResults,
            nextToken: token
        )
    }
}

extension M2.ListDataSetsRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> M2.ListDataSetsRequest {
        return .init(
            applicationId: self.applicationId,
            maxResults: self.maxResults,
            nameFilter: self.nameFilter,
            nextToken: token,
            prefix: self.prefix
        )
    }
}

extension M2.ListDeploymentsRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> M2.ListDeploymentsRequest {
        return .init(
            applicationId: self.applicationId,
            maxResults: self.maxResults,
            nextToken: token
        )
    }
}

extension M2.ListEngineVersionsRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> M2.ListEngineVersionsRequest {
        return .init(
            engineType: self.engineType,
            maxResults: self.maxResults,
            nextToken: token
        )
    }
}

extension M2.ListEnvironmentsRequest: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> M2.ListEnvironmentsRequest {
        return .init(
            engineType: self.engineType,
            maxResults: self.maxResults,
            names: self.names,
            nextToken: token
        )
    }
}
