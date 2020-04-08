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


//
// Patch operations
//
/*let servicePatches : [String: [Patch]] = [
    "CloudFront" : [
        .init(.replace, entry:["shapes", "HttpVersion", "enum", 0], value:"HTTP1_1", originalValue:"http1.1"),
        .init(.replace, entry:["shapes", "HttpVersion", "enum", 1], value:"HTTP2", originalValue:"http2")
    ],
    "CloudWatch" : [
        // Patch error shape to avoid warning in generated code. Both errors have the same code "ResourceNotFound"
        .init(.replace, entry:["operations", "GetDashboard", "errors", 1, "shape"], value:"ResourceNotFoundException", originalValue: "DashboardNotFoundError"),
        .init(.replace, entry:["operations", "DeleteDashboards", "errors", 1, "shape"], value:"ResourceNotFoundException", originalValue: "DashboardNotFoundError")
    ],
    "ComprehendMedical" : [
        .init(.add, entry:["shapes", "EntitySubType", "enum"], value:"DX_NAME")
    ],
    "Config" : [
        .init(.replace, entry:["serviceName"], value:"ConfigService", originalValue:"Config")
    ],
    "ECS" : [
        .init(.add, entry:["shapes", "PropagateTags", "enum"], value:"NONE")
    ],
    "EC2" : [
        .init(.replace, entry:["shapes", "PlatformValues", "enum", 0], value:"windows", originalValue:"Windows")
    ],
    "ElasticLoadBalancing" : [
        .init(.replace, entry:["serviceName"], value:"ELB", originalValue:"ElasticLoadBalancing"),
        .init(.replace, entry:["shapes", "SecurityGroupOwnerAlias", "type"], value:"integer", originalValue:"string")
    ],
    "ElasticLoadBalancingv2" : [
        .init(.replace, entry:["serviceName"], value:"ELBV2", originalValue:"ElasticLoadBalancingv2")
    ],
    "IAM" : [
        .init(.add, entry:["shapes", "PolicySourceType", "enum"], value:"IAM Policy")
    ],
    "Route53": [
        .init(.remove, entry:["shapes", "ListHealthChecksResponse", "required"], value:"Marker"),
        .init(.remove, entry:["shapes", "ListHostedZonesResponse", "required"], value:"Marker"),
        .init(.remove, entry:["shapes", "ListReusableDelegationSetsResponse", "required"], value:"Marker")
    ],
    "S3": [
        .init(.replace, entry:["shapes","ReplicationStatus","enum",0], value:"COMPLETED", originalValue:"COMPLETE"),
        .init(.replace, entry:["shapes","Size","type"], value:"long", originalValue:"integer"),
        // Add additional location constraints
        .init(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"us-east-2"),
        .init(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"eu-west-2"),
        .init(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"eu-west-3"),
        .init(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"eu-north-1"),
        .init(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"ap-east-1"),
        .init(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"ap-northeast-2"),
        .init(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"ap-northeast-3"),
        .init(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"ca-central-1"),
        .init(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"cn-northwest-1"),
        .init(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"me-south-1"),
    ],
    "SQS": [
        .init(.remove, entry:["shapes", "SendMessageBatchResult", "required"], value:"Successful"),
        .init(.remove, entry:["shapes", "SendMessageBatchResult", "required"], value:"Failed"),
    ]
]*/

enum APIPatchError: Error {
    case unexpectedValue(expected: String, got: String)
}

protocol PatchV2 {
    func apply(to api: inout API) throws
}

extension API {
    static let servicePatches: [String: [PatchV2]] = [
        "ElasticLoadBalancing" : [
            ReplacePatch(keyPath: \.serviceName, value:"ELB", originalValue:"ElasticLoadBalancing"),
            //ReplacePatch(keyPath: \.shapes.SecurityGroupOwnerAlias.shapeType, value: API.Shape.ShapeType.integer, originalValue: API.Shape.ShapeType.string)
            //.init(.replace, entry:["shapes", "SecurityGroupOwnerAlias", "type"], value:"integer", originalValue:"string")
        ],
        "ElasticLoadBalancingv2" : [
            ReplacePatch(keyPath: \.serviceName, value:"ELBV2", originalValue:"ElasticLoadBalancingv2")
        ],
    ]

    // structure defining a model patch
    struct ReplacePatch<T: Equatable>: PatchV2 {
        let keyPath: WritableKeyPath<API, T>
        let value : T
        let originalValue : T

        func apply(to api: inout API) throws {
            guard api[keyPath: keyPath] == originalValue else {
                throw APIPatchError.unexpectedValue(expected: "\(originalValue)", got: "\(api[keyPath: keyPath])")
            }
            api[keyPath: keyPath] = value
        }
    }

}
extension API {
    mutating func patch() throws {
        guard let patches = Self.servicePatches[serviceName] else { return }
        for patch in patches {
            try patch.apply(to: &self)
        }
    }
}
