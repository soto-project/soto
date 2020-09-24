# S3 Multipart Upload

S3 has a series of multipart upload operations. These can be used to upload an object to S3 in multiple parts. If your object is larger than 5GB you are required to use the multipart operations for uploading, but multipart also has the advantage that if one part fails to upload you don't need to re-upload the whole object, just the parts that failed. Finally you can upload multiple parts at the same time and thus improve your upload speed. The multiple part uploading isn't support by Soto at the moment, but it is on the list of improvements to make. You can read  Amazon's documentation on multipart upload [here](https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html).

Multipart upload has three stages. First you initiate the upload with an `S3.CreateMultipartUpload())`. Next, you upload each part using `S3.UploadPart()` and then you complete the upload by calling `S3.CompleteMultipartUpload()`. If there is an error and you don't want to finish the upload you need to call `S3.AbortMultipartUpload()`. The code to implement this can get quite complex so Soto provides you with a function that implements all of this for you.

```swift
let request = S3.CreateMultipartUploadRequest(bucket: "MyBucket", key: "MyFile.txt")
let responseFuture = s3.multipartUpload(
    request,
    partSize: 5*1024*1024,
    filename: "/Users/home/myfile.txt"
    abortOnFail: true,
    on: eventLoop,
    threadPoolProvider: .createNew
) { progress in
    print(progress)
}
```

The function parameters for multipartUpload are as follows
- `request` is the request object you would create to call `S3.CreateMultipartUpload`.
- `partSize` is the size of each part you upload. The minimum size for a part is 5MB.
- `filename` is the full path to the file you want to upload.
- `abortOnFail` is a flag indicating whether you want `S3.AbortMultipartUpload` to be called when a part upload fails. If you set this flag to false the abort function will not be called and the error `S3ErrorType.multipart.abortedUpload(resumeRequest:error:)` will be thrown. This holds an `S3.ResumeMultipartUploadRequest` object which can be used in the function `S3.resumeMultipartUpload` to resume the multipart upload. In this situation if you do not call the resume function you should call `S3.AbortMultipartUpload` with the uploadId contained in the `S3.ResumeMultipartUploadRequest` to delete the parts you have already uploaded.
- `on` indicates the `EventLoop` the upload should run on.
- `threadPoolProvider`: The file loading requires a `ThreadPool` to run. You can either provide your own, or have the function create its own, which it will destroy once the function is complete.
- `progress` is a closure that gets called after every part is loaded. It is called with a value between 0 and 1 indicating how far we are through the multipart upload. You can also use the `progress` closure as a way to cancel the upload, by throwing an error.

### Resuming an upload

As mentioned above if you call `s3.multipartUpload(_:filename:abortOnFail:)` with `abortOnFail` set to false, you can resume the upload if it fails. You can use the function `resumeMultipartUpload(_:filename:)` in the following manner. While not implemented here you can also set the `abortOnFail` to false again, and resume the upload again if the first `resumeMultipartUpload(_:filename:)` fails.   

```swift
let request = S3.CreateMultipartUploadRequest(bucket: name, key: name)
let responseFuture = s3.multipartUpload(request, filename: filename, abortOnFail: false)
    .flatMapError { error -> EventLoopFuture<S3.CompleteMultipartUploadOutput> in
        switch error {
        case S3ErrorType.multipart.abortedUpload(let resumeRequest, let error):
            return s3.resumeMultipartUpload(resumeRequest, filename: filename) { print("Progress \($0 * 100)") }
        default:
            return s3.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
```  
