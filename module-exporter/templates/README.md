# {{repositoryName}}

An AWS {{repositoryName}} type safe client for Swift (This is part of [aws-sdk-swift](https://github.com/swift-aws/aws-sdk-swift))

## Documentation

Visit the aws-sdk-swift [documentation](http://htmlpreview.github.io/?https://github.com/swift-aws/aws-sdk-swift/gh-pages/index.html) for instructions and browsing api references.

## Installation

### Package.swift

```swift
import PackageDescription

let package = Package(
    name: "MyAWSApp",
    dependencies: [
        .package(url: "https://github.com/swift-aws/{{repositoryName}}.git", .upToNextMajor(from: "{{version.major}}.{{version.minor}}.{{version.patch}}"))
    ]
)
```
