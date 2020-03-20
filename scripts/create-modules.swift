#!/usr/bin/swift sh

import ArgumentParser   // apple/swift-argument-parser ~> 0.0.1
import Files            // JohnSundell/Files
import Stencil          // swift-aws/Stencil

class GenerateProcess {
    let parameters: GenerateProjects
    let environment: Environment
    let fsLoader: FileSystemLoader

    var targetFolder: Folder!
    var servicesFolder: Folder!
    var extensionsFolder: Folder!

    init(_ parameters: GenerateProjects) {
        self.parameters = parameters
        self.fsLoader = FileSystemLoader(paths: ["./scripts/templates/create-modules"])
        self.environment = Environment(loader: fsLoader)
    }

    func createProject(_ serviceName: String) throws {
        let serviceSourceFolder = try servicesFolder.subfolder(at: serviceName)

        // create folders
        let serviceTargetFolder = try targetFolder.createSubfolder(at: serviceName)
        let sourceTargetFolder = try serviceTargetFolder.createSubfolder(at: "Sources")
        // delete folder if it already exists
        if let folder = try? sourceTargetFolder.subfolder(at: serviceName) {
            try folder.delete()
        }
        // copy source files across
        try serviceSourceFolder.copy(to: sourceTargetFolder)
        // Package.swift
        let context = [
            "name": serviceName,
            "version": parameters.version
        ]
        let package = try environment.renderTemplate(name: "Package.swift", context: context)
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
    }

    func run() throws {
        servicesFolder = try Folder(path: "./Sources/AWSSDKSwift/Services")
        extensionsFolder = try Folder(path: "./Sources/AWSSDKSwift/Services")
        targetFolder = try Folder(path: ".").createSubfolder(at: parameters.targetPath)

        //try Folder(path: "targetFolder").
        try parameters.services.forEach { service in
            try createProject(service)
        }
    }
}

struct GenerateProjects: ParsableCommand {
    @Argument(help: "The folder to create projects inside.")
    var targetPath: String

    @Option(name: .shortAndLong, help: "AWSSDKSwiftCore version to use.")
    var version: String

    let services = [
        "APIGateway",
        "CloudFront",
        "CloudWatch",
        "DynamoDB",
        "EC2",
        "ECR",
        "ECS",
        "IAM",
        "Kinesis",
        "Lambda",
        "S3",
        "SES"
    ]

    func run() throws {
        try GenerateProcess(self).run()
    }
}

GenerateProjects.main()
