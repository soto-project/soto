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
    case doesNotExist
    case unexpectedValue(expected: String, got: String)
}

protocol PatchV2 {
    func apply(to api: inout API) throws
}

protocol Patchable: class {}

extension API {
    static let servicePatches: [String: [PatchV2]] = [
        "CloudWatch" : [
            // Patch error shape to avoid warning in generated code. Both errors have the same code "ResourceNotFound"
            ReplacePatch2(keyPath1: \.operations["GetDashboard"], keyPath2: \.errors[1].shapeName, value: "ResourceNotFoundException", originalValue: "DashboardNotFoundError"),
            ReplacePatch2(keyPath1: \.operations["DeleteDashboards"], keyPath2: \.errors[1].shapeName, value: "ResourceNotFoundException", originalValue: "DashboardNotFoundError")
        ],
        "ElasticLoadBalancing" : [
            ReplacePatch(keyPath: \.serviceName, value:"ELB", originalValue:"ElasticLoadBalancing"),
            ReplacePatch2(keyPath1: \.shapes["SecurityGroupOwnerAlias"], keyPath2: \.type, value: .integer(), originalValue: .string())
        ],
        "ElasticLoadBalancingv2" : [
            ReplacePatch(keyPath: \.serviceName, value:"ELBV2", originalValue:"ElasticLoadBalancingv2")
        ],
        "S3": [
            ReplacePatch3(keyPath1: \.shapes["ReplicationStatus"], keyPath2: \.type.enum, keyPath3: \.cases[0], value: "COMPLETED", originalValue: "COMPLETE"),
            ReplacePatch2(keyPath1: \.shapes["Size"], keyPath2: \.type, value: .long(), originalValue: .integer()),
            // Add additional location constraints
            AddPatch3(keyPath1: \.shapes["BucketLocationConstraint"], keyPath2: \.type.enum, keyPath3: \.cases, value: "us-east-2"),
            AddPatch3(keyPath1: \.shapes["BucketLocationConstraint"], keyPath2: \.type.enum, keyPath3: \.cases, value: "eu-west-2"),
            AddPatch3(keyPath1: \.shapes["BucketLocationConstraint"], keyPath2: \.type.enum, keyPath3: \.cases, value: "eu-west-3"),
            AddPatch3(keyPath1: \.shapes["BucketLocationConstraint"], keyPath2: \.type.enum, keyPath3: \.cases, value: "eu-north-1"),
            AddPatch3(keyPath1: \.shapes["BucketLocationConstraint"], keyPath2: \.type.enum, keyPath3: \.cases, value: "ap-east-1"),
            AddPatch3(keyPath1: \.shapes["BucketLocationConstraint"], keyPath2: \.type.enum, keyPath3: \.cases, value: "ap-northeast-2"),
            AddPatch3(keyPath1: \.shapes["BucketLocationConstraint"], keyPath2: \.type.enum, keyPath3: \.cases, value: "ap-northeast-3"),
            AddPatch3(keyPath1: \.shapes["BucketLocationConstraint"], keyPath2: \.type.enum, keyPath3: \.cases, value: "ca-central-1"),
            AddPatch3(keyPath1: \.shapes["BucketLocationConstraint"], keyPath2: \.type.enum, keyPath3: \.cases, value: "cn-northwest-1"),
            AddPatch3(keyPath1: \.shapes["BucketLocationConstraint"], keyPath2: \.type.enum, keyPath3: \.cases, value: "me-south-1")
        ],
    ]

    // structure defining a model patch
    struct ReplacePatch<T: Equatable>: PatchV2 {
        let keyPath: WritableKeyPath<API, T>
        let value : T
        let originalValue : T

        func apply(to api: inout API) throws {
            guard api[keyPath: keyPath] == self.originalValue else {
                throw APIPatchError.unexpectedValue(expected: "\(self.originalValue)", got: "\(api[keyPath: keyPath])")
            }
            api[keyPath: keyPath] = value
        }
    }
    
    struct ReplacePatch2<T: Patchable, U: Equatable>: PatchV2 {
        let keyPath1: KeyPath<API, T?>
        let keyPath2: WritableKeyPath<T, U>
        let value : U
        let originalValue : U

        func apply(to api: inout API) throws {
            guard var object1 = api[keyPath: keyPath1] else { throw APIPatchError.doesNotExist }
            guard object1[keyPath: keyPath2] == self.originalValue else {
                throw APIPatchError.unexpectedValue(expected: "\(self.originalValue)", got: "\(object1[keyPath: keyPath2])")
            }
            object1[keyPath: keyPath2] = value
        }
    }
    
    struct ReplacePatch3<T: Patchable, U: Patchable, V: Equatable>: PatchV2 {
        let keyPath1: KeyPath<API, T?>
        let keyPath2: KeyPath<T, U?>
        let keyPath3: WritableKeyPath<U, V>
        let value : V
        let originalValue : V

        func apply(to api: inout API) throws {
            guard let object1 = api[keyPath: keyPath1] else { throw APIPatchError.doesNotExist }
            guard var object2 = object1[keyPath: keyPath2] else { throw APIPatchError.doesNotExist }
            guard object2[keyPath: keyPath3] == self.originalValue else {
                throw APIPatchError.unexpectedValue(expected: "\(self.originalValue)", got: "\(object2[keyPath: keyPath3])")
            }
            object2[keyPath: keyPath3] = value
        }
    }
    
    struct AddPatch2<T: Patchable, U>: PatchV2 {
        let keyPath1: KeyPath<API, T?>
        let keyPath2: WritableKeyPath<T, Array<U>>
        let value : U

        func apply(to api: inout API) throws {
            guard var object1 = api[keyPath: keyPath1] else { throw APIPatchError.doesNotExist }
            object1[keyPath: keyPath2].append(value)
        }
    }
    
    struct AddPatch3<T: Patchable, U: Patchable, V>: PatchV2 {
        let keyPath1: KeyPath<API, T?>
        let keyPath2: KeyPath<T, U?>
        let keyPath3: WritableKeyPath<U, Array<V>>
        let value : V

        func apply(to api: inout API) throws {
            guard let object1 = api[keyPath: keyPath1] else { throw APIPatchError.doesNotExist }
            guard var object2 = object1[keyPath: keyPath2] else { throw APIPatchError.doesNotExist }
            object2[keyPath: keyPath3].append(value)
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

extension API.Shape.ShapeType: Equatable {
    static func == (lhs: API.Shape.ShapeType, rhs: API.Shape.ShapeType) -> Bool {
        switch lhs {
        case .string:
            if case .string = rhs { return true}
        case .integer:
            if case .integer = rhs { return true}
        case .structure:
            if case .structure = rhs { return true}
        case .list:
            if case .list = rhs { return true}
        case .map:
            if case .map = rhs { return true}
        case .blob:
            if case .blob = rhs { return true}
        case .long:
            if case .long = rhs { return true}
        case .double:
            if case .double = rhs { return true}
        case .float:
            if case .float = rhs { return true}
        case .timestamp:
            if case .timestamp = rhs { return true}
        case .boolean:
            if case .boolean = rhs { return true}
        case .enum:
            if case .enum = rhs { return true}
        }
        return false
    }
}
