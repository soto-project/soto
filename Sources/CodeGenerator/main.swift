import Foundation
import SwiftyJSON
import Dispatch
import Core


let apis = try loadAPIJSONList()
let docs = try loadDocJSONList()

let group = DispatchGroup()

for index in 0..<apis.count {
    let api = apis[index]
    let doc = docs[index]
    let serviceName = api["metadata"]["endpointPrefix"].stringValue.toSwiftClassCase()
    
    group.enter()
    DispatchQueue.global().async {
        do {
            log("Generating \(serviceName) codes ........")
            
            let service = try AWSService(fromAPIJSON: api, docJSON: doc)
            let basePath = "\(rootPath())/Sources/AWSSDKSwift/Services/\(service.endpointPrefix)/"
            _ = mkdirp(basePath)
            
            try service.generateServiceCode()
                .write(
                    toFile: "\(basePath)/\(service.serviceName)_API.swift",
                    atomically: true,
                    encoding: .utf8
                )
            
            try service.generateShapesCode()
                .write(
                    toFile: "\(basePath)/\(service.serviceName)_Shapes.swift",
                    atomically: true,
                    encoding: .utf8
                )
            
            try service.generateResponseBuilderCode()
                .write(
                    toFile: "\(basePath)/\(service.serviceName)_Response_Builder.swift",
                    atomically: true,
                    encoding: .utf8
            )
            
            try service.generateErrorCode()
                .write(
                    toFile: "\(basePath)/\(service.serviceName)_Error.swift",
                    atomically: true,
                    encoding: .utf8
                )
            
            log("Succesfully Generated \(serviceName) codes!")
            group.leave()
        } catch {
            DispatchQueue.main.sync {
                print(error)
                exit(1)
            }
        }
    }
    //break
}

group.wait()

print("Done.")
