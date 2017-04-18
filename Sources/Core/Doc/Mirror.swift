//
//  Mirror.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/12.
//
//

import Foundation

extension Mirror {
    func getAttribute(forKey key: String) -> Any? {
        guard let matched = children.filter({ $0.label == key }).first else {
            return nil
        }
        guard let value = unwrap(any: matched.value) else {
            return nil
        }
        
        return value
    }
}
