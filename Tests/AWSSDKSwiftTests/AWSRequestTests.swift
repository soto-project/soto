//===----------------------------------------------------------------------===//
//
// This source file is part of the AWSSDKSwift open source project
//
// Copyright (c) 2017-2020 the AWSSDKSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of AWSSDKSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import XCTest

import AWSXML
@testable import AWSACM
@testable import AWSCloudFront
@testable import AWSEC2
@testable import AWSIAM
@testable import AWSRoute53
@testable import AWSS3
@testable import AWSSDKSwiftCore
@testable import AWSSES
@testable import AWSSNS

/// Tests to check the formatting of various AWSRequest bodies
class AWSRequestTests: XCTestCase {

    /// test awsRequest body is expected string
    func testRequestedBody(expected: String, result: AWSRequest) throws {
        // get body
        let body = result.body.asString()
        XCTAssertEqual(expected, body)
    }

    /// test
    func testAWSShapeRequest<Input: AWSEncodableShape>(
        client: AWSClient,
        operation: String,
        path: String = "/",
        httpMethod: String = "POST",
        input: Input,
        expected: String
    ) {
        do {
            let awsRequest = try client.createAWSRequest(operation: operation, path: path, httpMethod: httpMethod, input: input)
            var expected2 = expected

            // If XML remove whitespace from expected by converting to XMLNode and back
            if case .restxml = client.serviceProtocol {
                let document = try XML.Document(data: expected.data(using: .utf8)!)
                expected2 = document.xmlString
            }

            try testRequestedBody(expected: expected2, result: awsRequest)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// test validation
    func testAWSValidationFail<Input: AWSEncodableShape>(
        client: AWSClient,
        operation: String,
        path: String = "/",
        httpMethod: String = "POST",
        input: Input
    ) {
        do {
            _ = try client.createAWSRequest(operation: operation, path: path, httpMethod: httpMethod, input: input)
            XCTFail()
        } catch let error as AWSClientError where error == .validationError {
            print(error.message ?? "")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAWSValidationSuccess<Input: AWSEncodableShape>(
        client: AWSClient,
        operation: String,
        path: String = "/",
        httpMethod: String = "POST",
        input: Input
    ) {
        do {
            _ = try client.createAWSRequest(operation: operation, path: path, httpMethod: httpMethod, input: input)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testS3PutBucketLifecycleConfigurationRequest() {
        let s3 = S3(httpClientProvider: .createNew)
        defer {
            XCTAssertNoThrow(try s3.syncShutdown())
        }
        let expectedResult =
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?><LifecycleConfiguration xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\"><Rule><AbortIncompleteMultipartUpload><DaysAfterInitiation>7</DaysAfterInitiation></AbortIncompleteMultipartUpload><Status>Enabled</Status></Rule><Rule><Expiration><Days>30</Days><ExpiredObjectDeleteMarker>true</ExpiredObjectDeleteMarker></Expiration><Filter><Prefix>temp</Prefix></Filter><Status>Enabled</Status></Rule><Rule><Status>Enabled</Status><Transition><Days>20</Days><StorageClass>GLACIER</StorageClass></Transition><Transition><Days>180</Days><StorageClass>DEEP_ARCHIVE</StorageClass></Transition></Rule><Rule><NoncurrentVersionExpiration><NoncurrentDays>90</NoncurrentDays></NoncurrentVersionExpiration><Status>Disabled</Status></Rule></LifecycleConfiguration>"

        let abortRule = S3.LifecycleRule(abortIncompleteMultipartUpload: S3.AbortIncompleteMultipartUpload(daysAfterInitiation: 7), status: .enabled)
        let tempFileRule = S3.LifecycleRule(
            expiration: S3.LifecycleExpiration(days: 30, expiredObjectDeleteMarker: true),
            filter: S3.LifecycleRuleFilter(prefix: "temp"),
            status: .enabled
        )
        let glacierRule = S3.LifecycleRule(
            status: .enabled,
            transitions: [S3.Transition(days: 20, storageClass: .glacier), S3.Transition(days: 180, storageClass: .deepArchive)]
        )
        let versionsRule = S3.LifecycleRule(noncurrentVersionExpiration: S3.NoncurrentVersionExpiration(noncurrentDays: 90), status: .disabled)
        let rules = [abortRule, tempFileRule, glacierRule, versionsRule]
        let lifecycleConfiguration = S3.BucketLifecycleConfiguration(rules: rules)
        let request = S3.PutBucketLifecycleConfigurationRequest(bucket: "bucket", lifecycleConfiguration: lifecycleConfiguration)

        testAWSShapeRequest(
            client: s3.client,
            operation: "PutBucketLifecycleConfiguration",
            path: "/{Bucket}?lifecycle",
            httpMethod: "PUT",
            input: request,
            expected: expectedResult
        )
    }

    func testSNSCreateTopic() {
        let sns = SNS(httpClientProvider: .createNew)
        defer {
            XCTAssertNoThrow(try sns.syncShutdown())
        }
        let expectedResult =
            "Action=CreateTopic&Attributes.entry.1.key=TestAttribute&Attributes.entry.1.value=TestValue&Name=TestTopic&Tags.member.1.Key=tag1&Tags.member.1.Value=23&Tags.member.2.Key=tag2&Tags.member.2.Value=true&Version=2010-03-31"
        let request = SNS.CreateTopicInput(
            attributes: ["TestAttribute": "TestValue"],
            name: "TestTopic",
            tags: [SNS.Tag(key: "tag1", value: "23"), SNS.Tag(key: "tag2", value: "true")]
        )

        testAWSShapeRequest(client: sns.client, operation: "CreateTopic", path: "/", httpMethod: "POST", input: request, expected: expectedResult)
    }

    func testCloudFrontCreateDistribution() {
        let cloudFront = CloudFront(httpClientProvider: .createNew)
        defer {
            XCTAssertNoThrow(try cloudFront.syncShutdown())
        }
        let expectedResult =
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?><DistributionConfig xmlns=\"http://cloudfront.amazonaws.com/doc/2019-03-26/\"><CallerReference>test</CallerReference><Comment></Comment><DefaultCacheBehavior><ForwardedValues><Cookies><Forward>all</Forward></Cookies><QueryString>true</QueryString></ForwardedValues><MinTTL>1024</MinTTL><TargetOriginId>AWSRequestTests</TargetOriginId><TrustedSigners><Enabled>true</Enabled><Quantity>2</Quantity></TrustedSigners><ViewerProtocolPolicy>https-only</ViewerProtocolPolicy></DefaultCacheBehavior><Enabled>true</Enabled><Origins><Items><Origin><DomainName>aws.sdk.swift.com</DomainName><Id>1234</Id></Origin></Items><Quantity>1</Quantity></Origins></DistributionConfig>"

        let cookiePreference = CloudFront.CookiePreference(forward: .all)
        let forwardedValues = CloudFront.ForwardedValues(cookies: cookiePreference, queryString: true)
        let trustedSigners = CloudFront.TrustedSigners(enabled: true, quantity: 2)
        let defaultCacheBehavior = CloudFront.DefaultCacheBehavior(
            forwardedValues: forwardedValues,
            minTTL: 1024,
            targetOriginId: "AWSRequestTests",
            trustedSigners: trustedSigners,
            viewerProtocolPolicy: .httpsOnly
        )
        let origins = CloudFront.Origins(items: [CloudFront.Origin(domainName: "aws.sdk.swift.com", id: "1234")], quantity: 1)
        let distribution = CloudFront.DistributionConfig(
            callerReference: "test",
            comment: "",
            defaultCacheBehavior: defaultCacheBehavior,
            enabled: true,
            origins: origins
        )
        let request = CloudFront.CreateDistributionRequest(distributionConfig: distribution)

        testAWSShapeRequest(
            client: cloudFront.client,
            operation: "CreateDistribution2019_03_26",
            path: "/2019-03-26/distribution",
            httpMethod: "POST",
            input: request,
            expected: expectedResult
        )
    }

    func testEC2CreateImage() {
        let ec2 = EC2(httpClientProvider: .createNew)
        defer {
            XCTAssertNoThrow(try ec2.syncShutdown())
        }
        let expectedResult = "Action=CreateImage&InstanceId=i-123123&Name=TestInstance&Version=2016-11-15"
        let request = EC2.CreateImageRequest(instanceId: "i-123123", name: "TestInstance")

        testAWSShapeRequest(client: ec2.client, operation: "CreateImage", path: "/", httpMethod: "POST", input: request, expected: expectedResult)
    }

    func testEC2CreateInstanceExportTask() {
        let ec2 = EC2(httpClientProvider: .createNew)
        defer {
            XCTAssertNoThrow(try ec2.syncShutdown())
        }
        let expectedResult = "Action=CreateInstanceExportTask&ExportToS3.S3Bucket=testBucket&InstanceId=i-123123&Version=2016-11-15"
        let exportToS3Task = EC2.ExportToS3TaskSpecification(s3Bucket: "testBucket")
        let request = EC2.CreateInstanceExportTaskRequest(exportToS3Task: exportToS3Task, instanceId: "i-123123")

        testAWSShapeRequest(
            client: ec2.client,
            operation: "CreateInstanceExportTask",
            path: "/",
            httpMethod: "POST",
            input: request,
            expected: expectedResult
        )
    }

    func testIAMSimulateCustomPolicy() {
        let iam = IAM(httpClientProvider: .createNew)
        defer {
            XCTAssertNoThrow(try iam.syncShutdown())
        }
        let expectedResult =
            "Action=SimulateCustomPolicy&ActionNames.member.1=s3%2A&ActionNames.member.2=iam%2A&PolicyInputList.member.1=testPolicy&Version=2010-05-08"
        let request = IAM.SimulateCustomPolicyRequest(actionNames: ["s3*", "iam*"], policyInputList: ["testPolicy"])

        testAWSShapeRequest(client: iam.client, operation: "SimulateCustomPolicy", input: request, expected: expectedResult)
    }

    func testRoute53ChangeResourceRecordSetsRequest() {
        let route53 = Route53(httpClientProvider: .createNew)
        defer {
            XCTAssertNoThrow(try route53.syncShutdown())
        }
        let expectedResult = """
            <?xml version="1.0" encoding="UTF-8"?><ChangeResourceRecordSetsRequest xmlns="https://route53.amazonaws.com/doc/2013-04-01/"><ChangeBatch><Changes><Change><Action>CREATE</Action><ResourceRecordSet><Name>www</Name><Type>CNAME</Type></ResourceRecordSet></Change><Change><Action>UPSERT</Action><ResourceRecordSet><Name>dev</Name><Type>CNAME</Type></ResourceRecordSet></Change></Changes></ChangeBatch></ChangeResourceRecordSetsRequest>
            """
        let changes: [Route53.Change] = [
            .init(action: .create, resourceRecordSet: .init(name: "www", type: .cname)),
            .init(action: .upsert, resourceRecordSet: .init(name: "dev", type: .cname)),
        ]
        let changeBatch = Route53.ChangeBatch(changes: changes)
        let request = Route53.ChangeResourceRecordSetsRequest(changeBatch: changeBatch, hostedZoneId: "Zone")

        testAWSShapeRequest(client: route53.client, operation: "ChangeResourceRecordSets", input: request, expected: expectedResult)
    }

    func testSESSendEmail() {
        let ses = SES(httpClientProvider: .createNew)
        defer {
            XCTAssertNoThrow(try ses.syncShutdown())
        }
        let expectedResult =
            "Action=SendEmail&Destination.ToAddresses.member.1=them%40gmail.com&Message.Body.Text.Data=Testing%201%2C2%2C1%2C2&Message.Subject.Data=Testing&Source=me%40gmail.com&Version=2010-12-01"
        let destination = SES.Destination(toAddresses: ["them@gmail.com"])
        let message = SES.Message(body: SES.Body(text: SES.Content(data: "Testing 1,2,1,2")), subject: SES.Content(data: "Testing"))
        let request = SES.SendEmailRequest(destination: destination, message: message, source: "me@gmail.com")

        testAWSShapeRequest(client: ses.client, operation: "SendEmail", input: request, expected: expectedResult)
    }

    // VALIDATION TESTS

    func testS3GetObjectAclValidate() {
        // string length
        let s3 = S3(httpClientProvider: .createNew)
        defer {
            XCTAssertNoThrow(try s3.syncShutdown())
        }
        let request = S3.GetObjectAclRequest(bucket: "testbucket", key: "")
        testAWSValidationFail(client: s3.client, operation: "GetObjectAcl", input: request)
    }

    func testIAMAttachGroupPolicyValidate() {
        let iam = IAM(httpClientProvider: .createNew)
        defer {
            XCTAssertNoThrow(try iam.syncShutdown())
        }
        let client = iam.client
        // regular expression fail
        let request = IAM.AttachGroupPolicyRequest(groupName: ":MY:GROUP", policyArn: "arn://3948574985/unvalidated")
        testAWSValidationFail(client: client, operation: "AttachGroupPolicy", input: request)
        // string length
        let request2 = IAM.AttachGroupPolicyRequest(groupName: "MYGROUP", policyArn: "arn:tooshort")
        testAWSValidationFail(client: client, operation: "AttachGroupPolicy", input: request2)
        // regular expression success
        let request3 = IAM.AttachGroupPolicyRequest(groupName: "MY-GR_OU+P", policyArn: "arn://3948574985/unvalidated")
        testAWSValidationSuccess(client: client, operation: "AttachGroupPolicy", input: request3)
    }

    func testCloudFrontListTagsForResourceValidate() {
        // arn regular expressions, expect arn:aws(-cn)?:cloudfront::[0-9]+:.*
        let cloudFront = CloudFront(httpClientProvider: .createNew)
        defer {
            XCTAssertNoThrow(try cloudFront.syncShutdown())
        }
        let client = cloudFront.client
        let request = CloudFront.ListTagsForResourceRequest(resource: "test")
        testAWSValidationFail(client: client, operation: "ListTagsForResource", input: request)
        let request2 = CloudFront.ListTagsForResourceRequest(resource: "arn:aws::58979345:test")
        testAWSValidationFail(client: client, operation: "ListTagsForResource", input: request2)
        let request3 = CloudFront.ListTagsForResourceRequest(resource: "arn:aws:cloudfront::58979345")
        testAWSValidationFail(client: client, operation: "ListTagsForResource", input: request3)
        let successRequest = CloudFront.ListTagsForResourceRequest(resource: "arn:aws:cloudfront::58979345:test")
        testAWSValidationSuccess(client: client, operation: "ListTagsForResource", input: successRequest)
    }

    func testACMAddTagsToCertificateValidate() {
        // test validating array members
        let request = ACM.AddTagsToCertificateRequest(
            certificateArn: "arn:aws:acm:region:123456789012:certificate/12345678-1234-1234-1234-123456789012",
            tags: [ACM.Tag(key: "hello", value: "1"), ACM.Tag(key: "?hello?", value: "1")]
        )
        let acm = ACM(httpClientProvider: .createNew)
        defer {
            XCTAssertNoThrow(try acm.syncShutdown())
        }
        testAWSValidationFail(client: acm.client, operation: "AddTagsToCertificate", input: request)
    }

    func testCloudFrontCreateDistributionValidate() {
        let cookiePreference = CloudFront.CookiePreference(forward: .all)
        let forwardedValues = CloudFront.ForwardedValues(cookies: cookiePreference, queryString: true)
        let trustedSigners = CloudFront.TrustedSigners(enabled: true, quantity: 2)
        let defaultCacheBehavior = CloudFront.DefaultCacheBehavior(
            forwardedValues: forwardedValues,
            minTTL: 1024,
            targetOriginId: "AWSRequestTests",
            trustedSigners: trustedSigners,
            viewerProtocolPolicy: .httpsOnly
        )
        let origins = CloudFront.Origins(items: [], quantity: 0)
        let distribution = CloudFront.DistributionConfig(
            callerReference: "test",
            comment: "",
            defaultCacheBehavior: defaultCacheBehavior,
            enabled: true,
            origins: origins
        )
        let cloudFront = CloudFront(httpClientProvider: .createNew)
        defer {
            XCTAssertNoThrow(try cloudFront.syncShutdown())
        }
        let request = CloudFront.CreateDistributionRequest(distributionConfig: distribution)
        testAWSValidationFail(client: cloudFront.client, operation: "CreateDistribution", input: request)
    }
}
