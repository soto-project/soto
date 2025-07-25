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

extension Pricing {
    // MARK: Enums

    public enum FilterType: String, CustomStringConvertible, Codable, Sendable, CodingKeyRepresentable {
        case anyOf = "ANY_OF"
        case contains = "CONTAINS"
        case equals = "EQUALS"
        case noneOf = "NONE_OF"
        case termMatch = "TERM_MATCH"
        public var description: String { return self.rawValue }
    }

    // MARK: Shapes

    public struct AttributeValue: AWSDecodableShape {
        /// The specific value of an attributeName.
        public let value: String?

        @inlinable
        public init(value: String? = nil) {
            self.value = value
        }

        private enum CodingKeys: String, CodingKey {
            case value = "Value"
        }
    }

    public struct DescribeServicesRequest: AWSEncodableShape {
        /// The format version that you want the response to be in. Valid values are: aws_v1
        public let formatVersion: String?
        /// The maximum number of results that you want returned in the response.
        public let maxResults: Int?
        /// The pagination token that indicates the next set of results that you want to retrieve.
        public let nextToken: String?
        /// The code for the service whose information you want to retrieve, such as AmazonEC2. You can use  the ServiceCode to filter the results in a GetProducts call. To retrieve a list of all services, leave this blank.
        public let serviceCode: String?

        @inlinable
        public init(formatVersion: String? = nil, maxResults: Int? = nil, nextToken: String? = nil, serviceCode: String? = nil) {
            self.formatVersion = formatVersion
            self.maxResults = maxResults
            self.nextToken = nextToken
            self.serviceCode = serviceCode
        }

        public func validate(name: String) throws {
            try self.validate(self.formatVersion, name: "formatVersion", parent: name, max: 32)
            try self.validate(self.formatVersion, name: "formatVersion", parent: name, min: 1)
            try self.validate(self.maxResults, name: "maxResults", parent: name, max: 100)
            try self.validate(self.maxResults, name: "maxResults", parent: name, min: 1)
        }

        private enum CodingKeys: String, CodingKey {
            case formatVersion = "FormatVersion"
            case maxResults = "MaxResults"
            case nextToken = "NextToken"
            case serviceCode = "ServiceCode"
        }
    }

    public struct DescribeServicesResponse: AWSDecodableShape {
        /// The format version of the response. For example, aws_v1.
        public let formatVersion: String?
        /// The pagination token for the next set of retrievable results.
        public let nextToken: String?
        /// The service metadata for the service or services in the response.
        public let services: [Service]?

        @inlinable
        public init(formatVersion: String? = nil, nextToken: String? = nil, services: [Service]? = nil) {
            self.formatVersion = formatVersion
            self.nextToken = nextToken
            self.services = services
        }

        private enum CodingKeys: String, CodingKey {
            case formatVersion = "FormatVersion"
            case nextToken = "NextToken"
            case services = "Services"
        }
    }

    public struct Filter: AWSEncodableShape {
        /// The product metadata field that you want to filter on. You can filter by just the  service code to see all products for a specific service, filter  by just the attribute name to see a specific attribute for multiple services, or use both a service code and an attribute name to retrieve only products that match both fields. Valid values include: ServiceCode, and all attribute names For example, you can filter by the AmazonEC2 service code and the  volumeType attribute name to get the prices for only Amazon EC2 volumes.
        public let field: String
        /// The type of filter that you want to use. Valid values are:    TERM_MATCH: Returns only  products that match both the given filter field and the given value.    EQUALS: Returns products that have a field value exactly matching the provided value.    CONTAINS: Returns products where the field value contains the provided value as a substring.    ANY_OF: Returns products where the field value is any of the provided values.    NONE_OF: Returns products where the field value is not any of the provided values.
        public let type: FilterType
        /// The service code or attribute value that you want to filter by. If you're filtering by service code this is the actual service code, such as AmazonEC2. If you're filtering by attribute name, this is the attribute value that you want the returned products to match, such as a Provisioned IOPS volume. For ANY_OF and NONE_OF filter types, you can provide multiple values as a comma-separated string. For example, t2.micro,t2.small,t2.medium or Compute optimized, GPU instance, Micro instances.
        public let value: String

        @inlinable
        public init(field: String, type: FilterType, value: String) {
            self.field = field
            self.type = type
            self.value = value
        }

        public func validate(name: String) throws {
            try self.validate(self.field, name: "field", parent: name, max: 1024)
            try self.validate(self.field, name: "field", parent: name, min: 1)
            try self.validate(self.value, name: "value", parent: name, max: 1024)
            try self.validate(self.value, name: "value", parent: name, min: 1)
        }

        private enum CodingKeys: String, CodingKey {
            case field = "Field"
            case type = "Type"
            case value = "Value"
        }
    }

    public struct GetAttributeValuesRequest: AWSEncodableShape {
        /// The name of the attribute that you want to retrieve the values for, such as volumeType.
        public let attributeName: String
        /// The maximum number of results to return in response.
        public let maxResults: Int?
        /// The pagination token that indicates the next set of results that you want to retrieve.
        public let nextToken: String?
        /// The service code for the service whose attributes you want to retrieve. For example, if you want  the retrieve an EC2 attribute, use AmazonEC2.
        public let serviceCode: String

        @inlinable
        public init(attributeName: String, maxResults: Int? = nil, nextToken: String? = nil, serviceCode: String) {
            self.attributeName = attributeName
            self.maxResults = maxResults
            self.nextToken = nextToken
            self.serviceCode = serviceCode
        }

        public func validate(name: String) throws {
            try self.validate(self.maxResults, name: "maxResults", parent: name, max: 100)
            try self.validate(self.maxResults, name: "maxResults", parent: name, min: 1)
        }

        private enum CodingKeys: String, CodingKey {
            case attributeName = "AttributeName"
            case maxResults = "MaxResults"
            case nextToken = "NextToken"
            case serviceCode = "ServiceCode"
        }
    }

    public struct GetAttributeValuesResponse: AWSDecodableShape {
        /// The list of values for an attribute. For example, Throughput Optimized HDD and  Provisioned IOPS are two available values for the AmazonEC2 volumeType.
        public let attributeValues: [AttributeValue]?
        /// The pagination token that indicates the next set of results to retrieve.
        public let nextToken: String?

        @inlinable
        public init(attributeValues: [AttributeValue]? = nil, nextToken: String? = nil) {
            self.attributeValues = attributeValues
            self.nextToken = nextToken
        }

        private enum CodingKeys: String, CodingKey {
            case attributeValues = "AttributeValues"
            case nextToken = "NextToken"
        }
    }

    public struct GetPriceListFileUrlRequest: AWSEncodableShape {
        /// The format that you want to retrieve your Price List files in. The FileFormat can be obtained from the ListPriceLists response.
        public let fileFormat: String
        /// The unique identifier that maps to where your Price List files are located. PriceListArn can be obtained from the ListPriceLists response.
        public let priceListArn: String

        @inlinable
        public init(fileFormat: String, priceListArn: String) {
            self.fileFormat = fileFormat
            self.priceListArn = priceListArn
        }

        public func validate(name: String) throws {
            try self.validate(self.fileFormat, name: "fileFormat", parent: name, max: 255)
            try self.validate(self.fileFormat, name: "fileFormat", parent: name, min: 1)
            try self.validate(self.priceListArn, name: "priceListArn", parent: name, max: 2048)
            try self.validate(self.priceListArn, name: "priceListArn", parent: name, min: 18)
            try self.validate(self.priceListArn, name: "priceListArn", parent: name, pattern: "^arn:[A-Za-z0-9][-.A-Za-z0-9]{0,62}:pricing:::price-list/[A-Za-z0-9+_/.-]{1,1023}$")
        }

        private enum CodingKeys: String, CodingKey {
            case fileFormat = "FileFormat"
            case priceListArn = "PriceListArn"
        }
    }

    public struct GetPriceListFileUrlResponse: AWSDecodableShape {
        /// The URL to download your Price List file from.
        public let url: String?

        @inlinable
        public init(url: String? = nil) {
            self.url = url
        }

        private enum CodingKeys: String, CodingKey {
            case url = "Url"
        }
    }

    public struct GetProductsRequest: AWSEncodableShape {
        /// The list of filters that limit the returned products. only products that match all filters are returned.
        public let filters: [Filter]?
        /// The format version that you want the response to be in. Valid values are: aws_v1
        public let formatVersion: String?
        /// The maximum number of results to return in the response.
        public let maxResults: Int?
        /// The pagination token that indicates the next set of results that you want to retrieve.
        public let nextToken: String?
        /// The code for the service whose products you want to retrieve.
        public let serviceCode: String

        @inlinable
        public init(filters: [Filter]? = nil, formatVersion: String? = nil, maxResults: Int? = nil, nextToken: String? = nil, serviceCode: String) {
            self.filters = filters
            self.formatVersion = formatVersion
            self.maxResults = maxResults
            self.nextToken = nextToken
            self.serviceCode = serviceCode
        }

        public func validate(name: String) throws {
            try self.filters?.forEach {
                try $0.validate(name: "\(name).filters[]")
            }
            try self.validate(self.filters, name: "filters", parent: name, max: 50)
            try self.validate(self.formatVersion, name: "formatVersion", parent: name, max: 32)
            try self.validate(self.formatVersion, name: "formatVersion", parent: name, min: 1)
            try self.validate(self.maxResults, name: "maxResults", parent: name, max: 100)
            try self.validate(self.maxResults, name: "maxResults", parent: name, min: 1)
        }

        private enum CodingKeys: String, CodingKey {
            case filters = "Filters"
            case formatVersion = "FormatVersion"
            case maxResults = "MaxResults"
            case nextToken = "NextToken"
            case serviceCode = "ServiceCode"
        }
    }

    public struct GetProductsResponse: AWSDecodableShape {
        /// The format version of the response. For example, aws_v1.
        public let formatVersion: String?
        /// The pagination token that indicates the next set of results to retrieve.
        public let nextToken: String?
        /// The list of products that match your filters. The list contains both the product metadata and  the price information.
        public let priceList: [String]?

        @inlinable
        public init(formatVersion: String? = nil, nextToken: String? = nil, priceList: [String]? = nil) {
            self.formatVersion = formatVersion
            self.nextToken = nextToken
            self.priceList = priceList
        }

        private enum CodingKeys: String, CodingKey {
            case formatVersion = "FormatVersion"
            case nextToken = "NextToken"
            case priceList = "PriceList"
        }
    }

    public struct ListPriceListsRequest: AWSEncodableShape {
        /// The three alphabetical character ISO-4217 currency code that the Price List files are denominated in.
        public let currencyCode: String
        /// The date that the Price List file prices are effective from.
        public let effectiveDate: Date
        /// The maximum number of results to return in the response.
        public let maxResults: Int?
        /// The pagination token that indicates the next set of results that you want to retrieve.
        public let nextToken: String?
        /// This is used to filter the Price List by Amazon Web Services Region. For example, to get the price list only for the US East (N. Virginia) Region, use us-east-1. If nothing is specified, you retrieve price lists for all applicable Regions. The available RegionCode list can be retrieved from GetAttributeValues API.
        public let regionCode: String?
        /// The service code or the Savings Plan service code for the attributes that you want to retrieve. For example, to get the list of applicable Amazon EC2 price lists, use AmazonEC2. For a full list of service codes containing On-Demand and Reserved Instance (RI) pricing, use the DescribeServices API. To retrieve the Reserved Instance and Compute Savings Plan price lists, use ComputeSavingsPlans.  To retrieve Machine Learning Savings Plans price lists, use MachineLearningSavingsPlans.
        public let serviceCode: String

        @inlinable
        public init(currencyCode: String, effectiveDate: Date, maxResults: Int? = nil, nextToken: String? = nil, regionCode: String? = nil, serviceCode: String) {
            self.currencyCode = currencyCode
            self.effectiveDate = effectiveDate
            self.maxResults = maxResults
            self.nextToken = nextToken
            self.regionCode = regionCode
            self.serviceCode = serviceCode
        }

        public func validate(name: String) throws {
            try self.validate(self.currencyCode, name: "currencyCode", parent: name, pattern: "^[A-Z]{3}$")
            try self.validate(self.maxResults, name: "maxResults", parent: name, max: 100)
            try self.validate(self.maxResults, name: "maxResults", parent: name, min: 1)
            try self.validate(self.regionCode, name: "regionCode", parent: name, max: 255)
            try self.validate(self.regionCode, name: "regionCode", parent: name, min: 1)
            try self.validate(self.serviceCode, name: "serviceCode", parent: name, max: 32)
            try self.validate(self.serviceCode, name: "serviceCode", parent: name, min: 1)
        }

        private enum CodingKeys: String, CodingKey {
            case currencyCode = "CurrencyCode"
            case effectiveDate = "EffectiveDate"
            case maxResults = "MaxResults"
            case nextToken = "NextToken"
            case regionCode = "RegionCode"
            case serviceCode = "ServiceCode"
        }
    }

    public struct ListPriceListsResponse: AWSDecodableShape {
        /// The pagination token that indicates the next set of results to retrieve.
        public let nextToken: String?
        /// The type of price list references that match your request.
        public let priceLists: [PriceList]?

        @inlinable
        public init(nextToken: String? = nil, priceLists: [PriceList]? = nil) {
            self.nextToken = nextToken
            self.priceLists = priceLists
        }

        private enum CodingKeys: String, CodingKey {
            case nextToken = "NextToken"
            case priceLists = "PriceLists"
        }
    }

    public struct PriceList: AWSDecodableShape {
        /// The three alphabetical character ISO-4217 currency code the Price List files are denominated in.
        public let currencyCode: String?
        /// The format you want to retrieve your Price List files. The FileFormat can be obtained from the  ListPriceList response.
        public let fileFormats: [String]?
        /// The unique identifier that maps to where your Price List files are located. PriceListArn can be obtained from the  ListPriceList response.
        public let priceListArn: String?
        /// This is used to filter the Price List by Amazon Web Services Region. For example, to get the price list only for the US East (N. Virginia) Region, use us-east-1. If nothing is specified, you retrieve price lists for all applicable Regions. The available RegionCode list can be retrieved from  GetAttributeValues API.
        public let regionCode: String?

        @inlinable
        public init(currencyCode: String? = nil, fileFormats: [String]? = nil, priceListArn: String? = nil, regionCode: String? = nil) {
            self.currencyCode = currencyCode
            self.fileFormats = fileFormats
            self.priceListArn = priceListArn
            self.regionCode = regionCode
        }

        private enum CodingKeys: String, CodingKey {
            case currencyCode = "CurrencyCode"
            case fileFormats = "FileFormats"
            case priceListArn = "PriceListArn"
            case regionCode = "RegionCode"
        }
    }

    public struct Service: AWSDecodableShape {
        /// The attributes that are available for this service.
        public let attributeNames: [String]?
        /// The code for the Amazon Web Services service.
        public let serviceCode: String

        @inlinable
        public init(attributeNames: [String]? = nil, serviceCode: String) {
            self.attributeNames = attributeNames
            self.serviceCode = serviceCode
        }

        private enum CodingKeys: String, CodingKey {
            case attributeNames = "AttributeNames"
            case serviceCode = "ServiceCode"
        }
    }
}

// MARK: - Errors

/// Error enum for Pricing
public struct PricingErrorType: AWSErrorType {
    enum Code: String {
        case accessDeniedException = "AccessDeniedException"
        case expiredNextTokenException = "ExpiredNextTokenException"
        case internalErrorException = "InternalErrorException"
        case invalidNextTokenException = "InvalidNextTokenException"
        case invalidParameterException = "InvalidParameterException"
        case notFoundException = "NotFoundException"
        case resourceNotFoundException = "ResourceNotFoundException"
        case throttlingException = "ThrottlingException"
    }

    private let error: Code
    public let context: AWSErrorContext?

    /// initialize Pricing
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

    /// General authentication failure. The request wasn't signed correctly.
    public static var accessDeniedException: Self { .init(.accessDeniedException) }
    /// The pagination token expired. Try again without a pagination token.
    public static var expiredNextTokenException: Self { .init(.expiredNextTokenException) }
    /// An error on the server occurred during the processing of your request. Try again later.
    public static var internalErrorException: Self { .init(.internalErrorException) }
    /// The pagination token is invalid. Try again without a pagination token.
    public static var invalidNextTokenException: Self { .init(.invalidNextTokenException) }
    /// One or more parameters had an invalid value.
    public static var invalidParameterException: Self { .init(.invalidParameterException) }
    /// The requested resource can't be found.
    public static var notFoundException: Self { .init(.notFoundException) }
    /// The requested resource can't be found.
    public static var resourceNotFoundException: Self { .init(.resourceNotFoundException) }
    /// You've made too many requests exceeding service quotas.
    public static var throttlingException: Self { .init(.throttlingException) }
}

extension PricingErrorType: Equatable {
    public static func == (lhs: PricingErrorType, rhs: PricingErrorType) -> Bool {
        lhs.error == rhs.error
    }
}

extension PricingErrorType: CustomStringConvertible {
    public var description: String {
        return "\(self.error.rawValue): \(self.message ?? "")"
    }
}
