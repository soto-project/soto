//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2023 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore
import NIOPosix

/// An AsyncSequence that returns the contents of a file in fixed size ByteBuffers
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct FileByteBufferAsyncSequence: AsyncSequence {
    public typealias Element = ByteBuffer

    let fileHandle: NIOFileHandle
    let fileIO: NonBlockingFileIO
    let chunkSize: Int
    let byteBufferAllocator: ByteBufferAllocator

    public init(
        _ fileHandle: NIOFileHandle,
        fileIO: NonBlockingFileIO,
        chunkSize: Int,
        byteBufferAllocator: ByteBufferAllocator = ByteBufferAllocator()
    ) {
        self.fileHandle = fileHandle
        self.fileIO = fileIO
        self.chunkSize = chunkSize
        self.byteBufferAllocator = byteBufferAllocator
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        let fileHandle: NIOFileHandle
        var offset: Int = 0
        let chunkSize: Int
        let fileIO: NonBlockingFileIO
        let byteBufferAllocator: ByteBufferAllocator

        public mutating func next() async throws -> ByteBuffer? {
            let byteBuffer = try await self.fileIO.read(
                fileHandle: self.fileHandle,
                fromOffset: Int64(self.offset),
                byteCount: 64 * 1024,
                allocator: self.byteBufferAllocator
            )
            let size = byteBuffer.readableBytes
            guard size > 0 else {
                return nil
            }
            self.offset += size
            return byteBuffer
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        .init(
            fileHandle: self.fileHandle,
            chunkSize: self.chunkSize,
            fileIO: self.fileIO,
            byteBufferAllocator: self.byteBufferAllocator
        )
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
// Cannot set this to Sendable as it contains a `NIOFileHandle` but the context that this is
// used in is a fairly limited situation and will not cause an issue
extension FileByteBufferAsyncSequence: @unchecked Sendable {}
