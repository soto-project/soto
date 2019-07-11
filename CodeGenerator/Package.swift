// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "CodeGenerator",
    products: [
        .executable(name: "aws-sdk-swift-codegen", targets: ["CodeGenerator"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-aws/aws-sdk-swift-core.git", .branch("master")),
        .package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", .upToNextMajor(from: "17.0.2")),
        .package(url: "https://github.com/stencilproject/Stencil.git", .upToNextMajor(from: "0.13.0"))
    ],
    targets: [
        .target(name: "CodeGenerator", dependencies: ["AWSSDKSwiftCore", "SwiftyJSON", "Stencil"])
    ]
)
