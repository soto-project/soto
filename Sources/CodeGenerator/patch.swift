//
//  Patch.swift
//  AWSSDKSwift - CodeGenerator
//
//  Created by Adam Fowler 2019/5/16
//  Patches the JSON AWS model files as they are loaded into the CodeGenerator
//
import Foundation
import SwiftyJSON

//
// Patch operations
//
let servicePatches : [String: [Patch]] = [
    // Backup clashes with a macOS framework, so need to rename the framework
    "Backup" : [
        Patch(operation:.replace, entry:["serviceName"], value:"AWSBackup", originalValue:"Backup")
    ],
    // DirectoryService clashes with a macOS framework, so need to rename the framework
    "DirectoryService" : [
        Patch(operation:.replace, entry:["serviceName"], value:"AWSDirectoryService", originalValue:"DirectoryService")
    ],
    "ECS" : [
        Patch(operation:.add, entry:["shapes", "PropagateTags", "enum"], value:"NONE")
    ],
    "EC2" : [
        Patch(operation:.replace, entry:["shapes", "PlatformValues", "enum", 0], value:"windows", originalValue:"Windows")
    ],
    "ELB" : [
        Patch(operation:.replace, entry:["shapes", "SecurityGroupOwnerAlias", "type"], value:"integer", originalValue:"string")
    ],
    "S3": [
        Patch(operation:.replace, entry:["shapes","ReplicationStatus","enum",0], value:"COMPLETED", originalValue:"COMPLETE"),
        Patch(operation:.replace, entry:["shapes","Size","type"], value:"long", originalValue:"integer")
    ]
]

// structure defining a model patch
struct Patch {
    enum Operation {
        case replace
        case add
    }

    init(operation: Operation, entry: [JSONSubscriptType], value: String, originalValue: String? = nil) {
        self.operation = operation
        self.entry = entry
        self.value = value
        self.originalValue = originalValue
    }

    let operation : Operation
    let entry : [JSONSubscriptType]
    let value : CustomStringConvertible
    let originalValue : CustomStringConvertible?
}

/// patch model JSON
func patch(_ apiJSON: JSON) -> JSON {
    let service = apiJSON["serviceName"].stringValue.toSwiftClassCase()
    guard let patches = servicePatches[service] else {return apiJSON}
    var patchedJSON = apiJSON

    for patch in patches {
        let field = patchedJSON[patch.entry]
        guard field != JSON.null else {
            print("Attempting to patch field \(patch.entry) that doesn't eixst")
            exit(-1)
        }

        switch patch.operation {
        case .replace:
            if let originalValue = patch.originalValue {
                guard originalValue.description == field.stringValue else {
                    print("Found an unexpected value while patching \(patch.entry). Expected \"\(originalValue)\", got \"\(field.stringValue)\"")
                    exit(-1)
                }
            }

            patchedJSON[patch.entry].object = patch.value
        case .add:
            guard let array = field.array else {
                print("Attempting to add a field to \(patch.entry) that cannot be added to.")
                exit(-1)
            }

            guard array.first(where:{$0.stringValue == patch.value.description}) == nil else {
                print("Attempting to add field \"\(patch.value)\" to array \(patch.entry) that aleady exists.")
                exit(-1)
            }

            var newArray = field.arrayObject!
            newArray.append(patch.value)
            patchedJSON[patch.entry].arrayObject = newArray
        }
    }
    return patchedJSON
}
