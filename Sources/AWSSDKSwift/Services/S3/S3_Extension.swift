//
//  S3_Extension.swift
//  AWSSDKSwift
//
//  Created by Adam Fowler on 2019/08/01.
//
//
import Foundation
import AWSSDKSwiftCore

public extension S3 {

    ///  Creates presigned URL for retrieving object from Amazon S3.
    func presignedGetObject(bucket: String, key: String, expires: Int = 3600) throws -> URL {
        let signer = try Signers.V4(credential: SharedCredential(), region: .euwest1, service: "s3", endpoint: nil)
        let urlToSign = URL(string: "https://\(bucket).s3.amazonaws.com/\(key)")!
        let presignedURL = signer.signedURL(url: urlToSign,  method: "GET", date: Date(), expires: expires)
        return presignedURL
    }
    
    ///  Creates presigned URL for uploading object to Amazon S3.
    func presignedPutObject(bucket: String, key: String, expires: Int = 3600) throws -> URL {
        let signer = try Signers.V4(credential: SharedCredential(), region: .euwest1, service: "s3", endpoint: nil)
        let urlToSign = URL(string: "https://\(bucket).s3.amazonaws.com/\(key)")!
        let presignedURL = signer.signedURL(url: urlToSign,  method: "PUT", date: Date(), expires: expires)
        return presignedURL
    }
    
    /// Implement multipart download of a file. Returns a Future that contains the size of file downloaded. Each file part downloaded is passed to the outputStream function
    func multipartDownload(bucket: String, key: String, partSize: Int64=5*1024*1024, outputStream: @escaping (Data) throws -> ()) throws -> Future<Int64> {
        // function downloading part of a file
        func multipartDownloadPart(fileSize: Int64, offset: Int64) throws -> Future<Int64> {
            let range = "bytes=\(offset)-\(offset+Int64(partSize-1))"
            let request = S3.GetObjectRequest(bucket: bucket, key: key, range: range)
            let result = try getObject(request).then { output -> Future<Int64> in
                // should never happen
                guard let length = output.contentLength, length > 0 else { return AWSClient.eventGroup.next().newSucceededFuture(result: fileSize) }
                guard let body = output.body else { return AWSClient.eventGroup.next().newSucceededFuture(result: fileSize) }
                let newOffset = offset + partSize
                // callback
                return AWSClient.eventGroup.next().submit {
                    try outputStream(body)
                    }.then {
                        // if file size if less than of equal to new offset, then we have reached the end of the file and should return success
                        guard fileSize > newOffset else { return AWSClient.eventGroup.next().newSucceededFuture(result: fileSize) }
                        // download next part
                        do {
                            
                            return try multipartDownloadPart(fileSize: fileSize, offset: newOffset)
                        } catch {
                            return AWSClient.eventGroup.next().newFailedFuture(error: error)
                        }
                }
            }
            return result
        }
        
        // get object size before downloading
        let request = S3.HeadObjectRequest(bucket: bucket, key: key)
        let result = try headObject(request).then { object -> Future<Int64> in
            do {
                // download file
                return try multipartDownloadPart(fileSize: object.contentLength!, offset: 0)
            } catch {
                return AWSClient.eventGroup.next().newFailedFuture(error: error)
            }
        }
        return result
    }

    /// Implement multipart upload. The object you want to upload has to be greater then 5MB in size or S3 will reject it. The function inputStream should supply the object you want uploaded, in parts. Each part has to be exactly the same size except the last one which will be sized to supply the exact size of the object. eg if you are uploading an object of size 40MB in 16Mb parts you need to supply two 16MB parts and then the end 8MB part.
    func multipartUpload(_ input: CreateMultipartUploadRequest, inputStream: @escaping () throws -> Data?) throws -> Future<CompleteMultipartUploadOutput> {
        var completedParts: [S3.CompletedPart] = []
        // function uploading part of a file
        func multipartUploadPart(partNumber: Int32, uploadId: String) throws -> Future<[S3.CompletedPart]> {
            // load data
            let result = AWSClient.eventGroup.next().submit {
                return try inputStream()
                // upload data
                }.then { data -> Future<[S3.CompletedPart]> in
                    guard let data = data else { return AWSClient.eventGroup.next().newSucceededFuture(result: completedParts)}
                    // request upload
                    let request = S3.UploadPartRequest(body: data, bucket: input.bucket, contentLength: Int64(data.count), key: input.key, partNumber: partNumber, requestPayer: input.requestPayer, sSECustomerAlgorithm: input.sSECustomerAlgorithm, sSECustomerKey: input.sSECustomerKey, sSECustomerKeyMD5: input.sSECustomerKeyMD5, uploadId: uploadId)
                    do {
                        let result = try self.uploadPart(request).then { output -> Future<[S3.CompletedPart]> in
                            // upload next part
                            do {
                                let part = S3.CompletedPart(eTag: output.eTag, partNumber: partNumber)
                                completedParts.append(part)
                                return try multipartUploadPart(partNumber: partNumber+1, uploadId: uploadId)
                            } catch {
                                return AWSClient.eventGroup.next().newFailedFuture(error: error)
                            }
                        }
                        return result
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
                return try multipartUploadPart(partNumber: 1, uploadId: uploadId).then { parts -> Future<CompleteMultipartUploadOutput> in
                    do {
                        let request = S3.CompleteMultipartUploadRequest(bucket: input.bucket, key:input.key, multipartUpload: S3.CompletedMultipartUpload(parts:parts), requestPayer: input.requestPayer, uploadId: uploadId)
                        let result = try self.completeMultipartUpload(request)
                        return result
                    } catch {
                        return AWSClient.eventGroup.next().newFailedFuture(error: error)
                    }
                    }.thenIfErrorThrowing { error in
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
