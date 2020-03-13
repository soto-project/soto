//
//  GlacierTests.swift
//  AWSSDKSwift
//
//  Created by Adam Fowler 2020/01/28
//
//

import XCTest
import Foundation
import NIO
@testable import AWSGlacier

class GlacierTests: XCTestCase {

    // create a buffer of random values. Will always create the same given you supply the same z and w values
    // Random number generator from https://www.codeproject.com/Articles/25172/Simple-Random-Number-Generation
    func createRandomBuffer(_ w: UInt, _ z: UInt, size: Int) -> [UInt8] {
        var z = z
        var w = w
        func getUInt8() -> UInt8
        {
            z = 36969 * (z & 65535) + (z >> 16);
            w = 18000 * (w & 65535) + (w >> 16);
            return UInt8(((z << 16) + w) & 0xff);
        }
        var data = Array<UInt8>(repeating: 0, count: size)
        for i in 0..<size {
            data[i] = getUInt8()
        }
        return data
    }

    func testComputeTreeHash() throws {
        //  create buffer full of random data, use the same seeds to ensure we get the same buffer everytime
        let data = createRandomBuffer(23, 4, size: 7*1024*1024 + 258)

        let middleware = GlacierRequestMiddleware(apiVersion: "2012-06-01")
        let treeHash = middleware.computeTreeHash(Data(data))

        XCTAssertEqual(treeHash, [210, 50, 5, 126, 16, 6, 59, 6, 21, 40, 186, 74, 192, 56, 39, 85, 210, 25, 238, 54, 4, 252, 221, 238, 107, 127, 76, 118, 245, 76, 22, 45])
    }

}
