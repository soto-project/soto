//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if compiler(>=5.5.2) && canImport(_Concurrency)

import Logging
import NIOCore
import NIOPosix
import SotoCore

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension S3 {
    /// Multipart download of a file from S3.
    ///
    /// - parameters:
    ///     - input: The GetObjectRequest shape that contains the details of the object request.
    ///     - partSize: Size of each part to be downloaded
    ///     - on: an EventLoop to process each downloaded part on
    ///     - outputStream: Function to be called for each downloaded part. Called with data block and file size
    /// - returns: An EventLoopFuture that will receive the complete file size once the multipart download has finished.
    public func multipartDownload(
        _ input: GetObjectRequest,
        partSize: Int = 5 * 1024 * 1024,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        outputStream: @escaping (ByteBuffer, Int64, EventLoop) async throws -> Void
    ) async throws -> Int64 {
        let eventLoop = eventLoop ?? self.client.eventLoopGroup.next()

        // get object size before downloading
        let headRequest = S3.HeadObjectRequest(
            bucket: input.bucket,
            ifMatch: input.ifMatch,
            ifModifiedSince: input.ifModifiedSince,
            ifNoneMatch: input.ifNoneMatch,
            ifUnmodifiedSince: input.ifUnmodifiedSince,
            key: input.key,
            requestPayer: input.requestPayer,
            sseCustomerAlgorithm: input.sseCustomerAlgorithm,
            sseCustomerKey: input.sseCustomerKey,
            sseCustomerKeyMD5: input.sseCustomerKeyMD5,
            versionId: input.versionId
        )
        let object = try await headObject(headRequest, logger: logger, on: eventLoop)
        guard let contentLength = object.contentLength, contentLength > 0 else {
            throw S3ErrorType.multipart.downloadEmpty(message: "Content length is unexpectedly zero")
        }

        // download part task
        func downloadPartTask(offset: Int64, partSize: Int64) -> Task<GetObjectOutput, Swift.Error> {
            let range = "bytes=\(offset)-\(offset + Int64(partSize - 1))"
            let getRequest = S3.GetObjectRequest(
                bucket: input.bucket,
                key: input.key,
                range: range,
                sseCustomerAlgorithm: input.sseCustomerAlgorithm,
                sseCustomerKey: input.sseCustomerKey,
                sseCustomerKeyMD5: input.sseCustomerKeyMD5,
                versionId: input.versionId
            )
            return Task {
                try await getObject(getRequest, logger: logger, on: eventLoop)
            }
        }

        // save part task
        func savePart(downloadedPart: GetObjectOutput) async throws {
            guard let body = downloadedPart.body?.asByteBuffer() else {
                throw S3ErrorType.multipart.downloadEmpty(message: "Body is unexpectedly nil")
            }
            guard let length = downloadedPart.contentLength, length > 0 else {
                throw S3ErrorType.multipart.downloadEmpty(message: "Content length is unexpectedly zero")
            }
            try await outputStream(body, contentLength, eventLoop)
        }

        let partSize: Int64 = numericCast(partSize)
        var offset = min(partSize, contentLength)
        var downloadedPartTask = downloadPartTask(offset: 0, partSize: offset)
        while offset < contentLength {
            // wait for previous download
            let downloadedPart = try await downloadedPartTask.value

            // start next download
            let downloadPartSize = min(partSize, contentLength - offset)
            downloadedPartTask = downloadPartTask(offset: offset, partSize: downloadPartSize)
            offset += downloadPartSize

            // save part
            try await savePart(downloadedPart: downloadedPart)
        }
        // wait for last download
        let downloadedPart = try await downloadedPartTask.value
        // and save part
        try await savePart(downloadedPart: downloadedPart)

        return contentLength
    }

    /// Multipart download of a file from S3.
    ///
    /// - parameters:
    ///     - input: The GetObjectRequest shape that contains the details of the object request.
    ///     - partSize: Size of each part to be downloaded
    ///     - filename: Filename to save download to
    ///     - on: EventLoop to process downloaded parts, if nil an eventLoop is taken from the clients eventLoopGroup
    ///     - progress: Callback that returns the progress of the download. It is called after each part is downloaded with a value between 0.0 and 1.0 indicating how far the download is complete (1.0 meaning finished).
    /// - returns: An EventLoopFuture that will receive the complete file size once the multipart download has finished.
    public func multipartDownload(
        _ input: GetObjectRequest,
        partSize: Int = 5 * 1024 * 1024,
        filename: String,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        threadPoolProvider: ThreadPoolProvider = .createNew,
        progress: @escaping (Double) throws -> Void = { _ in }
    ) async throws -> Int64 {
        let eventLoop = eventLoop ?? self.client.eventLoopGroup.next()

        let threadPool = threadPoolProvider.create()
        let fileIO = NonBlockingFileIO(threadPool: threadPool)
        let fileHandle = try await fileIO.openFile(path: filename, mode: .write, flags: .allowFileCreation(), eventLoop: eventLoop).get()
        let progressValue: UnsafeMutableTransferBox<Int64> = .init(0)

        let downloaded: Int64
        do {
            downloaded = try await self.multipartDownload(input, partSize: partSize, logger: logger, on: eventLoop) { byteBuffer, fileSize, eventLoop in
                let bufferSize = byteBuffer.readableBytes
                return fileIO.write(fileHandle: fileHandle, buffer: byteBuffer, eventLoop: eventLoop).flatMapThrowing { _ in
                    progressValue.wrappedValue += Int64(bufferSize)
                    try progress(Double(progressValue.wrappedValue) / Double(fileSize))
                }
            }.get()
        } catch {
            try fileHandle.close()
            // ignore errors from thread pool provider shutdown, as we want to throw the original error
            try? await threadPoolProvider.destroy(threadPool)
            throw error
        }
        try fileHandle.close()
        try await threadPoolProvider.destroy(threadPool)
        return downloaded
    }

    /// Multipart upload of file to S3.
    ///
    /// - parameters:
    ///     - input: The CreateMultipartUploadRequest structure that contains the details about the upload
    ///     - abortOnFail: Whether should abort multipart upload if it fails. If you want to attempt to resume after a fail this should be set to false
    ///     - on: an EventLoop to process each part to upload
    ///     - inputStream: The function supplying the data parts to the multipartUpload. Each parts must be at least 5MB in size expect the last one which has no size limit.
    /// - returns: An EventLoopFuture that will receive a CompleteMultipartUploadOutput once the multipart upload has finished.
    public func multipartUploadFromStream(
        _ input: CreateMultipartUploadRequest,
        abortOnFail: Bool = true,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        inputStream: @escaping (EventLoop) async throws -> AWSPayload
    ) async throws -> CompleteMultipartUploadOutput {
        let eventLoop = eventLoop ?? self.client.eventLoopGroup.next()
        // initialize multipart upload
        let upload = try await createMultipartUpload(input, logger: logger, on: eventLoop)
        guard let uploadId = upload.uploadId else {
            throw S3ErrorType.multipart.noUploadId
        }

        do {
            // upload all the parts
            let parts = try await self.multipartUploadParts(
                input, uploadId: uploadId,
                logger: logger,
                on: eventLoop,
                inputStream: inputStream,
                skipStream: { _ in return true }
            )

            // complete multipart upload
            let request = S3.CompleteMultipartUploadRequest(
                bucket: input.bucket,
                key: input.key,
                multipartUpload: S3.CompletedMultipartUpload(parts: parts),
                requestPayer: input.requestPayer,
                uploadId: uploadId
            )
            do {
                return try await self.completeMultipartUpload(request, logger: logger, on: eventLoop)
            } catch {
                throw MultipartUploadError(error: error, completedParts: parts)
            }
        } catch {
            guard abortOnFail else {
                // if error is MultipartUploadError then we have completed uploading some parts and should include that in the error
                if let error = error as? MultipartUploadError {
                    throw S3ErrorType.multipart.abortedUpload(
                        resumeRequest: .init(uploadRequest: input, uploadId: uploadId, completedParts: error.completedParts),
                        error: error.error
                    )
                } else {
                    throw S3ErrorType.multipart.abortedUpload(
                        resumeRequest: .init(uploadRequest: input, uploadId: uploadId, completedParts: []),
                        error: error
                    )
                }
            }
            // if failure then abort the multipart upload
            let request = S3.AbortMultipartUploadRequest(
                bucket: input.bucket,
                key: input.key,
                requestPayer: input.requestPayer,
                uploadId: uploadId
            )
            _ = try await self.abortMultipartUpload(request, logger: logger, on: eventLoop)
            throw error
        }
    }

    /// Multipart upload of file to S3.
    ///
    /// Uploads file using multipart upload commands. If you want the function to not abort the multipart upload when it receives an error then set `abortOnFail` to false. With this you
    /// can then use `resumeMultipartUpload` to resume the failed upload. If you set `abortOnFail` to false but don't call `resumeMultipartUpload` on failure you will have
    /// to call `abortMultipartUpload` yourself.
    ///
    /// - parameters:
    ///     - input: The CreateMultipartUploadRequest structure that contains the details about the upload
    ///     - partSize: Size of each part to upload. This has to be at least 5MB
    ///     - fileHandle: File handle for file to upload
    ///     - fileIO: NIO non blocking file io manager
    ///     - uploadSize: Size of file to upload
    ///     - abortOnFail: Whether should abort multipart upload if it fails. If you want to attempt to resume after a fail this should be set to false
    ///     - on: EventLoop to process parts for upload, if nil an eventLoop is taken from the clients eventLoopGroup
    ///     - eventLoop: Eventloop to run upload on
    ///     - progress: Callback that returns the progress of the upload. It is called after each part is uploaded with a value between 0.0 and 1.0 indicating how far the upload is complete (1.0 meaning finished).
    /// - returns: An EventLoopFuture that will receive a CompleteMultipartUploadOutput once the multipart upload has finished.
    func multipartUpload(
        _ input: CreateMultipartUploadRequest,
        partSize: Int = 5 * 1024 * 1024,
        fileHandle: NIOFileHandle,
        fileIO: NonBlockingFileIO,
        uploadSize: Int,
        abortOnFail: Bool = true,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        progress: @escaping (Double) throws -> Void = { _ in }
    ) async throws -> CompleteMultipartUploadOutput {
        let eventLoop = eventLoop ?? self.client.eventLoopGroup.next()

        var progressAmount: Int = 0
        var prevProgressAmount: Int = 0

        return try await self.multipartUploadFromStream(input, abortOnFail: abortOnFail, logger: logger, on: eventLoop) { _ in
            let size = min(partSize, uploadSize - progressAmount)
            guard size > 0 else { return .empty }
            prevProgressAmount = progressAmount
            progressAmount += size
            let payload = AWSPayload.fileHandle(
                fileHandle,
                size: size,
                fileIO: fileIO,
                byteBufferAllocator: self.config.byteBufferAllocator
            ) { downloaded in
                try progress(Double(downloaded + prevProgressAmount) / Double(uploadSize))
            }
            return payload
        }
    }

    /// Multipart upload of file to S3.
    ///
    /// Uploads file using multipart upload commands. If you want the function to not abort the multipart upload when it receives an error then set `abortOnFail` to false. With this you
    /// can then use `resumeMultipartUpload` to resume the failed upload. If you set `abortOnFail` to false but don't call `resumeMultipartUpload` on failure you will have
    /// to call `abortMultipartUpload` yourself.
    ///
    /// - parameters:
    ///     - input: The CreateMultipartUploadRequest structure that contains the details about the upload
    ///     - partSize: Size of each part to upload. This has to be at least 5MB
    ///     - filename: Full path of file to upload
    ///     - abortOnFail: Whether should abort multipart upload if it fails. If you want to attempt to resume after a fail this should be set to false
    ///     - on: EventLoop to process parts for upload, if nil an eventLoop is taken from the clients eventLoopGroup
    ///     - eventLoop: Eventloop to run upload on
    ///     - threadPoolProvider: Provide a thread pool to use or create a new one
    ///     - progress: Callback that returns the progress of the upload. It is called after each part is uploaded with a value between 0.0 and 1.0 indicating how far the upload is complete (1.0 meaning finished).
    /// - returns: An EventLoopFuture that will receive a CompleteMultipartUploadOutput once the multipart upload has finished.
    public func multipartUpload(
        _ input: CreateMultipartUploadRequest,
        partSize: Int = 5 * 1024 * 1024,
        filename: String,
        abortOnFail: Bool = true,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        threadPoolProvider: ThreadPoolProvider = .createNew,
        progress: @escaping (Double) throws -> Void = { _ in }
    ) async throws -> CompleteMultipartUploadOutput {
        let eventLoop = eventLoop ?? self.client.eventLoopGroup.next()

        return try await openFileForMultipartUpload(
            filename: filename,
            logger: logger,
            on: eventLoop,
            threadPoolProvider: threadPoolProvider
        ) { fileHandle, fileRegion, fileIO in
            try await self.multipartUpload(
                input,
                partSize: partSize,
                fileHandle: fileHandle,
                fileIO: fileIO,
                uploadSize: fileRegion.readableBytes,
                abortOnFail: abortOnFail,
                logger: logger,
                on: eventLoop,
                progress: progress
            )
        }
    }

    /// resume multipart upload of file to S3.
    ///
    /// - parameters:
    ///     - input: The `ResumeMultipartUploadRequest` structure returned in upload fail error from previous upload call
    ///     - abortOnFail: Whether should abort multipart upload if it fails. If you want to attempt to resume after a fail this should be set to false
    ///     - on: an EventLoop to process each part to upload
    ///     - inputStream: The function supplying the data parts to the multipartUpload. Each parts must be at least 5MB in size expect the last one which has no size limit.
    ///     - skipStream: The function to call when skipping an already loaded part
    /// - returns: An EventLoopFuture that will receive a CompleteMultipartUploadOutput once the multipart upload has finished.
    public func resumeMultipartUpload(
        _ input: ResumeMultipartUploadRequest,
        abortOnFail: Bool = true,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        inputStream: @escaping (EventLoop) async throws -> AWSPayload,
        skipStream: @escaping (EventLoop) async throws -> Bool
    ) async throws -> CompleteMultipartUploadOutput {
        let eventLoop = eventLoop ?? self.client.eventLoopGroup.next()
        let uploadRequest = input.uploadRequest

        do {
            // upload all the parts
            let parts = try await self.multipartUploadParts(
                uploadRequest,
                uploadId: input.uploadId,
                parts: input.completedParts,
                logger: logger,
                on: eventLoop,
                inputStream: inputStream,
                skipStream: skipStream
            )

            let request = S3.CompleteMultipartUploadRequest(
                bucket: uploadRequest.bucket,
                key: uploadRequest.key,
                multipartUpload: S3.CompletedMultipartUpload(parts: parts),
                requestPayer: uploadRequest.requestPayer,
                uploadId: input.uploadId
            )
            do {
                return try await self.completeMultipartUpload(request, logger: logger, on: eventLoop)
            } catch {
                throw MultipartUploadError(error: error, completedParts: parts)
            }
        } catch {
            guard abortOnFail else {
                // if error is MultipartUploadError then we have completed uploading some parts and should include that in the error
                if let error = error as? MultipartUploadError {
                    throw S3ErrorType.multipart.abortedUpload(
                        resumeRequest: .init(uploadRequest: uploadRequest, uploadId: input.uploadId, completedParts: error.completedParts),
                        error: error.error
                    )
                } else {
                    throw S3ErrorType.multipart.abortedUpload(
                        resumeRequest: .init(uploadRequest: uploadRequest, uploadId: input.uploadId, completedParts: []),
                        error: error
                    )
                }
            }
            // if failure then abort the multipart upload
            let request = S3.AbortMultipartUploadRequest(
                bucket: uploadRequest.bucket,
                key: uploadRequest.key,
                requestPayer: uploadRequest.requestPayer,
                uploadId: input.uploadId
            )
            _ = try await self.abortMultipartUpload(request, logger: logger, on: eventLoop)
            throw error
        }
    }

    /// Resume multipart upload of file to S3.
    ///
    /// Call this with `ResumeMultipartUploadRequest`returned by the failed multipart upload. Make sure you are using the same `partSize`, the `fileHandle` points to the
    /// same file and is in the same position in that file and the uploadSize is the same as you used when calling `multipartUpload`.
    ///
    /// - parameters:
    ///     - input: The `ResumeMultipartUploadRequest` structure returned in upload fail error from previous upload call
    ///     - partSize: Size of each part to upload. This has to be at least 5MB
    ///     - fileHandle: File handle for file to upload
    ///     - fileIO: NIO non blocking file io manager
    ///     - uploadSize: Size of file to upload
    ///     - abortOnFail: Whether should abort multipart upload if it fails. If you want to attempt to resume after a fail this should be set to false
    ///     - on: EventLoop to process parts for upload, if nil an eventLoop is taken from the clients eventLoopGroup
    ///     - eventLoop: Eventloop to run upload on
    ///     - progress: Callback that returns the progress of the upload. It is called after each part is uploaded with a value between 0.0 and 1.0 indicating how far the upload is complete
    ///      (1.0 meaning finished).
    /// - returns: An EventLoopFuture that will receive a CompleteMultipartUploadOutput once the multipart upload has finished.
    public func resumeMultipartUpload(
        _ input: ResumeMultipartUploadRequest,
        partSize: Int = 5 * 1024 * 1024,
        fileHandle: NIOFileHandle,
        fileIO: NonBlockingFileIO,
        uploadSize: Int,
        abortOnFail: Bool = true,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        progress: @escaping (Double) throws -> Void = { _ in }
    ) async throws -> CompleteMultipartUploadOutput {
        let eventLoop = eventLoop ?? self.client.eventLoopGroup.next()

        var progressAmount: Int = 0
        var prevProgressAmount: Int = 0

        return try await self.resumeMultipartUpload(
            input,
            abortOnFail: abortOnFail,
            logger: logger,
            on: eventLoop,
            inputStream: { _ in
                let size = min(partSize, uploadSize - progressAmount)
                guard size > 0 else { return .empty }
                prevProgressAmount = progressAmount
                let payload = AWSPayload.fileHandle(
                    fileHandle,
                    offset: progressAmount,
                    size: size,
                    fileIO: fileIO,
                    byteBufferAllocator: self.config.byteBufferAllocator
                ) { downloaded in
                    try progress(Double(downloaded + prevProgressAmount) / Double(uploadSize))
                }
                progressAmount += size
                return payload
            },
            skipStream: { _ in
                let size = min(partSize, uploadSize - progressAmount)
                progressAmount += size
                return size == 0
            }
        )
    }

    /// Resume multipart upload of file to S3.
    ///
    /// Call this with `ResumeMultipartUploadRequest`returned by the failed multipart upload. Make sure you are using the same `partSize`and `filename` as you used when calling
    /// `multipartUpload`. `
    ///
    /// - parameters:
    ///     - input: The `ResumeMultipartUploadRequest` structure returned in upload fail error from previous upload call
    ///     - partSize: Size of each part to upload. This has to be at least 5MB
    ///     - filename: Full path of file to upload
    ///     - abortOnFail: Whether should abort multipart upload if it fails. If you want to attempt to resume after a fail this should be set to false
    ///     - on: EventLoop to process parts for upload, if nil an eventLoop is taken from the clients eventLoopGroup
    ///     - eventLoop: Eventloop to run upload on
    ///     - threadPoolProvider: Provide a thread pool to use or create a new one
    ///     - progress: Callback that returns the progress of the upload. It is called after each part is uploaded with a value between 0.0 and 1.0 indicating how far the upload is complete (1.0 meaning finished).
    /// - returns: An EventLoopFuture that will receive a CompleteMultipartUploadOutput once the multipart upload has finished.
    public func resumeMultipartUpload(
        _ input: ResumeMultipartUploadRequest,
        partSize: Int = 5 * 1024 * 1024,
        filename: String,
        abortOnFail: Bool = true,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        threadPoolProvider: ThreadPoolProvider = .createNew,
        progress: @escaping (Double) throws -> Void = { _ in }
    ) async throws -> CompleteMultipartUploadOutput {
        let eventLoop = eventLoop ?? self.client.eventLoopGroup.next()

        return try await openFileForMultipartUpload(
            filename: filename,
            logger: logger,
            on: eventLoop,
            threadPoolProvider: threadPoolProvider
        ) { fileHandle, fileRegion, fileIO in
            try await self.resumeMultipartUpload(
                input,
                partSize: partSize,
                fileHandle: fileHandle,
                fileIO: fileIO,
                uploadSize: fileRegion.readableBytes,
                abortOnFail: abortOnFail,
                logger: logger,
                on: eventLoop,
                progress: progress
            )
        }
    }

    /// Multipart copy of file to S3. Currently this only works within one region as it uses HeadObject to read the source file size
    ///
    /// - parameters:
    ///     - input: The CopyObjectRequest structure that contains the details about the copy
    ///     - partSize: Size of each part to copy. This has to be at least 5MB
    ///     - eventLoop: an EventLoop to process each part to upload
    /// - returns: An EventLoopFuture that will receive a CompleteMultipartUploadOutput once the multipart upload has finished.
    public func multipartCopy(
        _ input: CopyObjectRequest,
        partSize: Int = 8 * 1024 * 1024,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) async throws -> CompleteMultipartUploadOutput {
        let eventLoop = eventLoop ?? self.client.eventLoopGroup.next()

        // get object bucket, key and version from copySource
        guard let copySourceValues = getBucketKeyVersion(from: input.copySource) else { throw AWSClientError.validationError }

        // get object size from headObject
        let head = try await self.headObject(
            .init(bucket: copySourceValues.bucket, key: copySourceValues.key, versionId: copySourceValues.versionId),
            logger: logger,
            on: eventLoop
        )
        let objectSize = head.contentLength ?? 0

        // initialize multipart upload
        let request: CreateMultipartUploadRequest = .init(acl: input.acl, bucket: input.bucket, cacheControl: input.cacheControl, contentDisposition: input.contentDisposition, contentEncoding: input.contentEncoding, contentLanguage: input.contentLanguage, contentType: input.contentType, expectedBucketOwner: input.expectedBucketOwner, expires: input.expires, grantFullControl: input.grantFullControl, grantRead: input.grantRead, grantReadACP: input.grantReadACP, grantWriteACP: input.grantWriteACP, key: input.key, metadata: input.metadata, objectLockLegalHoldStatus: input.objectLockLegalHoldStatus, objectLockMode: input.objectLockMode, objectLockRetainUntilDate: input.objectLockRetainUntilDate, requestPayer: input.requestPayer, serverSideEncryption: input.serverSideEncryption, sseCustomerAlgorithm: input.sseCustomerAlgorithm, sseCustomerKey: input.sseCustomerKey, sseCustomerKeyMD5: input.sseCustomerKeyMD5, ssekmsEncryptionContext: input.ssekmsEncryptionContext, ssekmsKeyId: input.ssekmsKeyId, storageClass: input.storageClass, tagging: input.tagging, websiteRedirectLocation: input.websiteRedirectLocation)
        let uploadResponse = try await createMultipartUpload(request, logger: logger, on: eventLoop)
        guard let uploadId = uploadResponse.uploadId else {
            throw S3ErrorType.multipart.noUploadId
        }

        do {
            // calculate number of upload part calls and the size of the final upload
            let numParts = ((Int(objectSize) - 1) / partSize) + 1
            let finalPartSize = Int(objectSize) - (numParts - 1) * partSize

            // create array of upload part requests.
            let uploadPartRequests: [UploadPartCopyRequest] = (1...numParts).map { part in
                let copyRange: String
                if part != numParts {
                    copyRange = "bytes=\((part - 1) * partSize)-\(part * partSize - 1)"
                } else {
                    copyRange = "bytes=\((part - 1) * partSize)-\((part - 1) * partSize + finalPartSize - 1)"
                }
                return .init(bucket: input.bucket, copySource: input.copySource, copySourceRange: copyRange, copySourceSSECustomerAlgorithm: input.copySourceSSECustomerAlgorithm, copySourceSSECustomerKey: input.copySourceSSECustomerKey, copySourceSSECustomerKeyMD5: input.copySourceSSECustomerKeyMD5, expectedBucketOwner: input.expectedBucketOwner, expectedSourceBucketOwner: input.expectedSourceBucketOwner, key: input.key, partNumber: part, requestPayer: input.requestPayer, sseCustomerAlgorithm: input.sseCustomerAlgorithm, sseCustomerKey: input.sseCustomerKey, sseCustomerKeyMD5: input.sseCustomerKeyMD5, uploadId: uploadId)
            }
            // send upload part copy requests to AWS
            let parts: [S3.CompletedPart] = try await uploadPartRequests.concurrentMap {
                let response = try await self.uploadPartCopy($0, logger: logger, on: eventLoop)
                guard let copyPartResult = response.copyPartResult else { throw S3ErrorType.multipart.noCopyPartResult }
                return S3.CompletedPart(eTag: copyPartResult.eTag, partNumber: $0.partNumber)
            }
            // complete upload
            let completeRequest = S3.CompleteMultipartUploadRequest(
                bucket: input.bucket,
                key: input.key,
                multipartUpload: S3.CompletedMultipartUpload(parts: parts),
                requestPayer: input.requestPayer,
                uploadId: uploadId
            )
            return try await self.completeMultipartUpload(completeRequest, logger: logger, on: eventLoop)
        } catch {
            // if failure then abort the multipart upload
            let request = S3.AbortMultipartUploadRequest(
                bucket: input.bucket,
                key: input.key,
                requestPayer: input.requestPayer,
                uploadId: uploadId
            )
            _ = try await self.abortMultipartUpload(request, logger: logger, on: eventLoop)
            throw error
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension S3 {
    /// Do all the work for opening a file and closing it for MultiUpload function
    func openFileForMultipartUpload(
        filename: String,
        logger: Logger,
        on eventLoop: EventLoop,
        threadPoolProvider: ThreadPoolProvider = .createNew,
        uploadCallback: @escaping (NIOFileHandle, FileRegion, NonBlockingFileIO) async throws -> CompleteMultipartUploadOutput
    ) async throws -> CompleteMultipartUploadOutput {
        let threadPool = threadPoolProvider.create()
        let fileIO = NonBlockingFileIO(threadPool: threadPool)
        let (fileHandle, fileRegion) = try await fileIO.openFile(path: filename, eventLoop: eventLoop).get()

        logger.debug("Open file \(filename)")

        let uploadOutput: CompleteMultipartUploadOutput
        do {
            uploadOutput = try await uploadCallback(fileHandle, fileRegion, fileIO)
        } catch {
            try fileHandle.close()
            // ignore errors from thread pool provider shutdown, as we want to throw the original error
            try? await threadPoolProvider.destroy(threadPool)
            throw error
        }
        try fileHandle.close()
        try await threadPoolProvider.destroy(threadPool)
        return uploadOutput
    }

    /// used internally in multipartUpload, loads all the parts once the multipart upload has been initiated
    func multipartUploadParts(
        _ input: CreateMultipartUploadRequest,
        uploadId: String,
        parts: [S3.CompletedPart] = [],
        logger: Logger,
        on eventLoop: EventLoop,
        inputStream: @escaping (EventLoop) async throws -> AWSPayload,
        skipStream: @escaping (EventLoop) async throws -> Bool
    ) async throws -> [S3.CompletedPart] {
        var completedParts: [S3.CompletedPart] = []

        // Multipart uploads part numbers start at 1 not 0
        var partNumber = 1
        do {
            while true {
                if let part = parts.first(where: { $0.partNumber == partNumber }) {
                    completedParts.append(part)
                    let finish = try await skipStream(eventLoop)
                    if finish == true {
                        break
                    }
                    partNumber += 1
                    continue
                }

                let payload = try await inputStream(eventLoop)
                guard let size = payload.size, size > 0 else {
                    break
                }

                // upload part
                let request = S3.UploadPartRequest(
                    body: payload,
                    bucket: input.bucket,
                    key: input.key,
                    partNumber: partNumber,
                    requestPayer: input.requestPayer,
                    sseCustomerAlgorithm: input.sseCustomerAlgorithm,
                    sseCustomerKey: input.sseCustomerKey,
                    sseCustomerKeyMD5: input.sseCustomerKeyMD5,
                    uploadId: uploadId
                )
                // request upload future
                let uploadOutput = try await self.uploadPart(request, logger: logger, on: eventLoop)
                let part = S3.CompletedPart(eTag: uploadOutput.eTag, partNumber: partNumber)
                completedParts.append(part)

                partNumber += 1
            }
        } catch {
            throw MultipartUploadError(error: error, completedParts: completedParts)
        }

        return completedParts
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Sequence {
    #if compiler(>=5.6)
    public typealias ConcurrentMapTransform<T> = @Sendable (Element) async throws -> T
    #else
    public typealias ConcurrentMapTransform<T> = (Element) async throws -> T
    #endif

    /// Returns an array containing the results of mapping the given async closure over
    /// the sequence’s elements.
    ///
    /// This differs from `asyncMap` in that it uses a `TaskGroup` to run the transform
    /// closure for all the elements of the Sequence. This allows all the transform closures
    /// to run concurrently instead of serially. Returns only when the closure has been run
    /// on all the elements of the Sequence.
    /// - Parameters:
    ///   - priority: Task priority for tasks in TaskGroup
    ///   - transform: An async  mapping closure. transform accepts an
    ///     element of this sequence as its parameter and returns a transformed value of
    ///     the same or of a different type.
    /// - Returns: An array containing the transformed elements of this sequence.
    public func concurrentMap<T: _SotoSendable>(priority: TaskPriority? = nil, _ transform: @escaping ConcurrentMapTransform<T>) async rethrows -> [T] where Element: _SotoSendable {
        try await withThrowingTaskGroup(of: (Int, T).self) { group in
            self.enumerated().forEach { element in
                group.addTask(priority: priority) {
                    let result = try await transform(element.1)
                    return (element.0, result)
                }
            }
            // Code for collating results copied from Sequence.map in Swift codebase
            let initialCapacity = underestimatedCount
            var result = ContiguousArray<(Int, T)>()
            result.reserveCapacity(initialCapacity)

            // Add elements up to the initial capacity without checking for regrowth.
            for _ in 0..<initialCapacity {
                try await result.append(group.next()!)
            }
            // Add remaining elements, if any.
            while let element = try await group.next() {
                result.append(element)
            }

            // return result.sorted(by: {$0.0 < $1.0}).map(\.1)
            // construct final array and fill in elements
            return Array(unsafeUninitializedCapacity: result.count) { buffer, count in
                for value in result {
                    (buffer.baseAddress! + value.0).initialize(to: value.1)
                }
                count = result.count
            }
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension S3.ThreadPoolProvider {
    /// async version of destroy
    func destroy(_ threadPool: NIOThreadPool) async throws {
        if case .createNew = self {
            return try await withUnsafeThrowingContinuation { cont in
                threadPool.shutdownGracefully { error in
                    if let error = error {
                        cont.resume(throwing: error)
                    } else {
                        cont.resume()
                    }
                }
            }
        }
    }
}

#endif // compiler(>=5.5.2) && canImport(_Concurrency)
