//
//  Initializable.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/04.
//
//

import Foundation
import SWXMLHash
import SwiftyJSON

public protocol Initializable {
    init()
}

extension String {
    func upperFirst() -> String {
        return String(self[self.startIndex]).uppercased() + self.substring(from: self.index(after: self.startIndex))
    }
    
    func lowerFirst() -> String {
        return String(self[self.startIndex]).lowercased() + self.substring(from: self.index(after: self.startIndex))
    }
    
    func toSwiftVariableCase() -> String {
        return self.replacingOccurrences(of: "-", with: "_").camelCased().lowerFirst()
    }
    
    func camelCased() -> String {
        let items = self.components(separatedBy: "_")
        var camelCase = ""
        items.enumerated().forEach {
            camelCase += 0 == $0 ? $1 : $1.capitalized
        }
        return camelCase
    }
}
//
//public protocol XMLInitializable {
//    init()
//}
//
//extension XMLInitializable {
//    public init(xml: XMLIndexer) throws {
//        self.init()
//        
////        var mirror = Mirror(reflecting: self)
////        for (element, offset) in mirror.children.enumerated() {
////            mirror.children[mirror.children.startIndex] = Mirror.Child()
////            //mirror.children[e.offset].value = "hello"
////        }
////        print(mirror.children.first)
//    }
//}
//
//public protocol JSONInitializable {
//    init()
//}
//
//extension JSONInitializable {
//    public init(json: JSON) throws {
//        self.init()
//    }
//}
//
//
////func deserialize<T: Initializable>(fromXML xml: XMLIndexer) throws -> T {
////    var object = T()
////    
////    //NSClassFromString(<#T##aClassName: String##String#>)
////    
////    return object
////}
////
////func deserialize<T: Initializable>(fromJSON json: JSON) throws -> T {
////    var object = T()
////    return object
////}
