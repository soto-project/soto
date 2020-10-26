# Error Handling

Soto provides a variety of Error types. All errors that are formatted as expected are returned by Soto conform to the `AWSErrorType` protocol. This protocol provides an `errorCode` and an `AWSErrorContext` struct that contains additional information ie a message if it was provided, the http response status code and the http response headers. 

SotoCore provides three error types conforming to `AWSErrorType`: 
- `AWSClientError` and `AWSServerError`: Thrown when one of a standard set of client errors occur. AWS provide documentation on these [here](https://docs.aws.amazon.com/sns/latest/api/CommonErrors.html). The client errors generate `AWSClientError` and the server errors generate a `AWSServerError`.
- `AWSResponseError`: Thrown when the error code returned is unrecognised.

Code for responding to these errors could be as follows
```swift
do {
    try ...
} catch let error as AWSClientError where error == .accessDenied {
    print(error.messsage)
} catch let error as AWSServerError where error == .internalFailure {
    print(error.messsage)
}
```
If you want to respond to a number of errors from one type you could do the following
```swift
do {
    try ...
} catch let error as AWSClientError where error == .accessDenied {
    switch error {
    case .accessDenied:
        ...
    case .optInRequired:
        ...
    case .missingAction:
        ...
    default:
        ...
    }
}
```
If AWS returns an error without an error code then an `AWSRawError` is thrown. This contains the body of the HTTP response along with the `AWSErrorContext` object.

## Services

Each service has its own error type with errors specific to that service. They are named the service name with the suffix `ErrorType`. For instance when downloading a file from S3 you might want to deal with a number of errors specific to S3 in the following manner.
```swift
let request = S3.PutObjectRequest(
    body: myData, 
    bucket: "my-bucket", 
    key: "my-key"
)
do {
    try s3.putObject(request).wait()
} catch let error as S3ErrorType where error == .noSuchBucket {
    print("The bucket doesn't exist")
} catch let error as S3ErrorType where error == .noSuchKey {
    print("The file doesn't exist")
}
```

## Inconsistencies

The AWS services are not consistent in how they respond to the same action. For instanceIf if you try to connect to a service with an invalid AWS access key, DynamoDB will return a `AWSResponseError` with error code set to "UnrecognizedClient", SNS will return a `AWSClientError.invalidClientTokenId` and S3 will return a `AWSResponseError` with error code set to "InvalidAccessKey".
