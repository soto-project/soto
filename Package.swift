import PackageDescription

let package = Package(
    name: "AWSSDKSwift",
    targets: [
        Target(name: "CodeGenerator"),
        Target(name: "AWSSDKSwift")
    ],
    dependencies: [
        .Package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.1.0"),
        .Package(url: "https://github.com/noppoMan/aws-sdk-swift-core.git", majorVersion: 0, minor: 2),
    ]
)
