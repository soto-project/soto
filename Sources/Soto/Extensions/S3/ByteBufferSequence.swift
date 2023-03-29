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

#if compiler(>=5.5.2) && canImport(_Concurrency)

import NIOCore
import NIOPosix

/// Provide ByteBuffer as an AsyncSequence of equal size blocks
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
struct ByteBufferAsyncSequence: AsyncSequence, Sendable {
    typealias Element = ByteBuffer

    let byteBuffer: ByteBuffer
    let chunkSize: Int

    init(
        _ byteBuffer: ByteBuffer,
        chunkSize: Int
    ) {
        self.byteBuffer = byteBuffer
        self.chunkSize = chunkSize
    }

    struct AsyncIterator: AsyncIteratorProtocol {
        var byteBuffer: ByteBuffer
        let chunkSize: Int

        mutating func next() async throws -> ByteBuffer? {
            let size = Swift.min(self.chunkSize, self.byteBuffer.readableBytes)
            if size > 0 {
                return self.byteBuffer.readSlice(length: size)
            }
            return nil
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        .init(byteBuffer: self.byteBuffer, chunkSize: self.chunkSize)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension ByteBuffer {
    func asyncSequence(chunkSize: Int) -> ByteBufferAsyncSequence {
        return ByteBufferAsyncSequence(self, chunkSize: chunkSize)
    }
}

#endif // compiler(>=5.5.2) && canImport(_Concurrency)
