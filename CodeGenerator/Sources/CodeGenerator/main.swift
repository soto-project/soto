import Foundation
import SwiftyJSON
import Dispatch
import Stencil
import PathKit

let startTime = Date()
let apis = try loadAPIJSONList()
let docs = try loadDocJSONList()
let endpoint = try loadEndpointJSON()

let group = DispatchGroup()

var errorShapeMap: [String: String] = [:]

let fsLoader = FileSystemLoader(paths: [Path("\(rootPath())/CodeGenerator/Templates/")])
let environment = Environment(loader: fsLoader)

for index in 0..<apis.count {
    let api = apis[index]
    let doc = docs[index]

    group.enter()
    DispatchQueue.global().async {
        do {
            let service = try AWSService(fromAPIJSON: api, docJSON: doc, endpointJSON: endpoint)

            log("Generating \(service.serviceName) code ........")

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
            print("Succesfully Generated \(service.serviceName)")
            group.leave()
        } catch {
            DispatchQueue.main.sync {
                print(error)
                exit(1)
            }
        }
    }
}

group.wait()
print("Code Generation took \(Int(-startTime.timeIntervalSinceNow)) seconds")
print("Done.")
