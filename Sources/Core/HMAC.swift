//
//  HMAC.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/13.
//
//

import Foundation
import CLibreSSL

func hmac(string: String, key: [UInt8]) -> [UInt8] {
    var context = HMAC_CTX()
    HMAC_Init_ex(&context, key, Int32(key.count), EVP_sha256(), nil)
    
    let bytes = Array(string.utf8)
    HMAC_Update(&context, bytes, bytes.count)
    var digest = [UInt8](repeating: 0, count: Int(EVP_MAX_MD_SIZE))
    var length: UInt32 = 0
    HMAC_Final(&context, &digest, &length)
    
    return Array(digest[0..<Int(length)])
}
