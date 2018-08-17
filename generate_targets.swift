#!/usr/bin/env swift

import Foundation

struct GenerationError: Error {}

let manager = FileManager.default

let servicesBasePath = "./Sources/AWSSDKSwift/Services"
let middlewaresBasePath = "./Sources/AWSSDKSwift/Middlewares"

func findDirectoryNames(at path: String) -> [String]? {
    guard let names = try? manager.contentsOfDirectory(atPath: path) else {
	    print("Could not list \(path)")
	    return nil
    }
    return names
}

guard let services = findDirectoryNames(at: servicesBasePath) else {
	throw GenerationError()
}

guard let middlewares = findDirectoryNames(at: middlewaresBasePath) else {
	throw GenerationError()
}

let modules = services + middlewares.map { "\($0)Middleware" }

let sdkDependencies = modules.map { "\"\($0.capitalized)\"," }.sorted().joined(separator: "")
print("\(sdkDependencies)]),")

//TODO(Yasumoto): Need to auto-add S3RequestMiddleware to S3 module dependency
let servicesTargetDefinitions = services.map { "        .target(name: \"\($0.capitalized)\", dependencies: [\"AWSSDKSwiftCore\"], path: \"\(servicesBasePath)/\($0)\")," }
_ = servicesTargetDefinitions.sorted().map { print($0) }

let middlewaresTargetDefinitions = middlewares.map { "        .target(name: \"\($0.capitalized)Middleware\", dependencies: [\"AWSSDKSwiftCore\"], path: \"\(middlewaresBasePath)/\($0)\")," }
_ = middlewaresTargetDefinitions.sorted().map { print($0) }
