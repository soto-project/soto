//
//  Client.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/13.
//
//

import Foundation
import Dispatch
import SwiftyJSON

public struct AWSRequest {
    
    let signer: Signers.V4
    
    let amzTarget: String?
    
    let _endpoint: String?
    
    public var endpoint: String {
        let nameseparator = signer.service == "s3" ? "-" : "."
        return self._endpoint ?? "https://\(signer.service)\(nameseparator)\(signer.region.rawValue).amazonaws.com"
    }
    
    public init(accessKeyId: String? = nil, secretAccessKey: String? = nil, region: Core.Region?, amzTarget: String? = nil, service: String, endpoint: String? = nil) {
        let cred: CredentialProvider
        if let scred = SharedCredential.default {
            cred = scred
        } else {
            if let accessKey = accessKeyId, let secretKey = secretAccessKey {
                cred = Credential(accessKeyId: accessKey, secretAccessKey: secretKey)
            } else if let ecred = EnvironementCredential() {
                cred = ecred
            } else {
                cred = Credential(accessKeyId: "", secretAccessKey: "")
            }
        }
        
        self.signer = Signers.V4(credentials: cred, region: region ?? .useast1, service: service)
        self._endpoint = endpoint
        self.amzTarget = amzTarget
    }
    
    public func invoke(operation: String, path: String, httpMethod: String, httpHeaders: [String: Any?] = [:], input: Serializable?) throws -> (Data, HTTPURLResponse) {
        let url = URL(string: "\(endpoint)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        
        switch httpMethod {
        case "GET":
            // http://docs.aws.amazon.com/ja_jp/AmazonS3/latest/API/sigv4-query-string-auth.html
            request.addValue(url.host!, forHTTPHeaderField: "Host")
            request.url = signer.signedURLWithQueryParams(url: url)
            
        default:
            guard let input = input else {
                break
            }
            
            let data = try JSONSerializer().serialize(input.serialize())
            request.addValue("\(data.count)", forHTTPHeaderField: "Content-Length")
            request.httpBody = data
            
            let httpHeaders = signer.signedHeaders(url: url, bodyDigest: sha256(data).hexdigest(), method: httpMethod)
            
            if let target = self.amzTarget {
                request.addValue("\(target).\(operation)", forHTTPHeaderField: "x-amz-target")
            }
            
            for (key, value) in httpHeaders {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        for (key, value) in httpHeaders {
            guard let value = value else {
                continue
            }
            request.addValue("\(value)", forHTTPHeaderField: key)
        }
        
        request.addValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        
        return try URLSession.shared.resumeSync(request)
    }
}

extension URLSession {
    func resumeSync(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        var _data: Data?
        var _response: HTTPURLResponse?
        var _error: Error?
        
        // TODO should use mutex
        let g = DispatchGroup()
        g.enter()
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            _data = data
            _response = response as? HTTPURLResponse
            _error = error
            g.leave()
        }
        task.resume()
        g.wait()
        
        if let error = _error {
            throw error
        }
        
        return (_data!, _response!)
    }
}
