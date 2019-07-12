//
//  AWSRequestTests.swift
//  AWSSDKSwift
//
//  Created by Adam Fowler on 2019/06/28.
//
//

import Foundation
import XCTest
@testable import CloudFront
@testable import EC2
@testable import IAM
@testable import S3
@testable import SES
@testable import SNS
@testable import AWSSDKSwiftCore

/// Tests to check the formatting of various AWSRequest bodies
class AWSRequestTests: XCTestCase {

    /// test awsRequest body is expected string
    func testRequestedBody(expected: String, result: AWSRequest) throws {
        // get body
        let bodyData = try result.body.asData()
        XCTAssertNotNil(bodyData)
        if let body = String(data:bodyData!, encoding: .utf8) {
            XCTAssertEqual(expected, body)
        }
    }

    /// test
    func testAWSShapeRequest<Input: AWSShape>(client: AWSClient, operation: String, path: String="/", httpMethod: String="POST", input: Input, expected: String) {
        do {
            let awsRequest = try client.debugCreateAWSRequest(operation: operation, path: path, httpMethod: httpMethod, input: input)
            var expected2 = expected

            // If XML remove whitespace from expected by converting to XMLNode and back
            if case .restxml = client.serviceProtocol.type {
                let document = try XML.Document(data: expected.data(using: .utf8)!)
                expected2 = document.xmlString
            }

            try testRequestedBody(expected: expected2, result: awsRequest)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testS3CreateMultipartUpload() {
        let expectedResult = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><CreateMultipartUploadRequest><x-amz-acl>authenticated-read</x-amz-acl><Bucket>test-bucket</Bucket><Expires>1970-04-26T17:46:40.000Z</Expires><Key>test-object</Key><Metadata><entry><key>test-key</key><value>test-value</value></entry></Metadata><x-amz-object-lock-legal-hold>ON</x-amz-object-lock-legal-hold><x-amz-object-lock-mode>COMPLIANCE</x-amz-object-lock-mode><x-amz-object-lock-retain-until-date>1970-04-26T18:46:40.000Z</x-amz-object-lock-retain-until-date><x-amz-request-payer>requester</x-amz-request-payer><x-amz-server-side-encryption>AES256</x-amz-server-side-encryption><x-amz-storage-class>STANDARD</x-amz-storage-class></CreateMultipartUploadRequest>"

        let request = S3.CreateMultipartUploadRequest(acl: .authenticatedRead, bucket: "test-bucket", expires: TimeStamp(Date(timeIntervalSince1970: 10000000)), key:"test-object", metadata: ["test-key":"test-value"], objectLockLegalHoldStatus:.on, objectLockMode: .compliance, objectLockRetainUntilDate: TimeStamp(Date(timeIntervalSince1970: 10003600)), requestPayer: .requester, serverSideEncryption: .aes256, storageClass: .standard)

        testAWSShapeRequest(client:S3().client, operation: "CreateMultipartUpload", path: "/{Bucket}/{Key+}?uploads", httpMethod: "POST", input: request, expected: expectedResult)
    }

    func testSNSCreateTopic() {
        let expectedResult = "Action=CreateTopic&Attributes.entry.1.key=TestAttribute&Attributes.entry.1.value=TestValue&Name=TestTopic&Tags.member.1.Key=tag1&Tags.member.1.Value=23&Tags.member.2.Key=tag2&Tags.member.2.Value=true&Version=2010-03-31"
        let request = SNS.CreateTopicInput(attributes: ["TestAttribute":"TestValue"], name: "TestTopic", tags: [SNS.Tag(key:"tag1", value:"23"), SNS.Tag(key:"tag2", value:"true")])

        testAWSShapeRequest(client: SNS().client, operation: "CreateTopic", path: "/", httpMethod: "POST", input: request, expected: expectedResult)
    }

    func testCloudFrontCreateDistribution() {
        let expectedResult = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><DistributionConfig><CallerReference>test</CallerReference><Comment></Comment><DefaultCacheBehavior><ForwardedValues><Cookies><Forward>all</Forward></Cookies><QueryString>true</QueryString></ForwardedValues><MinTTL>1024</MinTTL><TargetOriginId>AWSRequestTests</TargetOriginId><TrustedSigners><Enabled>true</Enabled><Quantity>2</Quantity></TrustedSigners><ViewerProtocolPolicy>https-only</ViewerProtocolPolicy></DefaultCacheBehavior><Enabled>true</Enabled><Origins><Items><Origin><DomainName>aws.sdk.swift.com</DomainName><Id>1234</Id></Origin></Items><Quantity>1</Quantity></Origins></DistributionConfig>"

        let cookiePreference = CloudFront.CookiePreference(forward:.all)
        let forwardedValues = CloudFront.ForwardedValues(cookies: cookiePreference, queryString: true)
        let trustedSigners = CloudFront.TrustedSigners(enabled: true, quantity: 2)
        let defaultCacheBehavior = CloudFront.DefaultCacheBehavior(forwardedValues: forwardedValues, minTTL:1024, targetOriginId: "AWSRequestTests", trustedSigners: trustedSigners, viewerProtocolPolicy: .httpsOnly)
        let origins = CloudFront.Origins(items:[CloudFront.Origin(domainName:"aws.sdk.swift.com", id:"1234")], quantity:1)
        let distribution = CloudFront.DistributionConfig(callerReference:"test", comment:"", defaultCacheBehavior: defaultCacheBehavior, enabled:true, origins: origins)
        let request = CloudFront.CreateDistributionRequest(distributionConfig: distribution)

        testAWSShapeRequest(client: CloudFront().client, operation: "CreateDistribution2019_03_26", path: "/2019-03-26/distribution", httpMethod: "POST", input: request, expected: expectedResult)
    }

    func testEC2CreateImage() {
        let expectedResult = "Action=CreateImage&Version=2016-11-15&instanceId=i-123123&name=TestInstance"
        let request = EC2.CreateImageRequest(instanceId:"i-123123", name:"TestInstance")

        testAWSShapeRequest(client: EC2().client, operation: "CreateImage", path: "/", httpMethod: "POST", input: request, expected: expectedResult)
    }

    func testEC2CreateInstanceExportTask() {
        let expectedResult = "Action=CreateInstanceExportTask&Version=2016-11-15&exportToS3.s3Bucket=testBucket&instanceId=i-123123"
        let exportToS3Task = EC2.ExportToS3TaskSpecification(s3Bucket:"testBucket")
        let request = EC2.CreateInstanceExportTaskRequest(exportToS3Task: exportToS3Task, instanceId: "i-123123")

        testAWSShapeRequest(client: EC2().client, operation: "CreateInstanceExportTask", path: "/", httpMethod: "POST", input: request, expected: expectedResult)
    }

    func testIAMSimulateCustomPolicy() {
        let expectedResult = "Action=SimulateCustomPolicy&ActionNames.member.1=s3%2A&ActionNames.member.2=iam%2A&PolicyInputList.member.1=testPolicy&Version=2010-05-08"
        let request = IAM.SimulateCustomPolicyRequest(actionNames: ["s3*", "iam*"], policyInputList: ["testPolicy"])

        testAWSShapeRequest(client: IAM().client, operation: "SimulateCustomPolicy", input: request, expected: expectedResult)
    }

    func testSESSendEmail() {
        let expectedResult = "Action=SendEmail&Destination.ToAddresses.member.1=them%40gmail.com&Message.Body.Text.Data=Testing%201%2C2%2C1%2C2&Message.Subject.Data=Testing&Source=me%40gmail.com&Version=2010-12-01"
        let destination = SES.Destination(toAddresses: ["them@gmail.com"])
        let message = SES.Message(body:SES.Body(text:SES.Content(data:"Testing 1,2,1,2")), subject:SES.Content(data:"Testing"))
        let request = SES.SendEmailRequest(destination: destination, message: message, source: "me@gmail.com")

        testAWSShapeRequest(client: SES().client, operation: "SendEmail", input: request, expected: expectedResult)
    }

    static var allTests : [(String, (AWSRequestTests) -> () throws -> Void)] {
        return [
            ("testS3CreateMultipartUpload", testS3CreateMultipartUpload),
            ("testSNSCreateTopic", testSNSCreateTopic),
            //("testCloudFrontCreateDistribution", testCloudFrontCreateDistribution),
            ("testEC2CreateImage", testEC2CreateImage),
            ("testEC2CreateInstanceExportTask", testEC2CreateInstanceExportTask),
            ("testIAMSimulateCustomPolicy", testIAMSimulateCustomPolicy),
            ("testSESSendEmail", testSESSendEmail),
        ]
    }
}
