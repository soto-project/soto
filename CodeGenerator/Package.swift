// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "CodeGenerator",
    products: [
        .executable(name: "aws-sdk-swift-codegen", targets: ["CodeGenerator"])
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", .upToNextMajor(from: "17.0.2")),
        .package(url: "https://github.com/adam-fowler/Stencil.git", .upToNextMajor(from: "0.13.4"))
    ],
    targets: [
        .target(name: "CodeGenerator", dependencies: ["SwiftyJSON", "Stencil"])
    ]
)
