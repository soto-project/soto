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

extension DynamoDB {
    // MARK: Codable API

    /// Creates a new item, or replaces an old item with a new item. If an item that has the same primary key as the new item already exists in the specified table, the new item completely replaces the existing item. You can perform a conditional put operation (add a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values. You can return the item's attribute values in the same operation, using the `ReturnValues` parameter.</p> <important> <p>This topic provides general information about the `PutItem` API.
    ///
    /// For information on how to call the `PutItem` API using the AWS SDK in specific languages, see the following:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/goto/aws-cli/dynamodb-2012-08-10/PutItem"> PutItem in the AWS Command Line Interface</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/DotNetSDKV3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for .NET</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForCpp/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for C++</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForGoV1/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Go</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForJava/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Java</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/AWSJavaScriptSDK/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for JavaScript</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForPHPV3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for PHP V3</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/boto3/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Python</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/goto/SdkForRubyV2/dynamodb-2012-08-10/PutItem"> PutItem in the AWS SDK for Ruby V2</a> </p> </li> </ul> </important> <p>When you add an item, the primary key attributes are the only required attributes. Attribute values cannot be null.
    ///
    /// Empty String and Binary attribute values are allowed. Attribute values of type String and Binary must have a length greater than zero if the attribute is used as a key attribute for a table or index. Set type attributes cannot be empty.
    ///
    /// Invalid Requests with empty values will be rejected with a `ValidationException` exception.</p> <note> <p>To prevent a new item from replacing an existing item, use a conditional expression that contains the `attribute_not_exists` function with the name of the attribute being used as the partition key for the table. Since every record must contain that attribute, the `attribute_not_exists` function will only succeed if no matching item exists.</p> </note> <p>For more information about `PutItem`, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithItems.html">Working with Items</a> in the <i>Amazon DynamoDB Developer Guide</i>.
    public func putItem<T: Encodable>(
        _ input: PutItemCodableInput<T>,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> EventLoopFuture<PutItemOutput> {
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
            return self.putItem(request, logger: logger, on: eventLoop)
        } catch {
            let eventLoop = eventLoop ?? client.eventLoopGroup.next()
            return eventLoop.makeFailedFuture(error)
        }
    }

    /// The `GetItem` operation returns a set of attributes for the item with the given primary key. If there is no matching item, `GetItem` does not return any data and there will be no `Item` element in the response.
    ///
    ///  `GetItem` provides an eventually consistent read by default. If your application requires a strongly consistent read, set `ConsistentRead` to `true`. Although a strongly consistent read might take more time than an eventually consistent read, it always returns the last updated value.
    public func getItem<T: Decodable>(
        _ input: GetItemInput,
        type: T.Type,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> EventLoopFuture<GetItemCodableOutput<T>> {
        return self.getItem(input, logger: logger, on: eventLoop)
            .flatMapThrowing { response -> GetItemCodableOutput<T> in
                let item = try response.item.map { try DynamoDBDecoder().decode(T.self, from: $0) }
                return GetItemCodableOutput(
                    consumedCapacity: response.consumedCapacity,
                    item: item
                )
            }
    }

    /// Edits an existing item's attributes, or adds a new item to the table if it does not already exist. You can put, delete, or add attribute values. You can also perform a conditional update on an existing item (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).
    ///
    /// You can also return the item's attribute values in the same `UpdateItem` operation using the `ReturnValues` parameter.
    public func updateItem<T: Encodable>(
        _ input: UpdateItemCodableInput<T>,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> EventLoopFuture<UpdateItemOutput> {
        do {
            var item = try DynamoDBEncoder().encode(input.updateItem)
            // extract key from input object
            var key: [String: AttributeValue] = [:]
            input.key.forEach {
                key[$0] = item[$0]!
                item[$0] = nil
            }
            // construct expression attribute name and value arrays from name attribute value map.
            // if names already provided along with a custom update expression then use the provided names
            let expressionAttributeNames: [String: String]
            if let names = input.expressionAttributeNames, input.updateExpression != nil {
                expressionAttributeNames = names
            } else {
                expressionAttributeNames = .init(item.keys.map { ("#\($0)", $0) }) { first, _ in return first }
            }
            let expressionAttributeValues: [String: AttributeValue] = .init(item.map { (":\($0.key)", $0.value) }) { first, _ in return first }
            // construct update expression, if one if not already supplied
            let updateExpression: String
            if let inputUpdateExpression = input.updateExpression {
                updateExpression = inputUpdateExpression
            } else {
                let expressions = item.keys.map { "#\($0) = :\($0)" }
                updateExpression = "SET \(expressions.joined(separator: ","))"
            }
            let request = DynamoDB.UpdateItemInput(
                conditionExpression: input.conditionExpression,
                expressionAttributeNames: expressionAttributeNames,
                expressionAttributeValues: expressionAttributeValues,
                key: key,
                returnConsumedCapacity: input.returnConsumedCapacity,
                returnItemCollectionMetrics: input.returnItemCollectionMetrics,
                returnValues: input.returnValues,
                tableName: input.tableName,
                updateExpression: updateExpression
            )
            return self.updateItem(request, logger: logger, on: eventLoop)
        } catch {
            let eventLoop = eventLoop ?? client.eventLoopGroup.next()
            return eventLoop.makeFailedFuture(error)
        }
    }

    /// The `Query` operation finds items based on primary key values. You can query any table or secondary index that has a composite primary key (a partition key and a sort key).
    ///
    /// Use the `KeyConditionExpression` parameter to provide a specific value for the partition key. The `Query` operation will return all of the items from the table or index with that partition key value. You can optionally narrow the scope of the `Query` operation by specifying a sort key value and a comparison operator in `KeyConditionExpression`. To further refine the `Query` results, you can optionally provide a `FilterExpression`. A `FilterExpression` determines which items within the results should be returned to you. All of the other results are discarded.
    ///
    ///  A `Query` operation always returns a result set. If no matching items are found, the result set will be empty. Queries that do not return results consume the minimum number of read capacity units for that type of read operation. </p> <note> <p> DynamoDB calculates the number of read capacity units consumed based on item size, not on the amount of data that is returned to an application. The number of capacity units consumed will be the same whether you request all of the attributes (the default behavior) or just some of them (using a projection expression). The number will also be the same whether or not you use a `FilterExpression`. </p> </note> <p> `Query` results are always sorted by the sort key value. If the data type of the sort key is Number, the results are returned in numeric order; otherwise, the results are returned in order of UTF-8 bytes. By default, the sort order is ascending. To reverse the order, set the `ScanIndexForward` parameter to false.
    ///
    ///  A single `Query` operation will read up to the maximum number of items set (if using the `Limit` parameter) or a maximum of 1 MB of data and then apply any filtering to the results using `FilterExpression`. If `LastEvaluatedKey` is present in the response, you will need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Query.html#Query.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>.
    ///
    ///  `FilterExpression` is applied after a `Query` finishes, but before the results are returned. A `FilterExpression` cannot contain partition key or sort key attributes. You need to specify those attributes in the `KeyConditionExpression`. </p> <note> <p> A `Query` operation can return an empty result set and a `LastEvaluatedKey` if all the items read for the page of results are filtered out. </p> </note> <p>You can query a table, a local secondary index, or a global secondary index. For a query on a table or on a local secondary index, you can set the `ConsistentRead` parameter to `true` and obtain a strongly consistent result. Global secondary indexes support eventually consistent reads only, so do not specify `ConsistentRead` when querying a global secondary index.
    public func query<T: Decodable>(
        _ input: QueryInput,
        type: T.Type,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> EventLoopFuture<QueryCodableOutput<T>> {
        return self.query(input, logger: logger, on: eventLoop)
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

    /// The `Scan` operation returns one or more items and item attributes by accessing every item in a table or a secondary index. To have DynamoDB return fewer items, you can provide a `FilterExpression` operation.
    ///
    /// If the total number of scanned items exceeds the maximum dataset size limit of 1 MB, the scan stops and results are returned to the user as a `LastEvaluatedKey` value to continue the scan in a subsequent operation. The results also include the number of items exceeding the limit. A scan can result in no table data meeting the filter criteria.
    ///
    /// A single `Scan` operation reads up to the maximum number of items set (if using the `Limit` parameter) or a maximum of 1 MB of data and then apply any filtering to the results using `FilterExpression`. If `LastEvaluatedKey` is present in the response, you need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>.
    ///
    ///  `Scan` operations proceed sequentially; however, for faster performance on a large table or secondary index, applications can request a parallel `Scan` operation by providing the `Segment` and `TotalSegments` parameters. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.ParallelScan">Parallel Scan</a> in the <i>Amazon DynamoDB Developer Guide</i>.
    ///
    ///  `Scan` uses eventually consistent reads when accessing the data in a table; therefore, the result set might not include the changes to data in the table immediately before the operation began. If you need a consistent copy of the data, as of the time that the `Scan` begins, you can set the `ConsistentRead` parameter to `true`.
    public func scan<T: Decodable>(
        _ input: ScanInput,
        type: T.Type,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> EventLoopFuture<ScanCodableOutput<T>> {
        return self.scan(input, logger: logger, on: eventLoop)
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

    // MARK: Codable Paginators

    ///  The `Query` operation finds items based on primary key values. You can query any table or secondary index that has a composite primary key (a partition key and a sort key).
    ///
    /// Use the `KeyConditionExpression` parameter to provide a specific value for the partition key. The `Query` operation will return all of the items from the table or index with that partition key value. You can optionally narrow the scope of the `Query` operation by specifying a sort key value and a comparison operator in `KeyConditionExpression`. To further refine the `Query` results, you can optionally provide a `FilterExpression`. A `FilterExpression` determines which items within the results should be returned to you. All of the other results are discarded.
    ///
    ///  A `Query` operation always returns a result set. If no matching items are found, the result set will be empty. Queries that do not return results consume the minimum number of read capacity units for that type of read operation. </p> <note> <p> DynamoDB calculates the number of read capacity units consumed based on item size, not on the amount of data that is returned to an application. The number of capacity units consumed will be the same whether you request all of the attributes (the default behavior) or just some of them (using a projection expression). The number will also be the same whether or not you use a `FilterExpression`. </p> </note> <p> `Query` results are always sorted by the sort key value. If the data type of the sort key is Number, the results are returned in numeric order; otherwise, the results are returned in order of UTF-8 bytes. By default, the sort order is ascending. To reverse the order, set the `ScanIndexForward` parameter to false.
    ///
    ///  A single `Query` operation will read up to the maximum number of items set (if using the `Limit` parameter) or a maximum of 1 MB of data and then apply any filtering to the results using `FilterExpression`. If `LastEvaluatedKey` is present in the response, you will need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Query.html#Query.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>.
    ///
    ///  `FilterExpression` is applied after a `Query` finishes, but before the results are returned. A `FilterExpression` cannot contain partition key or sort key attributes. You need to specify those attributes in the `KeyConditionExpression`. </p> <note> <p> A `Query` operation can return an empty result set and a `LastEvaluatedKey` if all the items read for the page of results are filtered out. </p> </note> <p>You can query a table, a local secondary index, or a global secondary index. For a query on a table or on a local secondary index, you can set the `ConsistentRead` parameter to `true` and obtain a strongly consistent result. Global secondary indexes support eventually consistent reads only, so do not specify `ConsistentRead` when querying a global secondary index.
    public func queryPaginator<T: Decodable, Result>(
        _ input: QueryInput,
        _ initialValue: Result,
        type: T.Type,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, QueryCodableOutput<T>, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: self.query,
            tokenKey: \QueryOutput.lastEvaluatedKey,
            logger: logger,
            on: eventLoop
        ) { (result, response, eventLoop) -> EventLoopFuture<(Bool, Result)> in
            do {
                let items = try response.items.map { try $0.map { try DynamoDBDecoder().decode(T.self, from: $0) } }
                let queryOutput = QueryCodableOutput(
                    consumedCapacity: response.consumedCapacity,
                    count: response.count,
                    items: items,
                    lastEvaluatedKey: response.lastEvaluatedKey,
                    scannedCount: response.scannedCount
                )
                return onPage(result, queryOutput, eventLoop)
            } catch {
                return eventLoop.makeFailedFuture(error)
            }
        }
    }

    public func queryPaginator<T: Decodable>(
        _ input: QueryInput,
        type: T.Type,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (QueryCodableOutput<T>, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: self.query,
            tokenKey: \QueryOutput.lastEvaluatedKey,
            logger: logger,
            on: eventLoop
        ) { (response, eventLoop) -> EventLoopFuture<Bool> in
            do {
                let items = try response.items.map { try $0.map { try DynamoDBDecoder().decode(T.self, from: $0) } }
                let queryOutput = QueryCodableOutput(
                    consumedCapacity: response.consumedCapacity,
                    count: response.count,
                    items: items,
                    lastEvaluatedKey: response.lastEvaluatedKey,
                    scannedCount: response.scannedCount
                )
                return onPage(queryOutput, eventLoop)
            } catch {
                return eventLoop.makeFailedFuture(error)
            }
        }
    }

    /// The `Scan` operation returns one or more items and item attributes by accessing every item in a table or a secondary index. To have DynamoDB return fewer items, you can provide a `FilterExpression` operation.
    ///
    /// If the total number of scanned items exceeds the maximum dataset size limit of 1 MB, the scan stops and results are returned to the user as a `LastEvaluatedKey` value to continue the scan in a subsequent operation. The results also include the number of items exceeding the limit. A scan can result in no table data meeting the filter criteria.
    ///
    /// A single `Scan` operation reads up to the maximum number of items set (if using the `Limit` parameter) or a maximum of 1 MB of data and then apply any filtering to the results using `FilterExpression`. If `LastEvaluatedKey` is present in the response, you need to paginate the result set. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.Pagination">Paginating the Results</a> in the <i>Amazon DynamoDB Developer Guide</i>.
    ///
    ///  `Scan` operations proceed sequentially; however, for faster performance on a large table or secondary index, applications can request a parallel `Scan` operation by providing the `Segment` and `TotalSegments` parameters. For more information, see <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.ParallelScan">Parallel Scan</a> in the <i>Amazon DynamoDB Developer Guide</i>.
    ///
    ///  `Scan` uses eventually consistent reads when accessing the data in a table; therefore, the result set might not include the changes to data in the table immediately before the operation began. If you need a consistent copy of the data, as of the time that the `Scan` begins, you can set the `ConsistentRead` parameter to `true`.
    public func scanPaginator<T: Decodable, Result>(
        _ input: ScanInput,
        _ initialValue: Result,
        type: T.Type,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (Result, ScanCodableOutput<T>, EventLoop) -> EventLoopFuture<(Bool, Result)>
    ) -> EventLoopFuture<Result> {
        return client.paginate(
            input: input,
            initialValue: initialValue,
            command: self.scan,
            tokenKey: \ScanOutput.lastEvaluatedKey,
            logger: logger,
            on: eventLoop
        ) { (result, response, eventLoop) -> EventLoopFuture<(Bool, Result)> in
            do {
                let items = try response.items.map { try $0.map { try DynamoDBDecoder().decode(T.self, from: $0) } }
                let scanOutput = ScanCodableOutput(
                    consumedCapacity: response.consumedCapacity,
                    count: response.count,
                    items: items,
                    lastEvaluatedKey: response.lastEvaluatedKey,
                    scannedCount: response.scannedCount
                )
                return onPage(result, scanOutput, eventLoop)
            } catch {
                return eventLoop.makeFailedFuture(error)
            }
        }
    }

    public func scanPaginator<T: Decodable>(
        _ input: ScanInput,
        type: T.Type,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        onPage: @escaping (ScanCodableOutput<T>, EventLoop) -> EventLoopFuture<Bool>
    ) -> EventLoopFuture<Void> {
        return client.paginate(
            input: input,
            command: self.scan,
            tokenKey: \ScanOutput.lastEvaluatedKey,
            logger: logger,
            on: eventLoop
        ) { (response, eventLoop) -> EventLoopFuture<Bool> in
            do {
                let items = try response.items.map { try $0.map { try DynamoDBDecoder().decode(T.self, from: $0) } }
                let scanOutput = ScanCodableOutput(
                    consumedCapacity: response.consumedCapacity,
                    count: response.count,
                    items: items,
                    lastEvaluatedKey: response.lastEvaluatedKey,
                    scannedCount: response.scannedCount
                )
                return onPage(scanOutput, eventLoop)
            } catch {
                return eventLoop.makeFailedFuture(error)
            }
        }
    }

    // MARK: Codable Shapes

    /// Version of PutItemInput that replaces the `item` with a `Encodable` class that will then be encoded into `[String: AttributeValue]`
    public struct PutItemCodableInput<T: Encodable> {
        /// A condition that must be satisfied in order for a conditional PutItem operation to succeed. An expression can contain any of the following:   Functions: attribute_exists | attribute_not_exists | attribute_type | contains | begins_with | size  These function names are case-sensitive.   Comparison operators: = | &lt;&gt; | &lt; | &gt; | &lt;= | &gt;= | BETWEEN | IN      Logical operators: AND | OR | NOT    For more information on condition expressions, see Condition Expressions in the Amazon DynamoDB Developer Guide.
        public let conditionExpression: String?
        /// One or more substitution tokens for attribute names in an expression. The following are some use cases for using ExpressionAttributeNames:   To access an attribute whose name conflicts with a DynamoDB reserved word.   To create a placeholder for repeating occurrences of an attribute name in an expression.   To prevent special characters in an attribute name from being misinterpreted in an expression.   Use the # character in an expression to dereference an attribute name. For example, consider the following attribute name:    Percentile    The name of this attribute conflicts with a reserved word, so it cannot be used directly in an expression. (For the complete list of reserved words, see Reserved Words in the Amazon DynamoDB Developer Guide). To work around this, you could specify the following for ExpressionAttributeNames:    {"#P":"Percentile"}    You could then use this substitution in an expression, as in this example:    #P = :val     Tokens that begin with the : character are expression attribute values, which are placeholders for the actual value at runtime.  For more information on expression attribute names, see Specifying Item Attributes in the Amazon DynamoDB Developer Guide.
        public let expressionAttributeNames: [String: String]?
        /// One or more values that can be substituted in an expression. Use the : (colon) character in an expression to dereference an attribute value. For example, suppose that you wanted to check whether the value of the ProductStatus attribute was one of the following:   Available | Backordered | Discontinued  You would first need to specify ExpressionAttributeValues as follows:  { ":avail":{"S":"Available"}, ":back":{"S":"Backordered"}, ":disc":{"S":"Discontinued"} }  You could then use these values in an expression, such as this:  ProductStatus IN (:avail, :back, :disc)  For more information on expression attribute values, see Condition Expressions in the Amazon DynamoDB Developer Guide.
        public let expressionAttributeValues: [String: AttributeValue]?
        /// A codable object. Only the primary key attributes are required; you can optionally provide other attributes for the item. You must provide all of the attributes for the primary key. For example, with a simple primary key, you only need to provide a value for the partition key. For a composite primary key, you must provide both values for both the partition key and the sort key. If you specify any attributes that are part of an index key, then the data types for those attributes must match those of the schema in the table's attribute definition. Empty String and Binary attribute values are allowed. Attribute values of type String and Binary must have a length greater than zero if the attribute is used as a key attribute for a table or index. For more information about primary keys, see Primary Key in the Amazon DynamoDB Developer Guide. Each element in the Item map is an AttributeValue object.
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
        /// An item containing attributes, as specified by ProjectionExpression.
        public let item: T?

        public init(consumedCapacity: ConsumedCapacity? = nil, item: T? = nil) {
            self.consumedCapacity = consumedCapacity
            self.item = item
        }
    }

    public struct UpdateItemCodableInput<T: Encodable>: AWSEncodableShape {
        /// A condition that must be satisfied in order for a conditional update to succeed. An expression can contain any of the following:   Functions: attribute_exists | attribute_not_exists | attribute_type | contains | begins_with | size  These function names are case-sensitive.   Comparison operators: = | &lt;&gt; | &lt; | &gt; | &lt;= | &gt;= | BETWEEN | IN      Logical operators: AND | OR | NOT    For more information about condition expressions, see Specifying Conditions in the Amazon DynamoDB Developer Guide.
        public let conditionExpression: String?
        /// One or more substitution tokens for attribute names in an expression. The following are some use cases for using ExpressionAttributeNames:   To access an attribute whose name conflicts with a DynamoDB reserved word.   To create a placeholder for repeating occurrences of an attribute name in an expression.   To prevent special characters in an attribute name from being misinterpreted in an expression.   Use the # character in an expression to dereference an attribute name. For example, consider the following attribute name:    Percentile    The name of this attribute conflicts with a reserved word, so it cannot be used directly in an expression. (For the complete list of reserved words, see Reserved Words in the Amazon DynamoDB Developer Guide.) To work around this, you could specify the following for ExpressionAttributeNames:    {"#P":"Percentile"}    You could then use this substitution in an expression, as in this example:    #P = :val     Tokens that begin with the : character are expression attribute values, which are placeholders for the actual value at runtime.  For more information about expression attribute names, see Specifying Item Attributes in the Amazon DynamoDB Developer Guide.
        public let expressionAttributeNames: [String: String]?
        /// The primary key of the item to be updated. Each element consists of an attribute name. For the primary key, you must provide all of the attributes. For example, with a simple primary key, you only need to provide a value for the partition key. For a composite primary key, you must provide values for both the partition key and the sort key.
        public let key: [String]
        public let returnConsumedCapacity: ReturnConsumedCapacity?
        /// Determines whether item collection metrics are returned. If set to SIZE, the response includes statistics about item collections, if any, that were modified during the operation are returned in the response. If set to NONE (the default), no statistics are returned.
        public let returnItemCollectionMetrics: ReturnItemCollectionMetrics?
        /// Use ReturnValues if you want to get the item attributes as they appear before or after they are updated. For UpdateItem, the valid values are:    NONE - If ReturnValues is not specified, or if its value is NONE, then nothing is returned. (This setting is the default for ReturnValues.)    ALL_OLD - Returns all of the attributes of the item, as they appeared before the UpdateItem operation.    UPDATED_OLD - Returns only the updated attributes, as they appeared before the UpdateItem operation.    ALL_NEW - Returns all of the attributes of the item, as they appear after the UpdateItem operation.    UPDATED_NEW - Returns only the updated attributes, as they appear after the UpdateItem operation.   There is no additional cost associated with requesting a return value aside from the small network and processing overhead of receiving a larger response. No read capacity units are consumed. The values returned are strongly consistent.
        public let returnValues: ReturnValue?
        /// The name of the table containing the item to update.
        public let tableName: String
        /// An expression that defines one or more attributes to be updated, the action to be performed on them, and new values for them. If this is not set the update is automatically constructed to SET all the values from the updateItem. If you are creating your own updateExpression then all the attribute names are prefixed with the symbol #. The following action values are available for UpdateExpression.    SET - Adds one or more attributes and values to an item. If any of these attributes already exist, they are replaced by the new values. You can also use SET to add or subtract from an attribute that is of type Number. For example: SET myNum = myNum + :val   SET supports the following functions:    if_not_exists (path, operand) - if the item does not contain an attribute at the specified path, then if_not_exists evaluates to operand; otherwise, it evaluates to path. You can use this function to avoid overwriting an attribute that may already be present in the item.    list_append (operand, operand) - evaluates to a list with a new element added to it. You can append the new element to the start or the end of the list by reversing the order of the operands.   These function names are case-sensitive.    REMOVE - Removes one or more attributes from an item.    ADD - Adds the specified value to the item, if the attribute does not already exist. If the attribute does exist, then the behavior of ADD depends on the data type of the attribute:   If the existing attribute is a number, and if Value is also a number, then Value is mathematically added to the existing attribute. If Value is a negative number, then it is subtracted from the existing attribute.  If you use ADD to increment or decrement a number value for an item that doesn't exist before the update, DynamoDB uses 0 as the initial value. Similarly, if you use ADD for an existing item to increment or decrement an attribute value that doesn't exist before the update, DynamoDB uses 0 as the initial value. For example, suppose that the item you want to update doesn't have an attribute named itemcount, but you decide to ADD the number 3 to this attribute anyway. DynamoDB will create the itemcount attribute, set its initial value to 0, and finally add 3 to it. The result will be a new itemcount attribute in the item, with a value of 3.    If the existing data type is a set and if Value is also a set, then Value is added to the existing set. For example, if the attribute value is the set [1,2], and the ADD action specified [3], then the final attribute value is [1,2,3]. An error occurs if an ADD action is specified for a set attribute and the attribute type specified does not match the existing set type.  Both sets must have the same primitive data type. For example, if the existing data type is a set of strings, the Value must also be a set of strings.    The ADD action only supports Number and set data types. In addition, ADD can only be used on top-level attributes, not nested attributes.     DELETE - Deletes an element from a set. If a set of values is specified, then those values are subtracted from the old set. For example, if the attribute value was the set [a,b,c] and the DELETE action specifies [a,c], then the final attribute value is [b]. Specifying an empty set is an error.  The DELETE action only supports set data types. In addition, DELETE can only be used on top-level attributes, not nested attributes.    You can have many actions in a single expression, such as the following: SET a=:value1, b=:value2 DELETE :value3, :value4, :value5  For more information on update expressions, see Modifying Items and Attributes in the Amazon DynamoDB Developer Guide.
        public let updateExpression: String?
        /// Object containing item key and attributes to update
        public let updateItem: T

        public init(conditionExpression: String? = nil, expressionAttributeNames: [String: String]? = nil, key: [String], returnConsumedCapacity: ReturnConsumedCapacity? = nil, returnItemCollectionMetrics: ReturnItemCollectionMetrics? = nil, returnValues: ReturnValue? = nil, tableName: String, updateExpression: String? = nil, updateItem: T) {
            self.conditionExpression = conditionExpression
            self.expressionAttributeNames = expressionAttributeNames
            self.key = key
            self.returnConsumedCapacity = returnConsumedCapacity
            self.returnItemCollectionMetrics = returnItemCollectionMetrics
            self.returnValues = returnValues
            self.tableName = tableName
            self.updateExpression = updateExpression
            self.updateItem = updateItem
        }
    }

    public struct QueryCodableOutput<T: Decodable> {
        /// The capacity units consumed by the Query operation. The data returned includes the total provisioned throughput consumed, along with statistics for the table and any indexes involved in the operation. ConsumedCapacity is only returned if the ReturnConsumedCapacity parameter was specified. For more information, see Provisioned Throughput in the Amazon DynamoDB Developer Guide.
        public let consumedCapacity: ConsumedCapacity?
        /// The number of items in the response. If you used a QueryFilter in the request, then Count is the number of items returned after the filter was applied, and ScannedCount is the number of matching items before the filter was applied. If you did not use a filter in the request, then Count and ScannedCount are the same.
        public let count: Int?
        /// An array of items that match the query criteria.
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
        /// An array of items that match the scan criteria.
        public let items: [T]?
        /// The primary key of the item where the operation stopped, inclusive of the previous result set. Use this value to start a new operation, excluding this value in the new request. If LastEvaluatedKey is empty, then the "last page" of results has been processed and there is no more data to be retrieved. If LastEvaluatedKey is not empty, it does not necessarily mean that there is more data in the result set. The only way to know when you have reached the end of the result set is when LastEvaluatedKey is empty.
        public let lastEvaluatedKey: [String: AttributeValue]?
        /// The number of items evaluated, before any ScanFilter is applied. A high ScannedCount value with few, or no, Count results indicates an inefficient Scan operation. For more information, see Count and ScannedCount in the Amazon DynamoDB Developer Guide. If you did not use a filter in the request, then ScannedCount is the same as Count.
        public let scannedCount: Int?
    }
}

extension DynamoDB.AttributeValue: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.b(let lhs), .b(let rhs)):
            return lhs == rhs
        case (.bool(let lhs), .bool(let rhs)):
            return lhs == rhs
        case (.bs(let lhs), .bs(let rhs)):
            return lhs == rhs
        case (.l(let lhs), .l(let rhs)):
            return lhs == rhs
        case (.m(let lhs), .m(let rhs)):
            return lhs == rhs
        case (.n(let lhs), .n(let rhs)):
            return lhs == rhs
        case (.ns(let lhs), .ns(let rhs)):
            return lhs == rhs
        case (.null(let lhs), .null(let rhs)):
            return lhs == rhs
        case (.s(let lhs), .s(let rhs)):
            return lhs == rhs
        case (.ss(let lhs), .ss(let rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}
