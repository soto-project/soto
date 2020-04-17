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

import Darwin.C
import Foundation

public class Glob {

    public static func entries(pattern: String) -> [String] {
        var files = [String]()
        var gt: glob_t = glob_t()
        let res = glob(pattern.cString(using: .utf8)!, 0, nil, &gt)
        if res != 0 {
            return files
        }

        for i in (0..<gt.gl_pathc) {
            let x = gt.gl_pathv[Int(i)]
            let c = UnsafePointer<CChar>(x)!
            let s = String.init(cString: c)
            files.append(s)
        }

        globfree(&gt)
        return files
    }
}

func rootPath() -> String {
    return #file
        .split(separator: "/", omittingEmptySubsequences: false)
        .dropLast(4)
        .map { String(describing: $0) }
        .joined(separator: "/")
}

func apiDirectories() -> [String] {
    return Glob.entries(pattern: "\(rootPath())/models/apis/**")
}

func loadEndpointJSON() throws -> Endpoints {
    let data = try Data(contentsOf: URL(string: "file://\(rootPath())/models/endpoints/endpoints.json")!)
    return try JSONDecoder().decode(Endpoints.self, from: data)
}

func loadModelJSON() throws -> [(api: API, docs: Docs, paginators: Paginators?)] {
    let directories = apiDirectories()

    return try directories.map {
        let apiFile = Glob.entries(pattern: $0 + "/**/api-*.json")[0]
        let docFile = Glob.entries(pattern: $0 + "/**/docs-*.json")[0]
        let data = try Data(contentsOf: URL(fileURLWithPath: apiFile))
        var api = try JSONDecoder().decode(API.self, from: data)
        try api.postProcess()

        let docData = try Data(contentsOf: URL(fileURLWithPath: docFile))
        let docs = try JSONDecoder().decode(Docs.self, from: docData)

        // a paginator file doesn't always exist
        let paginators: Paginators?
        if let paginatorFile = Glob.entries(pattern: $0 + "/**/paginators-*.json").first {
            let paginatorData = try Data(contentsOf: URL(string: "file://\(paginatorFile)")!)
            paginators = try JSONDecoder().decode(Paginators.self, from: paginatorData)
        } else {
            paginators = nil
        }
        return (api: api, docs: docs, paginators: paginators)
    }
}

func makeDirectory(_ dir: String) throws {
    try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
}
