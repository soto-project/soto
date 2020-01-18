#!/usr/bin/env swift

import Foundation

enum GenerationError: Error {
    case directoryLocation(String)
}

let manager = FileManager.default

let servicesBasePath = "./Sources/AWSSDKSwift/Services"
let middlewaresBasePath = "./Sources/AWSSDKSwift/Middlewares"
let testsBasePath = "./Tests/AWSSDKSwiftTests/Services"

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
guard let tests = findDirectoryNames(at: testsBasePath) else {
    throw GenerationError.directoryLocation("Problem locating tests")
}
var testsSet: Set<String> = Set<String>(tests)
// insert test dependencies need for aws request tests
testsSet.insert("ACM")
testsSet.insert("CloudFront")
testsSet.insert("EC2")
testsSet.insert("IAM")
testsSet.insert("S3")
testsSet.insert("SES")
testsSet.insert("SNS")

// list of modules
let modules = services + middlewares.map { "\($0)Middleware" }
// dependencies for AWSSDKSwift lib
let sdkDependencies = modules.map { "\"AWS\($0)\"" }.sorted().joined(separator: ",")
// list of libraries
let libraries = services.map( { "        .library(name: \"AWS\($0)\", targets: [\"AWS\($0)\"])" }).sorted().joined(separator: ",\n")
// list of targets
let serviceTargets = services.map { (serviceName) -> String in
    if let middleware = middlewares.first(where: { $0 == serviceName }) {
        return "        .target(name: \"AWS\(serviceName)\", dependencies: [\"AWSSDKSwiftCore\", \"AWS\(middleware)Middleware\"], path: \"\(servicesBasePath)/\(serviceName)\")"
    } else {
        return "        .target(name: \"AWS\(serviceName)\", dependencies: [\"AWSSDKSwiftCore\"], path: \"\(servicesBasePath)/\(serviceName)\")"
    }
}.sorted().joined(separator: ",\n")
// list of middleware targets
let middlewareTargets = middlewares.map { "        .target(name: \"AWS\($0)Middleware\", dependencies: [\"AWSSDKSwiftCore\"], path: \"\(middlewaresBasePath)/\($0)\")" }.sorted().joined(separator: ",\n")
// test dependencies
let testDependencies = testsSet.map { "\"AWS\($0)\"" }.sorted().joined(separator: ",")

// Output the Package.swift
print("""
    // swift-tools-version:5.0
    import PackageDescription

    let package = Package(
        name: "AWSSDKSwift",
        platforms: [.iOS(.v12), .tvOS(.v12), .watchOS(.v5)],
        products: [
    """)
print("        .library(name: \"AWSSDKSwift\", targets: [\(sdkDependencies)]),\n")

print(libraries)

print("""
          ],
          dependencies: [
              .package(url: "https://github.com/swift-aws/aws-sdk-swift-core.git", .upToNextMinor(from: "4.1.0"))
          ],
          targets: [
      """)

print("\(serviceTargets),\n")

print("\(middlewareTargets),\n")

print("""
              .testTarget(name: "AWSSDKSwiftTests", dependencies: [\(testDependencies)])
          ]
      )
      """)


