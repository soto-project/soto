//===----------------------------------------------------------------------===//
//
// This source file is part of the AWSSDKSwift open source project
//
// Copyright (c) 2017-2020 the AWSSDKSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of AWSSDKSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import AWSSDKSwiftCore
import Foundation
import NIO

//MARK: Multipart

extension S3ErrorType {
    public enum multipart: Error {
        case noUploadId
        case downloadEmpty(message: String)
        case failedToOpen(file: String)
        case failedToWrite(file: String)
        case failedToRead(file: String)
    }
}

extension S3 {

    public enum ThreadPoolProvider {
        case createNew
        case shared(NIOThreadPool)
    }

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
        on eventLoop: EventLoop,
        outputStream: @escaping (ByteBuffer, Int64, EventLoop) -> EventLoopFuture<Void>
    ) -> EventLoopFuture<Int64> {

        let promise = eventLoop.makePromise(of: Int64.self)

        // function downloading part of a file
        func multipartDownloadPart(fileSize: Int64, offset: Int64, prevPartSave: EventLoopFuture<Void>) {
            // have we downloaded everything
            guard fileSize > offset else {
                prevPartSave.map { fileSize }.cascade(to: promise)
                return
            }

            let range = "bytes=\(offset)-\(offset + Int64(partSize - 1))"
            let getRequest = S3.GetObjectRequest(
                bucket: input.bucket,
                key: input.key,
                range: range,
                sSECustomerAlgorithm: input.sSECustomerAlgorithm,
                sSECustomerKey: input.sSECustomerKey,
                sSECustomerKeyMD5: input.sSECustomerKeyMD5,
                versionId: input.versionId
            )
            getObject(getRequest, on: eventLoop)
                .and(prevPartSave)
                .map { (output, _) -> () in
                    // should never happen
                    guard let body = output.body, let byteBuffer = body.asByteBuffer() else {
                        return promise.fail(S3ErrorType.multipart.downloadEmpty(message: "Body is unexpectedly nil"))
                    }
                    guard let length = output.contentLength, length > 0 else {
                        return promise.fail(S3ErrorType.multipart.downloadEmpty(message: "Content length is unexpectedly zero"))
                    }

                    let newOffset = offset + Int64(partSize)
                    multipartDownloadPart(fileSize: fileSize, offset: newOffset, prevPartSave: outputStream(byteBuffer, fileSize, eventLoop))
            }.cascadeFailure(to: promise)
        }

        // get object size before downloading
        let headRequest = S3.HeadObjectRequest(
            bucket: input.bucket,
            ifMatch: input.ifMatch,
            ifModifiedSince: input.ifModifiedSince,
            ifNoneMatch: input.ifNoneMatch,
            ifUnmodifiedSince: input.ifUnmodifiedSince,
            key: input.key,
            requestPayer: input.requestPayer,
            sSECustomerAlgorithm: input.sSECustomerAlgorithm,
            sSECustomerKey: input.sSECustomerKey,
            sSECustomerKeyMD5: input.sSECustomerKeyMD5,
            versionId: input.versionId
        )
        headObject(headRequest, on: eventLoop)
            .map { (object) -> Void in
                guard let contentLength = object.contentLength else {
                    return promise.fail(S3ErrorType.multipart.downloadEmpty(message: "Content length is unexpectedly zero"))
                }
                // download file
                multipartDownloadPart(fileSize: contentLength, offset: 0, prevPartSave: eventLoop.makeSucceededFuture(()))
        }.cascadeFailure(to: promise)

        return promise.futureResult
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
        on eventLoop: EventLoop? = nil,
        threadPoolProvider: ThreadPoolProvider = .createNew,
        progress: @escaping (Double) throws -> Void = { _ in }
    ) -> EventLoopFuture<Int64> {
        let eventLoop = eventLoop ?? self.client.eventLoopGroup.next()

        let threadPool: NIOThreadPool
        switch threadPoolProvider {
        case .createNew:
            threadPool = NIOThreadPool(numberOfThreads: 1)
            threadPool.start()
        case .shared(let sharedPool):
            threadPool = sharedPool
        }
        let fileIO = NonBlockingFileIO(threadPool: threadPool)

        return fileIO.openFile(path: filename, mode: .write, flags: .allowFileCreation(), eventLoop: eventLoop).flatMap {
            (fileHandle) -> EventLoopFuture<Int64> in
            var progressValue: Int64 = 0

            let download = self.multipartDownload(input, partSize: partSize, on: eventLoop) { byteBuffer, fileSize, eventLoop in
                let bufferSize = byteBuffer.readableBytes
                return fileIO.write(fileHandle: fileHandle, buffer: byteBuffer, eventLoop: eventLoop).flatMapThrowing { _ in
                    progressValue += Int64(bufferSize)
                    try progress(Double(progressValue) / Double(fileSize))
                }
            }

            download.whenComplete { _ in
                if case .createNew = threadPoolProvider {
                    threadPool.shutdownGracefully() { _ in }
                }
            }
            return
                download
                .flatMapErrorThrowing { error in
                    try fileHandle.close()
                    throw error
                }
                .flatMapThrowing { rt in
                    try fileHandle.close()
                    return rt
                }
        }
    }

    /// Multipart upload of file to S3.
    ///
    /// - parameters:
    ///     - input: The CreateMultipartUploadRequest structure that contains the details about the upload
    ///     - on: an EventLoop to process each part to upload
    ///     - inputStream: The function supplying the data parts to the multipartUpload. Each parts must be at least 5MB in size expect the last one which has no size limit.
    /// - returns: An EventLoopFuture that will receive a CompleteMultipartUploadOutput once the multipart upload has finished.
    public func multipartUpload(
        _ input: CreateMultipartUploadRequest,
        on eventLoop: EventLoop,
        inputStream: @escaping (EventLoop) -> EventLoopFuture<ByteBuffer>
    ) -> EventLoopFuture<CompleteMultipartUploadOutput> {

        // initialize multipart upload
        let result = createMultipartUpload(input, on: eventLoop).flatMap { upload -> EventLoopFuture<CompleteMultipartUploadOutput> in
            guard let uploadId = upload.uploadId else {
                return eventLoop.makeFailedFuture(S3ErrorType.multipart.noUploadId)
            }
            // upload all the parts
            return self.multipartUploadParts(input, uploadId: uploadId, on: eventLoop, inputStream: inputStream)
                .flatMap { parts -> EventLoopFuture<CompleteMultipartUploadOutput> in
                    let request = S3.CompleteMultipartUploadRequest(
                        bucket: input.bucket,
                        key: input.key,
                        multipartUpload: S3.CompletedMultipartUpload(parts: parts),
                        requestPayer: input.requestPayer,
                        uploadId: uploadId
                    )
                    return self.completeMultipartUpload(request, on: eventLoop)
                }
                .flatMapErrorThrowing { error in
                    // if failure then abort the multipart upload
                    let request = S3.AbortMultipartUploadRequest(
                        bucket: input.bucket,
                        key: input.key,
                        requestPayer: input.requestPayer,
                        uploadId: uploadId
                    )
                    _ = self.abortMultipartUpload(request, on: eventLoop)
                    throw error
                }
        }
        return result
    }

    /// Multipart upload of file to S3.
    ///
    /// - parameters:
    ///     - input: The CreateMultipartUploadRequest structure that contains the details about the upload
    ///     - partSize: Size of each part to upload. This has to be at least 5MB
    ///     - filename: Name of file to upload
    ///     - on: EventLoop to process parts for upload, if nil an eventLoop is taken from the clients eventLoopGroup
    ///     - progress: Callback that returns the progress of the upload. It is called after each part is uploaded with a value between 0.0 and 1.0 indicating how far the upload is complete (1.0 meaning finished).
    /// - returns: An EventLoopFuture that will receive a CompleteMultipartUploadOutput once the multipart upload has finished.
    public func multipartUpload(
        _ input: CreateMultipartUploadRequest,
        partSize: Int = 5 * 1024 * 1024,
        filename: String,
        on eventLoop: EventLoop? = nil,
        threadPoolProvider: ThreadPoolProvider = .createNew,
        progress: @escaping (Double) throws -> Void = { _ in }
    ) -> EventLoopFuture<CompleteMultipartUploadOutput> {
        let eventLoop = eventLoop ?? self.client.eventLoopGroup.next()

        let byteBufferAllocator = ByteBufferAllocator()
        let threadPool: NIOThreadPool
        switch threadPoolProvider {
        case .createNew:
            threadPool = NIOThreadPool(numberOfThreads: 1)
            threadPool.start()
        case .shared(let sharedPool):
            threadPool = sharedPool
        }
        let fileIO = NonBlockingFileIO(threadPool: threadPool)

        return fileIO.openFile(path: filename, eventLoop: eventLoop).flatMap {
            (fileHandle, fileRegion) -> EventLoopFuture<CompleteMultipartUploadOutput> in
            var progressAmount: Int64 = 0
            var prevProgressAmount: Int64 = 0

            let fileSize = fileRegion.readableBytes

            let upload = self.multipartUpload(input, on: eventLoop) { eventLoop in
                eventLoop.submit {
                    try progress(Double(prevProgressAmount) / Double(fileSize))
                }.flatMap { _ in
                    return fileIO.read(fileHandle: fileHandle, byteCount: partSize, allocator: byteBufferAllocator, eventLoop: eventLoop)
                }.map { buffer in
                    prevProgressAmount = progressAmount
                    progressAmount += Int64(buffer.readableBytes)
                    return buffer
                }
            }

            upload.whenComplete { _ in
                try? progress(Double(prevProgressAmount) / Double(fileSize))
                if case .createNew = threadPoolProvider {
                    threadPool.shutdownGracefully() { _ in }
                }
            }
            return
                upload
                .flatMapErrorThrowing { error in
                    try fileHandle.close()
                    throw error
                }
                .flatMapThrowing { rt in
                    try fileHandle.close()
                    return rt
                }
        }
    }
}

extension S3 {
    /// used internally in multipartUpload, loads all the parts once the multipart upload has been initiated
    func multipartUploadParts(
        _ input: CreateMultipartUploadRequest,
        uploadId: String,
        on eventLoop: EventLoop,
        inputStream: @escaping (EventLoop) -> EventLoopFuture<ByteBuffer>
    ) -> EventLoopFuture<[S3.CompletedPart]> {
        let promise = eventLoop.makePromise(of: [S3.CompletedPart].self)
        var completedParts: [S3.CompletedPart] = []
        // function uploading part of a file and queueing up upload of the next part
        func multipartUploadPart(partNumber: Int, uploadId: String, body: ByteBuffer) {
            let request = S3.UploadPartRequest(
                body: .byteBuffer(body),
                bucket: input.bucket,
                contentLength: Int64(body.readableBytes),
                key: input.key,
                partNumber: partNumber,
                requestPayer: input.requestPayer,
                sSECustomerAlgorithm: input.sSECustomerAlgorithm,
                sSECustomerKey: input.sSECustomerKey,
                sSECustomerKeyMD5: input.sSECustomerKeyMD5,
                uploadId: uploadId
            )
            // request upload future
            let uploadResult = self.uploadPart(request, on: eventLoop).map { output -> [S3.CompletedPart] in
                let part = S3.CompletedPart(eTag: output.eTag, partNumber: partNumber)
                completedParts.append(part)
                return completedParts
            }

            // load data EventLoopFuture
            inputStream(eventLoop)
                .and(uploadResult)
                .map { (data, parts) -> Void in
                    guard data.readableBytes > 0 else {
                        return promise.succeed(parts)
                    }
                    multipartUploadPart(partNumber: partNumber + 1, uploadId: uploadId, body: data)
            }.cascadeFailure(to: promise)
        }

        // read first block and initiate first upload with result
        inputStream(eventLoop).map { (buffer) -> Void in
            guard buffer.readableBytes > 0 else {
                return promise.succeed([])
            }
            // Multipart uploads part numbers start at 1 not 0
            multipartUploadPart(partNumber: 1, uploadId: uploadId, body: buffer)
        }.cascadeFailure(to: promise)

        return promise.futureResult
    }
}
