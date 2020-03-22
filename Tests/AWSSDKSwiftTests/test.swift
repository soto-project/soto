//
// test.swift
// written by Adam Fowler
// helper functions for tests
//
import XCTest
import NIO
import AWSSDKSwiftCore

func attempt(function : () throws -> ()) {
    do {
        try function()
    } catch let error as AWSErrorType {
        XCTFail(error.description)
    } catch DecodingError.typeMismatch(let type, let context) {
        print(type, context)
        XCTFail()
    } catch let error as NIO.ChannelError {
        XCTFail("\(error)")
    } catch {
        XCTFail("\(error)")
    }
}
