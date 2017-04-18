//
//  AWSRequest.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/07.
//
//

import Foundation

public protocol AWSRequestMiddleware {
    func chain(request: AWSRequest) throws -> AWSRequest
}

public struct AWSRequest {
    public let region: Region
    public var url: URL
    public let service: String
    public let amzTarget: String?
    public let operation: String
    public let httpMethod: String
    public var httpHeaders: [String: Any?] = [:]
    public var body: Body
    public let middlewares: [AWSRequestMiddleware]
    
    public init(region: Region = .useast1, url: URL, service: String, amzTarget: String? = nil, operation: String, httpMethod: String, httpHeaders: [String: Any?] = [:], body: Body = .empty, middlewares: [AWSRequestMiddleware] = []) {
        self.region = region
        self.url = url
        self.service = service
        self.amzTarget = amzTarget
        self.operation = operation
        self.httpMethod = httpMethod
        self.httpHeaders = httpHeaders
        self.body = body
        self.middlewares = middlewares
    }
    
    public mutating func addValue(_ value: String, forHTTPHeaderField field: String) {
        httpHeaders[field] = value
    }
    
    func toURLRequest() throws -> URLRequest {
        var awsRequest = self
        for middleware in middlewares {
            awsRequest = try middleware.chain(request: awsRequest)
        }
        
        var request = URLRequest(url: awsRequest.url)
        request.httpMethod = awsRequest.httpMethod
        request.httpBody = try awsRequest.body.asData()
        
        if awsRequest.body.isJSON() {
            request.addValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        }
        
        if let target = awsRequest.amzTarget {
            request.addValue("\(target).\(awsRequest.operation)", forHTTPHeaderField: "x-amz-target")
        }
        
        for (key, value) in awsRequest.httpHeaders {
            guard let value = value else { continue }
            request.addValue("\(value)", forHTTPHeaderField: key)
        }
        
        if awsRequest.httpHeaders.filter({ $0.key.lowercased() == "content-type" }).first == nil {
            request.addValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        }
        
        return request
    }
}
