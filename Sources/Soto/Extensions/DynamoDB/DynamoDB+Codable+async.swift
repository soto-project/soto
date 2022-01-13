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

#if compiler(>=5.5.2) && canImport(_Concurrency)

import SotoCore

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
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
    ) async throws -> PutItemOutput {
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
            return try await self.putItem(request, logger: logger, on: eventLoop)
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
    ) async throws -> GetItemCodableOutput<T> {
        let response = try await self.getItem(input, logger: logger, on: eventLoop)
        let item = try response.item.map { try DynamoDBDecoder().decode(T.self, from: $0) }
        return GetItemCodableOutput(
            consumedCapacity: response.consumedCapacity,
            item: item
        )
    }

    /// Edits an existing item's attributes, or adds a new item to the table if it does not already exist. You can put, delete, or add attribute values. You can also perform a conditional update on an existing item (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values).
    ///
    /// You can also return the item's attribute values in the same `UpdateItem` operation using the `ReturnValues` parameter.
    public func updateItem<T: Encodable>(
        _ input: UpdateItemCodableInput<T>,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) async throws -> UpdateItemOutput {
        return try await self.updateItem(input.createUpdateItemInput(), logger: logger, on: eventLoop)
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
    ) async throws -> QueryCodableOutput<T> {
        let response = try await self.query(input, logger: logger, on: eventLoop)
        let items = try response.items.map { try $0.map { try DynamoDBDecoder().decode(T.self, from: $0) } }
        return QueryCodableOutput(
            consumedCapacity: response.consumedCapacity,
            count: response.count,
            items: items,
            lastEvaluatedKey: response.lastEvaluatedKey,
            scannedCount: response.scannedCount
        )
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
    ) async throws -> ScanCodableOutput<T> {
        let response = try await self.scan(input, logger: logger, on: eventLoop)
        let items = try response.items.map { try $0.map { try DynamoDBDecoder().decode(T.self, from: $0) } }
        return ScanCodableOutput(
            consumedCapacity: response.consumedCapacity,
            count: response.count,
            items: items,
            lastEvaluatedKey: response.lastEvaluatedKey,
            scannedCount: response.scannedCount
        )
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
    public func queryPaginator<T: Decodable>(
        _ input: QueryInput,
        type: T.Type,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<QueryInput, QueryCodableOutput<T>> {
        return .init(
            input: input,
            command: { input, logger, eventLoop in try await query(input, type: T.self, logger: logger, on: eventLoop) },
            inputKey: \QueryInput.exclusiveStartKey,
            outputKey: \QueryCodableOutput<T>.lastEvaluatedKey,
            logger: logger,
            on: eventLoop
        )
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
    public func scanPaginator<T: Decodable>(
        _ input: ScanInput,
        type: T.Type,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> AWSClient.PaginatorSequence<ScanInput, ScanCodableOutput<T>> {
        return .init(
            input: input,
            command: { input, logger, eventLoop in try await scan(input, type: T.self, logger: logger, on: eventLoop) },
            inputKey: \ScanInput.exclusiveStartKey,
            outputKey: \ScanCodableOutput<T>.lastEvaluatedKey,
            logger: logger,
            on: eventLoop
        )
    }
}

#endif // compiler(>=5.5.2) && canImport(_Concurrency)
