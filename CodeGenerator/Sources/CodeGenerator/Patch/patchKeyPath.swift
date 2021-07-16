//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2021 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Protocol for PatchKeyPath objects. Contains a base object and the value object the key path references.
///
/// This is required because you cannot have a `WriteableKeyPath` referencing a object that has optionals
/// in the middle of the key path. Because the key path may contain optionals the `get` method returns an optional
/// value. The `set`does nothing if it finds a nil optional.
protocol PatchKeyPath {
    associatedtype Base
    associatedtype Value

    func get(_ object: Base) -> Value?
    func set(_ object: inout Base, value: Value)
}

/// Patch key path containing one key path
struct PatchKeyPath1<Object, U>: PatchKeyPath {
    typealias Base = Object
    typealias Value = U

    let keyPath1: WritableKeyPath<Object, U>

    init(_ keyPath1: WritableKeyPath<Object, U>) {
        self.keyPath1 = keyPath1
    }

    func get(_ object: Object) -> U? { return object[keyPath: self.keyPath1] }
    func set(_ object: inout Object, value: U) { object[keyPath: self.keyPath1] = value }
}

/// Patch key path containing two key paths
struct PatchKeyPath2<Object, U, V>: PatchKeyPath {
    typealias Base = Object
    typealias Value = V

    let keyPath1: WritableKeyPath<Object, U?>
    let keyPath2: WritableKeyPath<U, V>

    init(_ keyPath1: WritableKeyPath<Object, U?>, _ keyPath2: WritableKeyPath<U, V>) {
        self.keyPath1 = keyPath1
        self.keyPath2 = keyPath2
    }

    func get(_ object: Object) -> V? {
        return object[keyPath: self.keyPath1]?[keyPath: self.keyPath2]
    }

    func set(_ object: inout Object, value: V) {
        object[keyPath: self.keyPath1]?[keyPath: self.keyPath2] = value
    }
}

/// Patch key path containing three key paths
struct PatchKeyPath3<Object, U, V, W>: PatchKeyPath {
    typealias Base = Object
    typealias Value = W

    let keyPath1: WritableKeyPath<Object, U?>
    let keyPath2: WritableKeyPath<U, V?>
    let keyPath3: WritableKeyPath<V, W>

    init(_ keyPath1: WritableKeyPath<Object, U?>, _ keyPath2: WritableKeyPath<U, V?>, _ keyPath3: WritableKeyPath<V, W>) {
        self.keyPath1 = keyPath1
        self.keyPath2 = keyPath2
        self.keyPath3 = keyPath3
    }

    func get(_ object: Object) -> W? {
        return object[keyPath: self.keyPath1]?[keyPath: self.keyPath2]?[keyPath: self.keyPath3]
    }

    func set(_ object: inout Object, value: W) {
        object[keyPath: self.keyPath1]?[keyPath: self.keyPath2]?[keyPath: self.keyPath3] = value
    }
}

/// Patch key path containing four key paths
struct PatchKeyPath4<Object, U, V, W, X>: PatchKeyPath {
    typealias Base = Object
    typealias Value = X

    let keyPath1: WritableKeyPath<Object, U?>
    let keyPath2: WritableKeyPath<U, V?>
    let keyPath3: WritableKeyPath<V, W?>
    let keyPath4: WritableKeyPath<W, X>

    init(_ keyPath1: WritableKeyPath<Object, U?>, _ keyPath2: WritableKeyPath<U, V?>, _ keyPath3: WritableKeyPath<V, W?>, _ keyPath4: WritableKeyPath<W, X>) {
        self.keyPath1 = keyPath1
        self.keyPath2 = keyPath2
        self.keyPath3 = keyPath3
        self.keyPath4 = keyPath4
    }

    func get(_ object: Object) -> X? {
        return object[keyPath: self.keyPath1]?[keyPath: self.keyPath2]?[keyPath: self.keyPath3]?[keyPath: self.keyPath4]
    }

    func set(_ object: inout Object, value: X) {
        object[keyPath: self.keyPath1]?[keyPath: self.keyPath2]?[keyPath: self.keyPath3]?[keyPath: self.keyPath4] = value
    }
}
