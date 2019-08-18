//
//  Operation.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/22.
//
//

public struct Operation {
    public let name: String
    public let httpMethod: String
    public let path: String
    public let inputShape: Shape?
    public let outputShape: Shape?
    public let deprecatedMessage: String?
    
    public init(name: String, httpMethod: String, path: String, inputShape: Shape?, outputShape: Shape?, deprecatedMessage : String? = nil){
        self.name = name
        self.httpMethod = httpMethod
        self.path = path
        self.inputShape = inputShape
        self.outputShape = outputShape
        self.deprecatedMessage = deprecatedMessage
    }
}
