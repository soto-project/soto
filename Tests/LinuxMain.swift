import XCTest
@testable import AWSSDKSwiftTests

XCTMain([
     testCase(APIGatewayTests.allTests),
     testCase(AWSRequestTests.allTests),
     testCase(IAMTests.allTests),
     testCase(DynamoDBTests.allTests),
     testCase(S3Tests.allTests),
     testCase(SNSTests.allTests),
     testCase(SQSTests.allTests),
])
