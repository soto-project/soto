// THIS FILE IS AUTOMATICALLY GENERATED by https://github.com/swift-aws/aws-sdk-swift/blob/master/CodeGenerator/Sources/CodeGenerator/main.swift. DO NOT EDIT.

import NIO

extension EKS {

    ///  Lists the Amazon EKS clusters in your AWS account in the specified Region.
    public func listClustersPaginator(_ input: ListClustersRequest) -> EventLoopFuture<[String]> {
        return client.paginate(input: input, command: listClusters, resultKey: \ListClustersResponse.clusters, tokenKey: \ListClustersResponse.nextToken)
    }
    
    ///  Lists the AWS Fargate profiles associated with the specified cluster in your AWS account in the specified Region.
    public func listFargateProfilesPaginator(_ input: ListFargateProfilesRequest) -> EventLoopFuture<[String]> {
        return client.paginate(input: input, command: listFargateProfiles, resultKey: \ListFargateProfilesResponse.fargateProfileNames, tokenKey: \ListFargateProfilesResponse.nextToken)
    }
    
    ///  Lists the Amazon EKS node groups associated with the specified cluster in your AWS account in the specified Region.
    public func listNodegroupsPaginator(_ input: ListNodegroupsRequest) -> EventLoopFuture<[String]> {
        return client.paginate(input: input, command: listNodegroups, resultKey: \ListNodegroupsResponse.nodegroups, tokenKey: \ListNodegroupsResponse.nextToken)
    }
    
    ///  Lists the updates associated with an Amazon EKS cluster or managed node group in your AWS account, in the specified Region.
    public func listUpdatesPaginator(_ input: ListUpdatesRequest) -> EventLoopFuture<[String]> {
        return client.paginate(input: input, command: listUpdates, resultKey: \ListUpdatesResponse.updateIds, tokenKey: \ListUpdatesResponse.nextToken)
    }
    
}

extension EKS.ListClustersRequest: AWSPaginateStringToken {
    public init(_ original: EKS.ListClustersRequest, token: String) {
        self.init(
            maxResults: original.maxResults, 
            nextToken: token
        )
    }
}

extension EKS.ListFargateProfilesRequest: AWSPaginateStringToken {
    public init(_ original: EKS.ListFargateProfilesRequest, token: String) {
        self.init(
            clusterName: original.clusterName, 
            maxResults: original.maxResults, 
            nextToken: token
        )
    }
}

extension EKS.ListNodegroupsRequest: AWSPaginateStringToken {
    public init(_ original: EKS.ListNodegroupsRequest, token: String) {
        self.init(
            clusterName: original.clusterName, 
            maxResults: original.maxResults, 
            nextToken: token
        )
    }
}

extension EKS.ListUpdatesRequest: AWSPaginateStringToken {
    public init(_ original: EKS.ListUpdatesRequest, token: String) {
        self.init(
            maxResults: original.maxResults, 
            name: original.name, 
            nextToken: token, 
            nodegroupName: original.nodegroupName
        )
    }
}

