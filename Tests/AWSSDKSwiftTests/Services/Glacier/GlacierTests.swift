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
@testable import AWSGlacierMiddleware

class GlacierTests: XCTestCase {

    func testComputeTreeHash() throws {
        var z = 4
        var w = 23
        // Random number generator taken from https://www.codeproject.com/Articles/25172/Simple-Random-Number-Generation
        func simpleRNG() -> UInt8 {
            z = 36969 * (z & 65535) + (z >> 16);
            w = 18000 * (w & 65535) + (w >> 16);
            return UInt8(((z<<16)+w) & 0xff)
        }
        
        //  create buffer full of random data, use the same seeds to ensure we get the same buffer everytime
        let size = 7*1024*1024 + 258
        var data = Data(count: size)
        for i in 0..<size {
            data[i] = simpleRNG()
        }
        // create byte buffer
        var byteBuffer = ByteBufferAllocator().buffer(capacity: data.count)
        byteBuffer.writeBytes(data)
        
        let middleware = GlacierRequestMiddleware(apiVersion: "2012-06-01")
        let treeHash = try middleware.computeTreeHash(byteBuffer)
        
        XCTAssertEqual(treeHash, [210, 50, 5, 126, 16, 6, 59, 6, 21, 40, 186, 74, 192, 56, 39, 85, 210, 25, 238, 54, 4, 252, 221, 238, 107, 127, 76, 118, 245, 76, 22, 45])
    }
    
}
