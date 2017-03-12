//
//  Operation.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/22.
//
//

import SwiftyJSON

struct Operation {
    let name: String
    let httpMethod: String
    let path: String
    let inputShapeName: String?
    let outputShapeName: String?
}
