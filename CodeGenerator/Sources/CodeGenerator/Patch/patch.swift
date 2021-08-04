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

extension API {
    static let servicePatches: [String: [Patch<API>]] = [
        "Amplify": [
            RemovePatch(PatchKeyPath3(\Self.shapes["App"], \.type.structure, \.required), value: "description"),
            RemovePatch(PatchKeyPath3(\Self.shapes["App"], \.type.structure, \.required), value: "environmentVariables"),
            RemovePatch(PatchKeyPath3(\Self.shapes["App"], \.type.structure, \.required), value: "repository"),
        ],
        "CloudFront": [
            ReplacePatch(PatchKeyPath3(\Self.shapes["HttpVersion"], \.type.enum, \.cases[0]), value: "HTTP1_1", originalValue: "http1.1"),
            ReplacePatch(PatchKeyPath3(\Self.shapes["HttpVersion"], \.type.enum, \.cases[1]), value: "HTTP2", originalValue: "http2"),
        ],
        "CloudWatch": [
            // Patch error shape to avoid warning in generated code. Both errors have the same code "ResourceNotFound"
            ReplacePatch(PatchKeyPath2(\Self.operations["GetDashboard"], \.errors[1].shapeName), value: "ResourceNotFoundException", originalValue: "DashboardNotFoundError"),
            ReplacePatch(PatchKeyPath2(\Self.operations["DeleteDashboards"], \.errors[1].shapeName), value: "ResourceNotFoundException", originalValue: "DashboardNotFoundError"),
        ],
        "CloudFormation": [
            // this fixes the waiters
            AddPatch(PatchKeyPath3(\Self.shapes["StackStatus"], \.type.enum, \.cases), value: "UPDATE_FAILED"),
        ],
        "ComprehendMedical": [
            AddPatch(PatchKeyPath3(\Self.shapes["EntitySubType"], \.type.enum, \.cases), value: "DX_NAME"),
        ],
        "CognitoIdentityProvider": [
            AddPatch(PatchKeyPath3(\Self.shapes["UserStatusType"], \.type.enum, \.cases), value: "EXTERNAL_PROVIDER"),
        ],
        "DynamoDB": [
            ReplacePatch(PatchKeyPath3(\Self.shapes["AttributeValue"], \.type.structure, \.isEnum), value: true, originalValue: false),
            ReplacePatch(PatchKeyPath3(\Self.shapes["TransactWriteItem"], \.type.structure, \.isEnum), value: true, originalValue: false),
        ],
        "EC2": [
            ReplacePatch(PatchKeyPath3(\Self.shapes["PlatformValues"], \.type.enum, \.cases[0]), value: "windows", originalValue: "Windows"),
            ReplacePatch(PatchKeyPath3(\Self.shapes["InstanceType"], \.type.enum, \.isExtensible), value: true, originalValue: false),
            ReplacePatch(PatchKeyPath3(\Self.shapes["ArchitectureType"], \.type.enum, \.isExtensible), value: true, originalValue: false),
            // this fixes the waiter 'ConversionTaskDeleted'
            AddPatch(PatchKeyPath3(\Self.shapes["ConversionTaskState"], \.type.enum, \.cases), value: "deleted"),
        ],
        "ECS": [
            AddPatch(PatchKeyPath3(\Self.shapes["PropagateTags"], \.type.enum, \.cases), value: "NONE"),
        ],
        "ElasticLoadBalancing": [
            ReplacePatch(PatchKeyPath2(\Self.shapes["SecurityGroupOwnerAlias"], \.type), value: .integer(), originalValue: .string(Shape.ShapeType.StringType())),
        ],
        "IAM": [
            AddPatch(PatchKeyPath3(\Self.shapes["PolicySourceType"], \.type.enum, \.cases), value: "IAM Policy"),
        ],
        "Lambda": [
            AddDictionaryPatch(PatchKeyPath1(\Self.shapes), key: "SotoCore.Region", value: Shape(type: .stub, name: "SotoCore.Region")),
            ReplacePatch(PatchKeyPath4(\Self.shapes["ListFunctionsRequest"], \.type.structure, \.members["MasterRegion"], \.shapeName), value: "SotoCore.Region", originalValue: "MasterRegion"),
        ],
        "RDSDataService": [
            ReplacePatch(PatchKeyPath3(\Self.shapes["Arn"], \.type.string, \.max), value: 2048, originalValue: 100),
        ],
        "Route53": [
            RemovePatch(PatchKeyPath3(\Self.shapes["ListHealthChecksResponse"], \.type.structure, \.required), value: "Marker"),
            RemovePatch(PatchKeyPath3(\Self.shapes["ListHostedZonesResponse"], \.type.structure, \.required), value: "Marker"),
            RemovePatch(PatchKeyPath3(\Self.shapes["ListReusableDelegationSetsResponse"], \.type.structure, \.required), value: "Marker"),
        ],
        "S3": [
            ReplacePatch(PatchKeyPath3(\Self.shapes["ReplicationStatus"], \.type.enum, \.cases[0]), value: "COMPLETED", originalValue: "COMPLETE"),
            ReplacePatch(PatchKeyPath2(\Self.shapes["Size"], \.type), value: .long(), originalValue: .integer()),
            ReplacePatch(PatchKeyPath3(\Self.shapes["CopySource"], \.type.string, \.pattern), value: ".+\\/.+", originalValue: "\\/.+\\/.+"),
            AddPatch(PatchKeyPath3(\Self.shapes["LifecycleRule"], \.type.structure, \.required), value: "Filter"),
            ReplacePatch(PatchKeyPath2(\Self.shapes["ResponseExpires"], \.type), value: .timestamp(.rfc822), originalValue: .timestamp(.unspecified)),
            // Add additional location constraints
            ReplacePatch(PatchKeyPath3(\Self.shapes["BucketLocationConstraint"], \.type.enum, \.isExtensible), value: true, originalValue: false),
            AddPatch(PatchKeyPath3(\Self.shapes["BucketLocationConstraint"], \.type.enum, \.cases), value: "us-east-1"),
        ],
        "S3Control": [
            ReplacePatch(PatchKeyPath3(\Self.shapes["BucketLocationConstraint"], \.type.enum, \.isExtensible), value: true, originalValue: false),
        ],
        "SageMaker": [
            RemovePatch(PatchKeyPath3(\Self.shapes["ListFeatureGroupsResponse"], \.type.structure, \.required), value: "NextToken"),
        ]
    ]

    mutating func patch() throws {
        guard let patches = Self.servicePatches[serviceName] else { return }
        for patch in patches {
            try patch.apply(to: &self)
        }
    }
}

extension Waiters: PatchBase {
    static let waiterPatches: [String: [Patch<Waiters>]] = [
        "AppStream": [
            ReplacePatch(PatchKeyPath2(\Self.waiters["FleetStarted"], \.acceptors[0].matcher), value: .allPath(argument: "Fleets[].State", expected: .string("RUNNING")), originalValue: .allPath(argument: "Fleets[].State", expected: .string("ACTIVE"))),
            ReplacePatch(PatchKeyPath2(\Self.waiters["FleetStarted"], \.acceptors[1].matcher), value: .anyPath(argument: "Fleets[].State", expected: .string("STOPPING")), originalValue: .anyPath(argument: "Fleets[].State", expected: .string("PENDING_DEACTIVATE"))),
            ReplacePatch(PatchKeyPath2(\Self.waiters["FleetStarted"], \.acceptors[2].matcher), value: .anyPath(argument: "Fleets[].State", expected: .string("STOPPED")), originalValue: .anyPath(argument: "Fleets[].State", expected: .string("INACTIVE"))),
            ReplacePatch(PatchKeyPath2(\Self.waiters["FleetStopped"], \.acceptors[0].matcher), value: .allPath(argument: "Fleets[].State", expected: .string("STOPPED")), originalValue: .allPath(argument: "Fleets[].State", expected: .string("INACTIVE"))),
            ReplacePatch(PatchKeyPath2(\Self.waiters["FleetStopped"], \.acceptors[1].matcher), value: .anyPath(argument: "Fleets[].State", expected: .string("STARTING")), originalValue: .anyPath(argument: "Fleets[].State", expected: .string("PENDING_ACTIVATE"))),
            ReplacePatch(PatchKeyPath2(\Self.waiters["FleetStopped"], \.acceptors[2].matcher), value: .anyPath(argument: "Fleets[].State", expected: .string("RUNNING")), originalValue: .anyPath(argument: "Fleets[].State", expected: .string("ACTIVE"))),
        ],
    ]

    mutating func patch(serviceName: String) throws {
        guard let patches = Self.waiterPatches[serviceName] else { return }
        for patch in patches {
            try patch.apply(to: &self)
        }
    }
}
