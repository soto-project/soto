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
    var middlewaresFolder: Folder!

    init(_ parameters: GenerateProjects) {
        self.parameters = parameters
        self.fsLoader = FileSystemLoader(paths: ["./scripts/templates/create-modules"])
        self.environment = Environment(loader: fsLoader)
    }

    func createProject(_ serviceName: String) throws {
        let serviceSourceFolder = try servicesFolder.subfolder(at: serviceName)
        let middlewaresSourceFolder = try? middlewaresFolder.subfolder(at: serviceName)

        // create folders
        let serviceTargetFolder = try targetFolder.createSubfolder(at: serviceName.lowercased())
        let workflowsTargetFolder = try serviceTargetFolder.createSubfolder(at: ".github/workflows")
        let sourceTargetFolder = try serviceTargetFolder.createSubfolder(at: "Sources")
        // delete folder if it already exists
        if let folder = try? sourceTargetFolder.subfolder(at: serviceName) {
            try folder.delete()
        }
        // copy source files across
        try serviceSourceFolder.copy(to: sourceTargetFolder)

        // Package.swift
        var context = [
            "name": serviceName,
            "version": parameters.version
        ]

        // if there is an extensions folder copy files across to target source folder
        if let middlewaresSourceFolder = middlewaresSourceFolder {
            let middlewareTargetFolder = try sourceTargetFolder.createSubfolder(at: "\(serviceName)Middleware")
            try middlewaresSourceFolder.files.forEach { try $0.copy(to: middlewareTargetFolder)}
            context["middleware"] = "\(serviceName)Middleware"
        }
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
        // copy gitignore
        let gitIgnore = try templatesFolder.file(named: ".gitignore")
        try gitIgnore.copy(to: serviceTargetFolder)
        // copy ci.yml
        let ciYml = try templatesFolder.file(named: "ci.yml")
        try ciYml.copy(to: workflowsTargetFolder)
    }

    func run() throws {
        servicesFolder = try Folder(path: "./Sources/AWSSDKSwift/Services")
        middlewaresFolder = try Folder(path: "./Sources/AWSSDKSwift/Middlewares")
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
