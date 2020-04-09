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

import Foundation
import SwiftyJSON
import Dispatch
import Stencil
import PathKit

extension String {
    /// Only writes to file if the string contents are different to the file contents. This is used to stop XCode rebuilding and reindexing files unnecessarily.
    /// If the file is written to XCode assumes it has changed even when it hasn't
    /// - Parameters:
    ///   - toFile: Filename
    ///   - atomically: make file write atomic
    ///   - encoding: string encoding
    func writeIfChanged(toFile: String, atomically: Bool, encoding: String.Encoding) throws -> Bool {
        do {
            let original = try String(contentsOfFile: toFile)
            guard original != self else { return false }
        } catch {
            print(error)
        }
        try write(toFile: toFile, atomically: atomically, encoding: encoding)
        return true
    }
}

class CodeGenerator {
    let fsLoader: FileSystemLoader
    let environment: Environment
    
    init() {
        self.fsLoader = FileSystemLoader(paths: [Path("\(rootPath())/CodeGenerator/Templates/")])
        self.environment = Environment(loader: fsLoader)
    }
    
    /// Generate service files from AWSService
    /// - Parameter service: service generated from JSON
    func generateFiles(from service: AWSService) throws {

        let basePath = "\(rootPath())/Sources/AWSSDKSwift/Services/\(service.serviceName)/"
        _ = mkdirp(basePath)

        let apiContext = service.generateServiceContext()
        if try environment.renderTemplate(name: "api.stencil", context: apiContext).writeIfChanged(
                toFile: "\(basePath)/\(service.serviceName)_API.swift",
                atomically: true,
                encoding: .utf8
            ) {
            print("Wrote: \(service.serviceName)_API.swift")
        }

        let shapesContext = service.generateShapesContext()
        if try environment.renderTemplate(name: "shapes.stencil", context: shapesContext).writeIfChanged(
            toFile: "\(basePath)/\(service.serviceName)_Shapes.swift",
            atomically: true,
            encoding: .utf8
            ) {
            print("Wrote: \(service.serviceName)_Shapes.swift")
        }

        let errorContext = service.generateErrorContext()
        if errorContext["errors"] != nil {
            if try environment.renderTemplate(name: "error.stencil", context: errorContext).writeIfChanged(
                toFile: "\(basePath)/\(service.serviceName)_Error.swift",
                atomically: true,
                encoding: .utf8
                ) {
                print("Wrote: \(service.serviceName)_Error.swift")
            }
        }

        let paginatorContext = service.generatePaginatorContext()
        if paginatorContext["paginators"] != nil {
            if try environment.renderTemplate(name: "paginator.stencil", context: paginatorContext).writeIfChanged(
                toFile: "\(basePath)/\(service.serviceName)_Paginator.swift",
                atomically: true,
                encoding: .utf8
                ) {
                   print("Wrote: \(service.serviceName)_Paginator.swift")
            }
        }

        let customTemplates = service.getCustomTemplates()
        for template in customTemplates {
            let templateName = URL(fileURLWithPath: template).deletingPathExtension().lastPathComponent
            if try environment.renderTemplate(name: template).writeIfChanged(
                toFile: "\(basePath)/\(service.serviceName)+\(templateName).swift",
                atomically: true,
                encoding: .utf8
                ) {
                print("Wrote: \(service.serviceName)+\(templateName).swift")
            }
        }
        print("Succesfully Generated \(service.serviceName)")
    }
    
    /// Run the code generator, load JSON and generate service files
    func run() throws {
        // load JSON
        let models = try loadModelJSON()
        let endpoint = try loadEndpointJSON()

        let group = DispatchGroup()

        models.forEach { model in
            group.enter()
            
            DispatchQueue.global().async {
                defer { group.leave() }
                do {
                    let service = try AWSService(fromAPIJSON: model.api, paginatorJSON: model.paginator, docJSON: model.doc, endpointJSON: endpoint)
                    try self.generateFiles(from: service)
                } catch {
                    print(error)
                    exit(1)
                }
            }
        }

        group.wait()
    }
    
    /// Generate service files from AWSService
    /// - Parameter codeGenerator: service generated from JSON
    func generateFiles(with codeGenerator: CodeGeneratorV2) throws {

        let basePath = "\(rootPath())/Sources/AWSSDKSwift/Services/\(codeGenerator.api.serviceName)/"
        _ = mkdirp(basePath)

        let apiContext = codeGenerator.generateServiceContext()
        if try environment.renderTemplate(name: "api.stencil", context: apiContext).writeIfChanged(
            toFile: "\(basePath)/\(codeGenerator.api.serviceName)_API.swift",
                atomically: true,
                encoding: .utf8
            ) {
            print("Wrote: \(codeGenerator.api.serviceName)_API.swift")
        }

        /*let shapesContext = service.generateShapesContext()
        if try environment.renderTemplate(name: "shapes.stencil", context: shapesContext).writeIfChanged(
            toFile: "\(basePath)/\(service.serviceName)_Shapes.swift",
            atomically: true,
            encoding: .utf8
            ) {
            print("Wrote: \(service.serviceName)_Shapes.swift")
        }*/

        let errorContext = codeGenerator.generateErrorContext()
        if errorContext["errors"] != nil {
            if try environment.renderTemplate(name: "error.stencil", context: errorContext).writeIfChanged(
                toFile: "\(basePath)/\(codeGenerator.api.serviceName)_Error.swift",
                atomically: true,
                encoding: .utf8
                ) {
                print("Wrote: \(codeGenerator.api.serviceName)_Error.swift")
            }
        }

        let paginatorContext = try codeGenerator.generatePaginatorContext()
        if paginatorContext["paginators"] != nil {
            if try environment.renderTemplate(name: "paginator.stencil", context: paginatorContext).writeIfChanged(
                toFile: "\(basePath)/\(codeGenerator.api.serviceName)_Paginator.swift",
                atomically: true,
                encoding: .utf8
                ) {
                print("Wrote: \(codeGenerator.api.serviceName)_Paginator.swift")
            }
        }
        print("Succesfully Generated \(codeGenerator.api.serviceName)")
    }
    
    func run2() throws {
        // load JSON
        let endpoints = try loadEndpointJSONV2()
        let models = try loadModelJSONV2()
        let group = DispatchGroup()

        models.forEach { model in
            group.enter()
            
            DispatchQueue.global().async {
                defer { group.leave() }
                do {
                    let codeGenerator = try CodeGeneratorV2(api: model.api, docs: model.docs, paginators: model.paginators, endpoints: endpoints)
                    try self.generateFiles(with: codeGenerator)
                } catch {
                    print("\(error)")
                    exit(1)
                }
            }
        }
        
        group.wait()
    }
}

let startTime = Date()

try CodeGenerator().run2()

print("Code Generation took \(Int(-startTime.timeIntervalSinceNow)) seconds")
print("Done.")
