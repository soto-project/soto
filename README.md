# Soto for AWS

[<img src="http://img.shields.io/badge/swift-5.1-brightgreen.svg" alt="Swift 5.1" />](https://swift.org)
[<img src="https://github.com/soto-project/soto/workflows/CI/badge.svg" />](https://github.com/soto-project/soto/actions?query=workflow%3ACI)
[![sswg:sandbox|94x20](https://img.shields.io/badge/sswg-sandbox-lightgrey.svg)](https://github.com/swift-server/sswg/blob/master/process/incubation.md#sandbox-level)

Soto is a Swift language SDK for Amazon Web Services (AWS), working on Linux, macOS and iOS. This library provides access to all AWS services. The service APIs it provides are a direct mapping of the REST APIs Amazon publishes for each of its services. Soto is a community supported project and is in no way affiliated with AWS.

Table of Contents
-----------------

- [Structure](#structure)
- [Swift Package Manager](#swift-package-manager)
- [Compatibility](#compatibility)
- [Configuring Credentials](#configuring-credentials)
- [Using AWSSDKSwift](#using-awssdkswift)
    - [Using AWSSDKSwift with Vapor](#using-awssdkswift-with-vapor)
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
        .package(url: "https://github.com/soto-project/soto.git", from: "5.0.0-alpha")
    ],
```
Then add target dependencies for each of the Soto targets you want to use.
```swift
    targets: [
        .target(name: "MyAWSApp", dependencies: [
            .product(name: "AWSS3", package: "soto"),
            .product(name: "AWSSES", package: "soto"),
            .product(name: "AWSIAM", package: "soto")
        ]),
    ]
)
```
Alternatively if you are using Xcode 11 or later you can use the Swift Package Manager integration and add a dependency to Soto through that.

## Compatibility

Soto works on Linux, macOS and iOS. Version 4 and later is dependent on version 2 of [swift-nio](https://github.com/apple/swift-nio). Libraries/frameworks that are dependent on an earlier version of swift-nio will not work with version 4 or later of Soto. In this case Version 3 can be used. For example Vapor 3 uses swift-nio 1.13 so you can only use versions 3.x of Soto with Vapor 3. Below is a compatibility table for versions 3 and 4 of Soto.

| Version | Swift | MacOS | iOS    | Linux              | Vapor  |
|---------|-------|-------|--------|--------------------|--------|
| 3.x     | 4.2 - | ✓     |        | Ubuntu 14.04-18.04 | 3.0    |
| 4.x     | 5.0 - | ✓     | 12.0 - | Ubuntu 14.04-18.04 | 4.0    |
| 5.x     | 5.1 - | ✓     | 12.0 - | Ubuntu 14.04-18.04 | 4.0    |

## Configuring Credentials

Before using the SDK, you will need AWS credentials to sign all your requests. Credentials can be provided to the library in the following ways.
- Environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
- ECS container IAM policy
- EC2 IAM instance profile
- Shared credentials file in your home directory
- Static credentials provided at runtime

You can find out more about credential providers [here](documentation/credentials.md)

## Using Soto

Soto modules can be imported into any swift project. Each module provides a service struct that can be initialized with a `AWSClient`, AWS region, and some configuration options. This struct contains the instance methods that correspond to the AWS service REST apis. See [documentation](#documentation) for details on specific services. More can be found out about `AWSClient` and the service objects [here](documentation/client-and-services.md).

Each Soto command returns a [swift-nio](https://github.com/apple/swift-nio) `EventLoopFuture`. An `EventLoopFuture` _is not_ the response of the command, but rather a container object that will be populated with the response sometime later. In this manner calls to AWS do not block the main thread. It is recommended you familiarise yourself with the swift-nio [documentation](https://apple.github.io/swift-nio/docs/current/NIO/), specifically [EventLoopFuture](https://apple.github.io/swift-nio/docs/current/NIO/Classes/EventLoopFuture.html) if you want to take full advantage of Soto.

The recommended manner to interact with `EventLoopFutures` is chaining. The following function returns an `EventLoopFuture` that creates an S3 bucket, puts a file in the bucket, reads the file back from the bucket and finally prints the contents of the file. Each of these operations are chained together. The output of one being the input of the next.

```swift
import AWSS3 //ensure this module is specified as a dependency in your package.swift

let bucket = "my-bucket"

let client = AWSClient(
    credentialProvider: .static(accessKeyId: "Your-Access-Key", secretAccessKey: "Your-Secret-Key"),
    httpClientProvider: .createNew
)
let s3 = S3(client: client, region: .uswest2)

func createBucketPutGetObject() -> EventLoopFuture<S3.GetObjectOutput> {
    // Create Bucket, Put an Object, Get the Object
    let createBucketRequest = S3.CreateBucketRequest(bucket: bucket)

    s3.createBucket(createBucketRequest)
        .flatMap { response -> EventLoopFuture<S3.PutObjectOutput> in
            // Upload text file to the s3
            let bodyData = "hello world".data(using: .utf8)!
            let putObjectRequest = S3.PutObjectRequest(
                acl: .publicRead,
                body: bodyData,
                bucket: bucket,
                key: "hello.txt"
            )
            return s3.putObject(putObjectRequest)
        }
        .flatMap { response -> EventLoopFuture<S3.GetObjectOutput> in
            let getObjectRequest = S3.GetObjectRequest(bucket: bucket, key: "hello.txt")
            return s3.getObject(getObjectRequest)
        }
        .whenSuccess { response in
            if let body = response.body {
                print(String(data: body, encoding: .utf8)!)
            }
    }
}
```

### Using AWSSDKSwift with Vapor

Integration with Vapor is pretty straight forward. Although be sure you use the correct version of Soto depending on which version of Vapor you are using. See the [compatibility](#compatibility) section for details. Below is a simple Vapor 4 example that extracts an email address, subject and message from a request and then sends an email using these details. Take note of the `on: req.eventLoop` parameter in the `sendEmail` call. If your `AWSClient` is not working off the same `EventLoopGroup` as the Vapor `Request` this is a requirement.

```swift
import Vapor
import HTTP
import SES

let client = AWSClient()
let ses = SES(client: client, region: .uswest1)

final class MyController {
    struct EmailData: Content {
        let address: String
        let subject: String
        let message: String
    }
    func sendUserEmailFromJSON(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let emailData = try req.content.decode(EmailData.self)
        let destination = SES.Destination(toAddresses: [emailData.address])
        let message = SES.Message(body: .init(text:SES.Content(data:emailData.message)), subject: .init(data:emailData.subject))
        let sendEmailRequest = SES.SendEmailRequest(destination: destination, message: message, source:"awssdkswift@me.com")
        return ses.sendEmail(sendEmailRequest, on: req.eventLoop)
            .map { response -> HTTPStatus in
                return .ok
        }
    }
}
```

## Documentation

Visit the Soto [documentation](https://soto-project.github.io/soto/index.html) to browse the api reference. As there is a one-to-one correspondence with AWS REST api calls and the Soto api calls, you can also use the official AWS [documentation](https://docs.aws.amazon.com/) for more detailed information about AWS commands.

### User guides

Additional user guides for specific elements of AWS SDK Swift are available

- [AWSClient and service objects](documentation/client-and-services.md)
- [Credential providers](documentation/credentials.md)
- [Streaming](documentation/streaming.md)
- [S3 multipart](documentation/s3-multipart.md)
- [DynamoDB Codable](documentation/dynamodb-codable.md)

## Contributing

We welcome and encourage contributions from all developers. Please read [CONTRIBUTING.md](CONTRIBUTING.md) for our contributing guidelines.

## License
Soto is released under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0). See LICENSE for details.
