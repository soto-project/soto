//
//  Util.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/26.
//
//

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
    return Glob.entries(pattern: "\(rootPath())/models/apis/*")
}

func loadEndpointJSON() throws -> JSON {
    let data = try Data(contentsOf: URL(string: "file://\(rootPath())/models/endpoints/endpoints.json")!)
    return JSON(data: data)
}

func loadModelJSON() throws -> [(api:JSON, paginator:JSON, doc: JSON)] {
    let directories = apiDirectories()

    return try directories.map {
        let apiFile = Glob.entries(pattern: $0+"/**/api-*.json")[0]
        let docFile = Glob.entries(pattern: $0+"/**/docs-*.json")[0]
        // a paginator file doesn't always exist
        let paginatorFile = Glob.entries(pattern: $0+"/**/paginators-*.json").first
        
        var apiJson = JSON(data: try Data(contentsOf: URL(string: "file://\(apiFile)")!))
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
