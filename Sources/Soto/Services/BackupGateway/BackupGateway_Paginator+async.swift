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

// THIS FILE IS AUTOMATICALLY GENERATED by https://github.com/soto-project/soto/tree/main/CodeGenerator. DO NOT EDIT.

#if compiler(>=5.5) && canImport(_Concurrency)

import SotoCore

// MARK: Paginators

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension BackupGateway {
    ///  Lists backup gateways owned by an Amazon Web Services account in an Amazon Web Services Region. The returned list is ordered by gateway Amazon Resource Name (ARN).
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listGatewaysPaginator(
        _ input: ListGatewaysInput,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListGatewaysInput, ListGatewaysOutput> {
        return .init(
            input: input,
            command: listGateways,
            inputKey: \ListGatewaysInput.nextToken,
            outputKey: \ListGatewaysOutput.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    ///  Lists your hypervisors.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listHypervisorsPaginator(
        _ input: ListHypervisorsInput,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListHypervisorsInput, ListHypervisorsOutput> {
        return .init(
            input: input,
            command: listHypervisors,
            inputKey: \ListHypervisorsInput.nextToken,
            outputKey: \ListHypervisorsOutput.nextToken,
            logger: logger,
            on: eventLoop
        )
    }

    ///  Lists your virtual machines.
    /// Return PaginatorSequence for operation.
    ///
    /// - Parameters:
    ///   - input: Input for request
    ///   - logger: Logger used flot logging
    ///   - eventLoop: EventLoop to run this process on
    public func listVirtualMachinesPaginator(
        _ input: ListVirtualMachinesInput,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ListVirtualMachinesInput, ListVirtualMachinesOutput> {
        return .init(
            input: input,
            command: listVirtualMachines,
            inputKey: \ListVirtualMachinesInput.nextToken,
            outputKey: \ListVirtualMachinesOutput.nextToken,
            logger: logger,
            on: eventLoop
        )
    }
}

#endif // compiler(>=5.5) && canImport(_Concurrency)