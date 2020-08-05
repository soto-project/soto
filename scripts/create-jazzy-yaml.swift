#!/usr/bin/env swift sh
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

import Files // JohnSundell/Files
import Stencil // swift-aws/Stencil

class GenerateProcess {
    let environment: Environment
    let fsLoader: FileSystemLoader

    init() {
        self.fsLoader = FileSystemLoader(paths: ["./scripts/templates/create-jazzy-yaml"])
        self.environment = Environment(loader: self.fsLoader)
    }

    func run() throws {
        let currentFolder = try Folder(path: ".")
        let sourceKittenFolder = try Folder(path: "./sourcekitten")
        var files = sourceKittenFolder.files.map { $0.nameExcludingExtension }
        files.removeAll {
            $0 == "AWSSDKSwiftCore"
        }
        let context = [
            "services": files,
        ]
        let package = try environment.renderTemplate(name: ".jazzy.yaml", context: context)
        let packageFile = try currentFolder.createFile(named: ".jazzy.yaml")
        try packageFile.write(package)
    }
}

try GenerateProcess().run()
