#!/usr/bin/env swift sh
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

import Files // JohnSundell/Files
import Stencil // soto-project/Stencil

struct GeneratePackage {
    let environment: Environment
    let fsLoader: FileSystemLoader

    struct Target {
        let name: String
        let hasExtension: Bool
        let dependencies: [String]
    }

    init() {
        self.fsLoader = FileSystemLoader(paths: ["./scripts/templates/generate-package"])
        self.environment = Environment(loader: self.fsLoader)
    }

    func run() throws {
        let servicesFolder = try Folder(path: "./Sources/Soto/Services")
        let extensionsFolder = try Folder(path: "./Sources/Soto/Extensions")
        let testFolder = try Folder(path: "./Tests/SotoTests/Services")
        let currentFolder = try Folder(path: ".")

        let extensionSubfolders = extensionsFolder.subfolders
        // construct list of services along with a flag to say if they have an extension
        let srcFolders = servicesFolder.subfolders.map { (folder) -> Target in
            let hasExtension = extensionSubfolders.first { $0.name == folder.name } != nil
            let dependencies: [String]
            if folder.name == "S3" {
                dependencies = [#".product(name: "SotoCore", package: "soto-core")"#, #".byName(name: "CSotoZlib")"#]
            } else {
                dependencies = [#".product(name: "SotoCore", package: "soto-core")"#]
            }
            return Target(name: folder.name, hasExtension: hasExtension, dependencies: dependencies)
        }
        // construct list of tests, plus the ones used in AWSRequestTests.swift
        var testFolders = Set<String>(testFolder.subfolders.map { $0.name })
        ["ACM", "CloudFront", "EC2", "IAM", "Route53", "S3", "S3Control", "SES", "SNS"].forEach { testFolders.insert($0) }

        let context: [String: Any] = [
            "targets": srcFolders,
            "testTargets": testFolders.map { $0 }.sorted(),
        ]
        let package = try environment.renderTemplate(name: "Package.stencil", context: context)
        let packageFile = try currentFolder.createFile(named: "Package.swift")
        try packageFile.write(package)
    }
}

try GeneratePackage().run()
