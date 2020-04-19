#!/usr/bin/env swift sh

import Files            // JohnSundell/Files
import Stencil          // swift-aws/Stencil

class GenerateProcess {
    let environment: Environment
    let fsLoader: FileSystemLoader

    init() {
        self.fsLoader = FileSystemLoader(paths: ["./scripts/templates/create-jazzy-yaml"])
        self.environment = Environment(loader: fsLoader)
    }

    func run() throws {
        let currentFolder = try Folder(path: ".")
        let sourceKittenFolder = try Folder(path: "./sourcekitten")
        var files = sourceKittenFolder.files.map { $0.nameExcludingExtension }
        files.removeAll {
            $0 == "AWSSDKSwiftCore"
        }
        let context = [
            "services": files
        ]
        let package = try environment.renderTemplate(name: ".jazzy.yaml", context: context)
        let packageFile = try currentFolder.createFile(named: ".jazzy.yaml")
        try packageFile.write(package)
    }
}

try GenerateProcess().run()
