//
//  S3_Extension.swift
//  AWSSDKSwift
//
//  Created by Adam Fowler on 2019/08/01.
//
//
import Foundation
import AWSSDKSwiftCore

public extension S3ErrorType {
    enum extensionErrors : Error {
        case downloadEmpty(message: String)
    }
}

public extension S3 {

    ///  Creates pre-signed URL for retrieving object from Amazon S3.
    ///
    /// - parameters:
    ///     - bucket: The bucket to get the object from
    ///     - key: The key for the object
    ///     - expires: The amount of time before the url expires. Defaults to 1 hour
    /// - returns: A pre-signed url
    func presignedGetObject(bucket: String, key: String, expires: Int = 3600) throws -> URL {
        let signer = try Signers.V4(credential: SharedCredential(), region: .euwest1, service: "s3", endpoint: nil)
        let urlToSign = URL(string: "https://\(bucket).s3.amazonaws.com/\(key)")!
        let presignedURL = signer.signedURL(url: urlToSign,  method: "GET", date: Date(), expires: expires)
        return presignedURL
    }
    
    ///  Creates pre-signed URL for uploading object to Amazon S3.
    ///
    /// - parameters:
    ///     - bucket: The bucket where the object is being put
    ///     - key: The key for the object
    ///     - expires: The amount of time before the url expires. Defaults to 1 hour
    /// - returns: A pre-signed url
    func presignedPutObject(bucket: String, key: String, expires: Int = 3600) throws -> URL {
        let signer = try Signers.V4(credential: SharedCredential(), region: .euwest1, service: "s3", endpoint: nil)
        let urlToSign = URL(string: "https://\(bucket).s3.amazonaws.com/\(key)")!
        let presignedURL = signer.signedURL(url: urlToSign,  method: "PUT", date: Date(), expires: expires)
        return presignedURL
    }
    
    /// Implement multipart download of a file.
    ///
    /// - parameters:
    ///     - input: The GetObjectRequest shape that contains the details of the object request.
    ///     - partSize: Size of each part to be downloaded
    ///     - outputStream: Function to be called for each downloaded part
    /// - returns: A future that will receive the complete file size once the multipart download has finished.
    func multipartDownload(_ input: GetObjectRequest, partSize: Int64=5*1024*1024, outputStream: @escaping (Data) throws -> ()) throws -> Future<Int64> {
        // function downloading part of a file
        func multipartDownloadPart(fileSize: Int64, offset: Int64, body: Data? = nil) throws -> Future<Int64> {
            // output the data uploaded previously
            let outputBody = AWSClient.eventGroup.next().submit { ()->Int64 in
                if let body = body {
                    try outputStream(body)
                }
                return fileSize
            }
            guard fileSize > offset else { return outputBody }
            let range = "bytes=\(offset)-\(offset+Int64(partSize-1))"
            let request = S3.GetObjectRequest(bucket: input.bucket, key: input.key, range: range, sSECustomerAlgorithm: input.sSECustomerAlgorithm, sSECustomerKey: input.sSECustomerKey, sSECustomerKeyMD5: input.sSECustomerKeyMD5, versionId: input.versionId)
            let result = try getObject(request)
                .and(outputBody)
                .then { (output,_) -> Future<Int64> in
                    do {
                        // should never happen
                        guard let body = output.body else {
                            throw S3ErrorType.extensionErrors.downloadEmpty(message: "Body is unexpectedly nil")
                        }
                        guard let length = output.contentLength, length > 0 else {
                            throw S3ErrorType.extensionErrors.downloadEmpty(message: "Content length is unexpectedly zero")
                        }
                        let newOffset = offset + partSize
                        return try multipartDownloadPart(fileSize: fileSize, offset: newOffset, body: body)
                    } catch {
                        return AWSClient.eventGroup.next().newFailedFuture(error: error)
                    }
            }
            return result
        }
        
        // get object size before downloading
        let request = S3.HeadObjectRequest(bucket: input.bucket, ifMatch: input.ifMatch, ifModifiedSince: input.ifModifiedSince, ifNoneMatch: input.ifNoneMatch, ifUnmodifiedSince: input.ifUnmodifiedSince, key: input.key, requestPayer: input.requestPayer, sSECustomerAlgorithm: input.sSECustomerAlgorithm, sSECustomerKey: input.sSECustomerKey, sSECustomerKeyMD5: input.sSECustomerKeyMD5, versionId: input.versionId)
        let result = try headObject(request)
            .then { object -> Future<Int64> in
                do {
                    // download file
                    return try multipartDownloadPart(fileSize: object.contentLength!, offset: 0)
                } catch {
                    return AWSClient.eventGroup.next().newFailedFuture(error: error)
                }
        }
        return result
    }
    
    /// Implement S3 multipart upload.
    ///
    /// - parameters:
    ///     - input: The CreateMultipartUploadRequest structure that contains the details about the upload
    ///     - inputStream: The function supplying the data parts to the multipartUpload. Each parts must be at least 5MB in size expect the last one which has no size limit.
    /// - returns: A Future that will receive a CompleteMultipartUploadOutput once the multipart upload has finished.
    func multipartUpload(_ input: CreateMultipartUploadRequest, inputStream: @escaping () throws -> Data?) throws -> Future<CompleteMultipartUploadOutput> {
        var completedParts: [S3.CompletedPart] = []
        // function uploading part of a file
        func multipartUploadPart(partNumber: Int32, uploadId: String, body: Data? = nil) throws -> Future<[S3.CompletedPart]> {
            // create upload data future, if there is no data to load because this is the first time this is called create a succeeded future
            let uploadResult : Future<[S3.CompletedPart]>
            if let body = body {
                let request = S3.UploadPartRequest(body: body, bucket: input.bucket, contentLength: Int64(body.count), key: input.key, partNumber: partNumber, requestPayer: input.requestPayer, sSECustomerAlgorithm: input.sSECustomerAlgorithm, sSECustomerKey: input.sSECustomerKey, sSECustomerKeyMD5: input.sSECustomerKeyMD5, uploadId: uploadId)
                // request upload future
                uploadResult = try self.uploadPart(request).map { output -> [S3.CompletedPart] in
                    let part = S3.CompletedPart(eTag: output.eTag, partNumber: partNumber)
                    completedParts.append(part)
                    return completedParts
                }
            } else {
                uploadResult = AWSClient.eventGroup.next().newSucceededFuture(result: [])
            }
            
            // load data future
            let result = AWSClient.eventGroup.next().submit { ()->Data? in
                return try inputStream()
                }
                .and(uploadResult)
                // upload data
                .then { (data, parts) -> Future<[S3.CompletedPart]> in
                    guard let data = data else { return AWSClient.eventGroup.next().newSucceededFuture(result: parts)}
                    do {
                        return try multipartUploadPart(partNumber: partNumber+1, uploadId: uploadId, body: data)
                    } catch {
                        return AWSClient.eventGroup.next().newFailedFuture(error: error)
                    }
            }
            return result
        }
        
        // initialize multipart upload
        let result = try createMultipartUpload(input).then { upload -> Future<CompleteMultipartUploadOutput> in
            //guard uploadId = upload.uploadId else { return nil }
            let uploadId = upload.uploadId!
            do {
                return try multipartUploadPart(partNumber: 1, uploadId: uploadId)
                    .then { parts -> Future<CompleteMultipartUploadOutput> in
                        // if success then complete the multipart upload
                        do {
                            let request = S3.CompleteMultipartUploadRequest(bucket: input.bucket, key:input.key, multipartUpload: S3.CompletedMultipartUpload(parts:parts), requestPayer: input.requestPayer, uploadId: uploadId)
                            let result = try self.completeMultipartUpload(request)
                            return result
                        } catch {
                            return AWSClient.eventGroup.next().newFailedFuture(error: error)
                        }
                    }
                    .thenIfErrorThrowing { error in
                        // if failure then abort the multipart upload
                        let request = S3.AbortMultipartUploadRequest(bucket: input.bucket, key: input.key, requestPayer: input.requestPayer, uploadId: uploadId)
                        _ = try self.abortMultipartUpload(request)
                        throw error
                }
            } catch {
                return AWSClient.eventGroup.next().newFailedFuture(error: error)
            }
        }
        return result
    }
}
