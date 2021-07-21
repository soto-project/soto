// swift-tools-version:5.1
//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2021 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import PackageDescription

let package = Package(
    name: "CodeGenerator",
    products: [
        .executable(name: "soto-codegenerator", targets: ["CodeGenerator"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.3.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-mustache.git", from: "0.5.2"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat.git", .upToNextMinor(from: "0.47.4")),
    ],
    targets: [
        .target(name: "CodeGenerator", dependencies: ["ArgumentParser", "HummingbirdMustache", "SwiftFormat"]),
    ]
)
