import PackageDescription

let package = Package(
    name: "AWSSDKSwift",
    targets: [
        Target(name: "Core"),
        Target(name: "CodeGenerator", dependencies: ["Core"]),
        Target(name: "AWSSDKSwift", dependencies: ["Core"])
    ],
    dependencies: [
        .Package(url: "https://github.com/vapor/clibressl.git", majorVersion: 1),
        .Package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", majorVersion: 16),
        .Package(url: "https://github.com/noppoMan/Prorsum.git", majorVersion: 0, minor: 1)
    ]
)
