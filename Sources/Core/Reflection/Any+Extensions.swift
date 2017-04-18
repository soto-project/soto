//
//  Any+Extensions.swift
//  Reflection
//
//  Created by Bradley Hilton on 10/17/16.
//
//

protocol AnyExtensions {}

extension AnyExtensions {
    
    static func construct(constructor: (Property.Description) throws -> Any) throws -> Any {
        return try Core.construct(self, constructor: constructor)
    }
    
    static func construct(dictionary: [String: Any]) throws -> Any {
        return try Core.construct(self, dictionary: dictionary)
    }
    
    static func isValueTypeOrSubtype(_ value: Any) -> Bool {
        return value is Self
    }
    
    static func value(from storage: UnsafeRawPointer) -> Any {
        return storage.assumingMemoryBound(to: self).pointee
    }
    
    static func write(_ value: Any, to storage: UnsafeMutableRawPointer) throws {
        guard let this = value as? Self else {
            throw ReflectionError.valueIsNotType(value: value, type: self)
        }
        storage.assumingMemoryBound(to: self).initialize(to: this)
    }
    
}

func extensions(of type: Any.Type) -> AnyExtensions.Type {
    struct Extensions : AnyExtensions {}
    var extensions: AnyExtensions.Type = Extensions.self
    withUnsafePointer(to: &extensions) { pointer in
        UnsafeMutableRawPointer(mutating: pointer).assumingMemoryBound(to: Any.Type.self).pointee = type
    }
    return extensions
}

func extensions(of value: Any) -> AnyExtensions {
    struct Extensions : AnyExtensions {}
    var extensions: AnyExtensions = Extensions()
    withUnsafePointer(to: &extensions) { pointer in
        UnsafeMutableRawPointer(mutating: pointer).assumingMemoryBound(to: Any.self).pointee = value
    }
    return extensions
}
