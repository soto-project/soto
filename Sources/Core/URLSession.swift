//
//  URLSession.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/17.
//
//

import Foundation

extension URLSession {
    func resumeSync(_ request: URLRequest, cond: Cond) throws -> (Data, HTTPURLResponse) {
        var _data: Data?
        var _response: HTTPURLResponse?
        var _error: Error?
        
        cond.mutex.lock()
        defer {
            cond.mutex.unlock()
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            _data = data
            _response = response as? HTTPURLResponse
            _error = error
            cond.signal()
        }
        task.resume()
        cond.wait()
        
        if let error = _error {
            throw error
        }
        
        return (_data!, _response!)
    }
}
