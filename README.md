# aws-sdk-swift

AWS SDK for the Swift programming language that works on Linux and Mac.

<img src="https://camo.githubusercontent.com/93de6573350b91e48ab570a4fe710e4e8baa38b8/687474703a2f2f696d672e736869656c64732e696f2f62616467652f73776966742d332e302d627269676874677265656e2e737667"> [<img src="https://travis-ci.org/noppoMan/aws-sdk-swift.svg?branch=master">](https://travis-ci.org/noppoMan/aws-sdk-swift)

## Documentation

Visit the aws-sdk-swift [documentation](http://htmlpreview.github.io/?https://github.com/noppoMan/aws-sdk-swift-doc/blob/master/docs/index.html) for instructions and browsing api references.

## Installation

### SPM

Package.swift

```swift
import PackageDescription

let package = Package(
    name: "MyAWSApp",
    dependencies: [
        .Package(url: "https://github.com/noppoMan/aws-sdk-swift.git", majorVersion: 0, minor: 3)
    ]
)
```

### Carthage
Not supported yet

### Cocoapods
Not supported yet

## Contributing

All developers should feel welcome and encouraged to contribute to aws-sdk-swift, see our getting started document here to get involved.

To contribute a feature or idea to aws-sdk-swift, submit an issue and fill in the template. If the request is approved, you or one of the members of the community can start working on it.

If you find a bug, please submit a pull request with a failing test case displaying the bug or create an issue.

If you find a security vulnerability, please contact yuki@miketokyo.com as soon as possible. We take these matters seriously.

## Configuring Credentials

Before using the SDK, ensure that you've configured credentials.

### Load Credentials from shared credential file.

Not supported yet

### Load Credentials from Environment Variable

Alternatively, you can set the following environment variables:

```
AWS_ACCESS_KEY_ID=bar
AWS_SECRET_ACCESS_KEY=foo
```

### Pass the Credentials to the AWS Service struct directly

All of the AWS Services's initializers accept `accessKeyId` and `secretAccessKey`

```swift
let ec2 = EC2(
    accessKeyId: "Your-Access-Key",
    secretAccessKey: "Your-Secret-Key"
)
```

## Using the aws-sdk-swift

```swift
import AWSSDKSwift

do {
    let bucket = "my-bucket"

    let s3 = S3(
        accessKeyId: "Your-Access-Key",
        secretAccessKey: "Your-Secret-Key",
        region: .apnortheast1
    )

    // Create Bucket
    let createBucketRequest = S3.CreateBucketRequest(bucket: bucket)
    _ try s3.createBucket(createBucketRequest)

    // Upload text file to the s3
    let bodyData = "hello world".data(using: .utf8)!
    let putObjectRequest = S3.PutObjectRequest(bucket: bucket, contentLength: Int64(bodyData.count), key: "hello.txt", body: bodyData, aCL: "public-read")
    _ = try s3.putObject(putObjectRequest)

    // Get text file from s3
    let getObjectRequest = S3.GetObjectRequest(bucket: bucket, key: "hello.txt")
    let getObjectOutput = try s3.getObject(getObjectRequest)
    if let body = getObjectOutput.body {
      print(String(data: body, encoding: .utf8))
    }
} catch {
    print(error)
}
```

## How speed up compling?

Compiling the entire aws-sdk-swift requires a certain amount of time (ofc, dependes on machine spec). And I know 97% users don't need to install whole service sdks.

In order to answer such a request, we provide SDK for each service as a separate repository.

https://github.com/swift-aws

From here, it's possible to select and install only the SDKs of the service to be used in your application.

## Lisence
aws-sdk-swift is released under the MIT license. See LICENSE for details.
