//
//  Error.swift
//  AWSSDKSwift
//
//  Created by Adam Fowler on 2019/10/22.
//
//

public struct ErrorShape {
    public let name: String
    public let code: String?
    public let httpStatusCode: Int?
    
    public init(name: String, code: String?, httpStatusCode: Int?) {
        self.name = name
        self.code = code
        self.httpStatusCode = httpStatusCode
    }
}

