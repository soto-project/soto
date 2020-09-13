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

import ArgumentParser // apple/swift-argument-parser ~> 0.0.1
import Files // JohnSundell/Files
import Stencil // soto-project/Stencil

class GenerateProcess {
    let parameters: GenerateProjects
    let environment: Environment
    let fsLoader: FileSystemLoader

    var targetFolder: Folder!
    var servicesFolder: Folder!
    var extensionsFolder: Folder!
    var zlibSourceFolder: Folder!

    init(_ parameters: GenerateProjects) {
        self.parameters = parameters
        self.fsLoader = FileSystemLoader(paths: ["./scripts/templates/create-modules"])
        self.environment = Environment(loader: self.fsLoader)
    }

    func createProject(_ serviceName: String) throws {
        let serviceSourceFolder = try servicesFolder.subfolder(at: serviceName)
        let extensionSourceFolder = try? self.extensionsFolder.subfolder(at: serviceName)
        let includeZlib = (serviceName == "S3")

        // create folders
        let serviceTargetFolder = try targetFolder.createSubfolder(at: serviceName)
        let workflowsTargetFolder = try serviceTargetFolder.createSubfolder(at: ".github/workflows")
        let sourceTargetFolder = try serviceTargetFolder.createSubfolder(at: "Sources")
        // delete folder if it already exists
        if let folder = try? sourceTargetFolder.subfolder(at: serviceName) {
            try folder.delete()
        }
        // copy source files across
        try serviceSourceFolder.copy(to: sourceTargetFolder)
        // if there is an extensions folder copy files across to target source folder
        if let extensionSourceFolder = extensionSourceFolder {
            let serviceSourceTargetFolder = try sourceTargetFolder.subfolder(at: serviceName)
            try extensionSourceFolder.files.forEach { try $0.copy(to: serviceSourceTargetFolder) }
        }
        // if zlib is required copy CAWSZlib folder
        if includeZlib {
            try self.zlibSourceFolder.copy(to: sourceTargetFolder)
        }
        // Package.swift
        let context = [
            "name": serviceName,
            "version": parameters.version,
        ]
        let packageTemplate = includeZlib ? "Package_with_Zlib.stencil" : "Package.stencil"
        let package = try environment.renderTemplate(name: packageTemplate, context: context)
        let packageFile = try serviceTargetFolder.createFile(named: "Package.swift")
        try packageFile.write(package)
        // readme
        let readme = try environment.renderTemplate(name: "README.md", context: context)
        let readmeFile = try serviceTargetFolder.createFile(named: "README.md")
        try readmeFile.write(readme)
        // copy license
        let templatesFolder = try Folder(path: "./scripts/templates/create-modules")
        let licenseFile = try templatesFolder.file(named: "LICENSE")
        try licenseFile.copy(to: serviceTargetFolder)
        // gitIgnore
        let gitIgnore = try templatesFolder.file(named: ".gitignore")
        try gitIgnore.copy(to: serviceTargetFolder)
        // copy ci.yml
        let ciYml = try templatesFolder.file(named: "ci.yml")
        try ciYml.copy(to: workflowsTargetFolder)
    }

    func run() throws {
        self.servicesFolder = try Folder(path: "./Sources/Soto/Services")
        self.extensionsFolder = try Folder(path: "./Sources/Soto/Extensions")
        self.zlibSourceFolder = try Folder(path: "./Sources/CAWSZlib")
        self.targetFolder = try Folder(path: ".").createSubfolder(at: self.parameters.targetPath)

        // try Folder(path: "targetFolder").
        try self.parameters.services.forEach { service in
            try createProject(service)
        }
    }
}

struct GenerateProjects: ParsableCommand {
    @Argument(help: "The folder to create projects inside.")
    var targetPath: String

    @Option(name: .shortAndLong, help: "SotoCore version to use.")
    var version: String

    let services = [
        /*        "APIGateway",
         "CloudFront",
         "CloudWatch",
         "DynamoDB",
         "EC2",
         "ECR",
         "ECS",
         "IAM",
         "Kinesis",
         "Lambda",*/
        "S3",
        "SES",
    ]

    func run() throws {
        try GenerateProcess(self).run()
    }
}

GenerateProjects.main()
