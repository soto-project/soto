//
//  Credential.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/05.
//
//

import Foundation

public protocol CredentialProvider {
    var accessKeyId: String { get }
    var secretAccessKey: String { get }
}

public struct SharedCredential: CredentialProvider {
    
    static var `default`: Credential?
    
    public let accessKeyId: String
    public let secretAccessKey: String
    
    public init(filename: String = "~/.aws/credentials", profile: String = "default") throws {
        fatalError("Umimplemented")
        //let content = try String(contentsOfFile: filename)
    }
}

public struct Credential: CredentialProvider {
    public let accessKeyId: String
    public let secretAccessKey: String
    
    public init(accessKeyId: String, secretAccessKey: String) {
        self.accessKeyId = accessKeyId
        self.secretAccessKey = secretAccessKey
    }
}

struct EnvironementCredential: CredentialProvider {
    let accessKeyId: String
    let secretAccessKey: String
    
    init?() {
        guard let accessKeyId = ProcessInfo.processInfo.environment["AWS_ACCESS_KEY_ID"] else {
            return nil
        }
        guard let secretAccessKey = ProcessInfo.processInfo.environment["AWS_SECRET_ACCESS_KEY"] else {
            return nil
        }
        self.accessKeyId = accessKeyId
        self.secretAccessKey = secretAccessKey
    }
}

