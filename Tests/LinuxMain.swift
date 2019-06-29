import XCTest
@testable import AWSSDKSwiftTests

XCTMain([
     testCase(S3Tests.allTests),
     testCase(DynamoDBTests.allTests),
     testCase(AWSRequestTests.allTests)
])
