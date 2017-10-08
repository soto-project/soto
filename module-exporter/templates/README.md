# {{repositoryName}}

An AWS {{repositoryName}} type safe client for Swift (This is part of [aws-sdk-swift](https://github.com/noppoMan/aws-sdk-swift))

## Documentation

Visit the aws-sdk-swift [documentation](http://htmlpreview.github.io/?https://github.com/noppoMan/aws-sdk-swift-doc/blob/master/docs/index.html) for instructions and browsing api references.

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
