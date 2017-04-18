//
//  AWSShape.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/12.
//
//

public protocol AWSShape: DictionarySerializable, XMLNodeSerializable, Initializable {
    var pathParams: [String: String] { get }
    var headerParams: [String: String] { get }
    var queryParams: [String: String] { get }
    var _payload: String? { get }
}

extension AWSShape {
    public var pathParams: [String: String] {
        return [:]
    }
    
    public var headerParams: [String: String] {
        return [:]
    }
    
    public var queryParams: [String: String] {
        return [:]
    }
}

