#!/usr/bin/env swift sh

import Files            // JohnSundell/Files
import Stencil          // swift-aws/Stencil

struct GeneratePackage {
    let environment: Environment
    let fsLoader: FileSystemLoader

    struct Target {
        let name: String
        let hasExtension: Bool
    }
    
    init() {
        self.fsLoader = FileSystemLoader(paths: ["./scripts/templates/generate-package"])
        self.environment = Environment(loader: fsLoader)
    }

    func run() throws {
        let servicesFolder = try Folder(path: "./Sources/AWSSDKSwift/Services")
        let extensionsFolder = try Folder(path: "./Sources/AWSSDKSwift/Extensions")
        let testFolder = try Folder(path: "./Tests/AWSSDKSwiftTests/Services")
        let currentFolder = try Folder(path: ".")
        
        let extensionSubfolders = extensionsFolder.subfolders
        // construct list of services along with a flag to say if they have an extension
        let srcFolders = servicesFolder.subfolders.map { (folder) -> Target in
            let hasExtension = extensionSubfolders.first { $0.name == folder.name } != nil
            return Target(name: folder.name, hasExtension: hasExtension)
        }
        
        // construct list of tests, plus the ones used in AWSRequestTests.swift
        var testFolders = Set<String>(testFolder.subfolders.map { $0.name })
        ["ACM", "CloudFront", "EC2", "IAM", "Route53", "S3", "SES", "SNS"].forEach { testFolders.insert($0)}
        
        let context: [String: Any] = [
            "targets": srcFolders,
            "testTargets": testFolders.map{ $0 }.sorted()
        ]
        let package = try environment.renderTemplate(name: "_Package.swift", context: context)
        let packageFile = try currentFolder.createFile(named: "Package.swift")
        try packageFile.write(package)
    }
}

try GeneratePackage().run()
