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

/// Base class for Patches. Would make this a protocol, except I cannot store these easily as it requires
/// an associated type restriction for the apply function
class Patch<Root> {
    func apply(to api: inout Root) throws {}
}

/// Protocol for objects that can be patched.
protocol PatchBase {}

extension PatchBase {
    /// extends object to include [patchKeyPath:] subscript
    subscript<P: PatchKeyPath, T>(patchKeyPath patchKeyPath: P) -> T? where P.Base == Self, P.Value == T {
        get { patchKeyPath.get(self) }
        set(newValue) { newValue.map { patchKeyPath.set(&self, value: $0) } }
    }
}

enum APIPatchError: Error {
    case doesNotExist
    case unexpectedValue(expected: String, got: String)
}

class ReplacePatch<Value: Equatable, P: PatchKeyPath, Root: PatchBase>: Patch<Root> where P.Base == Root, P.Value == Value {
    let patchKeyPath: P
    let value: Value
    let expectedValue: Value

    init(_ patchKeyPath: P, value: Value, originalValue: Value) {
        self.patchKeyPath = patchKeyPath
        self.value = value
        self.expectedValue = originalValue
    }

    override func apply(to api: inout Root) throws {
        guard let originalValue = api[patchKeyPath: patchKeyPath] else { throw APIPatchError.doesNotExist }
        guard originalValue == self.expectedValue else {
            throw APIPatchError.unexpectedValue(expected: "\(self.expectedValue)", got: "\(originalValue)")
        }
        api[patchKeyPath: self.patchKeyPath] = self.value
    }
}

class RemovePatch<Remove: Equatable, P: PatchKeyPath, Root: PatchBase>: Patch<Root> where P.Base == Root, P.Value == [Remove] {
    typealias Root = Root

    let patchKeyPath: P
    let value: Remove

    init(_ patchKeyPath: P, value: Remove) {
        self.patchKeyPath = patchKeyPath
        self.value = value
    }

    override func apply(to api: inout Root) throws {
        guard let array = api[patchKeyPath: patchKeyPath] else { throw APIPatchError.doesNotExist }
        guard let index = array.firstIndex(of: value) else { throw APIPatchError.doesNotExist }
        api[patchKeyPath: self.patchKeyPath]?.remove(at: index)
    }
}

class AddPatch<Remove: Equatable, P: PatchKeyPath, Root: PatchBase>: Patch<Root> where P.Base == Root, P.Value == [Remove] {
    typealias Root = Root

    let patchKeyPath: P
    let value: Remove

    init(_ patchKeyPath: P, value: Remove) {
        self.patchKeyPath = patchKeyPath
        self.value = value
    }

    override func apply(to api: inout Root) throws {
        guard let _ = api[patchKeyPath: patchKeyPath] else { throw APIPatchError.doesNotExist }
        api[patchKeyPath: self.patchKeyPath]?.append(self.value)
    }
}

class AddDictionaryPatch<Remove: Equatable, P: PatchKeyPath, Root: PatchBase>: Patch<Root> where P.Base == Root, P.Value == [String: Remove] {
    typealias Root = Root

    let patchKeyPath: P
    let key: String
    let value: Remove

    init(_ patchKeyPath: P, key: String, value: Remove) {
        self.patchKeyPath = patchKeyPath
        self.key = key
        self.value = value
    }

    override func apply(to api: inout Root) throws {
        guard let _ = api[patchKeyPath: patchKeyPath] else { throw APIPatchError.doesNotExist }
        api[patchKeyPath: self.patchKeyPath]?[self.key] = self.value
    }
}

extension Shape.ShapeType: Equatable {
    /// use to verify if shape types are the same when checking original values in replace patches
    static func == (lhs: Shape.ShapeType, rhs: Shape.ShapeType) -> Bool {
        switch lhs {
        case .string:
            if case .string = rhs { return true }
        case .integer:
            if case .integer = rhs { return true }
        case .structure:
            if case .structure = rhs { return true }
        case .list:
            if case .list = rhs { return true }
        case .map:
            if case .map = rhs { return true }
        case .blob:
            if case .blob = rhs { return true }
        case .payload:
            if case .payload = rhs { return true }
        case .long:
            if case .long = rhs { return true }
        case .double:
            if case .double = rhs { return true }
        case .float:
            if case .float = rhs { return true }
        case .timestamp:
            if case .timestamp = rhs { return true }
        case .boolean:
            if case .boolean = rhs { return true }
        case .enum:
            if case .enum = rhs { return true }
        case .stub:
            return false
        }
        return false
    }
}
