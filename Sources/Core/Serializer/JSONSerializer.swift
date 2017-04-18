//
//  JSONSerializable.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/23.
//
//

import Foundation
import SwiftyJSON

struct JSONSerializer {
    public func serialize(_ dictionary: [String: Any]) throws -> Data {
        var dictionary = dictionary
        // TODO Should recursive check.
        for (key, value) in dictionary {
            switch value {
            case let v as Date:
                dictionary[key] = "\(v)"
                
            default:
                break
            }
        }
        
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: JSONSerialization.WritingOptions(rawValue: 0))
        
        guard let json = String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\\", with: "") else {
            return Data()
        }
        
        return json.data(using: .utf8) ?? Data()
    }
}
