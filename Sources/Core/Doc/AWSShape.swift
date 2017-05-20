//
//  AWSShape.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/12.
//
//

public protocol AWSShape: DictionaryConvertible, XMLNodeSerializable {
    static var payload: String? { get }
}

extension AWSShape {
    public static var pathParams: [String: String] {
        var params: [String: String] = [:]
        parsingHints.forEach {
            if let location = $0.location {
                switch location {
                case .uri(locationName: let name):
                    params[name] = $0.label
                default:
                    break
                }
            }
        }
        return params
    }
    
    public static var headerParams: [String: String] {
        var params: [String: String] = [:]
        parsingHints.forEach {
            if let location = $0.location {
                switch location {
                case .header(locationName: let name):
                    params[name] = $0.label
                default:
                    break
                }
            }
        }
        return params
    }
    
    public static var queryParams: [String: String] {
        var params: [String: String] = [:]
        parsingHints.forEach {
            if let location = $0.location {
                switch location {
                case .querystring(locationName: let name):
                    params[name] = $0.label
                default:
                    break
                }
            }
        }
        return params
    }
}
