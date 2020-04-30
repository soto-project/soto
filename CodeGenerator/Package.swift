// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "CodeGenerator",
    products: [
        .executable(name: "aws-sdk-swift-codegenerator", targets: ["CodeGenerator"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "0.0.1")),
        .package(url: "https://github.com/swift-aws/Stencil.git", .upToNextMajor(from: "0.13.2"))
    ],
    targets: [
        .target(name: "CodeGenerator", dependencies: ["ArgumentParser", "Stencil"])
    ]
)
