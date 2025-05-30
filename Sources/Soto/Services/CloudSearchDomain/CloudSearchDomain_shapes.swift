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

extension CloudSearchDomain {
    // MARK: Enums

    public enum ContentType: String, CustomStringConvertible, Codable, Sendable, CodingKeyRepresentable {
        case applicationJson = "application/json"
        case applicationXml = "application/xml"
        public var description: String { return self.rawValue }
    }

    public enum QueryParser: String, CustomStringConvertible, Codable, Sendable, CodingKeyRepresentable {
        case dismax = "dismax"
        case lucene = "lucene"
        case simple = "simple"
        case structured = "structured"
        public var description: String { return self.rawValue }
    }

    // MARK: Shapes

    public struct Bucket: AWSDecodableShape {
        /// The number of hits that contain the facet value in the specified facet field.
        public let count: Int64?
        /// The  facet value being counted.
        public let value: String?

        @inlinable
        public init(count: Int64? = nil, value: String? = nil) {
            self.count = count
            self.value = value
        }

        private enum CodingKeys: String, CodingKey {
            case count = "count"
            case value = "value"
        }
    }

    public struct BucketInfo: AWSDecodableShape {
        /// A list of the calculated facet values and counts.
        public let buckets: [Bucket]?

        @inlinable
        public init(buckets: [Bucket]? = nil) {
            self.buckets = buckets
        }

        private enum CodingKeys: String, CodingKey {
            case buckets = "buckets"
        }
    }

    public struct DocumentServiceException: AWSErrorShape {
        /// The description of the errors returned by the document service.
        public let message: String?
        /// The return status of a document upload request, error or success.
        public let status: String?

        @inlinable
        public init(message: String? = nil, status: String? = nil) {
            self.message = message
            self.status = status
        }

        private enum CodingKeys: String, CodingKey {
            case message = "message"
            case status = "status"
        }
    }

    public struct DocumentServiceWarning: AWSDecodableShape {
        /// The description for a warning returned by the document service.
        public let message: String?

        @inlinable
        public init(message: String? = nil) {
            self.message = message
        }

        private enum CodingKeys: String, CodingKey {
            case message = "message"
        }
    }

    public struct FieldStats: AWSDecodableShape {
        /// The number of documents that contain a value in the specified field in the result set.
        public let count: Int64?
        /// The maximum value found in the specified field in the result set. If the field is numeric (int, int-array, double, or double-array), max is the string representation of a double-precision 64-bit floating point value. If the field is date or date-array, max is the string representation of a date with the format specified in IETF RFC3339: yyyy-mm-ddTHH:mm:ss.SSSZ.
        public let max: String?
        /// The average of the values found in the specified field in the result set. If the field is numeric (int, int-array, double, or double-array), mean is the string representation of a double-precision 64-bit floating point value. If the field is date or date-array, mean is the string representation of a date with the format specified in IETF RFC3339: yyyy-mm-ddTHH:mm:ss.SSSZ.
        public let mean: String?
        /// The minimum value found in the specified field in the result set. If the field is numeric (int, int-array, double, or double-array), min is the string representation of a double-precision 64-bit floating point value. If the field is date or date-array, min is the string representation of a date with the format specified in IETF RFC3339: yyyy-mm-ddTHH:mm:ss.SSSZ.
        public let min: String?
        /// The number of documents that do not contain a value in the specified field in the result set.
        public let missing: Int64?
        /// The standard deviation of the values in the specified field in the result set.
        public let stddev: Double?
        /// The sum of the field values across the documents in the result set. null for date fields.
        public let sum: Double?
        /// The sum of all field values in the result set squared.
        public let sumOfSquares: Double?

        @inlinable
        public init(count: Int64? = nil, max: String? = nil, mean: String? = nil, min: String? = nil, missing: Int64? = nil, stddev: Double? = nil, sum: Double? = nil, sumOfSquares: Double? = nil) {
            self.count = count
            self.max = max
            self.mean = mean
            self.min = min
            self.missing = missing
            self.stddev = stddev
            self.sum = sum
            self.sumOfSquares = sumOfSquares
        }

        private enum CodingKeys: String, CodingKey {
            case count = "count"
            case max = "max"
            case mean = "mean"
            case min = "min"
            case missing = "missing"
            case stddev = "stddev"
            case sum = "sum"
            case sumOfSquares = "sumOfSquares"
        }
    }

    public struct Hit: AWSDecodableShape {
        /// The expressions returned from a document that matches the search request.
        public let exprs: [String: String]?
        /// The fields returned from a document that matches the search request.
        public let fields: [String: [String]]?
        /// The highlights returned from a document that matches the search request.
        public let highlights: [String: String]?
        /// The document ID of a document that matches the search request.
        public let id: String?

        @inlinable
        public init(exprs: [String: String]? = nil, fields: [String: [String]]? = nil, highlights: [String: String]? = nil, id: String? = nil) {
            self.exprs = exprs
            self.fields = fields
            self.highlights = highlights
            self.id = id
        }

        private enum CodingKeys: String, CodingKey {
            case exprs = "exprs"
            case fields = "fields"
            case highlights = "highlights"
            case id = "id"
        }
    }

    public struct Hits: AWSDecodableShape {
        /// A cursor that can be used to retrieve the next set of matching documents when you want to page through a large result set.
        public let cursor: String?
        /// The total number of documents that match the search request.
        public let found: Int64?
        /// A document that matches the search request.
        public let hit: [Hit]?
        /// The index of the first matching document.
        public let start: Int64?

        @inlinable
        public init(cursor: String? = nil, found: Int64? = nil, hit: [Hit]? = nil, start: Int64? = nil) {
            self.cursor = cursor
            self.found = found
            self.hit = hit
            self.start = start
        }

        private enum CodingKeys: String, CodingKey {
            case cursor = "cursor"
            case found = "found"
            case hit = "hit"
            case start = "start"
        }
    }

    public struct SearchRequest: AWSEncodableShape {
        /// Retrieves a cursor value you can use to page through large result sets. Use the size parameter to control the number of hits to include in each response. You can specify either the cursor or start parameter in a request; they are mutually exclusive. To get the first cursor, set the cursor value to initial. In subsequent requests, specify the cursor value returned in the hits section of the response.  For more information, see Paginating Results in the Amazon CloudSearch Developer Guide.
        public let cursor: String?
        /// Defines one or more numeric expressions that can be used to sort results or specify search or filter criteria. You can also specify expressions as return fields.  You specify the expressions in JSON using the form {"EXPRESSIONNAME":"EXPRESSION"}. You can define and use multiple expressions in a search request. For example:  {"expression1":"_score*rating", "expression2":"(1/rank)*year"}  For information about the variables, operators, and functions you can use in expressions, see Writing Expressions in the Amazon CloudSearch Developer Guide.
        public let expr: String?
        /// Specifies one or more fields for which to get facet information, and options that control how the facet information is returned. Each specified field must be facet-enabled in the domain configuration. The fields and options are specified in JSON using the form {"FIELD":{"OPTION":VALUE,"OPTION:"STRING"},"FIELD":{"OPTION":VALUE,"OPTION":"STRING"}}. You can specify the following faceting options:   buckets specifies an array of the facet values or ranges to count. Ranges are specified using the same syntax that you use to search for a range of values. For more information, see  Searching for a Range of Values in the Amazon CloudSearch Developer Guide. Buckets are returned in the order they are specified in the request. The sort and size options are not valid if you specify buckets.   size specifies the maximum number of facets to include in the results. By default, Amazon CloudSearch returns counts for the top 10. The size parameter is only valid when you specify the sort option; it cannot be used in conjunction with buckets.   sort specifies how you want to sort the facets in the results: bucket or count. Specify bucket to sort alphabetically or numerically by facet value (in ascending order). Specify count to sort by the facet counts computed for each facet value (in descending order). To retrieve facet counts for particular values or ranges of values, use the buckets option instead of sort.    If no facet options are specified, facet counts are computed for all field values, the facets are sorted by facet count, and the top 10 facets are returned in the results.
        ///  To count particular buckets of values, use the buckets option. For example, the following request uses the buckets option to calculate and return facet counts by decade.  {"year":{"buckets":["[1970,1979]","[1980,1989]","[1990,1999]","[2000,2009]","[2010,}"]}}
        ///  To sort facets by facet count, use the count option. For example, the following request sets the sort option to count to sort the facet values by facet count, with the facet values that have the most matching documents listed first. Setting the size option to 3 returns only the top three facet values.  {"year":{"sort":"count","size":3}}
        ///  To sort the facets by value, use the bucket option. For example, the following  request sets the sort option to bucket to sort the facet values numerically by year, with earliest year listed first.   {"year":{"sort":"bucket"}}  For more information, see Getting and Using Facet Information in the Amazon CloudSearch Developer Guide.
        public let facet: String?
        /// Specifies a structured query that filters the results of a search without affecting how the results are scored and sorted. You use filterQuery in conjunction with the query parameter to filter the documents that match the constraints specified in the query parameter. Specifying a filter controls only which matching documents are included in the results, it has no effect on how they are scored and sorted. The filterQuery parameter supports the full structured query syntax.  For more information about using filters, see Filtering Matching Documents in the Amazon CloudSearch Developer Guide.
        public let filterQuery: String?
        /// Retrieves highlights for matches in the specified text or text-array fields. Each specified field must be highlight enabled in the domain configuration. The fields and options are specified in JSON using the form {"FIELD":{"OPTION":VALUE,"OPTION:"STRING"},"FIELD":{"OPTION":VALUE,"OPTION":"STRING"}}. You can specify the following highlight options:   format: specifies the format of the data in the text field: text or html. When data is returned as HTML, all non-alphanumeric characters are encoded. The default is html.   max_phrases: specifies the maximum number of occurrences of the search term(s) you want to highlight. By default, the first occurrence is highlighted.   pre_tag: specifies the string to prepend to an occurrence of a search term. The default for HTML highlights is &lt;em&gt;. The default for text highlights is *.   post_tag: specifies the string to append to an occurrence of a search term. The default for HTML highlights is &lt;/em&gt;. The default for text highlights is *.   If no highlight options are specified for a field, the returned field text is treated as HTML and the first match is highlighted with emphasis tags:  &lt;em>search-term&lt;/em&gt;. For example, the following request retrieves highlights for the actors and title fields. { "actors": {}, "title": {"format": "text","max_phrases": 2,"pre_tag": "","post_tag": ""} }
        public let highlight: String?
        /// Enables partial results to be returned if one or more index partitions are unavailable. When your search index is partitioned across multiple search instances, by default Amazon CloudSearch only returns results if every partition can be queried. This means that the failure of a single search instance can result in 5xx (internal server) errors. When you enable partial results, Amazon CloudSearch returns whatever results are available and includes the percentage of documents searched in the search results (percent-searched). This enables you to more gracefully degrade your users' search experience. For example, rather than displaying no results, you could display the partial results and a message indicating that the results might be incomplete due to a temporary system outage.
        public let partial: Bool?
        /// Specifies the search criteria for the request. How you specify the search criteria depends on the query parser used for the request and the parser options specified in the queryOptions parameter. By default, the simple query parser is used to process requests. To use the structured, lucene, or dismax query parser, you must also specify the queryParser parameter.  For more information about specifying search criteria, see Searching Your Data in the Amazon CloudSearch Developer Guide.
        public let query: String
        /// Configures options for the query parser specified in the queryParser parameter. You specify the options in JSON using the following form {"OPTION1":"VALUE1","OPTION2":VALUE2"..."OPTIONN":"VALUEN"}.
        ///  The options you can configure vary according to which parser you use:  defaultOperator: The default operator used to combine individual terms in the search string. For example: defaultOperator: 'or'. For the dismax parser, you specify a percentage that represents the percentage of terms in the search string (rounded down) that must match, rather than a default operator. A value of 0% is the equivalent to OR, and a value of 100% is equivalent to AND. The percentage must be specified as a value in the range 0-100 followed by the percent (%) symbol. For example, defaultOperator: 50%. Valid values: and, or, a percentage in the range 0%-100% (dismax). Default: and (simple, structured, lucene) or 100 (dismax). Valid for: simple, structured, lucene, and dismax. fields: An array of the fields to search when no fields are specified in a search. If no fields are specified in a search and this option is not specified, all text and text-array fields are searched. You can specify a weight for each field to control the relative importance of each field when Amazon CloudSearch calculates relevance scores. To specify a field weight, append a caret (^) symbol and the weight to the field name. For example, to boost the importance of the title field over the description field you could specify: "fields":["title^5","description"].  Valid values: The name of any configured field and an optional numeric value greater than zero. Default: All text and text-array fields. Valid for: simple, structured, lucene, and dismax. operators: An array of the operators or special characters you want to disable for the simple query parser. If you disable the and, or, or not operators, the corresponding operators (+, |, -) have no special meaning and are dropped from the search string. Similarly, disabling prefix disables the wildcard operator (*) and disabling phrase disables the ability to search for phrases by enclosing phrases in double quotes. Disabling precedence disables the ability to control order of precedence using parentheses. Disabling near disables the ability to use the ~ operator to perform a sloppy phrase search. Disabling the fuzzy operator disables the ability to use the ~ operator to perform a fuzzy search. escape disables the ability to use a backslash (\) to escape special characters within the search string. Disabling whitespace is an advanced option that prevents the parser from tokenizing on whitespace, which can be useful for Vietnamese. (It prevents Vietnamese words from being split incorrectly.) For example, you could disable all operators other than the phrase operator to support just simple term and phrase queries: "operators":["and","not","or", "prefix"]. Valid values: and, escape, fuzzy, near, not, or, phrase, precedence, prefix, whitespace. Default: All operators and special characters are enabled. Valid for: simple. phraseFields: An array of the text or text-array fields you want to use for phrase searches. When the terms in the search string appear in close proximity within a field, the field scores higher. You can specify a weight for each field to boost that score. The phraseSlop option controls how much the matches can deviate from the search string and still be boosted. To specify a field weight, append a caret (^) symbol and the weight to the field name. For example, to boost phrase matches in the title field over the abstract field, you could specify: "phraseFields":["title^3", "plot"] Valid values: The name of any text or text-array field and an optional numeric value greater than zero. Default: No fields. If you don't specify any fields with phraseFields, proximity scoring is disabled even if phraseSlop is specified. Valid for: dismax. phraseSlop: An integer value that specifies how much matches can deviate from the search phrase and still be boosted according to the weights specified in the phraseFields option; for example, phraseSlop: 2. You must also specify phraseFields to enable proximity scoring. Valid values: positive integers. Default: 0. Valid for: dismax. explicitPhraseSlop: An integer value that specifies how much a match can deviate from the search phrase when the phrase is enclosed in double quotes in the search string. (Phrases that exceed this proximity distance are not considered a match.) For example, to specify a slop of three for dismax phrase queries, you would specify "explicitPhraseSlop":3. Valid values: positive integers. Default: 0. Valid for: dismax. tieBreaker: When a term in the search string is found in a document's field, a score is calculated for that field based on how common the word is in that field compared to other documents. If the term occurs in multiple fields within a document, by default only the highest scoring field contributes to the document's overall score. You can specify a tieBreaker value to enable the matches in lower-scoring fields to contribute to the document's score. That way, if two documents have the same max field score for a particular term, the score for the document that has matches in more fields will be higher. The formula for calculating the score with a tieBreaker is (max field score) + (tieBreaker) * (sum of the scores for the rest of the matching fields).
        ///  Set tieBreaker to 0 to disregard all but the highest scoring field (pure max): "tieBreaker":0. Set to 1 to sum the scores from all fields (pure sum): "tieBreaker":1. Valid values: 0.0 to 1.0. Default: 0.0. Valid for: dismax.
        public let queryOptions: String?
        /// Specifies which query parser to use to process the request. If queryParser is not specified, Amazon CloudSearch uses the simple query parser.  Amazon CloudSearch supports four query parsers:   simple: perform simple searches of text and text-array fields. By default, the simple query parser searches all text and text-array fields. You can specify which fields to search by with the queryOptions parameter. If you prefix a search term with a plus sign (+) documents must contain the term to be considered a match. (This is the default, unless you configure the default operator with the queryOptions parameter.) You can use the - (NOT), | (OR), and * (wildcard) operators to exclude particular terms, find results that match any of the specified terms, or search for a prefix. To search for a phrase rather than individual terms, enclose the phrase in double quotes. For more information, see Searching for Text in the Amazon CloudSearch Developer Guide.   structured: perform advanced searches by combining multiple expressions to define the search criteria. You can also search within particular fields, search for values and ranges of values, and use advanced options such as term boosting, matchall, and near. For more information, see Constructing Compound Queries in the Amazon CloudSearch Developer Guide.   lucene: search using the Apache Lucene query parser syntax. For more information, see Apache Lucene Query Parser Syntax.   dismax: search using the simplified subset of the Apache Lucene query parser syntax defined by the DisMax query parser. For more information, see DisMax Query Parser Syntax.
        ///
        public let queryParser: QueryParser?
        /// Specifies the field and expression values to include in the response. Multiple fields or expressions are specified as a comma-separated list. By default, a search response includes all return enabled fields (_all_fields). To  return only the document IDs for the matching documents, specify _no_fields. To retrieve the relevance score calculated for each document, specify _score.
        public let `return`: String?
        /// Specifies the maximum number of search hits to include in the response.
        public let size: Int64?
        /// Specifies the fields or custom expressions to use to sort the search results. Multiple fields or expressions are specified as a comma-separated list. You must specify the sort direction (asc or desc) for each field; for example, year desc,title asc. To use a field to sort results, the field must be sort-enabled in the domain configuration. Array type fields cannot be used for sorting. If no sort parameter is specified, results are sorted by their default relevance scores in descending order: _score desc. You can also sort by document ID (_id asc) and version (_version desc). For more information, see Sorting Results in the Amazon CloudSearch Developer Guide.
        public let sort: String?
        /// Specifies the offset of the first search hit you want to return. Note that the result set is zero-based; the first result is at index 0. You can specify either the start or cursor parameter in a request, they are mutually exclusive.   For more information, see Paginating Results in the Amazon CloudSearch Developer Guide.
        public let start: Int64?
        /// Specifies one or more fields for which to get statistics information. Each specified field must be facet-enabled in the domain configuration. The fields are specified in JSON using the form: {"FIELD-A":{},"FIELD-B":{}} There are currently no options supported for statistics.
        public let stats: String?

        @inlinable
        public init(cursor: String? = nil, expr: String? = nil, facet: String? = nil, filterQuery: String? = nil, highlight: String? = nil, partial: Bool? = nil, query: String, queryOptions: String? = nil, queryParser: QueryParser? = nil, return: String? = nil, size: Int64? = nil, sort: String? = nil, start: Int64? = nil, stats: String? = nil) {
            self.cursor = cursor
            self.expr = expr
            self.facet = facet
            self.filterQuery = filterQuery
            self.highlight = highlight
            self.partial = partial
            self.query = query
            self.queryOptions = queryOptions
            self.queryParser = queryParser
            self.`return` = `return`
            self.size = size
            self.sort = sort
            self.start = start
            self.stats = stats
        }

        public func encode(to encoder: Encoder) throws {
            let request = encoder.userInfo[.awsRequest]! as! RequestEncodingContainer
            _ = encoder.container(keyedBy: CodingKeys.self)
            request.encodeQuery(self.cursor, key: "cursor")
            request.encodeQuery(self.expr, key: "expr")
            request.encodeQuery(self.facet, key: "facet")
            request.encodeQuery(self.filterQuery, key: "fq")
            request.encodeQuery(self.highlight, key: "highlight")
            request.encodeQuery(self.partial, key: "partial")
            request.encodeQuery(self.query, key: "q")
            request.encodeQuery(self.queryOptions, key: "q.options")
            request.encodeQuery(self.queryParser, key: "q.parser")
            request.encodeQuery(self.`return`, key: "return")
            request.encodeQuery(self.size, key: "size")
            request.encodeQuery(self.sort, key: "sort")
            request.encodeQuery(self.start, key: "start")
            request.encodeQuery(self.stats, key: "stats")
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct SearchResponse: AWSDecodableShape {
        /// The requested facet information.
        public let facets: [String: BucketInfo]?
        /// The documents that match the search criteria.
        public let hits: Hits?
        /// The requested field statistics information.
        public let stats: [String: FieldStats]?
        /// The status information returned for the search request.
        public let status: SearchStatus?

        @inlinable
        public init(facets: [String: BucketInfo]? = nil, hits: Hits? = nil, stats: [String: FieldStats]? = nil, status: SearchStatus? = nil) {
            self.facets = facets
            self.hits = hits
            self.stats = stats
            self.status = status
        }

        private enum CodingKeys: String, CodingKey {
            case facets = "facets"
            case hits = "hits"
            case stats = "stats"
            case status = "status"
        }
    }

    public struct SearchStatus: AWSDecodableShape {
        /// The encrypted resource ID for the request.
        public let rid: String?
        /// How long it took to process the request, in milliseconds.
        public let timems: Int64?

        @inlinable
        public init(rid: String? = nil, timems: Int64? = nil) {
            self.rid = rid
            self.timems = timems
        }

        private enum CodingKeys: String, CodingKey {
            case rid = "rid"
            case timems = "timems"
        }
    }

    public struct SuggestModel: AWSDecodableShape {
        /// The number of documents that were found to match the query string.
        public let found: Int64?
        /// The query string specified in the suggest request.
        public let query: String?
        /// The documents that match the query string.
        public let suggestions: [SuggestionMatch]?

        @inlinable
        public init(found: Int64? = nil, query: String? = nil, suggestions: [SuggestionMatch]? = nil) {
            self.found = found
            self.query = query
            self.suggestions = suggestions
        }

        private enum CodingKeys: String, CodingKey {
            case found = "found"
            case query = "query"
            case suggestions = "suggestions"
        }
    }

    public struct SuggestRequest: AWSEncodableShape {
        /// Specifies the string for which you want to get suggestions.
        public let query: String
        /// Specifies the maximum number of suggestions to return.
        public let size: Int64?
        /// Specifies the name of the suggester to use to find suggested matches.
        public let suggester: String

        @inlinable
        public init(query: String, size: Int64? = nil, suggester: String) {
            self.query = query
            self.size = size
            self.suggester = suggester
        }

        public func encode(to encoder: Encoder) throws {
            let request = encoder.userInfo[.awsRequest]! as! RequestEncodingContainer
            _ = encoder.container(keyedBy: CodingKeys.self)
            request.encodeQuery(self.query, key: "q")
            request.encodeQuery(self.size, key: "size")
            request.encodeQuery(self.suggester, key: "suggester")
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct SuggestResponse: AWSDecodableShape {
        /// The status of a SuggestRequest. Contains the resource ID (rid) and how long it took to process the request (timems).
        public let status: SuggestStatus?
        /// Container for the matching search suggestion information.
        public let suggest: SuggestModel?

        @inlinable
        public init(status: SuggestStatus? = nil, suggest: SuggestModel? = nil) {
            self.status = status
            self.suggest = suggest
        }

        private enum CodingKeys: String, CodingKey {
            case status = "status"
            case suggest = "suggest"
        }
    }

    public struct SuggestStatus: AWSDecodableShape {
        /// The encrypted resource ID for the request.
        public let rid: String?
        /// How long it took to process the request, in milliseconds.
        public let timems: Int64?

        @inlinable
        public init(rid: String? = nil, timems: Int64? = nil) {
            self.rid = rid
            self.timems = timems
        }

        private enum CodingKeys: String, CodingKey {
            case rid = "rid"
            case timems = "timems"
        }
    }

    public struct SuggestionMatch: AWSDecodableShape {
        /// The document ID of the suggested document.
        public let id: String?
        /// The relevance score of a suggested match.
        public let score: Int64?
        /// The string that matches the query string specified in the SuggestRequest.
        public let suggestion: String?

        @inlinable
        public init(id: String? = nil, score: Int64? = nil, suggestion: String? = nil) {
            self.id = id
            self.score = score
            self.suggestion = suggestion
        }

        private enum CodingKeys: String, CodingKey {
            case id = "id"
            case score = "score"
            case suggestion = "suggestion"
        }
    }

    public struct UploadDocumentsRequest: AWSEncodableShape {
        public static let _options: AWSShapeOptions = [.allowStreaming]
        /// The format of the batch you are uploading. Amazon CloudSearch supports two document batch formats:  application/json application/xml
        public let contentType: ContentType
        /// A batch of documents formatted in JSON or HTML.
        public let documents: AWSHTTPBody

        @inlinable
        public init(contentType: ContentType, documents: AWSHTTPBody) {
            self.contentType = contentType
            self.documents = documents
        }

        public func encode(to encoder: Encoder) throws {
            let request = encoder.userInfo[.awsRequest]! as! RequestEncodingContainer
            var container = encoder.singleValueContainer()
            request.encodeHeader(self.contentType, key: "Content-Type")
            try container.encode(self.documents)
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct UploadDocumentsResponse: AWSDecodableShape {
        /// The number of documents that were added to the search domain.
        public let adds: Int64?
        /// The number of documents that were deleted from the search domain.
        public let deletes: Int64?
        /// The status of an UploadDocumentsRequest.
        public let status: String?
        /// Any warnings returned by the document service about the documents being uploaded.
        public let warnings: [DocumentServiceWarning]?

        @inlinable
        public init(adds: Int64? = nil, deletes: Int64? = nil, status: String? = nil, warnings: [DocumentServiceWarning]? = nil) {
            self.adds = adds
            self.deletes = deletes
            self.status = status
            self.warnings = warnings
        }

        private enum CodingKeys: String, CodingKey {
            case adds = "adds"
            case deletes = "deletes"
            case status = "status"
            case warnings = "warnings"
        }
    }
}

// MARK: - Errors

/// Error enum for CloudSearchDomain
public struct CloudSearchDomainErrorType: AWSErrorType {
    enum Code: String {
        case documentServiceException = "DocumentServiceException"
        case searchException = "SearchException"
    }

    private let error: Code
    public let context: AWSErrorContext?

    /// initialize CloudSearchDomain
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

    /// Information about any problems encountered while processing an upload request.
    public static var documentServiceException: Self { .init(.documentServiceException) }
    /// Information about any problems encountered while processing a search request.
    public static var searchException: Self { .init(.searchException) }
}

extension CloudSearchDomainErrorType: AWSServiceErrorType {
    public static let errorCodeMap: [String: AWSErrorShape.Type] = [
        "DocumentServiceException": CloudSearchDomain.DocumentServiceException.self
    ]
}

extension CloudSearchDomainErrorType: Equatable {
    public static func == (lhs: CloudSearchDomainErrorType, rhs: CloudSearchDomainErrorType) -> Bool {
        lhs.error == rhs.error
    }
}

extension CloudSearchDomainErrorType: CustomStringConvertible {
    public var description: String {
        return "\(self.error.rawValue): \(self.message ?? "")"
    }
}
