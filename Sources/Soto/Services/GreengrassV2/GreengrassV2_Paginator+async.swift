//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2021 the Soto project authors
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

#if compiler(>=5.5) && canImport(_Concurrency)

import SotoCore

// MARK: Paginators

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension GreengrassV2 {
    ///  Retrieves a paginated list of client devices that are associated with a core device.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listClientDevicesAssociatedWithCoreDevicePaginator(
        _ input: ListClientDevicesAssociatedWithCoreDeviceRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListClientDevicesAssociatedWithCoreDeviceRequest, ListClientDevicesAssociatedWithCoreDeviceResponse> {
        return .init(
            input: input,
            command: listClientDevicesAssociatedWithCoreDevice,
            inputKey: \ListClientDevicesAssociatedWithCoreDeviceRequest.nextToken,
            outputKey: \ListClientDevicesAssociatedWithCoreDeviceResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    ///  Retrieves a paginated list of all versions for a component. Greater versions are listed first.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listComponentVersionsPaginator(
        _ input: ListComponentVersionsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListComponentVersionsRequest, ListComponentVersionsResponse> {
        return .init(
            input: input,
            command: listComponentVersions,
            inputKey: \ListComponentVersionsRequest.nextToken,
            outputKey: \ListComponentVersionsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    ///  Retrieves a paginated list of component summaries. This list includes components that you have permission to view.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listComponentsPaginator(
        _ input: ListComponentsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListComponentsRequest, ListComponentsResponse> {
        return .init(
            input: input,
            command: listComponents,
            inputKey: \ListComponentsRequest.nextToken,
            outputKey: \ListComponentsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    ///  Retrieves a paginated list of Greengrass core devices.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listCoreDevicesPaginator(
        _ input: ListCoreDevicesRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListCoreDevicesRequest, ListCoreDevicesResponse> {
        return .init(
            input: input,
            command: listCoreDevices,
            inputKey: \ListCoreDevicesRequest.nextToken,
            outputKey: \ListCoreDevicesResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    ///  Retrieves a paginated list of deployments.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listDeploymentsPaginator(
        _ input: ListDeploymentsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListDeploymentsRequest, ListDeploymentsResponse> {
        return .init(
            input: input,
            command: listDeployments,
            inputKey: \ListDeploymentsRequest.nextToken,
            outputKey: \ListDeploymentsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    ///  Retrieves a paginated list of deployment jobs that IoT Greengrass sends to Greengrass core devices.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listEffectiveDeploymentsPaginator(
        _ input: ListEffectiveDeploymentsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListEffectiveDeploymentsRequest, ListEffectiveDeploymentsResponse> {
        return .init(
            input: input,
            command: listEffectiveDeployments,
            inputKey: \ListEffectiveDeploymentsRequest.nextToken,
            outputKey: \ListEffectiveDeploymentsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    ///  Retrieves a paginated list of the components that a Greengrass core device runs.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listInstalledComponentsPaginator(
        _ input: ListInstalledComponentsRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListInstalledComponentsRequest, ListInstalledComponentsResponse> {
        return .init(
            input: input,
            command: listInstalledComponents,
            inputKey: \ListInstalledComponentsRequest.nextToken,
            outputKey: \ListInstalledComponentsResponse.nextToken,
            logger: logger,
            on: eventLoop
        )
    }
}

#endif // compiler(>=5.5) && canImport(_Concurrency)