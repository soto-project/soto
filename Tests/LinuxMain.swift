//===----------------------------------------------------------------------===//
//
// This source file is part of the AWSSDKSwift open source project
//
// Copyright (c) 2020 the AWSSDKSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of AWSSDKSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import XCTest

@testable import AWSSDKSwiftTests

XCTMain([
    testCase(APIGatewayTests.allTests),
    testCase(AWSRequestTests.allTests),
    testCase(DynamoDBTests.allTests),
    testCase(IAMTests.allTests),
    testCase(S3Tests.allTests),
    testCase(SNSTests.allTests),
    testCase(SQSTests.allTests),
    testCase(SSMTests.allTests),
    testCase(STSTests.allTests),
])
