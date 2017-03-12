//
//  Bytes.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/13.
//
//

import Foundation

extension UInt8 {
    public func hexdigest() -> String {
        return String(format: "%02x", self)
    }
}

extension Collection where Self.Iterator.Element == UInt8 {
    public func hexdigest() -> String {
        return self.map({ $0.hexdigest() }).joined()
    }
}
