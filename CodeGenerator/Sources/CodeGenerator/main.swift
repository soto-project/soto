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

import ArgumentParser
import Foundation

struct CodeGeneratorCommand: ParsableCommand {
    
    @Option(name: .shortAndLong, default: Self.defaultOutputFolder, help: "Folder to output service files to")
    var outputFolder: String
    
    @Option(name: .shortAndLong, default: Self.defaultInputFolder, help: "Folder to find json model files")
    var inputFolder: String
    
    @Option(name: .shortAndLong, help: "Only output files for specified module")
    var module: String?
    
    @Flag(name: .long, default: true, inversion: .prefixedNo, help: "Output files")
    var output: Bool
    
    static var rootPath: String {
        return #file
            .split(separator: "/", omittingEmptySubsequences: false)
            .dropLast(4)
            .map { String(describing: $0) }
            .joined(separator: "/")
    }
    static var defaultOutputFolder: String { return "\(rootPath)/Sources/AWSSDKSwift/Services" }
    static var defaultInputFolder: String { return "\(rootPath)/models" }

    func run() throws {
        try CodeGenerator(command: self).generate()
    }
}

CodeGeneratorCommand.main()
