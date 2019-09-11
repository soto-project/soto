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
    "Backup" : [
        // Backup clashes with a macOS framework, so need to rename the framework
        Patch(.replace, entry:["serviceName"], value:"AWSBackup", originalValue:"Backup")
    ],
    "DirectoryService" : [
        // DirectoryService clashes with a macOS framework, so need to rename the framework
        Patch(.replace, entry:["serviceName"], value:"AWSDirectoryService", originalValue:"DirectoryService")
    ],
    "ECS" : [
        Patch(.add, entry:["shapes", "PropagateTags", "enum"], value:"NONE")
    ],
    "EC2" : [
        Patch(.replace, entry:["shapes", "PlatformValues", "enum", 0], value:"windows", originalValue:"Windows")
    ],
    "ELB" : [
        Patch(.replace, entry:["shapes", "SecurityGroupOwnerAlias", "type"], value:"integer", originalValue:"string")
    ],
    "Route53": [
        Patch(.remove, entry:["shapes", "ListHealthChecksResponse", "required"], value:"Marker"),
        Patch(.remove, entry:["shapes", "ListHostedZonesResponse", "required"], value:"Marker"),
        Patch(.remove, entry:["shapes", "ListReusableDelegationSetsResponse", "required"], value:"Marker")
    ],
    "S3": [
        Patch(.replace, entry:["shapes","ReplicationStatus","enum",0], value:"COMPLETED", originalValue:"COMPLETE"),
        Patch(.replace, entry:["shapes","Size","type"], value:"long", originalValue:"integer"),
        Patch(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"us-east-2"),
        Patch(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"eu-west-2"),
        Patch(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"eu-west-3"),
        Patch(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"eu-north-1"),
        Patch(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"ap-east-1"),
        Patch(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"ap-northeast-2"),
        Patch(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"ap-northeast-3"),
        Patch(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"ca-central-1"),
        Patch(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"cn-northwest-1"),
        Patch(.add, entry:["shapes", "BucketLocationConstraint", "enum"], value:"me-south-1")
    ]
]

// structure defining a model patch
struct Patch {
    enum Operation {
        case replace
        case add
        case remove
    }

    init(_ operation: Operation, entry: [JSONSubscriptType], value: String, originalValue: String? = nil) {
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
            fatalError("Attempting to patch field \(patch.entry) that doesn't eixst")
        }

        switch patch.operation {
        case .replace:
            if let originalValue = patch.originalValue {
                guard originalValue.description == field.stringValue else {
                    fatalError("Found an unexpected value while patching \(patch.entry). Expected \"\(originalValue)\", got \"\(field.stringValue)\"")
                }
            }

            patchedJSON[patch.entry].object = patch.value
            
        case .add:
            guard let array = field.array else {
                fatalError("Attempting to add a field to \(patch.entry) that cannot be added to.")
            }

            guard array.first(where:{$0.stringValue == patch.value.description}) == nil else {
                fatalError("Attempting to add field \"\(patch.value)\" to array \(patch.entry) that aleady exists.")
            }

            var newArray = field.arrayObject!
            newArray.append(patch.value)
            patchedJSON[patch.entry].arrayObject = newArray

        case .remove:
            if let array = field.array {
                guard let firstIndex = array.firstIndex(where:{$0.stringValue == patch.value.description}) else {
                    fatalError("Attempting to remove field \"\(patch.value)\" from array \(patch.entry) that doesn't exists.")
                }
                
                var newArray = field.arrayObject!
                newArray.remove(at: firstIndex)
                patchedJSON[patch.entry].arrayObject = newArray
            } else if let dictionary = field.dictionary {
                guard dictionary[patch.value.description] != nil else {
                    fatalError("Attempting to remove field \"\(patch.value)\" from dictionary \(patch.entry) that doesn't exists.")
                }
                
                var newDictionary = field.dictionaryObject!
                newDictionary[patch.value.description] = nil
                patchedJSON[patch.entry].dictionaryObject = newDictionary
            } else {
                fatalError("Attempting to remove a field from \(patch.entry) that cannot be removed from.")
            }
        }
    }
    return patchedJSON
}
