# AWSClient

Before you start using AWS SDK Swift you need to create an `AWSClient`. This is the object that manages your communication with AWS. It manages credential acqusition, takes your request, encodes it, signs it, sends it to AWS and then decodes the response for you. In most situations your application should only require one `AWSClient` . Create this at startup and use it throughout.

The init for `AWSClient` is as follows.
```
public init(
    credentialProvider credentialProviderFactory: CredentialProviderFactory = .default,
    retryPolicy retryPolicyFactory: RetryPolicyFactory = .default,
    middlewares: [AWSServiceMiddleware] = [],
    httpClientProvider: HTTPClientProvider,
    logger clientLogger: Logger = AWSClient.loggingDisabled
)
```

### Credential Provider

The `credentialProvider` defines how the client acquires its AWS credentials. Its default is to try four different methods: environment variables, ECS container credentials, EC2 instance metadata and the shared credential file `~/.aws/credential`. Another method is to provide credentials in code. You can do this as follows
```
let client = AWSClient(
    credentialProvider: .static(
        accessKeyId: "MY_AWS_ACCESS_KEY_ID",
        secretAccessKey: "MY_AWS_SECRET_ACCESS_KEY"
    )
)
```
You can find out more about `CredentialProviders` [here](credentials.md).

### Retry policy

The `retryPolicy` defines how the client reacts to a failed request. There are three retry policies supplied. `.noRetry` doesn't retry the request if it fails. The other two will retry if the response is a 5xx (server error) or a connection error. They differ is how long they wait before performing the retry. `.exponential` doubles the wait time after each retry and `.jitter` is the same as exponential except it adds a random element to the wait time. `.jitter` is the recommended method from AWS so it is the default.

### Middleware

Middleware allows you to insert your own code just as a request has been constructed or a response has been received. You can use this to edit the request/response or just to view it. AWS SDK Swift Core supplies one middleware `AWSLoggingMiddleware` which outputs  to the console your request once constructed and the response received from AWS.

### HTTP client provider

The `HTTPClientProvider` defines where you get your HTTP client from. Either you supply `.createNew` which indicates the `AWSClient` should create its own HTTP client. In which case it will create an instance of `HTTPClient` from the swift server project [`AsyncHTTPClient`](https://github.com/swift-server/async-http.client). Or you can supply your own HTTP client with `.shared` as long as it conforms to the protocol `AWSHTTPClient`.

Reasons you might want to provide your own client include
- You have one HTTP client you want to use across all your systems.
- You want to provide a client that is using a global `EventLoopGroup`.
- You want to change the configuration for the HTTP client used, perhaps you are running behind a proxy or want to enable decompression.
- You want to provide your own custom built HTTP client.

### Logger

The final function parameter is the `Logger`. This `Logger` is used for logging background processes the client might perform like AWS credential acquisition.

# AWS service objects
