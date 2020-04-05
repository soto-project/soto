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

import Foundation

public enum ShapeEncoding {
    case `default`
    case flatList
    case list(member: String)
    case flatMap(key: String, value: String)
    case map(entry: String, key: String, value: String)
    case blob
}

public struct Member {

    public struct Options : OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue =  rawValue
        }
        
        static let streaming    = Options(rawValue: 1 << 0)
        static let idempotencyToken  = Options(rawValue: 1 << 1)
    }
    
    public let name: String
    public let required: Bool
    public let shape: Shape
    public let location: Location?
    public let shapeEncoding: ShapeEncoding?
    public let options: Options
    
    public init(name: String, required: Bool, shape: Shape, location: Location?, shapeEncoding: ShapeEncoding?, options: Options){
        self.name = name
        self.required = required
        self.shape = shape
        self.location = location
        self.shapeEncoding = shapeEncoding
        self.options = options
    }
}
