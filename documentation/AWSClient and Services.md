# AWSClient

The `AWSClient` is the core of Soto. This is the object that manages your communication with AWS. It manages credential acquisition, takes your request, encodes it, signs it, sends it to AWS and then decodes the response for you. In most situations your application should only require one `AWSClient`. Create this at startup and use it throughout.

The `init` for creating an `AWSClient` looks like the following:

```swift
public init(
    credentialProvider credentialProviderFactory: CredentialProviderFactory = .default,
    retryPolicy retryPolicyFactory: RetryPolicyFactory = .default,
    middlewares: [AWSServiceMiddleware] = [],
    httpClientProvider: HTTPClientProvider,
    logger clientLogger: Logger = AWSClient.loggingDisabled
)
```

Details for each option are below.

#### Credential Provider

The `credentialProvider` defines how the client acquires its AWS credentials. Its default is to try four different methods: 

* environment variables
* ECS container credentials
* EC2 instance metadata 
* the shared credential file `~/.aws/credential` 

An alternative is to provide credentials in code. You can do this as follows

```swift
let client = AWSClient(
    credentialProvider: .static(
        accessKeyId: "MY_AWS_ACCESS_KEY_ID",
        secretAccessKey: "MY_AWS_SECRET_ACCESS_KEY"
    ),
    ...
)
```
You can find out more about `CredentialProviders` [here](CredentialProviders.md).

#### Retry policy

The `retryPolicy` defines how the client reacts to a failed request. There are three retry policies supplied. `.noRetry` doesn't retry the request if it fails. The other two will retry if the response is a 5xx (server error) or a connection error. They differ in how long they wait before performing the retry. `.exponential` doubles the wait time after each retry and `.jitter` is the same as exponential except it adds a random element to the wait time. `.jitter` is the recommended method from AWS so it is the default.

#### Middleware

Middleware allows you to insert your own code just as a request has been constructed or a response has been received. You can use this to edit the request/response or just to view it. Soto Core supplies one middleware — `AWSLoggingMiddleware` — which outputs your request to the console once constructed and the response received from AWS.

#### HTTP Client provider

The `HTTPClientProvider` defines where you get your HTTP client from. You have two options:

* Pass `.createNew` which indicates the `AWSClient` should create its own HTTP client. This creates an instance of `HTTPClient` using [`AsyncHTTPClient`](https://github.com/swift-server/async-http.client).
* Supply your own HTTP client with `.shared(AWSHTTPClient)` as long as it conforms to the protocol `AWSHTTPClient`. `AsyncHTTPClient.HTTPClient` already conforms to this protocol.

There are a number of reasons you might want to provide your own client, such as:

- You have one HTTP client you want to use across all your systems.
- You want to provide a client that is using a global `EventLoopGroup`.
- You want to change the configuration for the HTTP client used, perhaps you are running behind a proxy or want to enable decompression.
- You want to provide your own custom HTTP client.

#### Logger

The final function parameter is the `Logger`. This `Logger` is used for logging background processes the client might perform like AWS credential acquisition.

## AWSClient Shutdown

The AWSClient requires you shut it down manually before it is deinitialized. The manual shutdown is required to ensure any internal processes are finished before the `AWSClient` is freed and Soto's event loops and client are shutdown properly. You can either do this asynchronously with `AWSClient.shutdown()` or do this synchronously with `AWSClient.syncShutdown()`.

# AWS Service Objects

In Soto each AWS Service has a service object. This object brings together an `AWSClient` and a service configuration, `AWSServiceConfig`, and provides methods for accessing all the operations available from that service.

The `init` for each service is as follows. Again details about each parameter are available below.

```swift
public init(
    client: AWSClient,
    region: SotoCore.Region? = nil,
    partition: AWSPartition = .aws,
    endpoint: String? = nil,
    timeout: TimeAmount? = nil,
    byteBufferAllocator: ByteBufferAllocator = ByteBufferAllocator(),
    options: AWSServiceConfig.Options = []
)
```

#### Client

The client is the `AWSClient` this service object will use when communicating with AWS.

#### Region and Partition

The `region` defines which AWS region you want to use for that service. The `partition` defines which set of AWS server regions you want to work with. Partitions include the standard `.aws`, US government `.awsusgov` and China `.awscn`. If you provide a `region`, the `partition` parameter is ignored. If you don't supply a `region` then the `region` will be set as the default region for the specified `partition`, if that is not defined it will check the `AWS_DEFAULT_REGION` environment variable or default to `us-east-1`.

Some services do not have a `region` parameter in their initializer, such as IAM. These services require you to communicate with one global region which is defined by the service. You can still control which partition you connect to though.

#### Endpoint

If you want to communicate with non-AWS servers you can provide an endpoint which replaces the `amazonaws.com` web address. You may want to do this if you are using a AWS mocking service for debugging purposes for example, or you are communicating with a non-AWS service that replicates AWS functionality.

#### Time out

Time out defines how long the HTTP client will wait until it cancels a request. This value defaults to 20 seconds. If you are planning on downloading/uploading large objects you should probably increase this value. `AsyncHTTPClient` allows you to set an additional connection timeout value. If you are extending your general timeout, use an `HTTPClient` configured with a shorter connection timeout to avoid waiting for long periods when a connection fails.

#### ByteBufferAllocator

During request processing the `AWSClient` will most likely be required to allocate space for `ByteBuffer`s. You can define how these are allocated with the `byteBufferAllocator` parameter.

#### Options

A series of flags, that can affect how requests are constructed. The only option available at the moment is `s3ForceVirtualHost`. S3 uses virtual host addressing by default except if you use a custom endpoint. `s3ForceVirtualHost` will force virtual host addressing even when you specify a custom endpoint.
