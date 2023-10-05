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

import Atomics
import Dispatch
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
    ///     - progress: Callback that returns the progress of the download. It is called after each part is downloaded with a value
    ///         between 0.0 and 1.0 indicating how far the download is complete (1.0 meaning finished).
    /// - returns: An EventLoopFuture that will receive the complete file size once the multipart download has finished.
    public func multipartDownload(
        _ input: GetObjectRequest,
        partSize: Int = 5 * 1024 * 1024,
        filename: String,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        threadPoolProvider: ThreadPoolProvider = .singleton,
        progress: @escaping (Double) throws -> Void = { _ in }
    ) async throws -> Int64 {
        let eventLoop = eventLoop ?? self.client.eventLoopGroup.next()

        let threadPool = await threadPoolProvider.create()
        let fileIO = NonBlockingFileIO(threadPool: threadPool)
        let fileHandle = try await fileIO.openFile(path: filename, mode: .write, flags: .allowFileCreation(), eventLoop: eventLoop).get()
        let progressValue = ManagedAtomic(0)

        let downloaded: Int64
        do {
            downloaded = try await self.multipartDownload(input, partSize: partSize, logger: logger, on: eventLoop) { byteBuffer, fileSize, eventLoop in
                let bufferSize = byteBuffer.readableBytes
                return fileIO.write(fileHandle: fileHandle, buffer: byteBuffer, eventLoop: eventLoop).flatMapThrowing { _ in
                    let progressIntValue = progressValue.wrappingIncrementThenLoad(by: bufferSize, ordering: .relaxed)
                    try progress(Double(progressIntValue) / Double(fileSize))
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
    /// Uploads file using multipart upload commands. If you want the function to not abort the multipart upload when it receives
    /// an error then set `abortOnFail` to false. With this you can then use `resumeMultipartUpload` to resume the failed upload.
    /// If you set `abortOnFail` to false but don't call `resumeMultipartUpload` on failure you will have to call `abortMultipartUpload`
    /// yourself.
    ///
    /// - parameters:
    ///     - input: The CreateMultipartUploadRequest structure that contains the details about the upload
    ///     - partSize: Size of each part to upload. This has to be at least 5MB
    ///     - filename: Full path of file to upload
    ///     - abortOnFail: Whether should abort multipart upload if it fails. If you want to attempt to resume after a fail this should
    ///         be set to false
    ///     - eventLoop: Eventloop to run upload on
    ///     - threadPoolProvider: Provide a thread pool to use or create a new one
    ///     - progress: Callback that returns the progress of the upload. It is called after each part is uploaded with a value between
    ///         0.0 and 1.0 indicating how far the upload is complete (1.0 meaning finished).
    /// - returns: An EventLoopFuture that will receive a CompleteMultipartUploadOutput once the multipart upload has finished.
    public func multipartUpload(
        _ input: CreateMultipartUploadRequest,
        partSize: Int = 5 * 1024 * 1024,
        filename: String,
        abortOnFail: Bool = true,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        threadPoolProvider: ThreadPoolProvider = .singleton,
        progress: @escaping @Sendable (Double) throws -> Void = { _ in }
    ) async throws -> CompleteMultipartUploadOutput {
        let eventLoop = eventLoop ?? self.client.eventLoopGroup.next()

        return try await openFileForMultipartUpload(
            filename: filename,
            logger: logger,
            on: eventLoop,
            threadPoolProvider: threadPoolProvider
        ) { fileHandle, fileRegion, fileIO in
            let length = Double(fileRegion.readableBytes)
            @Sendable func percentProgress(_ value: Int) throws {
                try progress(Double(value) / length)
            }
            return try await self.multipartUpload(
                input,
                partSize: partSize,
                bufferSequence: FileByteBufferAsyncSequence(
                    fileHandle,
                    fileIO: fileIO,
                    chunkSize: partSize,
                    byteBufferAllocator: self.config.byteBufferAllocator,
                    eventLoop: eventLoop
                ),
                abortOnFail: abortOnFail,
                logger: logger,
                on: eventLoop,
                progress: percentProgress
            )
        }
    }

    /// Resume multipart upload of file to S3.
    ///
    /// Call this with `ResumeMultipartUploadRequest`returned by the failed multipart upload. Make sure you are using the same
    /// `partSize`and `filename` as you used when calling `multipartUpload`. `
    ///
    /// - parameters:
    ///     - input: The `ResumeMultipartUploadRequest` structure returned in upload fail error from previous upload call
    ///     - partSize: Size of each part to upload. This has to be at least 5MB
    ///     - filename: Full path of file to upload
    ///     - abortOnFail: Whether should abort multipart upload if it fails. If you want to attempt to resume after a fail
    ///         this should be set to false
    ///     - on: EventLoop to process parts for upload, if nil an eventLoop is taken from the clients eventLoopGroup
    ///     - eventLoop: Eventloop to run upload on
    ///     - threadPoolProvider: Provide a thread pool to use or create a new one
    ///     - progress: Callback that returns the progress of the upload. It is called after each part is uploaded with a value
    ///         between 0.0 and 1.0 indicating how far the upload is complete (1.0 meaning finished).
    /// - returns: Output from CompleteMultipartUpload.
    public func resumeMultipartUpload(
        _ input: ResumeMultipartUploadRequest,
        partSize: Int = 5 * 1024 * 1024,
        filename: String,
        abortOnFail: Bool = true,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        threadPoolProvider: ThreadPoolProvider = .singleton,
        progress: @escaping (Double) throws -> Void = { _ in }
    ) async throws -> CompleteMultipartUploadOutput {
        let eventLoop = eventLoop ?? self.client.eventLoopGroup.next()

        return try await openFileForMultipartUpload(
            filename: filename,
            logger: logger,
            on: eventLoop,
            threadPoolProvider: threadPoolProvider
        ) { fileHandle, fileRegion, fileIO in
            let length = Double(fileRegion.readableBytes)
            @Sendable func percentProgress(_ value: Int) throws {
                try progress(Double(value) / length)
            }
            return try await self.resumeMultipartUpload(
                input,
                partSize: partSize,
                bufferSequence: FileByteBufferAsyncSequence(
                    fileHandle,
                    fileIO: fileIO,
                    chunkSize: partSize,
                    byteBufferAllocator: self.config.byteBufferAllocator,
                    eventLoop: eventLoop
                ),
                abortOnFail: abortOnFail,
                logger: logger,
                on: eventLoop,
                progress: percentProgress
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
            let parts: [S3.CompletedPart] = try await uploadPartRequests.concurrentMap(maxConcurrentTasks: 8) {
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
        threadPoolProvider: ThreadPoolProvider = .singleton,
        uploadCallback: @escaping (NIOFileHandle, FileRegion, NonBlockingFileIO) async throws -> CompleteMultipartUploadOutput
    ) async throws -> CompleteMultipartUploadOutput {
        let threadPool = await threadPoolProvider.create()
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
}

/// AsyncSequence version of multipart upload
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension S3 {
    /// Multipart upload of AsyncSequence to S3.
    ///
    /// Uploads file using multipart upload commands. If you want the function to not abort the multipart upload when it
    /// receives an error then set `abortOnFail` to false. With this you can then use `resumeMultipartUpload` to resume
    /// the failed upload. If you set `abortOnFail` to false but don't call `resumeMultipartUpload` on failure you will have
    /// to call `abortMultipartUpload` yourself.
    ///
    /// - parameters:
    ///     - input: The CreateMultipartUploadRequest structure that contains the details about the upload
    ///     - partSize: Size of each part to upload. This has to be at least 5MB
    ///     - filename: Full path of file to upload
    ///     - abortOnFail: Whether should abort multipart upload if it fails. If you want to attempt to resume after
    ///         a fail this should be set to false
    ///     - eventLoop: EventLoop to process parts for upload, if nil an eventLoop is taken from the clients eventLoopGroup
    ///     - threadPoolProvider: Provide a thread pool to use or create a new one
    ///     - progress: Callback that returns the progress of the upload. It is called after each part and is called with how
    ///         many bytes have been uploaded so far.
    /// - returns: Output from CompleteMultipartUpload.
    public func multipartUpload<ByteBufferSequence: AsyncSequence>(
        _ input: CreateMultipartUploadRequest,
        partSize: Int = 5 * 1024 * 1024,
        bufferSequence: ByteBufferSequence,
        abortOnFail: Bool = true,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        threadPoolProvider: ThreadPoolProvider = .singleton,
        progress: (@Sendable (Int) throws -> Void)? = nil
    ) async throws -> CompleteMultipartUploadOutput where ByteBufferSequence.Element == ByteBuffer {
        // initialize multipart upload
        let upload = try await createMultipartUpload(input, logger: logger, on: eventLoop)
        guard let uploadId = upload.uploadId else {
            throw S3ErrorType.multipart.noUploadId
        }

        do {
            // upload all the parts
            let parts = try await self.multipartUploadParts(
                input,
                uploadId: uploadId,
                partSequence: bufferSequence.fixedSizeSequence(chunkSize: partSize).enumerated(),
                progress: progress,
                logger: logger,
                on: eventLoop
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

    ///  Resume upload of failed multipart upload
    ///
    /// - Parameters:
    ///   - input: The CreateMultipartUploadRequest structure that contains the details about the upload
    ///   - partSize: Size of each part to upload. Should be the same as the original upload
    ///   - bufferSequence: Sequence of ByteBuffers to upload
    ///   - abortOnFail: Whether should abort multipart upload if it fails. If you want to attempt to resume after
    ///         a fail this should be set to false
    ///   - eventLoop: EventLoop to process parts for upload, if nil an eventLoop is taken from the clients eventLoopGroup
    ///   - progress: Callback that returns the progress of the upload. It is called after each part and is called with how
    ///         many bytes have been uploaded so far.
    /// - Returns: Output from CompleteMultipartUpload.
    public func resumeMultipartUpload<ByteBufferSequence: AsyncSequence>(
        _ input: ResumeMultipartUploadRequest,
        partSize: Int = 5 * 1024 * 1024,
        bufferSequence: ByteBufferSequence,
        abortOnFail: Bool = true,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        progress: (@Sendable (Int) throws -> Void)? = nil
    ) async throws -> CompleteMultipartUploadOutput where ByteBufferSequence.Element == ByteBuffer {
        // upload all the parts
        let partsSet = Set<Int>(input.completedParts.map { $0.partNumber! - 1 })
        let partSequence = bufferSequence
            .fixedSizeSequence(chunkSize: partSize)
            .enumerated()
            .filter { !partsSet.contains($0.0) }

        return try await self.resumeMultipartUpload(
            input,
            partSize: partSize,
            partSequence: partSequence,
            abortOnFail: abortOnFail,
            progress: progress,
            logger: logger,
            on: eventLoop
        )
    }

    ///  Resume upload of failed multipart upload
    ///
    /// - Parameters:
    ///   - input: The CreateMultipartUploadRequest structure that contains the details about the upload
    ///   - partSize: Size of each part to upload. Should be the same as the original upload
    ///   - bufferSequence: Sequence of ByteBuffers to upload
    ///   - abortOnFail: Whether should abort multipart upload if it fails. If you want to attempt to resume after
    ///         a fail this should be set to false
    ///   - eventLoop: EventLoop to process parts for upload, if nil an eventLoop is taken from the clients eventLoopGroup
    ///   - progress: Callback that returns the progress of the upload. It is called after each part and is called with how
    ///         many bytes have been uploaded so far.
    /// - Returns: Output from CompleteMultipartUpload.
    public func resumeMultipartUpload<PartsSequence: AsyncSequence>(
        _ input: ResumeMultipartUploadRequest,
        partSize: Int = 5 * 1024 * 1024,
        partSequence: PartsSequence,
        abortOnFail: Bool = true,
        progress: (@Sendable (Int) throws -> Void)? = nil,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) async throws -> CompleteMultipartUploadOutput where PartsSequence.Element == (Int, ByteBuffer) {
        let uploadRequest = input.uploadRequest

        do {
            // upload all the parts
            let parts = try await self.multipartUploadParts(
                uploadRequest,
                uploadId: input.uploadId,
                partSequence: partSequence,
                initialProgress: input.completedParts.count * partSize,
                progress: progress,
                logger: logger,
                on: eventLoop
            )
            // combine array of already uploaded parts prior to the resume with the parts just uploaded
            let completedParts = (input.completedParts + parts).sorted { $0.partNumber! < $1.partNumber! }

            let request = S3.CompleteMultipartUploadRequest(
                bucket: uploadRequest.bucket,
                key: uploadRequest.key,
                multipartUpload: S3.CompletedMultipartUpload(parts: completedParts),
                requestPayer: uploadRequest.requestPayer,
                uploadId: input.uploadId
            )
            do {
                return try await self.completeMultipartUpload(request, logger: logger, on: eventLoop)
            } catch {
                throw MultipartUploadError(error: error, completedParts: completedParts)
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

    /// Used internally in multipartUpload, loads all the parts once the multipart upload has been initiated
    ///
    /// - Parameters:
    ///   - input: multipart upload request
    ///   - uploadId: upload id
    ///   - bufferSequence: AsyncSequence supplying fixed size ByteBuffers
    ///   - progress: Progress function updated with accumulated amount uploaded.
    ///   - logger: logger
    ///   - eventLoop: eventloop to run Soto calls on
    /// - Returns: Array of completed parts
    func multipartUploadParts<PartSequence: AsyncSequence>(
        _ input: CreateMultipartUploadRequest,
        uploadId: String,
        partSequence: PartSequence,
        initialProgress: Int = 0,
        progress: (@Sendable (Int) throws -> Void)? = nil,
        logger: Logger,
        on eventLoop: EventLoop?
    ) async throws -> [S3.CompletedPart] where PartSequence.Element == (Int, ByteBuffer) {
        var newProgress: (@Sendable (Int) throws -> Void)?
        if let progress = progress {
            let size = ManagedAtomic(initialProgress)
            @Sendable func accumulatingProgress(_ amount: Int) throws {
                let totalSize = size.wrappingIncrementThenLoad(by: amount, ordering: .relaxed)
                try progress(totalSize)
            }
            newProgress = accumulatingProgress
        }

        return try await withThrowingTaskGroup(of: (Int, S3.CompletedPart).self) { group in
            var results = ContiguousArray<(Int, S3.CompletedPart)>()

            var count = 0
            for try await(index, buffer) in partSequence {
                count += 1
                // once we have kicked off 4 tasks we can start waiting for a task to finish before
                // starting another
                if count > 4 {
                    if let element = try await group.next() {
                        results.append(element)
                    }
                }
                let body: AWSPayload
                if let progress = newProgress {
                    body = .asyncSequence(buffer.asyncSequence(chunkSize: 64 * 1024).reportProgress(reportFn: progress), size: buffer.readableBytes)
                } else {
                    body = .asyncSequence(buffer.asyncSequence(chunkSize: 64 * 1024), size: buffer.readableBytes)
                }
                group.addTask {
                    // Multipart uploads part numbers start at 1 not 0
                    let request = S3.UploadPartRequest(
                        body: body,
                        bucket: input.bucket,
                        key: input.key,
                        partNumber: index + 1,
                        requestPayer: input.requestPayer,
                        sseCustomerAlgorithm: input.sseCustomerAlgorithm,
                        sseCustomerKey: input.sseCustomerKey,
                        sseCustomerKeyMD5: input.sseCustomerKeyMD5,
                        uploadId: uploadId
                    )
                    let uploadOutput = try await self.uploadPart(request, logger: logger, on: eventLoop)
                    let part = S3.CompletedPart(eTag: uploadOutput.eTag, partNumber: index + 1)

                    return (index, part)
                }
            }
            // if no parts were uploaded and this is not called from resumeMultipartUpload then
            // upload an empty part
            if count == 0, initialProgress == 0 {
                group.addTask {
                    let request = S3.UploadPartRequest(
                        body: .empty,
                        bucket: input.bucket,
                        key: input.key,
                        partNumber: 1,
                        requestPayer: input.requestPayer,
                        sseCustomerAlgorithm: input.sseCustomerAlgorithm,
                        sseCustomerKey: input.sseCustomerKey,
                        sseCustomerKeyMD5: input.sseCustomerKeyMD5,
                        uploadId: uploadId
                    )
                    let uploadOutput = try await self.uploadPart(request, logger: logger, on: eventLoop)
                    let part = S3.CompletedPart(eTag: uploadOutput.eTag, partNumber: 1)

                    return (0, part)
                }
            }
            do {
                while let element = try await group.next() {
                    results.append(element)
                }
            } catch {
                throw MultipartUploadError(error: error, completedParts: results.sorted { $0.0 < $1.0 }.map { $0.1 })
            }
            // construct final array and fill in elements
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension S3.ThreadPoolProvider {
    func create() async -> NIOThreadPool {
        switch self {
        case .createNew:
            return await withUnsafeContinuation { (cont: UnsafeContinuation<NIOThreadPool, Never>) in
                DispatchQueue.global(qos: .background).async {
                    let threadPool = NIOThreadPool(numberOfThreads: NonBlockingFileIO.defaultThreadPoolSize)
                    threadPool.start()
                    cont.resume(returning: threadPool)
                }
            }
        case .singleton:
            return await withUnsafeContinuation { (cont: UnsafeContinuation<NIOThreadPool, Never>) in
                DispatchQueue.global(qos: .background).async {
                    cont.resume(returning: .singleton)
                }
            }
        case .shared(let sharedPool):
            return sharedPool
        }
    }

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
