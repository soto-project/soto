// swift-tools-version:5.1
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

import PackageDescription

let package = Package(
    name: "CodeGenerator",
    products: [
        .executable(name: "aws-sdk-swift-codegenerator", targets: ["CodeGenerator"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "0.0.1")),
        .package(url: "https://github.com/swift-aws/Stencil.git", .upToNextMajor(from: "0.13.2"))
    ],
    targets: [
        .target(name: "CodeGenerator", dependencies: ["ArgumentParser", "Stencil"])
    ]
)
