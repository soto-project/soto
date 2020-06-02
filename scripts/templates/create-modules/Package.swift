// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "{{name}}",
    platforms: [.iOS(.v12), .tvOS(.v12), .watchOS(.v5)],
    products: [
        .library(name: "{{name}}", targets: ["{{name}}"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-aws/aws-sdk-swift-core.git", .upToNextMinor(from: "{{version}}"))
    ],
    targets: [
        .target(name: "{{name}}", dependencies: ["AWSSDKSwiftCore"{%if middleware %}, "{{middleware}}"{%endif %}], path: "./Sources/{{name}}"),
{%if middleware %}
        .target(name: "{{middleware}}", dependencies: ["AWSSDKSwiftCore"], path: "./Sources/{{middleware}}"),
{%endif %}
    ]
)
