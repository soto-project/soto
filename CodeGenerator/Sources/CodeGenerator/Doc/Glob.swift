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

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

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
