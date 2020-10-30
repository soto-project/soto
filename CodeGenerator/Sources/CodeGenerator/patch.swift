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

enum APIPatchError: Error {
    case doesNotExist
    case unexpectedValue(expected: String, got: String)
}

protocol Patch {
    func apply(to api: inout API) throws
}

protocol Patchable: AnyObject {}

extension API {
    static let servicePatches: [String: [Patch]] = [
        "CloudFront": [
            ReplacePatch(PatchKeyPath3(\.shapes["HttpVersion"], \.type.enum, \.cases[0]), value: "HTTP1_1", originalValue: "http1.1"),
            ReplacePatch(PatchKeyPath3(\.shapes["HttpVersion"], \.type.enum, \.cases[1]), value: "HTTP2", originalValue: "http2"),
        ],
        "CloudWatch": [
            // Patch error shape to avoid warning in generated code. Both errors have the same code "ResourceNotFound"
            ReplacePatch(PatchKeyPath2(\.operations["GetDashboard"], \.errors[1].shapeName), value: "ResourceNotFoundException", originalValue: "DashboardNotFoundError"),
            ReplacePatch(PatchKeyPath2(\.operations["DeleteDashboards"], \.errors[1].shapeName), value: "ResourceNotFoundException", originalValue: "DashboardNotFoundError"),
        ],
        "ComprehendMedical": [
            AddPatch(PatchKeyPath3(\.shapes["EntitySubType"], \.type.enum, \.cases), value: "DX_NAME"),
        ],
        "DynamoDB": [
            ReplacePatch(PatchKeyPath3(\.shapes["AttributeValue"], \.type.structure, \.isEnum), value: true, originalValue: false),
            ReplacePatch(PatchKeyPath3(\.shapes["TransactWriteItem"], \.type.structure, \.isEnum), value: true, originalValue: false),
        ],
        "EC2": [
            ReplacePatch(PatchKeyPath3(\.shapes["PlatformValues"], \.type.enum, \.cases[0]), value: "windows", originalValue: "Windows"),
            ReplacePatch(PatchKeyPath3(\.shapes["InstanceType"], \.type.enum, \.isExtensible), value: true, originalValue: false),
        ],
        "ECS": [
            AddPatch(PatchKeyPath3(\.shapes["PropagateTags"], \.type.enum, \.cases), value: "NONE"),
        ],
        "ElasticLoadBalancing": [
            ReplacePatch(PatchKeyPath2(\.shapes["SecurityGroupOwnerAlias"], \.type), value: .integer(), originalValue: .string(Shape.ShapeType.StringType())),
        ],
        "IAM": [
            AddPatch(PatchKeyPath3(\.shapes["PolicySourceType"], \.type.enum, \.cases), value: "IAM Policy"),
        ],
        "Lambda": [
            AddDictionaryPatch(PatchKeyPath1(\.shapes), key: "SotoCore.Region", value: Shape(type: .stub, name: "SotoCore.Region")),
            ReplacePatch(PatchKeyPath4(\.shapes["ListFunctionsRequest"], \.type.structure, \.members["MasterRegion"], \.shapeName), value: "SotoCore.Region", originalValue: "MasterRegion"),
        ],
        "Route53": [
            RemovePatch(PatchKeyPath3(\.shapes["ListHealthChecksResponse"], \.type.structure, \.required), value: "Marker"),
            RemovePatch(PatchKeyPath3(\.shapes["ListHostedZonesResponse"], \.type.structure, \.required), value: "Marker"),
            RemovePatch(PatchKeyPath3(\.shapes["ListReusableDelegationSetsResponse"], \.type.structure, \.required), value: "Marker"),
        ],
        "S3": [
            ReplacePatch(PatchKeyPath3(\.shapes["ReplicationStatus"], \.type.enum, \.cases[0]), value: "COMPLETED", originalValue: "COMPLETE"),
            ReplacePatch(PatchKeyPath2(\.shapes["Size"], \.type), value: .long(), originalValue: .integer()),
            ReplacePatch(PatchKeyPath3(\.shapes["CopySource"], \.type.string, \.pattern), value: ".+\\/.+", originalValue: "\\/.+\\/.+"),
            // Add additional location constraints
            ReplacePatch(PatchKeyPath3(\.shapes["BucketLocationConstraint"], \.type.enum, \.isExtensible), value: true, originalValue: false),
            AddPatch(PatchKeyPath3(\.shapes["BucketLocationConstraint"], \.type.enum, \.cases), value: "us-east-1"),
        ],
    ]

    struct ReplacePatch<Value: Equatable, P: PatchKeyPath>: Patch where P.Base == API, P.Value == Value {
        let patchKeyPath: P
        let value: Value
        let expectedValue: Value

        init(_ patchKeyPath: P, value: Value, originalValue: Value) {
            self.patchKeyPath = patchKeyPath
            self.value = value
            self.expectedValue = originalValue
        }

        func apply(to api: inout API) throws {
            guard let originalValue = api[patchKeyPath: patchKeyPath] else { throw APIPatchError.doesNotExist }
            guard originalValue == self.expectedValue else {
                throw APIPatchError.unexpectedValue(expected: "\(self.expectedValue)", got: "\(originalValue)")
            }
            api[patchKeyPath: self.patchKeyPath] = self.value
        }
    }

    struct RemovePatch<Remove: Equatable, P: PatchKeyPath>: Patch where P.Base == API, P.Value == [Remove] {
        let patchKeyPath: P
        let value: Remove

        init(_ patchKeyPath: P, value: Remove) {
            self.patchKeyPath = patchKeyPath
            self.value = value
        }

        func apply(to api: inout API) throws {
            guard let array = api[patchKeyPath: patchKeyPath] else { throw APIPatchError.doesNotExist }
            guard let index = array.firstIndex(of: value) else { throw APIPatchError.doesNotExist }
            api[patchKeyPath: self.patchKeyPath]?.remove(at: index)
        }
    }

    struct AddPatch<Remove: Equatable, P: PatchKeyPath>: Patch where P.Base == API, P.Value == [Remove] {
        let patchKeyPath: P
        let value: Remove

        init(_ patchKeyPath: P, value: Remove) {
            self.patchKeyPath = patchKeyPath
            self.value = value
        }

        func apply(to api: inout API) throws {
            guard let _ = api[patchKeyPath: patchKeyPath] else { throw APIPatchError.doesNotExist }
            api[patchKeyPath: self.patchKeyPath]?.append(self.value)
        }
    }

    struct AddDictionaryPatch<Remove: Equatable, P: PatchKeyPath>: Patch where P.Base == API, P.Value == [String: Remove] {
        let patchKeyPath: P
        let key: String
        let value: Remove

        init(_ patchKeyPath: P, key: String, value: Remove) {
            self.patchKeyPath = patchKeyPath
            self.key = key
            self.value = value
        }

        func apply(to api: inout API) throws {
            guard let _ = api[patchKeyPath: patchKeyPath] else { throw APIPatchError.doesNotExist }
            api[patchKeyPath: self.patchKeyPath]?[self.key] = self.value
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
        case .stub:
            return false
        }
        return false
    }
}
