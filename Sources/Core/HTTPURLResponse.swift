//
//  HTTPURLResponse.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/16.
//
//

import Foundation

enum ContentType {
    case json
    case xml
    case octetStream
}

extension HTTPURLResponse {
    func contentType() -> ContentType? {
        if let contentType = allHeaderFields.filter({ $0.key.description.lowercased() == "content-type" }).first {
            if "\(contentType.value)".lowercased().contains("octet-stream") {
                return .octetStream
            }
            
            if "\(contentType.value)".lowercased().contains("json") {
                return .json
            }
            
            if "\(contentType.value)".lowercased().contains("xml") {
                return .xml
            }
        }
        
        return nil
    }
}
