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

enum PatchKeyPathError: Error {
    case doesNotExist
}

protocol PatchKeyPath {
    associatedtype Base
    associatedtype Value
    
    func get(_ object: Base) -> Value?
    func set(_ object: inout Base, value: Value)
}

struct PatchKeyPath1<Object, U>: PatchKeyPath {
    typealias Base = Object
    typealias Value = U

    let keyPath1: WritableKeyPath<Object, U>
    
    init(_ keyPath1: WritableKeyPath<Object, U>) {
        self.keyPath1 = keyPath1
    }
    
    func get(_ object: Object) -> U? { return object[keyPath: keyPath1] }
    func set(_ object: inout Object, value: U) { object[keyPath: keyPath1] = value }
}

struct PatchKeyPath2<Object, U: Patchable, V>: PatchKeyPath {
    typealias Base = Object
    typealias Value = V

    let keyPath1: KeyPath<Object, U?>
    let keyPath2: WritableKeyPath<U, V>
    
    init(_ keyPath1: KeyPath<Object, U?>, _ keyPath2: WritableKeyPath<U, V>) {
        self.keyPath1 = keyPath1
        self.keyPath2 = keyPath2
    }
    
    func get(_ object: Object) -> V? {
        guard let object1 = object[keyPath: keyPath1] else { return nil }
        return object1[keyPath: keyPath2]
    }
    
    func set(_ object: inout Object, value: V) {
        guard var object1 = object[keyPath: keyPath1] else { return }
        object1[keyPath: keyPath2] = value
    }
}

struct PatchKeyPath3<Object, U: Patchable, V: Patchable, W>: PatchKeyPath {
    typealias Base = Object
    typealias Value = W

    let keyPath1: KeyPath<Object, U?>
    let keyPath2: KeyPath<U, V?>
    let keyPath3: WritableKeyPath<V, W>
    
    init(_ keyPath1: KeyPath<Object, U?>, _ keyPath2: KeyPath<U, V?>, _ keyPath3: WritableKeyPath<V, W>) {
        self.keyPath1 = keyPath1
        self.keyPath2 = keyPath2
        self.keyPath3 = keyPath3
    }
    
    func get(_ object: Object) -> W? {
        guard let object1 = object[keyPath: keyPath1] else { return nil }
        guard let object2 = object1[keyPath: keyPath2] else { return nil }
        return object2[keyPath: keyPath3]
    }
    
    func set(_ object: inout Object, value: W) {
        guard let object1 = object[keyPath: keyPath1] else { return }
        guard var object2 = object1[keyPath: keyPath2] else { return }
        object2[keyPath: keyPath3] = value
    }
}

struct PatchKeyPath4<Object, U: Patchable, V: Patchable, W: Patchable, X>: PatchKeyPath {
    typealias Base = Object
    typealias Value = X

    let keyPath1: KeyPath<Object, U?>
    let keyPath2: KeyPath<U, V?>
    let keyPath3: KeyPath<V, W?>
    let keyPath4: WritableKeyPath<W, X>
    
    init(_ keyPath1: KeyPath<Object, U?>, _ keyPath2: KeyPath<U, V?>, _ keyPath3: KeyPath<V, W?>, _ keyPath4: WritableKeyPath<W, X>) {
        self.keyPath1 = keyPath1
        self.keyPath2 = keyPath2
        self.keyPath3 = keyPath3
        self.keyPath4 = keyPath4
    }
    
    func get(_ object: Object) -> X? {
        guard let object1 = object[keyPath: keyPath1] else { return nil }
        guard let object2 = object1[keyPath: keyPath2] else { return nil }
        guard let object3 = object2[keyPath: keyPath3] else { return nil }
        return object3[keyPath: keyPath4]
    }
    
    func set(_ object: inout Object, value: X) {
        guard let object1 = object[keyPath: keyPath1] else { return }
        guard let object2 = object1[keyPath: keyPath2] else { return }
        guard var object3 = object2[keyPath: keyPath3] else { return }
        object3[keyPath: keyPath4] = value
    }
}

protocol PatchBase {
}

extension PatchBase {
    subscript<P: PatchKeyPath, T>(patchKeyPath patchKeyPath: P) -> T? where P.Base == Self, P.Value == T {
        get { patchKeyPath.get(self) }
        set(newValue) { newValue.map { patchKeyPath.set(&self, value: $0) } }
    }
}
