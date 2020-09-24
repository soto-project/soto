# Upgrading to Version 5

There are a number of changes to Soto which you will need to take into account when upgrading from version 4 or earlier to version 5. 

## Package.swift

If we first look at the `Package.swift` you will notice 
- Soto now requires Swift 5.3.
- The package name has changed to "soto". 
- All the library names are prefixed with "Soto". 

Because of this your `Package.swift` dependencies will need to be in the following format
```
    dependencies: [
        .package(url: "https://github.com/soto-project/soto.git", from: "5.0.0")
    ],
    targets: [
        .target(name: "MyApp", dependencies: [
            .product(name: "SotoS3", package: "soto"),
            .product(name: "SotoSES", package: "soto"),
            .product(name: "SotoIAM", package: "soto")
        ]),
    ]
```
Also the core package libraries are now prefixed with Soto. If you are importing `AWSSDKSwiftCore` you will need to change it to `import SotoCore`.

## Client/Service split

Previously each service had its own `AWSClient` which it created and managed. In version 5 the `AWSClient` is created separately from the services and can be shared among multiple services. As long as you don't require `AWSClient`'s with different settings it is now recommended you have one `AWSClient` in your application that is used by all the service objects. When you create a service you need to provide the client

```
let awsClient = AWSClient(httpClientProvider: .createNew)
let s3 = S3(client: awsClient, region: .useast1)
let dynamoDB = DynamoDB(client: awsClient, region: .useast1)
```

## HTTP Client provider

In the example above the `AWSClient` included an `httpClientProvider` parameter in its initialization. You can either ask the `AWSClient` to create a new HTTP client, or provide one yourself with `.shared(_)`. When left to create its own client it will create an instance of the swift server [`AsyncHTTPClient`](https://github.com/swift-server/async-http-client). You can also provide your own HTTP client as long as it conforms to the protocol `AWSHTTPClient`.

You can find out more about `AWSClient` and the service objects [here](AWSClient%20and%20Services.md)

## AWSClient shutdown

The `AWSClient` needs shutdown before it is deinitialized. You can do this asynchronously with `AWSClient.shutdown()` or synchronously with `AWSClient.syncShutdown()`. These will shutdown the HTTP client, if required, and ensure the credential providers are not running. 

## Providing static credentials

Previously to supply static AWS credentials for use by the library you would do the following
```
let iam = IAM(accessKeyId: "MYACCESSKEYID", secretAccessKey: "MYSECRETACCESSKEY")
```
Now the credentials are attached to the `AWSClient` and you supply them using a `CredentialProvider` as follows
```
let awsClient = AWSClient(credentialProvider: .static(accessKeyId: "MYACCESSKEYID", secretAccessKey: "MYSECRETACCESSKEY"))
```
If you don't supply credentials, the `AWSClient` will attempt to acquire them through the same methods that were used in v4 and before with one minor exception. The order of methods it uses to acquire credentials has changed slightly. Before it was environment variables, `~/.aws/credential` file, ecs credentials, ec2 metadata. This has now changed to environment variables, ecs credentials, ec2 metadata, `~/.aws/credential` file. `CredentialProvider`'s provide more flexibility in supplying credentials to Soto. Please read the article [here](CredentialProviders.md) for more information on them.

## Additional support

Above are the main changes you will need to make when upgrading to v5. This doesn't detail all the additional support Soto v5 supplies, which includes custom credential providers, request retries, payload streaming, improved S3 multipart upload, DynamoDB `Codable` support and further integration with the swift server eco-system through the use of [async-http-client](https://github.com/swift-server/async-http-client), [swift-crypto](https://github.com/apple/swift-crypto), [swift-log](https://github.com/apple/swift-log) and [swift-metrics](https://github.com/apple/swift-metrics).
