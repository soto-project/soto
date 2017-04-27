import XCTest
@testable import AWSSDKSwiftTests

XCTMain([
     testCase(SerializableTests.allTests),
     testCase(SignersV4TestsTests.allTests),
     testCase(XML2ParserTests.allTests),
     testCase(S3Tests.allTests),
     testCase(DynamoDBTests.allTests)
])
