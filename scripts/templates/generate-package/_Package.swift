// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "aws-sdk-swift",
    platforms: [.iOS(.v12), .tvOS(.v12), .watchOS(.v5)],
    products: [
{%for target in targets %}
        .library(name: "AWS{{target.name}}", targets: ["AWS{{target.name}}"]){%if not forloop.last %},{%endif +%}
{%endfor %}
    ],
    dependencies: [
        .package(url: "https://github.com/swift-aws/aws-sdk-swift-core.git", .branch("master"))
    ],
    targets: [
{%for target in targets %}
{%if target.hasExtension %}
        .target(name: "AWS{{target.name}}", dependencies: ["AWSSDKSwiftCore"], path: "./Sources/AWSSDKSwift/", sources: ["Services/{{target.name}}", "Extensions/{{target.name}}"]){%if not forloop.last %},{%endif +%}
{%else %}
        .target(name: "AWS{{target.name}}", dependencies: ["AWSSDKSwiftCore"], path: "./Sources/AWSSDKSwift/Services/{{target.name}}"),
{%endif %}
{%endfor %}

        .testTarget(name: "AWSSDKSwiftTests", dependencies: [
{%for target in testTargets %}
            "AWS{{target}}"{%if not forloop.last %},{%endif +%}
{%endfor %}
        ])
    ]
)
