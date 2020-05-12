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

enum APIPatchError: Error {
    case doesNotExist
    case unexpectedValue(expected: String, got: String)
}

protocol Patch {
    func apply(to api: inout API) throws
}

protocol Patchable: class {}

extension API {
    static let servicePatches: [String: [Patch]] = [
        "CloudFront": [
            ReplacePatch3(keyPath1: \.shapes["HttpVersion"], keyPath2: \.type.enum, keyPath3: \.cases[0], value: "HTTP1_1", originalValue: "http1.1"),
            ReplacePatch3(keyPath1: \.shapes["HttpVersion"], keyPath2: \.type.enum, keyPath3: \.cases[1], value: "HTTP2", originalValue: "http2"),
        ],
        "CloudTrail": [
            ReplacePatch2(keyPath1: \.shapes["Date"], keyPath2: \.type, value: .timestamp(.unixTimestamp), originalValue: .timestamp(.iso8601))
        ],
        "CloudWatch": [
            // Patch error shape to avoid warning in generated code. Both errors have the same code "ResourceNotFound"
            ReplacePatch2(
                keyPath1: \.operations["GetDashboard"],
                keyPath2: \.errors[1].shapeName,
                value: "ResourceNotFoundException",
                originalValue: "DashboardNotFoundError"
            ),
            ReplacePatch2(
                keyPath1: \.operations["DeleteDashboards"],
                keyPath2: \.errors[1].shapeName,
                value: "ResourceNotFoundException",
                originalValue: "DashboardNotFoundError"
            ),
        ],
        "ComprehendMedical": [
            AddPatch3(keyPath1: \.shapes["EntitySubType"], keyPath2: \.type.enum, keyPath3: \.cases, value: "DX_NAME"),
        ],
        "EC2": [
            ReplacePatch3(
                keyPath1: \.shapes["PlatformValues"],
                keyPath2: \.type.enum,
                keyPath3: \.cases[0],
                value: "windows",
                originalValue: "Windows"
            ),
        ],
        "ECS": [
            AddPatch3(keyPath1: \.shapes["PropagateTags"], keyPath2: \.type.enum, keyPath3: \.cases, value: "NONE"),
            //.init(.add, entry:["shapes", "PropagateTags", "enum"], value:"NONE")
        ],
        "ElasticLoadBalancing": [
            ReplacePatch(keyPath: \.serviceName, value: "ELB", originalValue: "ElasticLoadBalancing"),
            ReplacePatch2(keyPath1: \.shapes["SecurityGroupOwnerAlias"], keyPath2: \.type, value: .integer(), originalValue: .string()),
        ],
        "ElasticLoadBalancingv2": [
            ReplacePatch(keyPath: \.serviceName, value: "ELBV2", originalValue: "ElasticLoadBalancingv2")
        ],
        "IAM": [
            AddPatch3(keyPath1: \.shapes["PolicySourceType"], keyPath2: \.type.enum, keyPath3: \.cases, value: "IAM Policy"),
        ],
        "Route53": [
            RemovePatch3(keyPath1: \.shapes["ListHealthChecksResponse"], keyPath2: \.type.structure, keyPath3: \.required, value: "Marker"),
            RemovePatch3(keyPath1: \.shapes["ListHostedZonesResponse"], keyPath2: \.type.structure, keyPath3: \.required, value: "Marker"),
            RemovePatch3(keyPath1: \.shapes["ListReusableDelegationSetsResponse"], keyPath2: \.type.structure, keyPath3: \.required, value: "Marker"),
        ],
        "S3": [
            ReplacePatch3(
                keyPath1: \.shapes["ReplicationStatus"],
                keyPath2: \.type.enum,
                keyPath3: \.cases[0],
                value: "COMPLETED",
                originalValue: "COMPLETE"
            ),
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
            AddPatch3(keyPath1: \.shapes["BucketLocationConstraint"], keyPath2: \.type.enum, keyPath3: \.cases, value: "me-south-1"),
        ],
        "SQS": [
            RemovePatch3(keyPath1: \.shapes["SendMessageBatchResult"], keyPath2: \.type.structure, keyPath3: \.required, value: "Successful"),
            RemovePatch3(keyPath1: \.shapes["SendMessageBatchResult"], keyPath2: \.type.structure, keyPath3: \.required, value: "Failed"),
        ],
    ]

    // structure defining a model patch
    struct ReplacePatch<T: Equatable>: Patch {
        let keyPath: WritableKeyPath<API, T>
        let value: T
        let originalValue: T

        func apply(to api: inout API) throws {
            guard api[keyPath: keyPath] == self.originalValue else {
                throw APIPatchError.unexpectedValue(expected: "\(self.originalValue)", got: "\(api[keyPath: keyPath])")
            }
            api[keyPath: keyPath] = value
        }
    }

    struct ReplacePatch2<T: Patchable, U: Equatable>: Patch {
        let keyPath1: KeyPath<API, T?>
        let keyPath2: WritableKeyPath<T, U>
        let value: U
        let originalValue: U

        func apply(to api: inout API) throws {
            guard var object1 = api[keyPath: keyPath1] else { throw APIPatchError.doesNotExist }
            guard object1[keyPath: keyPath2] == self.originalValue else {
                throw APIPatchError.unexpectedValue(expected: "\(self.originalValue)", got: "\(object1[keyPath: keyPath2])")
            }
            object1[keyPath: keyPath2] = value
        }
    }

    struct ReplacePatch3<T: Patchable, U: Patchable, V: Equatable>: Patch {
        let keyPath1: KeyPath<API, T?>
        let keyPath2: KeyPath<T, U?>
        let keyPath3: WritableKeyPath<U, V>
        let value: V
        let originalValue: V

        func apply(to api: inout API) throws {
            guard let object1 = api[keyPath: keyPath1] else { throw APIPatchError.doesNotExist }
            guard var object2 = object1[keyPath: keyPath2] else { throw APIPatchError.doesNotExist }
            guard object2[keyPath: keyPath3] == self.originalValue else {
                throw APIPatchError.unexpectedValue(expected: "\(self.originalValue)", got: "\(object2[keyPath: keyPath3])")
            }
            object2[keyPath: keyPath3] = value
        }
    }

    struct RemovePatch2<T: Patchable, U: Equatable>: Patch {
        let keyPath1: KeyPath<API, T?>
        let keyPath2: WritableKeyPath<T, [U]>
        let value: U

        func apply(to api: inout API) throws {
            guard var object1 = api[keyPath: keyPath1] else { throw APIPatchError.doesNotExist }
            guard let index = object1[keyPath: keyPath2].firstIndex(of: value) else { throw APIPatchError.doesNotExist }
            object1[keyPath: keyPath2].remove(at: index)
        }
    }

    struct RemovePatch3<T: Patchable, U: Patchable, V: Equatable>: Patch {
        let keyPath1: KeyPath<API, T?>
        let keyPath2: KeyPath<T, U?>
        let keyPath3: WritableKeyPath<U, [V]>
        let value: V

        func apply(to api: inout API) throws {
            guard let object1 = api[keyPath: keyPath1] else { throw APIPatchError.doesNotExist }
            guard var object2 = object1[keyPath: keyPath2] else { throw APIPatchError.doesNotExist }
            guard let index = object2[keyPath: keyPath3].firstIndex(of: value) else { throw APIPatchError.doesNotExist }
            object2[keyPath: keyPath3].remove(at: index)
        }
    }

    struct AddPatch2<T: Patchable, U>: Patch {
        let keyPath1: KeyPath<API, T?>
        let keyPath2: WritableKeyPath<T, [U]>
        let value: U

        func apply(to api: inout API) throws {
            guard var object1 = api[keyPath: keyPath1] else { throw APIPatchError.doesNotExist }
            object1[keyPath: keyPath2].append(value)
        }
    }

    struct AddPatch3<T: Patchable, U: Patchable, V>: Patch {
        let keyPath1: KeyPath<API, T?>
        let keyPath2: KeyPath<T, U?>
        let keyPath3: WritableKeyPath<U, [V]>
        let value: V

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

extension Shape.ShapeType: Equatable {
    /// use to verify is shape types are the same when checking original values in replace patches
    static func == (lhs: Shape.ShapeType, rhs: Shape.ShapeType) -> Bool {
        switch lhs {
        case .string:
            if case .string = rhs { return true }
        case .integer:
            if case .integer = rhs { return true }
        case .structure:
            if case .structure = rhs { return true }
        case .list:
            if case .list = rhs { return true }
        case .map:
            if case .map = rhs { return true }
        case .blob:
            if case .blob = rhs { return true }
        case .payload:
            if case .payload = rhs { return true }
        case .long:
            if case .long = rhs { return true }
        case .double:
            if case .double = rhs { return true }
        case .float:
            if case .float = rhs { return true }
        case .timestamp:
            if case .timestamp = rhs { return true }
        case .boolean:
            if case .boolean = rhs { return true }
        case .enum:
            if case .enum = rhs { return true }
        }
        return false
    }
}
