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

/// An AsyncSequence that reports the amount of ByteBuffer provided via its iterator
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
struct ReportProgressByteBufferAsyncSequence<Base: AsyncSequence>: AsyncSequence where Base.Element == ByteBuffer {
    typealias Element = ByteBuffer

    let base: Base
    let reportFn: @Sendable (Int) async throws -> Void

    struct AsyncIterator: AsyncIteratorProtocol {
        @usableFromInline
        var iterator: Base.AsyncIterator
        @usableFromInline
        let reportFn: @Sendable (Int) async throws -> Void

        @usableFromInline
        init(iterator: Base.AsyncIterator, reportFn: @Sendable @escaping (Int) async throws -> Void) {
            self.iterator = iterator
            self.reportFn = reportFn
        }

        @inlinable
        public mutating func next() async throws -> ByteBuffer? {
            if let buffer = try await self.iterator.next() {
                try await self.reportFn(buffer.readableBytes)
                return buffer
            }
            return nil
        }
    }

    /// Make async iterator
    __consuming func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(iterator: self.base.makeAsyncIterator(), reportFn: self.reportFn)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension ReportProgressByteBufferAsyncSequence: Sendable where Base: Sendable {}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension AsyncSequence where Element == ByteBuffer {
    /// Return an AsyncSequence that returns ByteBuffers of a fixed size
    /// - Parameter chunkSize: Size of each chunk
    func reportProgress(reportFn: @Sendable @escaping (Int) async throws -> Void) -> ReportProgressByteBufferAsyncSequence<Self> {
        .init(base: self, reportFn: reportFn)
    }
}
