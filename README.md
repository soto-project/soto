# Soto for AWS

[<img src="http://img.shields.io/badge/swift-5.1-brightgreen.svg" alt="Swift 5.1" />](https://swift.org)
[<img src="https://github.com/soto-project/soto/workflows/CI/badge.svg" />](https://github.com/soto-project/soto/actions?query=workflow%3ACI)

Soto is a Swift language SDK for Amazon Web Services (AWS), working on Linux, macOS and iOS. This library provides access to all AWS services. The service APIs it provides are a direct mapping of the REST APIs Amazon publishes for each of its services. Soto is a community supported project and is in no way affiliated with AWS.

The library consists of three parts
1. [soto-core](https://github.com/soto-project/soto-core) which does all the core request encoding and signing, response decoding and error handling.
2. The service [api files](https://github.com/soto-project/soto/tree/main/Sources/Soto/Services) which define the individual AWS services and their commands with their input and output structures.
3. The [CodeGenerator](https://github.com/soto-project/soto/tree/main/CodeGenerator) which builds the service api files from the [JSON model](https://github.com/soto-project/soto/tree/main/models/apis) files supplied by Amazon.

## Version 5 documentation

If you are looking for documentation for the version 5 beta of Soto. You will find it [here](https://github.com/soto-project/soto/blob/5.x.x-docs/README.md).

## Installation

### Swift Package Manager

Soto uses the Swift Package Manager to manage its code dependencies. To use Soto in your codebase it is recommended you do the same. Add a dependency to the package in your own Package.swift dependencies.
```swift
    dependencies: [
        .package(name: "AWSSDKSwift", url: "https://github.com/soto-project/soto.git", from: "4.0.0")
    ],
```
Then add target dependencies for each of the Soto targets you want to use.
```swift
    targets: [
        .target(name: "MyAWSApp", dependencies: [
            .product(name: "S3", package: "AWSSDKSwift"),
            .product(name: "SES", package: "AWSSDKSwift"),
            .product(name: "IAM", package: "AWSSDKSwift")
        ]),
    ]
)
```
If you are using one of the v5.0.0 pre-releases then the `name` parameter in the package dependencies is unnecessary, the `package` parameter of the target dependencies is `soto` instead of `AWSSDKSwift` and also all the target names are prefixed with `Soto`.

Alternatively if you are using Xcode 11+ you can use the Swift Package integration and add a dependency to Soto through that.

## Compatibility

Soto works on Linux, macOS and iOS. Version 4 is dependent on version 2 of [swift-nio](https://github.com/apple/swift-nio). Libraries/frameworks that are dependent on an earlier version of swift-nio will not work with version 4 of Soto. In this case Version 3 can be used. For example Vapor 3 uses swift-nio 1.13 so you can only use versions 3.x of Soto with Vapor 3. Below is a compatibility table for versions 3 and 4 of Soto.

| Version | Swift | MacOS | iOS    | Linux              | Vapor  |
|---------|-------|-------|--------|--------------------|--------|
| 3.x     | 4.2 - | ✓     |        | Ubuntu 14.04-18.04 | 3.0    |
| 4.x     | 5.0 - | ✓     | 12.0 - | Ubuntu 14.04-18.04 | 4.0    |

## Configuring Credentials

Before using the SDK, you will need AWS credentials to sign all your requests. Credentials can be provided to the library in the following ways.

### Via EC2 Instance Profile

If you are running your code on an AWS EC2 instance, you [can setup an IAM role](https://docs.aws.amazon.com/codedeploy/latest/userguide/getting-started-create-iam-instance-profile.html) as the server's Instance Profile to automatically grant credentials via the metadata service.

There are no code changes or configurations to specify in the code, it will automatically pull and use the credentials.

### Via ECS Container credentials

If you are running your code as an AWS ECS container task, you [can setup an IAM role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html#create_task_iam_policy_and_role) for your container task to automatically grant credentials via the metadata service.

Similar to the EC2 setup there are no code changes or configurations to specify in the code, it will automatically pull and use the credentials.

### Load Credentials from shared credential file.

You can [set shared credentials](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/create-shared-credentials-file.html) in the home directory for the user running the app, in the file ~/.aws/credentials,

```ini
[default]
aws_access_key_id = YOUR_AWS_ACCESS_KEY_ID
aws_secret_access_key = YOUR_AWS_SECRET_ACCESS_KEY
```

### Load Credentials from Environment Variable

Alternatively, you can set the following environment variables:

```bash
AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY
```

### Pass the Credentials to the AWS Service struct directly

All of the AWS Services's initializers accept `accessKeyId` and `secretAccessKey`

```swift
let ec2 = EC2(
    accessKeyId: "YOUR_AWS_ACCESS_KEY_ID",
    secretAccessKey: "YOUR_AWS_SECRET_ACCESS_KEY"
)
```
### Without Credentials

Some services like CognitoIdentityProvider don't require credentials to access some of their functionality. In this case explicitly set `accessKeyId` and `secretAccessKey` to "". This will disable all other credential access functions and send requests unsigned.

## Using Soto

Soto modules can be imported into any swift project. Each module provides a service struct that can be initialized with AWS credentials, if required, AWS region, and some configuration options. This struct contains the instance methods that correspond to the AWS service REST apis. See [documentation](#documentation) for details on specific services.

Each Soto command returns a [swift-nio](https://github.com/apple/swift-nio) `EventLoopFuture`. An `EventLoopFuture` _is not_ the response of the command, but rather a container object that will be populated with the response sometime later. In this manner calls to AWS do not block the main thread. It is recommended you familiarise yourself with the swift-nio [documentation](https://apple.github.io/swift-nio/docs/current/NIO/), specifically [EventLoopFuture](https://apple.github.io/swift-nio/docs/current/NIO/Classes/EventLoopFuture.html) if you want to take full advantage of Soto.

The recommended manner to interact with `EventLoopFutures` is chaining. The following function returns an `EventLoopFuture` that creates an S3 bucket, puts a file in the bucket, reads the file back from the bucket and finally prints the contents of the file. Each of these operations are chained together. The output of one being the input of the next.

```swift
import S3 //ensure this module is specified as a dependency in your package.swift

let bucket = "my-bucket"

let s3 = S3(accessKeyId: "Your-Access-Key", secretAccessKey: "Your-Secret-Key", region: .uswest2)

func createBucketPutGetObject() -> EventLoopFuture<S3.GetObjectOutput> {
    // Create Bucket, Put an Object, Get the Object
    let createBucketRequest = S3.CreateBucketRequest(bucket: bucket)

    s3.createBucket(createBucketRequest)
        .flatMap { response -> EventLoopFuture<S3.PutObjectOutput> in
            // Upload text file to the s3
            let bodyData = "hello world".data(using: .utf8)!
            let putObjectRequest = S3.PutObjectRequest(acl: .publicRead, body: bodyData, bucket: bucket, contentLength: Int64(bodyData.count), key: "hello.txt")
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

## HTTP client (v5.x.x)

Soto sets up its own HTTP client for communication with AWS but you are also able to provide your own as long as it conforms to the protocol `AWSHTTPClient`. If you don't provide a client the SDK uses one of two different HTTP clients depending on what platform you are running on. We have [extended](https://github.com/soto-project/soto-core/blob/main/Sources/SotoCore/HTTP/AsyncHTTPClient.swift) the swift server [AsyncHTTPClient](https://github.com/swift-server/async-http-client) so it conforms with `AWSHTTPClient`. This is the default client if you are running on Linux or macOS 10.14 and earlier. `AsyncHTTPClient` is not available on iOS. We have also supplied are own client `NIOTSHTTPClient` which uses [NIO Transport Services](https://github.com/apple/swift-nio-transport-services) and the Apple Network framework. This is the default client if you are running on iOS or macOS 10.15 and later. `NIOTSHTTPClient` is not available on Linux or versions of macOS earlier than 10.15.

You can provide your own HTTP client as follows
```
let s3 = S3(region:.uswest2, httpClientProvider: .shared(myHTTPClient))
```
Reasons you might want to provide your own client.
- You have one HTTP client you want to use across all your systems.
- You want to provide a client that is using a global `EventLoopGroup`.
- On macOS you want to force the usage of the swift server [AsyncHTTPClient](https://github.com/swift-server/async-http-client) regardless of OS version.
- You want to change the configuration for the HTTP client used.
- You want to provide your own custom built HTTP client.

## Using Soto with Vapor

Integration with Vapor is pretty straight forward. Although be sure you use the correct version of Soto. See the [compatibility](#compatibility) section for details. Below is a simple Vapor 4 example that extracts an email address, subject and message from a request and then sends an email using these details. Take note of the `hopTo(eventLoop:)` call. If Soto is not working off the same `EventLoopGroup` as the Vapor `Request` this is a requirement.

```swift
import Vapor
import HTTP
import SES

let client = SES(region: .uswest1)

final class MyController {
    struct EmailData: Content {
        let address: String
        let subject: String
        let message: String
    }
    func sendUserEmailFromJSON(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let emailData = try req.content.decode(EmailData.self)
        let destination = SES.Destination(toAddresses: [emailData.address])
        let message = SES.Message(body:SES.Body(text:SES.Content(data:emailData.message)), subject:SES.Content(data:emailData.subject))
        let sendEmailRequest = SES.SendEmailRequest(destination: destination, message: message, source:"awssdkswift@me.com")

        return client.sendEmail(sendEmailRequest)
            .hopTo(eventLoop: req.eventLoop)
            .transform(to: .ok)
    }
}
```

## Documentation

Visit the Soto [documentation](https://soto-project.github.io/soto/index.html) to browse the api reference. As there is a one-to-one correspondence with AWS REST api calls and the Soto api calls, you can also use the official AWS [documentation](https://docs.aws.amazon.com/) for more detailed information about AWS commands.

## upgrading from <3.0.x

The simplest way to upgrade from an existing 1.0 or 2.0 implementation is to call `.wait()` on existing synchronous calls. However it is recommend to rewrite your synchronous code to work with the returned future objects. It is no longer necessary to use a DispatchQueue.

## License
Soto is released under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0). See LICENSE for details.
