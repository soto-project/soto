//
//  S3_Extension.swift
//  AWSSDKSwift
//
//  Created by Adam Fowler on 2019/08/01.
//
//
import Foundation
import AWSSDKSwiftCore
import S3

public extension S3ErrorType {
    enum multipart : Error {
        case noUploadId
        case downloadEmpty(message: String)
        case failedToWrite(file: String)
        case failedToRead(file: String)
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
    
    /// Multipart download of a file from S3.
    ///
    /// - parameters:
    ///     - input: The GetObjectRequest shape that contains the details of the object request.
    ///     - partSize: Size of each part to be downloaded
    ///     - outputStream: Function to be called for each downloaded part
    /// - returns: A future that will receive the complete file size once the multipart download has finished.
    func multipartDownload(_ input: GetObjectRequest, partSize: Int = 5*1024*1024, outputStream: @escaping (Data) throws -> ()) throws -> Future<Int64> {
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
                            throw S3ErrorType.multipart.downloadEmpty(message: "Body is unexpectedly nil")
                        }
                        guard let length = output.contentLength, length > 0 else {
                            throw S3ErrorType.multipart.downloadEmpty(message: "Content length is unexpectedly zero")
                        }
                        let newOffset = offset + Int64(partSize)
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
                    guard let contentLength = object.contentLength else {
                        throw S3ErrorType.multipart.downloadEmpty(message: "Content length is unexpectedly zero")
                    }
                    // download file
                    return try multipartDownloadPart(fileSize: contentLength, offset: 0)
                } catch {
                    return AWSClient.eventGroup.next().newFailedFuture(error: error)
                }
        }
        return result
    }
    
    /// Multipart upload of file to S3.
    ///
    /// - parameters:
    ///     - input: The CreateMultipartUploadRequest structure that contains the details about the upload
    ///     - inputStream: The function supplying the data parts to the multipartUpload. Each parts must be at least 5MB in size expect the last one which has no size limit.
    /// - returns: A Future that will receive a CompleteMultipartUploadOutput once the multipart upload has finished.
    func multipartUpload(_ input: CreateMultipartUploadRequest, inputStream: @escaping () throws -> Data?) throws -> Future<CompleteMultipartUploadOutput> {
        var completedParts: [S3.CompletedPart] = []
        
        // function uploading part of a file and queueing up upload of the next part
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
            guard let uploadId = upload.uploadId else { return AWSClient.eventGroup.next().newFailedFuture(error: S3ErrorType.multipart.noUploadId) }
            do {
                // upload all the parts
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

    /// Multipart download of a file from S3.
    ///
    /// - parameters:
    ///     - input: The GetObjectRequest shape that contains the details of the object request.
    ///     - partSize: Size of each part to be downloaded
    ///     - filename: Filename to save download to
    /// - returns: A future that will receive the complete file size once the multipart download has finished.
    func multipartDownload(_ input: GetObjectRequest, partSize: Int = 5*1024*1024, filename: String, progress: @escaping (Int64)->() = {_ in}) throws -> Future<Int64> {
        if let outputStream = OutputStream(toFileAtPath: filename, append: false) {
            outputStream.open()
            
            var progressValue : Int64 = 0
            let download = try self.multipartDownload(input, partSize: partSize, outputStream:{ data in
                let bytesWritten = data.withUnsafeBytes { (bytes : UnsafePointer<UInt8>) -> Int in
                    // read chunk
                    return outputStream.write(bytes, maxLength: data.count)
                }
                if bytesWritten != data.count {
                    throw S3ErrorType.multipart.failedToWrite(file: filename)
                }
                // update progress
                progressValue += Int64(data.count)
                progress(progressValue)
            })
            download.whenComplete {
                outputStream.close()
            }
            return download
        } else {
            throw S3ErrorType.multipart.failedToWrite(file: filename)
        }
    }

    /// Multipart upload of file to S3.
    ///
    /// - parameters:
    ///     - input: The CreateMultipartUploadRequest structure that contains the details about the upload
    ///     - partSize: Size of each part to upload. This has to be at least 5MB
    ///     - filename: Name of file to upload
    ///
    /// - returns: A Future that will receive a CompleteMultipartUploadOutput once the multipart upload has finished.
    func multipartUpload(_ input: CreateMultipartUploadRequest, partSize: Int = 5*1024*1024, filename: String, progress: @escaping (Int64)->() = { _ in }) throws -> Future<CompleteMultipartUploadOutput> {
        if let inputStream = InputStream(fileAtPath: filename) {
            inputStream.open()

            var progressAmount : Int64 = 0
            let upload = try self.multipartUpload(input, inputStream:{
                progress(progressAmount)
                
                var data = Data(count:partSize)
                let bytesRead = data.withUnsafeMutableBytes { (bytes : UnsafeMutablePointer<UInt8>) -> Int in
                    return inputStream.read(bytes, maxLength: partSize)
                }
                if bytesRead == 0 {
                    return nil
                }
                if bytesRead == -1 {
                    throw S3ErrorType.multipart.failedToRead(file: filename)
                }
                
                progressAmount += Int64(bytesRead)
                
                if bytesRead != data.count {
                    data.removeSubrange(bytesRead..<partSize)
                }
                return data
            })
            upload.whenComplete {
                inputStream.close()
            }
            return upload
        } else {
            throw S3ErrorType.multipart.failedToRead(file: filename)
        }
    }
}
