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
@_spi(SotoInternal) import SotoCore

extension Forecastquery {
    // MARK: Enums

    // MARK: Shapes

    public struct DataPoint: AWSDecodableShape {
        /// The timestamp of the specific forecast.
        public let timestamp: String?
        /// The forecast value.
        public let value: Double?

        @inlinable
        public init(timestamp: String? = nil, value: Double? = nil) {
            self.timestamp = timestamp
            self.value = value
        }

        private enum CodingKeys: String, CodingKey {
            case timestamp = "Timestamp"
            case value = "Value"
        }
    }

    public struct Forecast: AWSDecodableShape {
        /// The forecast. The string of the string-to-array map is one of the following values:   p10   p50   p90   The default setting is ["0.1", "0.5", "0.9"]. Use the optional ForecastTypes parameter of the CreateForecast operation to change the values. The values will vary depending on how this is set, with a minimum of 1 and a maximum of 5.
        public let predictions: [String: [DataPoint]]?

        @inlinable
        public init(predictions: [String: [DataPoint]]? = nil) {
            self.predictions = predictions
        }

        private enum CodingKeys: String, CodingKey {
            case predictions = "Predictions"
        }
    }

    public struct QueryForecastRequest: AWSEncodableShape {
        /// The end date for the forecast. Specify the date using this format: yyyy-MM-dd'T'HH:mm:ss (ISO 8601 format). For example, 2015-01-01T20:00:00.
        public let endDate: String?
        /// The filtering criteria to apply when retrieving the forecast. For example, to get the forecast for client_21 in the electricity usage dataset, specify the following:  {"item_id" : "client_21"}    To get the full forecast, use the CreateForecastExportJob operation.
        public let filters: [String: String]
        /// The Amazon Resource Name (ARN) of the forecast to query.
        public let forecastArn: String
        /// If the result of the previous request was truncated, the response includes a NextToken. To retrieve the next set of results, use the token in the next request. Tokens expire after 24 hours.
        public let nextToken: String?
        /// The start date for the forecast. Specify the date using this format: yyyy-MM-dd'T'HH:mm:ss (ISO 8601 format). For example, 2015-01-01T08:00:00.
        public let startDate: String?

        @inlinable
        public init(endDate: String? = nil, filters: [String: String], forecastArn: String, nextToken: String? = nil, startDate: String? = nil) {
            self.endDate = endDate
            self.filters = filters
            self.forecastArn = forecastArn
            self.nextToken = nextToken
            self.startDate = startDate
        }

        public func validate(name: String) throws {
            try self.filters.forEach {
                try validate($0.key, name: "filters.key", parent: name, max: 256)
                try validate($0.key, name: "filters.key", parent: name, pattern: "^[a-zA-Z0-9\\_\\-]+$")
                try validate($0.value, name: "filters[\"\($0.key)\"]", parent: name, max: 256)
            }
            try self.validate(self.filters, name: "filters", parent: name, max: 50)
            try self.validate(self.filters, name: "filters", parent: name, min: 1)
            try self.validate(self.forecastArn, name: "forecastArn", parent: name, max: 256)
            try self.validate(self.forecastArn, name: "forecastArn", parent: name, pattern: "^arn:([a-z\\d-]+):forecast:.*:.*:.+$")
            try self.validate(self.nextToken, name: "nextToken", parent: name, max: 3000)
            try self.validate(self.nextToken, name: "nextToken", parent: name, min: 1)
        }

        private enum CodingKeys: String, CodingKey {
            case endDate = "EndDate"
            case filters = "Filters"
            case forecastArn = "ForecastArn"
            case nextToken = "NextToken"
            case startDate = "StartDate"
        }
    }

    public struct QueryForecastResponse: AWSDecodableShape {
        /// The forecast.
        public let forecast: Forecast?

        @inlinable
        public init(forecast: Forecast? = nil) {
            self.forecast = forecast
        }

        private enum CodingKeys: String, CodingKey {
            case forecast = "Forecast"
        }
    }

    public struct QueryWhatIfForecastRequest: AWSEncodableShape {
        /// The end date for the what-if forecast. Specify the date using this format: yyyy-MM-dd'T'HH:mm:ss (ISO 8601 format). For example, 2015-01-01T20:00:00.
        public let endDate: String?
        /// The filtering criteria to apply when retrieving the forecast. For example, to get the forecast for client_21 in the electricity usage dataset, specify the following:  {"item_id" : "client_21"}  To get the full what-if forecast, use the CreateForecastExportJob operation.
        public let filters: [String: String]
        /// If the result of the previous request was truncated, the response includes a NextToken. To retrieve the next set of results, use the token in the next request. Tokens expire after 24 hours.
        public let nextToken: String?
        /// The start date for the what-if forecast. Specify the date using this format: yyyy-MM-dd'T'HH:mm:ss (ISO 8601 format). For example, 2015-01-01T08:00:00.
        public let startDate: String?
        /// The Amazon Resource Name (ARN) of the what-if forecast to query.
        public let whatIfForecastArn: String

        @inlinable
        public init(endDate: String? = nil, filters: [String: String], nextToken: String? = nil, startDate: String? = nil, whatIfForecastArn: String) {
            self.endDate = endDate
            self.filters = filters
            self.nextToken = nextToken
            self.startDate = startDate
            self.whatIfForecastArn = whatIfForecastArn
        }

        public func validate(name: String) throws {
            try self.filters.forEach {
                try validate($0.key, name: "filters.key", parent: name, max: 256)
                try validate($0.key, name: "filters.key", parent: name, pattern: "^[a-zA-Z0-9\\_\\-]+$")
                try validate($0.value, name: "filters[\"\($0.key)\"]", parent: name, max: 256)
            }
            try self.validate(self.filters, name: "filters", parent: name, max: 50)
            try self.validate(self.filters, name: "filters", parent: name, min: 1)
            try self.validate(self.nextToken, name: "nextToken", parent: name, max: 3000)
            try self.validate(self.nextToken, name: "nextToken", parent: name, min: 1)
            try self.validate(self.whatIfForecastArn, name: "whatIfForecastArn", parent: name, max: 300)
            try self.validate(self.whatIfForecastArn, name: "whatIfForecastArn", parent: name, pattern: "^arn:([a-z\\d-]+):forecast:.*:.*:.+$")
        }

        private enum CodingKeys: String, CodingKey {
            case endDate = "EndDate"
            case filters = "Filters"
            case nextToken = "NextToken"
            case startDate = "StartDate"
            case whatIfForecastArn = "WhatIfForecastArn"
        }
    }

    public struct QueryWhatIfForecastResponse: AWSDecodableShape {
        public let forecast: Forecast?

        @inlinable
        public init(forecast: Forecast? = nil) {
            self.forecast = forecast
        }

        private enum CodingKeys: String, CodingKey {
            case forecast = "Forecast"
        }
    }
}

// MARK: - Errors

/// Error enum for Forecastquery
public struct ForecastqueryErrorType: AWSErrorType {
    enum Code: String {
        case invalidInputException = "InvalidInputException"
        case invalidNextTokenException = "InvalidNextTokenException"
        case limitExceededException = "LimitExceededException"
        case resourceInUseException = "ResourceInUseException"
        case resourceNotFoundException = "ResourceNotFoundException"
    }

    private let error: Code
    public let context: AWSErrorContext?

    /// initialize Forecastquery
    public init?(errorCode: String, context: AWSErrorContext) {
        guard let error = Code(rawValue: errorCode) else { return nil }
        self.error = error
        self.context = context
    }

    internal init(_ error: Code) {
        self.error = error
        self.context = nil
    }

    /// return error code string
    public var errorCode: String { self.error.rawValue }

    /// The value is invalid or is too long.
    public static var invalidInputException: Self { .init(.invalidInputException) }
    /// The token is not valid. Tokens expire after 24 hours.
    public static var invalidNextTokenException: Self { .init(.invalidNextTokenException) }
    /// The limit on the number of requests per second has been exceeded.
    public static var limitExceededException: Self { .init(.limitExceededException) }
    /// The specified resource is in use.
    public static var resourceInUseException: Self { .init(.resourceInUseException) }
    /// We can't find that resource. Check the information that you've provided and try again.
    public static var resourceNotFoundException: Self { .init(.resourceNotFoundException) }
}

extension ForecastqueryErrorType: Equatable {
    public static func == (lhs: ForecastqueryErrorType, rhs: ForecastqueryErrorType) -> Bool {
        lhs.error == rhs.error
    }
}

extension ForecastqueryErrorType: CustomStringConvertible {
    public var description: String {
        return "\(self.error.rawValue): \(self.message ?? "")"
    }
}
