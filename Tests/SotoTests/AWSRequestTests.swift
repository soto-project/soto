//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import XCTest

@testable import SotoACM
@testable import SotoCloudFront
@testable import SotoCore
@testable import SotoEC2
@testable import SotoIAM
@testable import SotoRoute53
@testable import SotoS3
@testable import SotoS3Control
@testable import SotoSES
@testable import SotoSNS
import SotoXML

/// Tests to check the formatting of various AWSRequest bodies
class AWSRequestTests: XCTestCase {
    static let client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middlewares: TestEnvironment.middlewares, httpClientProvider: .createNew)

    /// test awsRequest body is expected string
    func testRequestedBody(expected: String, result: AWSRequest) throws {
        // get body
        let body = result.body.asString()
        XCTAssertEqual(expected, body)
    }

    /// test
    func testAWSShapeRequest<Input: AWSEncodableShape>(
        config: AWSServiceConfig,
        operation: String,
        path: String = "/",
        httpMethod: HTTPMethod = .POST,
        input: Input,
        expected: String
    ) {
        do {
            let awsRequest = try AWSRequest(operation: operation, path: path, httpMethod: httpMethod, input: input, configuration: config)
            var expected2 = expected

            // If XML remove whitespace from expected by converting to XMLNode and back
            if case .restxml = config.serviceProtocol {
                let document = try XML.Document(data: expected.data(using: .utf8)!)
                expected2 = document.xmlString
            }

            try self.testRequestedBody(expected: expected2, result: awsRequest)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// test validation
    func testAWSValidationFail<Input: AWSEncodableShape>(
        config: AWSServiceConfig,
        operation: String,
        path: String = "/",
        httpMethod: HTTPMethod = .POST,
        input: Input
    ) {
        do {
            _ = try AWSRequest(operation: operation, path: path, httpMethod: httpMethod, input: input, configuration: config)
            XCTFail()
        } catch let error as AWSClientError where error == .validationError {
            print(error.message ?? "")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAWSValidationSuccess<Input: AWSEncodableShape>(
        config: AWSServiceConfig,
        operation: String,
        path: String = "/",
        httpMethod: HTTPMethod = .POST,
        input: Input
    ) {
        do {
            _ = try AWSRequest(operation: operation, path: path, httpMethod: httpMethod, input: input, configuration: config)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testS3PutBucketLifecycleConfigurationRequest() {
        let s3 = S3(client: Self.client)
        let expectedResult =
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?><LifecycleConfiguration xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\"><Rule><AbortIncompleteMultipartUpload><DaysAfterInitiation>7</DaysAfterInitiation></AbortIncompleteMultipartUpload><Filter><Prefix></Prefix></Filter><Status>Enabled</Status></Rule><Rule><Expiration><Days>30</Days><ExpiredObjectDeleteMarker>true</ExpiredObjectDeleteMarker></Expiration><Filter><Prefix>temp</Prefix></Filter><Status>Enabled</Status></Rule><Rule><Filter><Prefix></Prefix></Filter><Status>Enabled</Status><Transition><Days>20</Days><StorageClass>GLACIER</StorageClass></Transition><Transition><Days>180</Days><StorageClass>DEEP_ARCHIVE</StorageClass></Transition></Rule><Rule><Filter><Prefix></Prefix></Filter><NoncurrentVersionExpiration><NoncurrentDays>90</NoncurrentDays></NoncurrentVersionExpiration><Status>Disabled</Status></Rule></LifecycleConfiguration>"

        let abortRule = S3.LifecycleRule(abortIncompleteMultipartUpload: S3.AbortIncompleteMultipartUpload(daysAfterInitiation: 7), filter: .init(prefix: ""), status: .enabled)
        let tempFileRule = S3.LifecycleRule(
            expiration: S3.LifecycleExpiration(days: 30, expiredObjectDeleteMarker: true),
            filter: S3.LifecycleRuleFilter(prefix: "temp"),
            status: .enabled
        )
        let glacierRule = S3.LifecycleRule(
            filter: .init(prefix: ""),
            status: .enabled,
            transitions: [S3.Transition(days: 20, storageClass: .glacier), S3.Transition(days: 180, storageClass: .deepArchive)]
        )
        let versionsRule = S3.LifecycleRule(filter: .init(prefix: ""), noncurrentVersionExpiration: S3.NoncurrentVersionExpiration(noncurrentDays: 90), status: .disabled)
        let rules = [abortRule, tempFileRule, glacierRule, versionsRule]
        let lifecycleConfiguration = S3.BucketLifecycleConfiguration(rules: rules)
        let request = S3.PutBucketLifecycleConfigurationRequest(bucket: "bucket", lifecycleConfiguration: lifecycleConfiguration)

        self.testAWSShapeRequest(
            config: s3.config,
            operation: "PutBucketLifecycleConfiguration",
            path: "/{Bucket}?lifecycle",
            httpMethod: .PUT,
            input: request,
            expected: expectedResult
        )
    }

    func testSNSCreateTopic() {
        let sns = SNS(client: Self.client)
        let expectedResult =
            "Action=CreateTopic&Attributes.entry.1.key=TestAttribute&Attributes.entry.1.value=TestValue&Name=TestTopic&Tags.member.1.Key=tag1&Tags.member.1.Value=23&Tags.member.2.Key=tag2&Tags.member.2.Value=true&Version=2010-03-31"
        let request = SNS.CreateTopicInput(
            attributes: ["TestAttribute": "TestValue"],
            name: "TestTopic",
            tags: [SNS.Tag(key: "tag1", value: "23"), SNS.Tag(key: "tag2", value: "true")]
        )

        self.testAWSShapeRequest(config: sns.config, operation: "CreateTopic", path: "/", httpMethod: .POST, input: request, expected: expectedResult)
    }

    func testCloudFrontCreateDistribution() {
        let cloudFront = CloudFront(client: Self.client)
        let expectedResult =
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?><DistributionConfig xmlns=\"http://cloudfront.amazonaws.com/doc/2020-05-31/\"><CallerReference>test</CallerReference><Comment></Comment><DefaultCacheBehavior><TargetOriginId>AWSRequestTests</TargetOriginId><TrustedSigners><Enabled>true</Enabled><Quantity>2</Quantity></TrustedSigners><ViewerProtocolPolicy>https-only</ViewerProtocolPolicy></DefaultCacheBehavior><Enabled>true</Enabled><Origins><Items><Origin><DomainName>aws.sdk.swift.com</DomainName><Id>1234</Id></Origin></Items><Quantity>1</Quantity></Origins></DistributionConfig>"

        let trustedSigners = CloudFront.TrustedSigners(enabled: true, quantity: 2)
        let defaultCacheBehavior = CloudFront.DefaultCacheBehavior(
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

        self.testAWSShapeRequest(
            config: cloudFront.config,
            operation: "CreateDistribution2019_03_26",
            path: "/2019-03-26/distribution",
            httpMethod: .POST,
            input: request,
            expected: expectedResult
        )
    }

    func testEC2CreateImage() {
        let ec2 = EC2(client: Self.client)
        let expectedResult = "Action=CreateImage&InstanceId=i-123123&Name=TestInstance&Version=2016-11-15"
        let request = EC2.CreateImageRequest(instanceId: "i-123123", name: "TestInstance")

        self.testAWSShapeRequest(config: ec2.config, operation: "CreateImage", path: "/", httpMethod: .POST, input: request, expected: expectedResult)
    }

    func testEC2CreateInstanceExportTask() {
        let ec2 = EC2(client: Self.client)
        let expectedResult = "Action=CreateInstanceExportTask&ExportToS3.S3Bucket=testBucket&InstanceId=i-123123&TargetEnvironment=vmware&Version=2016-11-15"
        let exportToS3Task = EC2.ExportToS3TaskSpecification(s3Bucket: "testBucket")
        let request = EC2.CreateInstanceExportTaskRequest(exportToS3Task: exportToS3Task, instanceId: "i-123123", targetEnvironment: .vmware)

        self.testAWSShapeRequest(
            config: ec2.config,
            operation: "CreateInstanceExportTask",
            path: "/",
            httpMethod: .POST,
            input: request,
            expected: expectedResult
        )
    }

    func testIAMSimulateCustomPolicy() {
        let iam = IAM(client: Self.client)
        let expectedResult =
            "Action=SimulateCustomPolicy&ActionNames.member.1=s3%2A&ActionNames.member.2=iam%2A&PolicyInputList.member.1=testPolicy&Version=2010-05-08"
        let request = IAM.SimulateCustomPolicyRequest(actionNames: ["s3*", "iam*"], policyInputList: ["testPolicy"])

        self.testAWSShapeRequest(config: iam.config, operation: "SimulateCustomPolicy", input: request, expected: expectedResult)
    }

    func testRoute53ChangeResourceRecordSetsRequest() {
        let route53 = Route53(client: Self.client)
        let expectedResult = """
        <?xml version="1.0" encoding="UTF-8"?><ChangeResourceRecordSetsRequest xmlns="https://route53.amazonaws.com/doc/2013-04-01/"><ChangeBatch><Changes><Change><Action>CREATE</Action><ResourceRecordSet><Name>www</Name><Type>CNAME</Type></ResourceRecordSet></Change><Change><Action>UPSERT</Action><ResourceRecordSet><Name>dev</Name><Type>CNAME</Type></ResourceRecordSet></Change></Changes></ChangeBatch></ChangeResourceRecordSetsRequest>
        """
        let changes: [Route53.Change] = [
            .init(action: .create, resourceRecordSet: .init(name: "www", type: .cname)),
            .init(action: .upsert, resourceRecordSet: .init(name: "dev", type: .cname)),
        ]
        let changeBatch = Route53.ChangeBatch(changes: changes)
        let request = Route53.ChangeResourceRecordSetsRequest(changeBatch: changeBatch, hostedZoneId: "Zone")

        self.testAWSShapeRequest(config: route53.config, operation: "ChangeResourceRecordSets", input: request, expected: expectedResult)
    }

    func testSESSendEmail() {
        let ses = SES(client: Self.client)
        let expectedResult =
            "Action=SendEmail&Destination.ToAddresses.member.1=them%40gmail.com&Message.Body.Text.Data=Testing%201%2C2%2C1%2C2&Message.Subject.Data=Testing&Source=me%40gmail.com&Version=2010-12-01"
        let destination = SES.Destination(toAddresses: ["them@gmail.com"])
        let message = SES.Message(body: SES.Body(text: SES.Content(data: "Testing 1,2,1,2")), subject: SES.Content(data: "Testing"))
        let request = SES.SendEmailRequest(destination: destination, message: message, source: "me@gmail.com")

        self.testAWSShapeRequest(config: ses.config, operation: "SendEmail", input: request, expected: expectedResult)
    }

    // VALIDATION TESTS

    func testS3GetObjectAclValidate() {
        // string length
        let s3 = S3(client: Self.client)
        let request = S3.GetObjectAclRequest(bucket: "testbucket", key: "")
        self.testAWSValidationFail(config: s3.config, operation: "GetObjectAcl", input: request)
    }

    func testIAMAttachGroupPolicyValidate() {
        let iam = IAM(client: Self.client)
        // regular expression fail
        let request = IAM.AttachGroupPolicyRequest(groupName: ":MY:GROUP", policyArn: "arn://3948574985/unvalidated")
        self.testAWSValidationFail(config: iam.config, operation: "AttachGroupPolicy", input: request)
        // string length
        let request2 = IAM.AttachGroupPolicyRequest(groupName: "MYGROUP", policyArn: "arn:tooshort")
        self.testAWSValidationFail(config: iam.config, operation: "AttachGroupPolicy", input: request2)
        // regular expression success
        let request3 = IAM.AttachGroupPolicyRequest(groupName: "MY-GR_OU+P", policyArn: "arn://3948574985/unvalidated")
        self.testAWSValidationSuccess(config: iam.config, operation: "AttachGroupPolicy", input: request3)
    }

    func testCloudFrontListTagsForResourceValidate() {
        // arn regular expressions, expect arn:aws(-cn)?:cloudfront::[0-9]+:.*
        let cloudFront = CloudFront(client: Self.client)
        let request = CloudFront.ListTagsForResourceRequest(resource: "test")
        self.testAWSValidationFail(config: cloudFront.config, operation: "ListTagsForResource", input: request)
        let request2 = CloudFront.ListTagsForResourceRequest(resource: "arn:aws::58979345:test")
        self.testAWSValidationFail(config: cloudFront.config, operation: "ListTagsForResource", input: request2)
        let request3 = CloudFront.ListTagsForResourceRequest(resource: "arn:aws:cloudfront::58979345")
        self.testAWSValidationFail(config: cloudFront.config, operation: "ListTagsForResource", input: request3)
        let successRequest = CloudFront.ListTagsForResourceRequest(resource: "arn:aws:cloudfront::58979345:test")
        self.testAWSValidationSuccess(config: cloudFront.config, operation: "ListTagsForResource", input: successRequest)
    }

    func testACMAddTagsToCertificateValidate() {
        // test validating array members
        let request = ACM.AddTagsToCertificateRequest(
            certificateArn: "arn:aws:acm:region:123456789012:certificate/12345678-1234-1234-1234-123456789012",
            tags: [ACM.Tag(key: "hello", value: "1"), ACM.Tag(key: "?hello?", value: "1")]
        )
        let acm = ACM(client: Self.client)
        self.testAWSValidationFail(config: acm.config, operation: "AddTagsToCertificate", input: request)
    }

    func testCloudFrontCreateDistributionValidate() {
        let trustedSigners = CloudFront.TrustedSigners(enabled: true, quantity: 2)
        let defaultCacheBehavior = CloudFront.DefaultCacheBehavior(
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
        let cloudFront = CloudFront(client: Self.client)
        let request = CloudFront.CreateDistributionRequest(distributionConfig: distribution)
        self.testAWSValidationFail(config: cloudFront.config, operation: "CreateDistribution", input: request)
    }
}
