import Foundation
import SwiftyJSON
import Dispatch
import Stencil
import PathKit

let startTime = Date()
let models = try loadModelJSON()
/*let apis = try loadAPIJSONList()
let paginators = try loadPaginatorJSONList()
let docs = try loadDocJSONList()*/
let endpoint = try loadEndpointJSON()

let group = DispatchGroup()

var errorShapeMap: [String: String] = [:]

let fsLoader = FileSystemLoader(paths: [Path("\(rootPath())/CodeGenerator/Templates/")])
let environment = Environment(loader: fsLoader)

for model in models {

    group.enter()

    DispatchQueue.global().async {
        do {
            let service = try AWSService(fromAPIJSON: model.api, paginatorJSON: model.paginator, docJSON: model.doc, endpointJSON: endpoint)

            let basePath = "\(rootPath())/Sources/AWSSDKSwift/Services/\(service.serviceName)/"
            _ = mkdirp(basePath)

            let apiContext = service.generateServiceContext()
            try environment.renderTemplate(name: "api.stencil", context: apiContext).write(
                    toFile: "\(basePath)/\(service.serviceName)_API.swift",
                    atomically: true,
                    encoding: .utf8
                )

            let shapesContext = service.generateShapesContext()
            try environment.renderTemplate(name: "shapes.stencil", context: shapesContext).write(
                toFile: "\(basePath)/\(service.serviceName)_Shapes.swift",
                atomically: true,
                encoding: .utf8
            )

            let errorContext = service.generateErrorContext()
            if errorContext["errors"] != nil {
                try environment.renderTemplate(name: "error.stencil", context: errorContext).write(
                    toFile: "\(basePath)/\(service.serviceName)_Error.swift",
                    atomically: true,
                    encoding: .utf8
                )
            }

            let paginatorContext = service.generatePaginatorContext()
            if paginatorContext["paginators"] != nil {
                try environment.renderTemplate(name: "paginator.stencil", context: paginatorContext).write(
                    toFile: "\(basePath)/\(service.serviceName)_Paginator.swift",
                    atomically: true,
                    encoding: .utf8
                )
            }

            let customTemplates = service.getCustomTemplates()
            for template in customTemplates {
                let templateName = URL(fileURLWithPath: template).deletingPathExtension().lastPathComponent
                try environment.renderTemplate(name: template).write(
                    toFile: "\(basePath)/\(service.serviceName)+\(templateName).swift",
                    atomically: true,
                    encoding: .utf8
                )
            }
            print("Succesfully Generated \(service.serviceName)")
            group.leave()
        } catch {
            print(error)
            exit(1)
        }
    }
}

group.wait()
print("Code Generation took \(Int(-startTime.timeIntervalSinceNow)) seconds")
print("Done.")
