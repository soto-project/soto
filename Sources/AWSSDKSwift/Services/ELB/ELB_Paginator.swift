// THIS FILE IS AUTOMATICALLY GENERATED by https://github.com/swift-aws/aws-sdk-swift/blob/master/CodeGenerator/Sources/CodeGenerator/main.swift. DO NOT EDIT.

import NIO

extension ELB {

    ///  Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
    public func describeLoadBalancersPaginator(_ input: DescribeAccessPointsInput) -> EventLoopFuture<[LoadBalancerDescription]> {
        return client.paginate(input: input, command: describeLoadBalancers, resultKey: \DescribeAccessPointsOutput.loadBalancerDescriptions, tokenKey: \DescribeAccessPointsOutput.nextMarker)
    }
    
}

extension ELB.DescribeAccessPointsInput: AWSPaginateStringToken {
    public init(_ original: ELB.DescribeAccessPointsInput, token: String) {
        self.init(
            loadBalancerNames: original.loadBalancerNames, 
            marker: token, 
            pageSize: original.pageSize
        )
    }
}

