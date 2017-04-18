//
//  String.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/06.
//
//

extension String {
    func upperFirst() -> String {
        return String(self[self.startIndex]).uppercased() + self.substring(from: self.index(after: self.startIndex))
    }
}
