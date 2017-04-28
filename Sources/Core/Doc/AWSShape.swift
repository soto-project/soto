//
//  AWSShape.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/12.
//
//

public protocol AWSShape: DictionarySerializable, XMLNodeSerializable, InitializableFromDictionary {
    static var pathParams: [String: String] { get }
    static var headerParams: [String: String] { get }
    static var queryParams: [String: String] { get }
    static var payload: String? { get }
}

extension AWSShape {
    public static var pathParams: [String: String] {
        return [:]
    }
    
    public static var headerParams: [String: String] {
        return [:]
    }
    
    public static var queryParams: [String: String] {
        return [:]
    }
}

