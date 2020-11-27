//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import Foundation

struct CodeGeneratorCommand: ParsableCommand {
    @Option(name: .shortAndLong, help: "Folder to output service files to")
    var outputFolder: String = Self.defaultOutputFolder

    @Option(name: .shortAndLong, help: "Folder to find json model files")
    var inputFolder: String = Self.defaultInputFolder

    @Option(name: .shortAndLong, help: "Only output files for specified module")
    var module: String?

    @Flag(name: .long, inversion: .prefixedNo, help: "Output files")
    var output: Bool = true

    @Flag(name: [.customShort("f"), .customLong("format")], inversion: .prefixedNo, help: "Run swift format on output")
    var swiftFormat: Bool = false

    @Flag(name: .shortAndLong, help: "Verbose logging")
    var verbose: Bool = false

    @Flag(name: .long, help: "HTML comments")
    var htmlComments: Bool = false

    static var rootPath: String {
        return #file
            .split(separator: "/", omittingEmptySubsequences: false)
            .dropLast(4)
            .map { String(describing: $0) }
            .joined(separator: "/")
    }

    static var defaultOutputFolder: String { return "\(rootPath)/Sources/Soto/Services" }
    static var defaultInputFolder: String { return "\(rootPath)/models" }

    func run() throws {
        try CodeGenerator(command: self).generate()
    }
}

CodeGeneratorCommand.main()
