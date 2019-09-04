// swift-tools-version:4.2

import PackageDescription

let package = Package(
  name: "{{name}}",
  products: [
      .library(name: "{{name}}", targets: ["{{name}}"]),
  ],
  dependencies: [
      .package(url: "https://github.com/swift-aws/aws-sdk-swift-core.git", .upToNextMinor(from: "3.1.0"))
  ],
  targets: [
      .target(name: "{{name}}", dependencies: ["AWSSDKSwiftCore"]),
  ]
)
