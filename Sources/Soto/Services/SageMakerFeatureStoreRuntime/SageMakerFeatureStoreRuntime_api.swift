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

/// Service object for interacting with AWS SageMakerFeatureStoreRuntime service.
///
/// Contains all data plane API operations and data types for the Amazon SageMaker Feature Store. Use this API to put, delete, and retrieve (get) features from a feature store. Use the following operations to configure your OnlineStore and OfflineStore features, and to create and manage feature groups:    CreateFeatureGroup     DeleteFeatureGroup     DescribeFeatureGroup     ListFeatureGroups
public struct SageMakerFeatureStoreRuntime: AWSService {
    // MARK: Member variables

    /// Client used for communication with AWS
    public let client: AWSClient
    /// Service configuration
    public let config: AWSServiceConfig

    // MARK: Initialization

    /// Initialize the SageMakerFeatureStoreRuntime client
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
            serviceName: "SageMakerFeatureStoreRuntime",
            serviceIdentifier: "featurestore-runtime.sagemaker",
            signingName: "sagemaker",
            serviceProtocol: .restjson,
            apiVersion: "2020-07-01",
            endpoint: endpoint,
            errorType: SageMakerFeatureStoreRuntimeErrorType.self,
            middleware: middleware,
            timeout: timeout,
            byteBufferAllocator: byteBufferAllocator,
            options: options
        )
    }





    // MARK: API Calls

    /// Retrieves a batch of Records from a FeatureGroup.
    @Sendable
    public func batchGetRecord(_ input: BatchGetRecordRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> BatchGetRecordResponse {
        return try await self.client.execute(
            operation: "BatchGetRecord", 
            path: "/BatchGetRecord", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Deletes a Record from a FeatureGroup in the OnlineStore. Feature Store supports both SoftDelete and HardDelete. For SoftDelete (default), feature columns are set to null and the record is no longer retrievable by GetRecord or BatchGetRecord. For HardDelete, the complete Record is removed from the OnlineStore. In both cases, Feature Store appends the deleted record marker to the OfflineStore. The deleted record marker is a record with the same RecordIdentifer as the original, but with is_deleted value set to True, EventTime set to the delete input EventTime, and other feature values set to null. Note that the EventTime specified in DeleteRecord should be set later than the EventTime of the existing record in the OnlineStore for that RecordIdentifer. If it is not, the deletion does not occur:   For SoftDelete, the existing (not deleted) record remains in the OnlineStore, though the delete record marker is still written to the OfflineStore.    HardDelete returns EventTime: 400 ValidationException to indicate that the delete operation failed. No delete record marker is written to the OfflineStore.   When a record is deleted from the OnlineStore, the deleted record marker is appended to the OfflineStore. If you have the Iceberg table format enabled for your OfflineStore, you can remove all history of a record from the OfflineStore using Amazon Athena or Apache Spark. For information on how to hard delete a record from the OfflineStore with the Iceberg table format enabled, see Delete records from the offline store.
    @Sendable
    public func deleteRecord(_ input: DeleteRecordRequest, logger: Logger = AWSClient.loggingDisabled) async throws {
        return try await self.client.execute(
            operation: "DeleteRecord", 
            path: "/FeatureGroup/{FeatureGroupName}", 
            httpMethod: .DELETE, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// Use for OnlineStore serving from a FeatureStore. Only the latest records stored in the OnlineStore can be retrieved. If no Record with RecordIdentifierValue is found, then an empty result is returned.
    @Sendable
    public func getRecord(_ input: GetRecordRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> GetRecordResponse {
        return try await self.client.execute(
            operation: "GetRecord", 
            path: "/FeatureGroup/{FeatureGroupName}", 
            httpMethod: .GET, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }

    /// The PutRecord API is used to ingest a list of Records into your feature group.  If a new record’s EventTime is greater, the new record is written to both the OnlineStore and OfflineStore. Otherwise, the record is a historic record and it is written only to the OfflineStore.  You can specify the ingestion to be applied to the OnlineStore, OfflineStore, or both by using the TargetStores request parameter.  You can set the ingested record to expire at a given time to live (TTL) duration after the record’s event time, ExpiresAt = EventTime + TtlDuration, by specifying the TtlDuration parameter. A record level TtlDuration is set when specifying the TtlDuration parameter using the PutRecord API call. If the input TtlDuration is null or unspecified, TtlDuration is set to the default feature group level TtlDuration. A record level TtlDuration supersedes the group level TtlDuration.
    @Sendable
    public func putRecord(_ input: PutRecordRequest, logger: Logger = AWSClient.loggingDisabled) async throws {
        return try await self.client.execute(
            operation: "PutRecord", 
            path: "/FeatureGroup/{FeatureGroupName}", 
            httpMethod: .PUT, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
}

extension SageMakerFeatureStoreRuntime {
    /// Initializer required by `AWSService.with(middlewares:timeout:byteBufferAllocator:options)`. You are not able to use this initializer directly as there are not public
    /// initializers for `AWSServiceConfig.Patch`. Please use `AWSService.with(middlewares:timeout:byteBufferAllocator:options)` instead.
    public init(from: SageMakerFeatureStoreRuntime, patch: AWSServiceConfig.Patch) {
        self.client = from.client
        self.config = from.config.with(patch: patch)
    }
}
