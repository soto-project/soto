//===----------------------------------------------------------------------===//
//
// This source file is part of the AWSSDKSwift open source project
//
// Copyright (c) 2020 the AWSSDKSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of AWSSDKSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import AWSSDKSwiftCore

//MARK: EC2 Array Coder

// EC2 requires a special case array encoder as it flattens arrays on encode, while still expecting them to have array elements
// on decode. EC2 will use this Coder instead of the one in aws-sdk-swift-core due to scoping rules.

extension EC2 {
    /// Coder for encoding/decoding Arrays. This is extended to support encoding and decoding based on whether `Element` is `Encodable` or `Decodable`.
    public struct ArrayCoder<Properties: ArrayCoderProperties, Element>: CustomCoder {
        public typealias CodableValue = [Element]
    }

    public typealias DefaultArrayCoder<Element> = ArrayCoder<DefaultArrayCoderProperties, Element>

    /// CodingKey used by Encoder property wrappers
    internal struct _EncodingWrapperKey : CodingKey {
        public var stringValue: String
        public var intValue: Int?
        
        public init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }
        
        public init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
        
        public init(stringValue: String, intValue: Int?) {
            self.stringValue = stringValue
            self.intValue = intValue
        }
    }
}

/// extend to support decoding
extension EC2.ArrayCoder: CustomDecoder where Element: Decodable {
    public static func decode(from decoder: Decoder) throws -> CodableValue {
        let topLevelContainer = try decoder.container(keyedBy: EC2._EncodingWrapperKey.self)
        var values: [Element] = []
        let memberKey = EC2._EncodingWrapperKey(stringValue: Properties.member, intValue: nil)
        guard topLevelContainer.contains(memberKey) else { return values }
        
        var container = try topLevelContainer.nestedUnkeyedContainer(forKey: memberKey)
        while !container.isAtEnd {
            values.append(try container.decode(Element.self))
        }
        return values
    }
}

/// extend to support encoding (flatten the array)
extension EC2.ArrayCoder: CustomEncoder where Element: Encodable {
    public static func encode(value: CodableValue, to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

