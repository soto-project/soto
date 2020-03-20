// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "AWS{{name}}",
  products: [
      .library(name: "AWS{{name}}", targets: ["AWS{{name}}"]),
  ],
  dependencies: [
      .package(url: "https://github.com/swift-aws/aws-sdk-swift-core.git", .upToNextMinor(from: "{{version}}"))
  ],
  targets: [
    .target(name: "AWS{{name}}", dependencies: ["AWSSDKSwiftCore", "AWS{{middleware}}"], path: "./Sources/{{name}}"),
    .target(name: "AWS{{middleware}}", dependencies: ["AWSSDKSwiftCore"], path: "./Sources/{{middleware}}"),
  ]
)
