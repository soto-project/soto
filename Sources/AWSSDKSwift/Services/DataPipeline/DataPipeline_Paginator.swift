// THIS FILE IS AUTOMATICALLY GENERATED by https://github.com/swift-aws/aws-sdk-swift/blob/master/CodeGenerator/Sources/CodeGenerator/main.swift. DO NOT EDIT.

import NIO

extension DataPipeline {

    ///  Gets the object definitions for a set of objects associated with the pipeline. Object definitions are composed of a set of fields that define the properties of the object.
    public func describeObjectsPaginator(_ input: DescribeObjectsInput) -> EventLoopFuture<[PipelineObject]> {
        return client.paginate(input: input, command: describeObjects, resultKey: \DescribeObjectsOutput.pipelineObjects, tokenKey: \DescribeObjectsOutput.marker)
    }
    
    ///  Lists the pipeline identifiers for all active pipelines that you have permission to access.
    public func listPipelinesPaginator(_ input: ListPipelinesInput) -> EventLoopFuture<[PipelineIdName]> {
        return client.paginate(input: input, command: listPipelines, resultKey: \ListPipelinesOutput.pipelineIdList, tokenKey: \ListPipelinesOutput.marker)
    }
    
    ///  Queries the specified pipeline for the names of objects that match the specified set of conditions.
    public func queryObjectsPaginator(_ input: QueryObjectsInput) -> EventLoopFuture<[String]> {
        return client.paginate(input: input, command: queryObjects, resultKey: \QueryObjectsOutput.ids, tokenKey: \QueryObjectsOutput.marker)
    }
    
}

extension DataPipeline.DescribeObjectsInput: AWSPaginateStringToken {
    public init(_ original: DataPipeline.DescribeObjectsInput, token: String) {
        self.init(
            evaluateExpressions: original.evaluateExpressions, 
            marker: token, 
            objectIds: original.objectIds, 
            pipelineId: original.pipelineId
        )
    }
}

extension DataPipeline.ListPipelinesInput: AWSPaginateStringToken {
    public init(_ original: DataPipeline.ListPipelinesInput, token: String) {
        self.init(
            marker: token
        )
    }
}

extension DataPipeline.QueryObjectsInput: AWSPaginateStringToken {
    public init(_ original: DataPipeline.QueryObjectsInput, token: String) {
        self.init(
            limit: original.limit, 
            marker: token, 
            pipelineId: original.pipelineId, 
            query: original.query, 
            sphere: original.sphere
        )
    }
}

