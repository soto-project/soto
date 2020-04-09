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

import Foundation
import SwiftyJSON

func rootPath() -> String {
    return #file
        .split(separator: "/", omittingEmptySubsequences: false)
        .dropLast(4)
        .map { String(describing: $0) }
        .joined(separator: "/")
}

func apiDirectories() -> [String] {
    return Glob.entries(pattern: "\(rootPath())/models/apis/s3")
}

func loadEndpointJSON() throws -> JSON {
    let data = try Data(contentsOf: URL(string: "file://\(rootPath())/models/endpoints/endpoints.json")!)
    return JSON(data: data)
}

func loadEndpointJSONV2() throws -> Endpoints {
    let data = try Data(contentsOf: URL(string: "file://\(rootPath())/models/endpoints/endpoints.json")!)
    return try JSONDecoder().decode(Endpoints.self, from: data)
}

func loadModelJSONV2() throws -> [(api: API, docs: Docs, paginators: Paginators?)] {
    let directories = apiDirectories()

    return try directories.map {
        let apiFile = Glob.entries(pattern: $0+"/**/api-*.json")[0]
        let docFile = Glob.entries(pattern: $0+"/**/docs-*.json")[0]
        let data = try Data(contentsOf: URL(fileURLWithPath: apiFile))
        var api = try JSONDecoder().decode(API.self, from: data)
        try api.postProcess()
        
        let docData = try Data(contentsOf: URL(fileURLWithPath: docFile))
        let docs = try JSONDecoder().decode(Docs.self, from: docData)
        
        // a paginator file doesn't always exist
        let paginators: Paginators?
        if let paginatorFile = Glob.entries(pattern: $0+"/**/paginators-*.json").first {
            let paginatorData = try Data(contentsOf: URL(string: "file://\(paginatorFile)")!)
            paginators = try JSONDecoder().decode(Paginators.self, from: paginatorData)
        } else {
            paginators = nil
        }
        return (api:api, docs:docs, paginators:paginators)
    }
}

func loadModelJSON() throws -> [(api:JSON, paginator:JSON, doc: JSON)] {
    let directories = apiDirectories()

    return try directories.map {
        let apiFile = Glob.entries(pattern: $0+"/**/api-*.json")[0]
        let docFile = Glob.entries(pattern: $0+"/**/docs-*.json")[0]
        // a paginator file doesn't always exist
        let paginatorFile = Glob.entries(pattern: $0+"/**/paginators-*.json").first
        let data = try Data(contentsOf: URL(fileURLWithPath: apiFile))
        var apiJson = JSON(data: data)
        apiJson["serviceName"].stringValue = serviceNameForApi(apiJSON: apiJson)
        let docJson = JSON(data: try Data(contentsOf: URL(string: "file://\(docFile)")!))
        let paginatorJson: JSON
        if let paginatorFile = paginatorFile {
            paginatorJson = JSON(data: try Data(contentsOf: URL(string: "file://\(paginatorFile)")!))
        } else {
            paginatorJson = JSON()
        }

        return (api: apiJson, paginator: paginatorJson, doc: docJson)
    }
}

// port of https://github.com/aws/aws-sdk-go-v2/blob/996478f06a00c31ee7e7b0c3ac6674ce24ba0120/private/model/api/api.go#L105
//
let stripServiceNamePrefixes: [String] = [
  "Amazon",
  "AWS",
]

func serviceNameForApi(apiJSON: JSON) -> String {
    var serviceNameJSON = apiJSON["metadata"]["serviceAbbreviation"]

    if serviceNameJSON == nil {
        serviceNameJSON = apiJSON["metadata"]["serviceFullName"]
    }

    var serviceName = serviceNameJSON.stringValue

    serviceName.trimCharacters(in: .whitespaces)

    // Strip out prefix names not reflected in service client symbol names.
    for prefix in stripServiceNamePrefixes {
        serviceName.deletePrefix(prefix)
    }

    // Remove all Non-letter/number values
    serviceName.removeCharacterSet(in: CharacterSet.alphanumerics.inverted)

    serviceName.removeWhitespaces()

    serviceName.capitalizeFirstLetter()

    return serviceName
}

func mkdirp(_ dir: String) -> Int32 {
    let process = Process()
    process.launchPath = "/bin/mkdir" // Mac and Linux
    process.arguments = ["-p", dir]
    process.launch()
    process.waitUntilExit()
    return process.terminationStatus
}

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }

    mutating func deletePrefix(_ prefix: String) {
        self = self.deletingPrefix(prefix)
    }

    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }

    mutating func removeWhitespaces() {
        self = self.removingWhitespaces()
    }

    func removingCharacterSet(in characterset: CharacterSet) -> String {
        return components(separatedBy: characterset).joined()
    }

    mutating func removeCharacterSet(in characterset: CharacterSet) {
        self = self.removingCharacterSet(in: characterset)
    }

    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }

    mutating func trimCharacters(in characterset: CharacterSet) {
        self = self.trimmingCharacters(in: characterset)
    }
}
