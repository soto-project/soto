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

enum Region: String, Decodable {
    case useast1 = "us-east-1"
    case useast2 = "us-east-2"
    case uswest1 = "us-west-1"
    case uswest2 = "us-west-2"
    case apsouth1 = "ap-south-1"
    case apnortheast2 = "ap-northeast-2"
    case apsoutheast1 = "ap-southeast-1"
    case apsoutheast2 = "ap-southeast-2"
    case apnortheast1 = "ap-northeast-1"
    case apeast1 = "ap-east-1"
    case cacentral1 = "ca-central-1"
    case euwest1 = "eu-west-1"
    case euwest3 = "eu-west-3"
    case euwest2 = "eu-west-2"
    case eucentral1 = "eu-central-1"
    case eunorth1 = "eu-north-1"
    case saeast1 = "sa-east-1"
    case mesouth1 = "me-south-1"
    
    case cnnorth1 = "cn-north-1"
    case cnnorthwest1 = "cn-northwest-1"
    
    case usgoveast1 = "us-gov-east-1"
    case usgovwest1 = "us-gov-west-1"
    case usisoeast1 = "us-iso-east-1"
    case usisobeast1 = "us-isob-east-1"
}

enum SignatureVersion: String, Decodable {
    case v2 = "v2"
    case v4 = "v4"
    case s3 = "s3"
    case s3v4 = "s3v4"
}


struct Endpoints: Decodable {
    struct CredentialScope: Decodable {
        var region: Region?
        var service: String?
    }
    
    struct Defaults: Decodable {
        var credentialScope: CredentialScope?
        var hostname: String?
        var protocols: [String]?
        var signatureVersions: [SignatureVersion]?
    }
    
    struct RegionDesc: Decodable {
        var description: String
    }
    
    struct Service: Decodable {
        struct Endpoint: Decodable {
            var credentialScope: CredentialScope?
            var hostname: String?
            var protocols: [String]?
            var signatureVersions: [SignatureVersion]?
        }
        var endpoints: [String: Endpoint]
        var isRegionalized: Bool?
        var partitionEndpoint: String?
    }

    struct Partition: Decodable {
        var defaults: Defaults
        var dnsSuffix: String
        var partition: String
        var partitionName: String
        var regionRegex: String
        var regions: [String: RegionDesc]
        var services: [String: Service]
    }
    
    var partitions: [Partition]
}
