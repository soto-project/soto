// swift-tools-version:5.1
//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2020 the Soto project authors
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
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/soto-project/Stencil.git", .upToNextMajor(from: "0.13.2")),
        .package(url: "https://github.com/nicklockwood/SwiftFormat.git", .upToNextMinor(from: "0.46.0")),
    ],
    targets: [
        .target(name: "CodeGenerator", dependencies: ["ArgumentParser", "Stencil", "SwiftFormat"]),
    ]
)
