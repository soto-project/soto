extension Metadata {
    struct Class : NominalType {

        static let kind: Kind? = .class
        var pointer: UnsafePointer<_Metadata._Class>

        var nominalTypeDescriptorOffsetLocation: Int {
            return is64BitPlatform ? 8 : 11
        }

        var superclass: Class? {
            guard let superclass = pointer.pointee.superclass else { return nil }
            return Metadata.Class(type: superclass)
        }
        
        func properties() throws -> [Property.Description] {
            let properties = try fetchAndSaveProperties(nominalType: self, hashedType: HashedType(pointer))
            guard let superclass = superclass, String(describing: unsafeBitCast(superclass.pointer, to: Any.Type.self)) != "SwiftObject" else {
                return properties
            }
            return try superclass.properties() + properties
        }

    }
}

extension _Metadata {
    struct _Class {
        var kind: Int
        var superclass: Any.Type?
    }
}
