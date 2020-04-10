// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "CodeGenerator",
    products: [
        .executable(name: "aws-sdk-swift-codegen", targets: ["CodeGenerator"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-aws/Stencil.git", .upToNextMajor(from: "0.13.2"))
    ],
    targets: [
        .target(name: "CodeGenerator", dependencies: ["Stencil"])
    ]
)
