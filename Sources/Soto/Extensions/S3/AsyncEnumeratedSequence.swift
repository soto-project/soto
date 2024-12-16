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

/// An enumeration of the elements of an AsyncSequence.
///
/// `AsyncEnumeratedSequence` generates a sequence of pairs (*n*, *x*), where *n*s are
/// consecutive `Int` values starting at zero, and *x*s are the elements from an
/// base AsyncSequence.
///
/// To create an instance of `EnumeratedSequence`, call `enumerated()` on an
/// AsyncSequence.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
struct AsyncEnumeratedSequence<Base: AsyncSequence> {
    @usableFromInline
    let base: Base

    @usableFromInline
    init(_ base: Base) {
        self.base = base
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension AsyncEnumeratedSequence: AsyncSequence {
    typealias Element = (Int, Base.Element)

    struct AsyncIterator: AsyncIteratorProtocol {
        @usableFromInline
        var baseIterator: Base.AsyncIterator
        @usableFromInline
        var index: Int

        @usableFromInline
        init(baseIterator: Base.AsyncIterator) {
            self.baseIterator = baseIterator
            self.index = 0
        }

        @inlinable
        mutating func next() async rethrows -> AsyncEnumeratedSequence.Element? {
            let value = try await self.baseIterator.next().map { (self.index, $0) }
            self.index += 1
            return value
        }
    }

    @inlinable
    __consuming func makeAsyncIterator() -> AsyncIterator {
        .init(baseIterator: self.base.makeAsyncIterator())
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension AsyncEnumeratedSequence: Sendable where Base: Sendable {}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension AsyncSequence {
    /// Return an enumaterated AsyncSequence
    func enumerated() -> AsyncEnumeratedSequence<Self> { AsyncEnumeratedSequence(self) }
}
