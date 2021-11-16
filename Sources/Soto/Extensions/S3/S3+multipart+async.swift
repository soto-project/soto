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

#if compiler(>=5.5) && canImport(_Concurrency)

import NIO
import SotoCore

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
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
            sSECustomerAlgorithm: input.sSECustomerAlgorithm,
            sSECustomerKey: input.sSECustomerKey,
            sSECustomerKeyMD5: input.sSECustomerKeyMD5,
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
                sSECustomerAlgorithm: input.sSECustomerAlgorithm,
                sSECustomerKey: input.sSECustomerKey,
                sSECustomerKeyMD5: input.sSECustomerKeyMD5,
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

        let threadPool: NIOThreadPool
        switch threadPoolProvider {
        case .createNew:
            threadPool = NIOThreadPool(numberOfThreads: 1)
            threadPool.start()
        case .shared(let sharedPool):
            threadPool = sharedPool
        }
        defer {
            if case .createNew = threadPoolProvider {
                threadPool.shutdownGracefully { _ in }
            }
        }

        let fileIO = NonBlockingFileIO(threadPool: threadPool)
        let fileHandle = try await fileIO.openFile(path: filename, mode: .write, flags: .allowFileCreation(), eventLoop: eventLoop).get()
        var progressValue: Int64 = 0

        let downloaded: Int64
        do {
            downloaded = try await self.multipartDownload(input, partSize: partSize, logger: logger, on: eventLoop) { byteBuffer, fileSize, eventLoop in
                let bufferSize = byteBuffer.readableBytes
                return fileIO.write(fileHandle: fileHandle, buffer: byteBuffer, eventLoop: eventLoop).flatMapThrowing { _ in
                    progressValue += Int64(bufferSize)
                    try progress(Double(progressValue) / Double(fileSize))
                }
            }.get()
        } catch {
            try fileHandle.close()
            throw error
        }
        try fileHandle.close()
        return downloaded
    }
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
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
        defer {
            threadPoolProvider.destory(threadPool)
        }
        let fileIO = NonBlockingFileIO(threadPool: threadPool)
        let (fileHandle, fileRegion) = try await fileIO.openFile(path: filename, eventLoop: eventLoop).get()

        logger.debug("Open file \(filename)")

        let uploadOutput: CompleteMultipartUploadOutput
        do {
            uploadOutput = try await uploadCallback(fileHandle, fileRegion, fileIO)
        } catch {
            try fileHandle.close()
            throw error
        }
        try fileHandle.close()
        return uploadOutput
    }
}
#endif // compiler(>=5.5) && canImport(_Concurrency)
