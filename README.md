# Soto for AWS

[![sswg:graduated|104x20](https://img.shields.io/badge/sswg-graduated-blue.svg)](https://www.swift.org/sswg/incubation-process.html#graduation-requirements)
[<img src="http://img.shields.io/badge/swift-5.10_to_6.1-brightgreen.svg" alt="Swift 5.10" />](https://swift.org)
[<img src="https://github.com/soto-project/soto/workflows/CI/badge.svg" />](https://github.com/soto-project/soto/actions?query=workflow%3ACI)

Soto is a Swift language SDK for Amazon Web Services (AWS), working on Linux, macOS and iOS. This library provides access to all AWS services. The service APIs it provides are a direct mapping of the REST APIs Amazon publishes for each of its services. Soto is a community supported project and is in no way affiliated with AWS.

Table of Contents
-----------------

- [Structure](#structure)
- [Swift Package Manager](#swift-package-manager)
- [Configuring Credentials](#configuring-credentials)
- [Using Soto](#using-soto)
- [Documentation](#documentation)
    - [API Reference](#api-reference)
    - [User guides](#user-guides)
- [Contributing](#contributing)
- [License](#license)

## Structure

The library consists of three parts
1. [soto-core](https://github.com/soto-project/soto-core) which does all the core request encoding and signing, response decoding and error handling.
2. The service [api files](https://github.com/soto-project/soto/tree/main/Sources/Soto/Services) which define the individual AWS services and their commands with their input and output structures.
3. The [CodeGenerator](https://github.com/soto-project/soto/tree/main/CodeGenerator) which builds the service api files from the [JSON model](https://github.com/soto-project/soto/tree/main/models/apis) files supplied by Amazon.

## Swift Package Manager

Soto uses the Swift Package Manager to manage its code dependencies. To use Soto in your codebase it is recommended you do the same. Add a dependency to the package in your own Package.swift dependencies.
```swift
    dependencies: [
        .package(url: "https://github.com/soto-project/soto.git", from: "7.0.0")
    ],
```
Then add target dependencies for each of the Soto targets you want to use.
```swift
    targets: [
        .target(name: "MyApp", dependencies: [
            .product(name: "SotoS3", package: "soto"),
            .product(name: "SotoSES", package: "soto"),
            .product(name: "SotoIAM", package: "soto")
        ]),
    ]
)
```
Alternatively if you are using Xcode 11 or later you can use the Swift Package Manager integration and add a dependency to Soto through that.

## Configuring Credentials

Before using the SDK, you will need AWS credentials to sign all your requests. Credentials can be provided to the library in the following ways.
- Environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
- ECS container IAM policy
- EC2 IAM instance profile
- Shared credentials file in your home directory
- Static credentials provided at runtime

You can find out more about credential providers [here](https://soto.codes/user-guides/credential-providers.html)

## Using Soto

To use Soto you need to create an `AWSClient` and a service object for the AWS service you want to work with. The `AWSClient` provides all the communication with AWS and the service object provides the configuration and APIs for communicating with a specific AWS service. More can be found out about `AWSClient` [here](https://soto.codes/user-guides/awsclient.html) and the AWS service objects [here](https://soto.codes/user-guides/service-objects.html).

```swift
import SotoS3 //ensure this module is specified as a dependency in your package.swift

let bucket = "my-bucket"

let client = AWSClient(
    credentialProvider: .static(accessKeyId: "Your-Access-Key", secretAccessKey: "Your-Secret-Key"),
    httpClientProvider: .createNew
)
let s3 = S3(client: client, region: .uswest2)

func createBucketPutGetObject() async throws -> S3.GetObjectOutput {
    // Create Bucket, Put an Object, Get the Object
    _ = try await s3.createBucket(bucket: bucket)
    // Upload text file to the s3
    let bodyData = "hello world"
    _ = try await s3.putObject(
        acl: .publicRead,
        body: .string(bodyData),
        bucket: bucket,
        key: "hello.txt"
    )
    // download text file just uploaded to S3
    let response = try await s3.getObject(bucket: bucket, key: "hello.txt")
    // print contents of response
    if let body = response.body?.asString() {
        print(body)
    }
    return response
}
```

## Build Plugin

Soto is a very large package. If you would rather not include it in your package dependencies you can instead use the SotoCodeGenerator Swift Package Manager build plugin to generate the Swift source code for only the services/operations you actually need. Find out more [here](https://github.com/soto-project/soto-codegenerator/blob/main/README.md).

## Documentation

### API Reference

Visit [soto.codes](https://soto.codes) to browse the user guides and api reference. As there is a one-to-one correspondence with AWS REST api calls and the Soto api calls, you can also use the official AWS [documentation](https://docs.aws.amazon.com/) for more detailed information about AWS commands.

### User guides

Additional user guides for specific elements of Soto are available

- [Getting Started](https://soto.codes/getting-started.html)
- [Upgrading to Soto v5](https://soto.codes/2020/12/upgrading-to-v5.html)
- [AWSClient](https://soto.codes/user-guides/awsclient.html)
- [AWS Service Objects](https://soto.codes/user-guides/service-objects.html)
- [Credential Providers](https://soto.codes/user-guides/credential-providers.html)
- [Error Handling](https://soto.codes/user-guides/error-handling.html)
- [Streaming Payloads](https://soto.codes/user-guides/streaming-payloads.html)
- [DynamoDB and Codable](https://soto.codes/user-guides/dynamodb-and-codable.html)
- [S3 Multipart Upload](https://soto.codes/user-guides/s3-multipart-upload.html)
- [Using Soto on AWS Lambda](https://soto.codes/user-guides/using-soto-on-aws-lambda.html)
- [Using Soto with Vapor 4](https://soto.codes/user-guides/using-soto-with-vapor.html)

## Contributing

We welcome and encourage contributions from all developers. Please read [CONTRIBUTING.md](CONTRIBUTING.md) for our contributing guidelines.

## License
Soto is released under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0). See LICENSE for details.

## Backers
Support development of Soto by becoming a [backer](https://github.com/sponsors/adam-fowler)

<a href="https://github.com/brokenhandsio">
    <img src="https://avatars1.githubusercontent.com/u/23179490?s=120" width="60px">
</a>
<a href="https://github.com/bitwit">
    <img src="https://avatars1.githubusercontent.com/u/707507?s=120" width="60px">
</a>
<a href="https://github.com/slashmo">
    <img src="https://avatars1.githubusercontent.com/u/16192401?s=120" width="60px">
</a>
<a href="https://github.com/idelfonsog2">
    <img src="https://avatars1.githubusercontent.com/u/7195235?s=120" width="60px">
</a>
<a href="https://github.com/rausnitz">
    <img src="https://avatars1.githubusercontent.com/u/6132143?s=120" width="60px">
</a>
<a href="https://github.com/florentmorin">
    <img src="https://avatars1.githubusercontent.com/u/1071783?s=120" width="60px">
</a>
