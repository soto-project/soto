# AWS SDK Swift

AWS SDK for the Swift programming language working on Linux, macOS and iOS.

[<img src="http://img.shields.io/badge/swift-5.0-brightgreen.svg" alt="Swift 5.0" />](https://swift.org)
[<img src="https://travis-ci.org/swift-aws/aws-sdk-swift.svg?branch=master">](https://travis-ci.org/swift-aws/aws-sdk-swift)


## Compatibility

AWSSDKSwift works on both Linux, macOS and iOS. Version 4 is dependent on swift-nio 2, this means certain libraries/frameworks that are dependent on an earlier version of swift-nio will not work with version 4 of AWSSDKSwift. Version 3 can be used if you need to use an earlier version of swift-nio. For instance Vapor 3 uses swift-nio 1.13 so you can only use versions 3.x of AWSSDKSwift with Vapor 3. Below is a compatibility table for versions 3 and 4 of AWSSDKSwift.

| Version | Swift | MacOS | iOS    | Linux              | Vapor  |
|---------|-------|-------|--------|--------------------|--------|
| 3.x     | 4.2 - | ✓     |        | Ubuntu 14.04-18.04 | 3.0    |
| 4.x     | 5.0 - | ✓     | 12.0 - | Ubuntu 14.04-18.04 | 4.0    |

## Documentation

Visit the `aws-sdk-swift` [documentation](https://swift-aws.github.io/aws-sdk-swift/index.html) for instructions and browsing api references.

## Installation

### Swift Package Manager

AWSSDKSwift uses the Swift Package Manager to manager its code dependencies. To use AWSSDKSwift in your codebase it is recommended you do the same. Add a dependency to the package in your own Package.swift dependencies.
```swift
    dependencies: [
        .package(url: "https://github.com/swift-aws/aws-sdk-swift.git", from: "4.0.0")
    ],
```
Then add target dependencies for each of the AWSSDKSwift targets you want to use.
```swift
    targets: [
      .target(name: "MyAWSApp", dependencies: ["S3", "SES", "CloudFront", "ELBV2", "IAM", "Kinesis"]),
    ]
)
```
Alternatively if you are using Xcode 11+ you can use the Swift Package integration and add a dependency to AWSSDKSwift through that. 

## Contributing

All developers should feel welcome and encouraged to contribute to `aws-sdk-swift`.

As contributors and maintainers of this project, and in the interest of fostering an open and welcoming community, we pledge to respect all people who contribute through reporting issues, posting feature requests, updating documentation, submitting pull requests or patches, and other activities.

To contribute a feature or idea to `aws-sdk-swift`, submit an issue and fill in the template. If the request is approved, you or one of the members of the community can start working on it.

If you find a bug, please submit a pull request with a failing test case displaying the bug or create an issue.

If you find a security vulnerability, please contact <yuki@miketokyo.com> and reach out on the [**#aws** channel on the Vapor Discord](https://discordapp.com/channels/431917998102675485/472522745067077632) as soon as possible. We take these matters seriously.

## Configuring Credentials

Before using the SDK, you will need AWS credentials to sign all your requests. Credentials can be accessed in the following ways.

### Via EC2 Instance Profile

If you are running your code on an AWS EC2 instance, you [can setup an IAM role as the server's Instance Profile](https://docs.aws.amazon.com/codedeploy/latest/userguide/getting-started-create-iam-instance-profile.html) to automatically grant credentials via the metadata service.

There are no code changes or configurations to specify in the code, it will automatically pull and use them.

### Via ECS Container credentials

If you are running your code as an AWS ECS container task, you [can setup an IAM role for your container task](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html#create_task_iam_policy_and_role) to automatically grant credentials via the metadata service.

There are no code changes or configurations to specify in the code, it will automatically pull and use them.

### Load Credentials from shared credential file.

You can [set shared credentials in the home directory for the user running the app](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/create-shared-credentials-file.html)

in ~/.aws/credentials,

```
[default]
aws_access_key_id = YOUR_AWS_ACCESS_KEY_ID
aws_secret_access_key = YOUR_AWS_SECRET_ACCESS_KEY
```

### Load Credentials from Environment Variable

Alternatively, you can set the following environment variables:

```
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

Some services like CognitoIdentityProvider don't require credentials to access some of their functions. Explicitly set `accessKeyId` and `secretAccessKey` to "". This will disable all other credential access functions and send requests unsigned.

## Using `aws-sdk-swift`

AWS Swift Modules can be imported into any swift project. Each module provides a struct that can be initialized, with instance methods to call aws services. See documentation for details on specific services.

The underlying aws-sdk-swift httpclient returns a [swift-nio EventLoopFuture object](https://apple.github.io/swift-nio/docs/current/NIO/Classes/EventLoopFuture.html). An EventLoopFuture _is not_ the response, but rather a container object that will be populated with the response sometime later. In this manner calls to AWS do not block the main thread.

The recommended manner to interact with futures is chaining. The following function returns an EventLoopFuture that creates an S3 bucket, puts a file in the bucket, then reads the file back from the bucket and finally prints the contents of the file. Each of these operations are chained together. The output of one being the input of the next. 

```swift
import S3 //ensure this module is specified as a dependency in your package.swift

let bucket = "my-bucket"

let s3 = S3(accessKeyId: "Your-Access-Key", secretAccessKey: "Your-Secret-Key", region: .uswest2)

func createBucketPutGetObject() -> EventLoopFuture<S3.GetObjectOutput> {
    // Create Bucket, Put an Object, Get the Object
    let createBucketRequest = S3.CreateBucketRequest(bucket: bucket)

    s3.createBucket(createBucketRequest)
        .flatMap { response -> Future<S3.PutObjectOutput> in
            // Upload text file to the s3
            let bodyData = "hello world".data(using: .utf8)!
            let putObjectRequest = S3.PutObjectRequest(acl: .publicRead, body: bodyData, bucket: bucket, contentLength: Int64(bodyData.count), key: "hello.txt")
            return s3.putObject(putObjectRequest)
        }
        .flatMap { response -> Future<S3.GetObjectOutput> in
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

## upgrading from <3.0.x

The simplest way to upgrade from an existing 1.0 or 2.0 implementation is to call `.wait()` on existing synchronous calls. However it is recommend to rewrite your synchronous code to work with the returned future objects. It is no longer necessary to use a DispatchQueue.

## EventLoopGroup management

The AWS SDK has its own `EventLoopGroup` but it is recommended that you provide your own `EventLoopGroup` for the SDK to work off. You can do this when you construct your client.
```
let s3 = S3(region:.uswest2, eventLoopGroupProvider: .shared(myEventLoopGroup)
```
The EventLoopGroup types you can use depend on the platform you are running on. On Linux use `MultiThreadedEventLoopGroup`, on macOS use `MultiThreadedEventLoopGroup` or `NIOTSEventLoopGroup` and iOS use `NIOTSEventLoopGroup`. Using the `NIOTSEventLoopGroup` will mean you use [NIO Transport Services](https://github.com/apple/swift-nio-transport-services) and the Apple Network framework.

## Using `aws-sdk-swift` with Vapor

Integration with Vapor is pretty straight forward. Although be sure you use the correct version of AWSSDKSwift depending on which version of Vapor you are using. See the compatibility section for details. Below is a simple Vapor 3 example.

```swift
import Vapor
import HTTP
import SES

final class MyController {
    struct EmailData: Content {
        let address: String
        let subject: String
        let message: String
    }
    func sendUserEmailFromJSON(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.content.decode(EmailData.self)
            .flatMap { (emailData)->EventLoopFuture<SES.SendEmailResponse> in
                let client = SES(region: .uswest1)

                let destination = SES.Destination(toAddresses: [emailData.address])
                let message = SES.Message(body:SES.Body(text:SES.Content(data:emailData.message)), subject:SES.Content(data:emailData.subject))
                let sendEmailRequest = SES.SendEmailRequest(destination: destination, message: message, source:"awssdkswift@me.com")

                return client.sendEmail(sendEmailRequest)
            }
            .hopTo(eventLoop: req.eventLoop)
            .map { response -> HTTPResponseStatus in
                return HTTPStatus.ok
        }
    }
}
```
<!--
## Using the `aws-sdk-swift` with the swift REPL (OS X)


```swift

$ swift -I .build/debug
1> import Foundation
2> import S3

let bucket = "my-bucket"

let s3 = S3(accessKeyId: "Your-Access-Key", secretAccessKey: "Your-Secret-Key", region: .uswest1)

// Create Bucket, Put an Object, Get the Object
let createBucketRequest = S3.CreateBucketRequest(bucket: bucket)

s3.createBucket(createBucketRequest).whenSuccess { response in
    print(response)
}

```
-->
## Speed Up Compilation

By specifying only those modules necessary for your application, only those modules will compile which makes for fast compilation.

If you want to create a module for your service, you can try using the module-exporter to build a separate repo for any of the modules.

## License
`aws-sdk-swift` is released under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0). See LICENSE for details.
