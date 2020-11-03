//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// THIS FILE IS AUTOMATICALLY GENERATED by https://github.com/soto-project/soto/tree/main/CodeGenerator. DO NOT EDIT.

import SotoCore

// MARK: Paginators

extension CodeBuild {
    ///  Retrieves one or more code coverage reports.
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
    public func describeCodeCoveragesPaginator<Result>(
        _ input: DescribeCodeCoveragesInput,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, DescribeCodeCoveragesOutput, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: describeCodeCoverages,
            tokenKey: \DescribeCodeCoveragesOutput.nextToken,
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
    public func describeCodeCoveragesPaginator(
        _ input: DescribeCodeCoveragesInput,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (DescribeCodeCoveragesOutput, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: describeCodeCoverages,
            tokenKey: \DescribeCodeCoveragesOutput.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///   Returns a list of details about test cases for a report.
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
    public func describeTestCasesPaginator<Result>(
        _ input: DescribeTestCasesInput,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, DescribeTestCasesOutput, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: describeTestCases,
            tokenKey: \DescribeTestCasesOutput.nextToken,
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
    public func describeTestCasesPaginator(
        _ input: DescribeTestCasesInput,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (DescribeTestCasesOutput, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: describeTestCases,
            tokenKey: \DescribeTestCasesOutput.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///  Retrieves the identifiers of your build batches in the current region.
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
    public func listBuildBatchesPaginator<Result>(
        _ input: ListBuildBatchesInput,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, ListBuildBatchesOutput, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: listBuildBatches,
            tokenKey: \ListBuildBatchesOutput.nextToken,
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
    public func listBuildBatchesPaginator(
        _ input: ListBuildBatchesInput,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (ListBuildBatchesOutput, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listBuildBatches,
            tokenKey: \ListBuildBatchesOutput.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///  Retrieves the identifiers of the build batches for a specific project.
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
    public func listBuildBatchesForProjectPaginator<Result>(
        _ input: ListBuildBatchesForProjectInput,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, ListBuildBatchesForProjectOutput, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: listBuildBatchesForProject,
            tokenKey: \ListBuildBatchesForProjectOutput.nextToken,
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
    public func listBuildBatchesForProjectPaginator(
        _ input: ListBuildBatchesForProjectInput,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (ListBuildBatchesForProjectOutput, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listBuildBatchesForProject,
            tokenKey: \ListBuildBatchesForProjectOutput.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///  Gets a list of build IDs, with each build ID representing a single build.
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
    public func listBuildsPaginator<Result>(
        _ input: ListBuildsInput,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, ListBuildsOutput, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: listBuilds,
            tokenKey: \ListBuildsOutput.nextToken,
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
    public func listBuildsPaginator(
        _ input: ListBuildsInput,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (ListBuildsOutput, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listBuilds,
            tokenKey: \ListBuildsOutput.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///  Gets a list of build IDs for the specified build project, with each build ID representing a single build.
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
    public func listBuildsForProjectPaginator<Result>(
        _ input: ListBuildsForProjectInput,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, ListBuildsForProjectOutput, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: listBuildsForProject,
            tokenKey: \ListBuildsForProjectOutput.nextToken,
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
    public func listBuildsForProjectPaginator(
        _ input: ListBuildsForProjectInput,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (ListBuildsForProjectOutput, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listBuildsForProject,
            tokenKey: \ListBuildsForProjectOutput.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///  Gets a list of build project names, with each build project name representing a single build project.
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
    public func listProjectsPaginator<Result>(
        _ input: ListProjectsInput,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, ListProjectsOutput, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: listProjects,
            tokenKey: \ListProjectsOutput.nextToken,
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
    public func listProjectsPaginator(
        _ input: ListProjectsInput,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (ListProjectsOutput, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listProjects,
            tokenKey: \ListProjectsOutput.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///   Gets a list ARNs for the report groups in the current AWS account.
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
    public func listReportGroupsPaginator<Result>(
        _ input: ListReportGroupsInput,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, ListReportGroupsOutput, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: listReportGroups,
            tokenKey: \ListReportGroupsOutput.nextToken,
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
    public func listReportGroupsPaginator(
        _ input: ListReportGroupsInput,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (ListReportGroupsOutput, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listReportGroups,
            tokenKey: \ListReportGroupsOutput.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///   Returns a list of ARNs for the reports in the current AWS account.
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
    public func listReportsPaginator<Result>(
        _ input: ListReportsInput,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, ListReportsOutput, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: listReports,
            tokenKey: \ListReportsOutput.nextToken,
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
    public func listReportsPaginator(
        _ input: ListReportsInput,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (ListReportsOutput, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listReports,
            tokenKey: \ListReportsOutput.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///   Returns a list of ARNs for the reports that belong to a ReportGroup.
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
    public func listReportsForReportGroupPaginator<Result>(
        _ input: ListReportsForReportGroupInput,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, ListReportsForReportGroupOutput, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: listReportsForReportGroup,
            tokenKey: \ListReportsForReportGroupOutput.nextToken,
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
    public func listReportsForReportGroupPaginator(
        _ input: ListReportsForReportGroupInput,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (ListReportsForReportGroupOutput, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listReportsForReportGroup,
            tokenKey: \ListReportsForReportGroupOutput.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///   Gets a list of projects that are shared with other AWS accounts or users.
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
    public func listSharedProjectsPaginator<Result>(
        _ input: ListSharedProjectsInput,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, ListSharedProjectsOutput, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: listSharedProjects,
            tokenKey: \ListSharedProjectsOutput.nextToken,
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
    public func listSharedProjectsPaginator(
        _ input: ListSharedProjectsInput,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (ListSharedProjectsOutput, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listSharedProjects,
            tokenKey: \ListSharedProjectsOutput.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }

    ///   Gets a list of report groups that are shared with other AWS accounts or users.
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
    public func listSharedReportGroupsPaginator<Result>(
        _ input: ListSharedReportGroupsInput,
        _ initialValue: Result,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, ListSharedReportGroupsOutput, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: listSharedReportGroups,
            tokenKey: \ListSharedReportGroupsOutput.nextToken,
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
    public func listSharedReportGroupsPaginator(
        _ input: ListSharedReportGroupsInput,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (ListSharedReportGroupsOutput, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: listSharedReportGroups,
            tokenKey: \ListSharedReportGroupsOutput.nextToken,
            on: eventLoop,
            onPage: onPage
        )
    }
}

extension CodeBuild.DescribeCodeCoveragesInput: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> CodeBuild.DescribeCodeCoveragesInput {
        return .init(
            maxLineCoveragePercentage: self.maxLineCoveragePercentage,
            maxResults: self.maxResults,
            minLineCoveragePercentage: self.minLineCoveragePercentage,
            nextToken: token,
            reportArn: self.reportArn,
            sortBy: self.sortBy,
            sortOrder: self.sortOrder
        )
    }
}

extension CodeBuild.DescribeTestCasesInput: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> CodeBuild.DescribeTestCasesInput {
        return .init(
            filter: self.filter,
            maxResults: self.maxResults,
            nextToken: token,
            reportArn: self.reportArn
        )
    }
}

extension CodeBuild.ListBuildBatchesInput: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> CodeBuild.ListBuildBatchesInput {
        return .init(
            filter: self.filter,
            maxResults: self.maxResults,
            nextToken: token,
            sortOrder: self.sortOrder
        )
    }
}

extension CodeBuild.ListBuildBatchesForProjectInput: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> CodeBuild.ListBuildBatchesForProjectInput {
        return .init(
            filter: self.filter,
            maxResults: self.maxResults,
            nextToken: token,
            projectName: self.projectName,
            sortOrder: self.sortOrder
        )
    }
}

extension CodeBuild.ListBuildsInput: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> CodeBuild.ListBuildsInput {
        return .init(
            nextToken: token,
            sortOrder: self.sortOrder
        )
    }
}

extension CodeBuild.ListBuildsForProjectInput: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> CodeBuild.ListBuildsForProjectInput {
        return .init(
            nextToken: token,
            projectName: self.projectName,
            sortOrder: self.sortOrder
        )
    }
}

extension CodeBuild.ListProjectsInput: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> CodeBuild.ListProjectsInput {
        return .init(
            nextToken: token,
            sortBy: self.sortBy,
            sortOrder: self.sortOrder
        )
    }
}

extension CodeBuild.ListReportGroupsInput: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> CodeBuild.ListReportGroupsInput {
        return .init(
            maxResults: self.maxResults,
            nextToken: token,
            sortBy: self.sortBy,
            sortOrder: self.sortOrder
        )
    }
}

extension CodeBuild.ListReportsInput: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> CodeBuild.ListReportsInput {
        return .init(
            filter: self.filter,
            maxResults: self.maxResults,
            nextToken: token,
            sortOrder: self.sortOrder
        )
    }
}

extension CodeBuild.ListReportsForReportGroupInput: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> CodeBuild.ListReportsForReportGroupInput {
        return .init(
            filter: self.filter,
            maxResults: self.maxResults,
            nextToken: token,
            reportGroupArn: self.reportGroupArn,
            sortOrder: self.sortOrder
        )
    }
}

extension CodeBuild.ListSharedProjectsInput: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> CodeBuild.ListSharedProjectsInput {
        return .init(
            maxResults: self.maxResults,
            nextToken: token,
            sortBy: self.sortBy,
            sortOrder: self.sortOrder
        )
    }
}

extension CodeBuild.ListSharedReportGroupsInput: AWSPaginateToken {
    public func usingPaginationToken(_ token: String) -> CodeBuild.ListSharedReportGroupsInput {
        return .init(
            maxResults: self.maxResults,
            nextToken: token,
            sortBy: self.sortBy,
            sortOrder: self.sortOrder
        )
    }
}