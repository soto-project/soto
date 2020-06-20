//===----------------------------------------------------------------------===//
//
// This source file is part of the AWSSDKSwift open source project
//
// Copyright (c) 2017-2020 the AWSSDKSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of AWSSDKSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

extension DynamoDB {
    
    //MARK: Codable API
    
    public func putItemCodable<T: Encodable>(_ input: PutItemCodableInput<T>, on eventLoop: EventLoop? = nil) -> EventLoopFuture<PutItemOutput> {
        do {
            let item = try DynamoDBEncoder().encode(input.item)
            let request = DynamoDB.PutItemInput(
                conditionExpression: input.conditionExpression,
                expressionAttributeNames: input.expressionAttributeNames,
                expressionAttributeValues: input.expressionAttributeValues,
                item: item,
                returnConsumedCapacity: input.returnConsumedCapacity,
                returnItemCollectionMetrics: input.returnItemCollectionMetrics,
                returnValues: input.returnValues,
                tableName: input.tableName
            )
            return putItem(request, on: eventLoop)
        } catch {
            let eventLoop = eventLoop ?? client.eventLoopGroup.next()
            return eventLoop.makeFailedFuture(error)
        }
    }

    public func getItemCodable<T: Decodable>(_ input: GetItemInput, type: T.Type, on eventLoop: EventLoop? = nil) -> EventLoopFuture<GetItemCodableOutput<T>> {
        return getItem(input, on: eventLoop)
            .flatMapThrowing { response -> GetItemCodableOutput<T> in
                let item = try response.item.map { try DynamoDBDecoder().decode(T.self, from: $0) }
                return GetItemCodableOutput(
                    consumedCapacity: response.consumedCapacity,
                    item: item
                )
        }
    }
    
    public func queryCodable<T: Decodable>(_ input: QueryInput, type: T.Type, on eventLoop: EventLoop? = nil) -> EventLoopFuture<QueryCodableOutput<T>> {
        return query(input, on: eventLoop)
            .flatMapThrowing { response -> QueryCodableOutput<T> in
                let items = try response.items.map { try $0.map { try DynamoDBDecoder().decode(T.self, from: $0) } }
                return QueryCodableOutput(
                    consumedCapacity: response.consumedCapacity,
                    count: response.count,
                    items: items,
                    lastEvaluatedKey: response.lastEvaluatedKey,
                    scannedCount: response.scannedCount
                )
        }
    }
    
    public func scanCodable<T: Decodable>(_ input: ScanInput, type: T.Type, on eventLoop: EventLoop? = nil) -> EventLoopFuture<ScanCodableOutput<T>> {
        return scan(input, on: eventLoop)
            .flatMapThrowing { response -> ScanCodableOutput<T> in
                let items = try response.items.map { try $0.map { try DynamoDBDecoder().decode(T.self, from: $0) } }
                return ScanCodableOutput(
                    consumedCapacity: response.consumedCapacity,
                    count: response.count,
                    items: items,
                    lastEvaluatedKey: response.lastEvaluatedKey,
                    scannedCount: response.scannedCount
                )
        }
    }
    
    //MARK: Codable Shapes

    /// Version of PutItemInput that replaces the `item` with a `Encodable` class that will then be encoded into `[String: AttributeValue]`
    public struct PutItemCodableInput<T: Encodable> {

        /// A condition that must be satisfied in order for a conditional PutItem operation to succeed. An expression can contain any of the following:   Functions: attribute_exists | attribute_not_exists | attribute_type | contains | begins_with | size  These function names are case-sensitive.   Comparison operators: = | &lt;&gt; | &lt; | &gt; | &lt;= | &gt;= | BETWEEN | IN      Logical operators: AND | OR | NOT    For more information on condition expressions, see Condition Expressions in the Amazon DynamoDB Developer Guide.
        public let conditionExpression: String?
        /// One or more substitution tokens for attribute names in an expression. The following are some use cases for using ExpressionAttributeNames:   To access an attribute whose name conflicts with a DynamoDB reserved word.   To create a placeholder for repeating occurrences of an attribute name in an expression.   To prevent special characters in an attribute name from being misinterpreted in an expression.   Use the # character in an expression to dereference an attribute name. For example, consider the following attribute name:    Percentile    The name of this attribute conflicts with a reserved word, so it cannot be used directly in an expression. (For the complete list of reserved words, see Reserved Words in the Amazon DynamoDB Developer Guide). To work around this, you could specify the following for ExpressionAttributeNames:    {"#P":"Percentile"}    You could then use this substitution in an expression, as in this example:    #P = :val     Tokens that begin with the : character are expression attribute values, which are placeholders for the actual value at runtime.  For more information on expression attribute names, see Specifying Item Attributes in the Amazon DynamoDB Developer Guide.
        public let expressionAttributeNames: [String: String]?
        /// One or more values that can be substituted in an expression. Use the : (colon) character in an expression to dereference an attribute value. For example, suppose that you wanted to check whether the value of the ProductStatus attribute was one of the following:   Available | Backordered | Discontinued  You would first need to specify ExpressionAttributeValues as follows:  { ":avail":{"S":"Available"}, ":back":{"S":"Backordered"}, ":disc":{"S":"Discontinued"} }  You could then use these values in an expression, such as this:  ProductStatus IN (:avail, :back, :disc)  For more information on expression attribute values, see Condition Expressions in the Amazon DynamoDB Developer Guide.
        public let expressionAttributeValues: [String: AttributeValue]?
        /// A map of attribute name/value pairs, one for each attribute. Only the primary key attributes are required; you can optionally provide other attribute name-value pairs for the item. You must provide all of the attributes for the primary key. For example, with a simple primary key, you only need to provide a value for the partition key. For a composite primary key, you must provide both values for both the partition key and the sort key. If you specify any attributes that are part of an index key, then the data types for those attributes must match those of the schema in the table's attribute definition. Empty String and Binary attribute values are allowed. Attribute values of type String and Binary must have a length greater than zero if the attribute is used as a key attribute for a table or index. For more information about primary keys, see Primary Key in the Amazon DynamoDB Developer Guide. Each element in the Item map is an AttributeValue object.
        public let item: T
        public let returnConsumedCapacity: ReturnConsumedCapacity?
        /// Determines whether item collection metrics are returned. If set to SIZE, the response includes statistics about item collections, if any, that were modified during the operation are returned in the response. If set to NONE (the default), no statistics are returned.
        public let returnItemCollectionMetrics: ReturnItemCollectionMetrics?
        /// Use ReturnValues if you want to get the item attributes as they appeared before they were updated with the PutItem request. For PutItem, the valid values are:    NONE - If ReturnValues is not specified, or if its value is NONE, then nothing is returned. (This setting is the default for ReturnValues.)    ALL_OLD - If PutItem overwrote an attribute name-value pair, then the content of the old item is returned.    The ReturnValues parameter is used by several DynamoDB operations; however, PutItem does not recognize any values other than NONE or ALL_OLD.
        public let returnValues: ReturnValue?
        /// The name of the table to contain the item.
        public let tableName: String

        public init(conditionExpression: String? = nil, expressionAttributeNames: [String: String]? = nil, expressionAttributeValues: [String: AttributeValue]? = nil, item: T, returnConsumedCapacity: ReturnConsumedCapacity? = nil, returnItemCollectionMetrics: ReturnItemCollectionMetrics? = nil, returnValues: ReturnValue? = nil, tableName: String) {
            self.conditionExpression = conditionExpression
            self.expressionAttributeNames = expressionAttributeNames
            self.expressionAttributeValues = expressionAttributeValues
            self.item = item
            self.returnConsumedCapacity = returnConsumedCapacity
            self.returnItemCollectionMetrics = returnItemCollectionMetrics
            self.returnValues = returnValues
            self.tableName = tableName
        }
    }

    public struct GetItemCodableOutput<T: Decodable> {

        /// The capacity units consumed by the GetItem operation. The data returned includes the total provisioned throughput consumed, along with statistics for the table and any indexes involved in the operation. ConsumedCapacity is only returned if the ReturnConsumedCapacity parameter was specified. For more information, see Read/Write Capacity Mode in the Amazon DynamoDB Developer Guide.
        public let consumedCapacity: ConsumedCapacity?
        /// A map of attribute names to AttributeValue objects, as specified by ProjectionExpression.
        public let item: T?

        public init(consumedCapacity: ConsumedCapacity? = nil, item: T? = nil) {
            self.consumedCapacity = consumedCapacity
            self.item = item
        }
    }

    public struct QueryCodableOutput<T: Decodable> {

        /// The capacity units consumed by the Query operation. The data returned includes the total provisioned throughput consumed, along with statistics for the table and any indexes involved in the operation. ConsumedCapacity is only returned if the ReturnConsumedCapacity parameter was specified. For more information, see Provisioned Throughput in the Amazon DynamoDB Developer Guide.
        public let consumedCapacity: ConsumedCapacity?
        /// The number of items in the response. If you used a QueryFilter in the request, then Count is the number of items returned after the filter was applied, and ScannedCount is the number of matching items before the filter was applied. If you did not use a filter in the request, then Count and ScannedCount are the same.
        public let count: Int?
        /// An array of item attributes that match the query criteria. Each element in this array consists of an attribute name and the value for that attribute.
        public let items: [T]?
        /// The primary key of the item where the operation stopped, inclusive of the previous result set. Use this value to start a new operation, excluding this value in the new request. If LastEvaluatedKey is empty, then the "last page" of results has been processed and there is no more data to be retrieved. If LastEvaluatedKey is not empty, it does not necessarily mean that there is more data in the result set. The only way to know when you have reached the end of the result set is when LastEvaluatedKey is empty.
        public let lastEvaluatedKey: [String: AttributeValue]?
        /// The number of items evaluated, before any QueryFilter is applied. A high ScannedCount value with few, or no, Count results indicates an inefficient Query operation. For more information, see Count and ScannedCount in the Amazon DynamoDB Developer Guide. If you did not use a filter in the request, then ScannedCount is the same as Count.
        public let scannedCount: Int?
    }

    public struct ScanCodableOutput<T: Decodable> {

        /// The capacity units consumed by the Scan operation. The data returned includes the total provisioned throughput consumed, along with statistics for the table and any indexes involved in the operation. ConsumedCapacity is only returned if the ReturnConsumedCapacity parameter was specified. For more information, see Provisioned Throughput in the Amazon DynamoDB Developer Guide.
        public let consumedCapacity: ConsumedCapacity?
        /// The number of items in the response. If you set ScanFilter in the request, then Count is the number of items returned after the filter was applied, and ScannedCount is the number of matching items before the filter was applied. If you did not use a filter in the request, then Count is the same as ScannedCount.
        public let count: Int?
        /// An array of item attributes that match the scan criteria. Each element in this array consists of an attribute name and the value for that attribute.
        public let items: [T]?
        /// The primary key of the item where the operation stopped, inclusive of the previous result set. Use this value to start a new operation, excluding this value in the new request. If LastEvaluatedKey is empty, then the "last page" of results has been processed and there is no more data to be retrieved. If LastEvaluatedKey is not empty, it does not necessarily mean that there is more data in the result set. The only way to know when you have reached the end of the result set is when LastEvaluatedKey is empty.
        public let lastEvaluatedKey: [String: AttributeValue]?
        /// The number of items evaluated, before any ScanFilter is applied. A high ScannedCount value with few, or no, Count results indicates an inefficient Scan operation. For more information, see Count and ScannedCount in the Amazon DynamoDB Developer Guide. If you did not use a filter in the request, then ScannedCount is the same as Count.
        public let scannedCount: Int?
    }

}
