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

public struct AWSClient {
    
    let signer: Signers.V4
    
    let amzTarget: String?
    
    let _endpoint: String?
    
    let serviceProtocol: ServiceProtocol
    
    private var cond = Cond()
    
    public let middlewares: [AWSRequestMiddleware]
    
    public var possibleErrorTypes: [AWSErrorType.Type]
    
    public var endpoint: String {
        let nameseparator = signer.service == "s3" ? "-" : "."
        return self._endpoint ?? "https://\(signer.service)\(nameseparator)\(signer.region.rawValue).amazonaws.com"
    }
    
    public init(accessKeyId: String? = nil, secretAccessKey: String? = nil, region: Core.Region?, amzTarget: String? = nil, service: String, serviceProtocol: ServiceProtocol, endpoint: String? = nil, middlewares: [AWSRequestMiddleware] = [], possibleErrorTypes: [AWSErrorType.Type]? = nil) {
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
        self.middlewares = middlewares
        self.serviceProtocol = serviceProtocol
        self.possibleErrorTypes = possibleErrorTypes ?? []
    }
    
    public func send(operation operationName: String, path: String, httpMethod: String, input: AWSShape) throws {
        let request = try createRequest(operation: operationName, path: path, httpMethod: httpMethod, input: input)
        _ = try self.request(request)
    }
    
    public func send(operation operationName: String, path: String, httpMethod: String) throws {
        let request = try createRequest(operation: operationName, path: path, httpMethod: httpMethod)
        _ = try self.request(request)
    }
    
    public func send<Output: AWSShape>(operation operationName: String, path: String, httpMethod: String) throws -> Output {
        let request = try createRequest(operation: operationName, path: path, httpMethod: httpMethod)
        let (data, urlResponse) = try self.request(request)
        return try validateResponse(bodyData: data, urlResponse: urlResponse)
    }
    
    public func send<Output: AWSShape>(operation operationName: String, path: String, httpMethod: String, input: AWSShape) throws -> Output {
        let request = try createRequest(operation: operationName, path: path, httpMethod: httpMethod, input: input)
        let (data, urlResponse) = try self.request(request)
        return try validateResponse(bodyData: data, urlResponse: urlResponse)
    }
    
    public func request(_ request: AWSRequest) throws -> (Data, HTTPURLResponse) {
        var urlRequest: URLRequest
        switch request.httpMethod {
        case "GET":
            var request = request
            // http://docs.aws.amazon.com/ja_jp/AmazonS3/latest/API/sigv4-query-string-auth.html
            request.addValue(request.url.host!, forHTTPHeaderField: "Host")
            request.url = signer.signedURL(url: request.url)
            urlRequest = try request.toURLRequest()
            
        default:
            urlRequest = try request.toURLRequest()
            let signedHeaders = signer.signedHeaders(
                url: urlRequest.url!,
                headers: urlRequest.allHTTPHeaderFields ?? [:],
                method: request.httpMethod,
                bodyData: urlRequest.httpBody ?? Data()
            )
            urlRequest.allHTTPHeaderFields = signedHeaders
        }
        
        return try URLSession.shared.resumeSync(urlRequest, cond: cond)
    }
    
    private func validateResponse<Output: AWSShape>(bodyData data: Data, urlResponse: HTTPURLResponse) throws -> Output {
        var responseBody: Body = .empty
        if !data.isEmpty, let contentType = urlResponse.contentType() {
            switch contentType {
            case .json:
                if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    responseBody = .json(dictionary)
                }
            case .xml:
                let xmlNode = try XML2Parser(data: data).parse()
                responseBody = .xml(xmlNode)
                
            case .octetStream:
                responseBody = .buffer(data)
            }
        }
        
        var responseHeaders: [String: String] = [:]
        for (key, value) in urlResponse.allHeaderFields {
            responseHeaders[key.description] = "\(value)"
        }
        
        guard (200..<300).contains(urlResponse.statusCode) else {
            var bodyDict = try responseBody.asDictionary() ?? [:]
            var code: String?
            var message: String?
            
            if responseBody.isXML() {
                let errorDict = bodyDict["Error"] as? [String: Any]
                code = errorDict?["Code"] as? String
                message = errorDict?["Message"] as? String
            }
            else if responseBody.isJSON() {
                code = bodyDict["__type"] as? String
                message = bodyDict.filter({ $0.key.lowercased() == "message" }).first?.value as? String
            }
            
            if let errorCode = code {
                for errorType in possibleErrorTypes {
                    if let error = errorType.init(errorCode: errorCode, message: message) {
                        throw error
                    }
                }
                
                if let error = AWSClientError(errorCode: errorCode, message: message) {
                    throw error
                }
                
                if let error = AWSServerError(errorCode: errorCode, message: message) {
                    throw error
                }
                
                throw AWSRawError(errorCode: errorCode, message: message)
            }
            
            throw AWSRawError(errorCode: "Unknown", message: nil)
        }
        
        var outputDict: [String: Any] = [:]
        var output = Output()
        switch responseBody {
        case .json(let dictionary):
            outputDict = dictionary
            
        case .xml(let node):
            let str = XMLNodeSerializer(node: node).serializeToJSON()
            outputDict = try JSONSerialization.jsonObject(with: str.data(using: .utf8)!, options: []) as? [String: Any] ?? [:]
            
        case .buffer(let data):
            if let payload = output._payload {
                outputDict[payload] = data
            }
            
        case .text(let text):
            if let payload = output._payload {
                outputDict[payload] = text
            }
            
        default:
            break
        }
        
        for (key, value) in urlResponse.allHeaderFields {
            if let param = output.headerParams.filter({ $0.key.lowercased() == key.description.lowercased() }).first {
                outputDict[param.key] = "\(value)"
            }
        }
        
        for (key, value) in outputDict {
            do { try set(value, key: key.toSwiftVariableCase(), for: &output) } catch {}
        }
        
        return output
    }
    
    private func createRequest(operation operationName: String, path: String, httpMethod: String, input: AWSShape? = nil) throws -> AWSRequest {
        
        var headers: [String: String] = [:]
        var body: Body = .empty
        var path = path
        var queryParams = [URLQueryItem]()
        
        if let input = input {
            let mirror = Mirror(reflecting: input)
            
            for (key, value) in input.headerParams {
                if let attr = mirror.getAttribute(forKey: value.toSwiftVariableCase()) {
                    headers[key] = "\(attr)"
                }
            }
            
            for (key, value) in input.queryParams {
                if let attr = mirror.getAttribute(forKey: value.toSwiftVariableCase()) {
                    queryParams.append(URLQueryItem(name: key, value: "\(attr)"))
                }
            }
            
            for (key, value) in input.pathParams {
                if let attr = mirror.getAttribute(forKey: value.toSwiftVariableCase()) {
                    path = path.replacingOccurrences(of: "{\(key)}", with: "\(attr)").replacingOccurrences(of: "{\(key)+}", with: "\(attr)")
                }
            }
            
            if !queryParams.isEmpty {
                let separator = path.contains("?") ? "&" : "?"
                path = path+separator+queryParams.asStringForURL
            }
            
            switch serviceProtocol {
            case .json:
                if let payload = input._payload, let payloadBody = mirror.getAttribute(forKey: payload.toSwiftVariableCase()) {
                    body = Body(anyValue: payloadBody)
                    headers.removeValue(forKey: payload.toSwiftVariableCase())
                } else {
                    body = .json(try input.serializeToDictionary())
                }
            case .query:
                break
            case .restxml:
                if let payload = input._payload, let payloadBody = mirror.getAttribute(forKey: payload.toSwiftVariableCase()) {
                    body = Body(anyValue: payloadBody)
                    headers.removeValue(forKey: payload.toSwiftVariableCase())
                } else {
                    body = .xml(try input.serializeToXMLNode())
                }
            }
        }
        
        return AWSRequest(
            region: self.signer.region,
            url: URL(string: "\(endpoint)\(path)")!,
            service: signer.service,
            amzTarget: amzTarget,
            operation: operationName,
            httpMethod: httpMethod,
            httpHeaders: headers,
            body: body,
            middlewares: middlewares
        )
    }
}
