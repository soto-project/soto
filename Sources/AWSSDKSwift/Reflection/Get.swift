/// Get value for key from instance
public func get(_ key: String, from instance: Any) throws -> Any {
    guard let value = try properties(instance).first(where: { $0.key == key })?.value else {
        throw ReflectionError.instanceHasNoKey(type: type(of: instance), key: key)
    }
    return value
}

/// Get value for key from instance as type `T`
public func get<T>(_ key: String, from instance: Any) throws -> T {
    let any: Any = try get(key, from: instance)
    guard let value = any as? T else {
        throw ReflectionError.valueIsNotType(value: any, type: T.self)
    }
    return value
}
