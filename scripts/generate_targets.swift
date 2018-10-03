#!/usr/bin/env swift

import Foundation

enum GenerationError: Error {
    case directoryLocation(String)
}

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
	throw GenerationError.directoryLocation("Problem locating services")
}

guard let middlewares = findDirectoryNames(at: middlewaresBasePath) else {
	throw GenerationError.directoryLocation("Problem locating middlewares")
}

let modules = services + middlewares.map { "\($0)Middleware" }

let sdkDependencies = modules.map { "\"\($0)\"," }.sorted().joined(separator: "")
print("Dependencies for .library(AWSSDKSwift):")
print("([\(sdkDependencies)]),")

let libraries =  services.map( { ".library(name: \"\($0)\", targets: [\"\($0)\"]),\n" }).sorted().joined(separator: "")
print("Full list of libraries:")
print(libraries)


//TODO(Yasumoto): Need to auto-add S3RequestMiddleware to S3 module dependency
let servicesTargetDefinitions = services.map { "        .target(name: \"\($0)\", dependencies: [\"AWSSDKSwiftCore\"], path: \"\(servicesBasePath)/\($0)\")," }
_ = servicesTargetDefinitions.sorted().map { print($0) }

let middlewaresTargetDefinitions = middlewares.map { "        .target(name: \"\($0)Middleware\", dependencies: [\"AWSSDKSwiftCore\"], path: \"\(middlewaresBasePath)/\($0)\")," }
_ = middlewaresTargetDefinitions.sorted().map { print($0) }
