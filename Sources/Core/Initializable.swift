//
//  Initializable.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/06.
//
//

public protocol Initializable {
    init()
}

public protocol InitializableFromDictionary {
    init(dictionary: [String: Any]) throws
}

public enum InitializableError: Error {
    case missingRequiredParam(String)
    case convertingError
}

public func decode(dictionary: [String: Any]) -> [String: AWSShape] {
    return [:]
}
