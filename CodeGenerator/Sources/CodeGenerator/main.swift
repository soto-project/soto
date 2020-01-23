import Foundation
import SwiftyJSON
import Dispatch
import Stencil
import PathKit

extension String {
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

