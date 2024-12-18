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

import AsyncHTTPClient
import NIOFoundationCompat
import NIOPosix
import XCTest

@testable import SotoCore
@testable import SotoS3

extension S3Tests {
    /// test bucket location is correctly returned.
    func testGetBucketLocation() async throws {
        let name = TestEnvironment.generateResourceName()
        try await testBucket(name) { name in
            let response = try await Self.s3.getBucketLocation(.init(bucket: name))
            XCTAssertEqual(response.locationConstraint, .usEast1)
        }
    }

    /// test metadata is uploaded and downloaded ok
    func testMetaData() async throws {
        let name = TestEnvironment.generateResourceName()
        let contents = "testing metadata header"
        try await testBucket(name) { _ in
            let putRequest = S3.PutObjectRequest(
                body: .init(string: contents),
                bucket: name,
                key: name,
                metadata: ["Test": "testing", "first": "one"]
            )
            _ = try await Self.s3.putObject(putRequest)

            let getResponse = try await Self.s3.getObject(.init(bucket: name, key: name))
            XCTAssertEqual(getResponse.metadata?["test"], "testing")
            XCTAssertEqual(getResponse.metadata?["first"], "one")
        }
    }

    func testMultipartUploadDownloadToFile() async throws {
        let s3 = Self.s3.with(timeout: .minutes(2))
        let buffer = Self.randomBytes!
        let name = TestEnvironment.generateResourceName()
        let filename = #function

        try await testBucket(name) { name in
            let putRequest = S3.CreateMultipartUploadRequest(bucket: name, key: filename)
            _ = try await s3.multipartUpload(putRequest, bufferSequence: buffer.asyncSequence(chunkSize: 64000))
            let request = S3.GetObjectRequest(bucket: name, key: filename)
            let size = try await s3.multipartDownload(
                request,
                partSize: 1024 * 1024,
                filename: filename,
                logger: TestEnvironment.logger
            ) { print("Progress \($0 * 100)%") }
            XCTAssertEqual(size, Int64(buffer.readableBytes))
            try await NonBlockingFileIO(threadPool: .singleton).remove(path: filename)
        }
    }

    func testMultipartDownloadFailure() async throws {
        let name = TestEnvironment.generateResourceName()
        try await testBucket(name) { name in
            await XCTAsyncExpectError(S3ErrorType.notFound) {
                let request = S3.GetObjectRequest(bucket: name, key: name)
                _ = try await Self.s3.multipartDownload(request, partSize: 1024 * 1024, filename: name, logger: TestEnvironment.logger) {
                    print("Progress \($0 * 100)%")
                }
            }
        }
        try? await NonBlockingFileIO(threadPool: .singleton).remove(path: name)
    }

    func testStuff(_ process: () async throws -> Void) async throws {
        try await process()
    }

    func testMultipartUploadFile() async throws {
        let s3 = Self.s3.with(timeout: .minutes(2))
        let buffer = Self.randomBytes!
        let name = TestEnvironment.generateResourceName()
        let filename = "S3MultipartUploadTest"
        let fileIO = NonBlockingFileIO(threadPool: .singleton)
        await XCTAsyncAssertNoThrow {
            try await fileIO.withFileHandle(path: filename, mode: .write, flags: .allowFileCreation()) { fileHandle in
                try await fileIO.write(fileHandle: fileHandle, buffer: buffer)
            }
        }

        try await withTeardown {
            try await testBucket(name) { name in
                let request = S3.CreateMultipartUploadRequest(bucket: name, key: filename)
                _ = try await s3.multipartUpload(
                    request,
                    partSize: 5 * 1024 * 1024,
                    filename: filename,
                    logger: TestEnvironment.logger
                ) {
                    print("Progress \($0 * 100)%")
                }

                let getResponse = try await s3.getObject(.init(bucket: name, key: filename))
                let responseBody = try await getResponse.body.collect(upTo: .max)
                XCTAssertEqual(responseBody, buffer)
            }
        } teardown: {
            await XCTAsyncAssertNoThrow { try await NonBlockingFileIO(threadPool: .singleton).remove(path: filename) }
        }
    }

    func testMultipartUploadBuffer() async throws {
        let s3 = Self.s3.with(timeout: .minutes(2))
        let buffer = Self.randomBytes!
        let name = TestEnvironment.generateResourceName()
        let filename = "testMultipartUploadBuffer"

        try await testBucket(name) { name in
            let request = S3.CreateMultipartUploadRequest(bucket: name, key: filename)
            _ = try await s3.multipartUpload(
                request,
                partSize: 5 * 1024 * 1024,
                buffer: buffer,
                logger: TestEnvironment.logger
            ) {
                print("Progress \($0 * 100)%")
            }

            let getResponse = try await s3.getObject(.init(bucket: name, key: filename))
            let responseBody = try await getResponse.body.collect(upTo: .max)
            XCTAssertEqual(responseBody, buffer)
        }
    }

    func testResumeMultipartUpload() async throws {
        struct CancelError: Error {}
        let s3 = Self.s3.with(timeout: .minutes(2))
        let buffer = Self.randomBytes!
        let name = TestEnvironment.generateResourceName()
        let filename = "testResumeMultiPartUpload"

        let fileIO = NonBlockingFileIO(threadPool: .singleton)
        await XCTAsyncAssertNoThrow {
            try await fileIO.withFileHandle(path: filename, mode: .write, flags: .allowFileCreation()) { fileHandle in
                try await fileIO.write(fileHandle: fileHandle, buffer: buffer)
            }
        }

        try await withTeardown {
            try await testBucket(name) { name in
                do {
                    let request = S3.CreateMultipartUploadRequest(bucket: name, key: filename)
                    _ = try await s3.multipartUpload(
                        request,
                        filename: filename,
                        abortOnFail: false,
                        logger: TestEnvironment.logger
                    ) {
                        guard $0 < 0.55 else { throw CancelError() }
                        print("Progress \($0 * 100)")
                    }

                    XCTFail("First multipartUpload was successful")
                } catch S3ErrorType.MultipartError.abortedUpload(let resumeRequest, _) {
                    do {
                        _ = try await s3.resumeMultipartUpload(
                            resumeRequest,
                            partSize: 5 * 1024 * 1024,
                            filename: filename,
                            abortOnFail: false,
                            logger: TestEnvironment.logger
                        ) {
                            guard $0 < 0.95 else { throw CancelError() }
                            print("Progress \($0 * 100)")
                        }
                    } catch S3ErrorType.MultipartError.abortedUpload(let resumeRequest, _) {
                        _ = try await s3.resumeMultipartUpload(
                            resumeRequest,
                            partSize: 5 * 1024 * 1024,
                            filename: filename,
                            abortOnFail: false,
                            logger: TestEnvironment.logger
                        ) {
                            print("Progress \($0 * 100)")
                        }
                    }
                }
                let getResponse = try await s3.getObject(.init(bucket: name, key: filename))
                let responseBody = try await getResponse.body.collect(upTo: .max)
                XCTAssertEqual(responseBody, buffer)
            }
        } teardown: {
            await XCTAsyncAssertNoThrow { try await NonBlockingFileIO(threadPool: .singleton).remove(path: filename) }
        }
    }

    func testMultipartUploadEmpty() async throws {
        let s3 = Self.s3.with(timeout: .minutes(2))
        let name = TestEnvironment.generateResourceName()

        try await testBucket(name) { name in
            let request = S3.CreateMultipartUploadRequest(bucket: name, key: name)
            _ = try await s3.multipartUpload(request, bufferSequence: ByteBuffer().asyncSequence(chunkSize: 1), logger: TestEnvironment.logger)

            let getRequest = S3.GetObjectRequest(bucket: name, key: name)
            let response = try await s3.getObject(getRequest, logger: TestEnvironment.logger)
            let responseBody = try await response.body.collect(upTo: .max)
            XCTAssertEqual(responseBody.readableBytes, 0)  // Empty
        }
    }

    func testMultipartUploadFailure() async throws {
        let name = TestEnvironment.generateResourceName()
        let buffer = Self.randomBytes!

        await XCTAsyncExpectError(S3ErrorType.noSuchBucket) {
            let request = S3.CreateMultipartUploadRequest(bucket: name, key: name)
            _ = try await Self.s3.multipartUpload(request, bufferSequence: buffer.asyncSequence(chunkSize: 1000))
        }
    }

    func testMultipartCopy() async throws {
        let s3 = Self.s3.with(timeout: .minutes(5))
        let buffer = S3Tests.createRandomBuffer(size: 6 * 1024 * 1000)
        let name = TestEnvironment.generateResourceName()
        let name2 = name + "2"
        let filename = "testMultipartCopy"
        let filename2 = "testMultipartCopy2"

        let s3Euwest2 = S3(
            client: S3Tests.client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT"),
            timeout: .minutes(5)
        )
        try await testBucket(name) { name in
            let request = S3.CreateMultipartUploadRequest(bucket: name, key: filename)
            _ = try await s3.multipartUpload(request, bufferSequence: buffer.asyncSequence(chunkSize: 32 * 1024)) { print("Progress \($0 * 100)%") }

            try await Self.createBucket(name: name2, s3: s3Euwest2)
            let copyRequest = S3.CopyObjectRequest(
                bucket: name2,
                copySource: "/\(name)/\(filename)",
                key: filename2
            )
            _ = try await s3Euwest2.multipartCopy(copyRequest)

            let getResponse = try await s3Euwest2.getObject(.init(bucket: name2, key: filename2))
            let responseBuffer = try await getResponse.body.collect(upTo: .max)
            XCTAssertEqual(responseBuffer, buffer)
        }
    }

    func testCopySourceBucketKeyExtraction() {
        let values = Self.s3.getBucketKeyVersion(from: "test-bucket/test-key/path")
        XCTAssertEqual(values?.bucket, "test-bucket")
        XCTAssertEqual(values?.key, "test-key/path")
        let values2 = Self.s3.getBucketKeyVersion(from: "/test-bucket/test-key/path")
        XCTAssertEqual(values2?.bucket, "test-bucket")
        XCTAssertEqual(values2?.key, "test-key/path")
        let values3 = Self.s3.getBucketKeyVersion(from: "/test-bucket/test-key/path?versionId=5")
        XCTAssertEqual(values3?.bucket, "test-bucket")
        XCTAssertEqual(values3?.key, "test-key/path")
        XCTAssertEqual(values3?.versionId, "5")
    }

    func testSelectObjectContent() async throws {
        // doesnt work with LocalStack
        try XCTSkipIf(TestEnvironment.isUsingLocalstack)

        let s3 = Self.s3.with(timeout: .minutes(2))
        let strings =
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
            .split(separator: " ")
        let file = strings.reduce("") { $0 + "\($1), \($1.count), \($0.count + $1.count)\n" }
        let file2 = file + file
        let file3 = file2 + file2
        let file4 = file3 + file3
        let file5 = file4 + file4
        let file6 = file5 + file5
        let file7 = file6 + file6
        let file8 = file7 + file7
        let file9 = file8 + file8
        let file10 = file9 + file9

        let name = TestEnvironment.generateResourceName()

        try await testBucket(name) { name in
            let putRequest = S3.PutObjectRequest(body: .init(string: file10), bucket: name, key: "file.csv")
            _ = try await s3.putObject(putRequest, logger: TestEnvironment.logger)

            let expression = "Select * from S3Object"
            let input = S3.InputSerialization(csv: .init(fieldDelimiter: ",", fileHeaderInfo: .use, recordDelimiter: "\n"))
            let output = S3.OutputSerialization(csv: .init(fieldDelimiter: ",", recordDelimiter: "\n"))
            let request = S3.SelectObjectContentRequest(
                bucket: name,
                expression: expression,
                expressionType: .sql,
                inputSerialization: input,
                key: "file.csv",
                outputSerialization: output,
                requestProgress: S3.RequestProgress(enabled: true)
            )
            let size = file10.utf8.count
            var returnedSize = 0

            let response = try await s3.selectObjectContent(request, logger: TestEnvironment.logger)
            for try await event in response.payload {
                switch event {
                case .records(let records):
                    let decodedCount = records.payload.buffer.readableBytes
                    returnedSize += decodedCount
                    print("Record size: \(decodedCount)")
                case .stats(let stats):
                    let details = stats.details
                    print("Stats: ")
                    print("  processed: \(details.bytesProcessed ?? 0)")
                    print("  returned: \(details.bytesReturned ?? 0)")
                    print("  scanned: \(details.bytesScanned ?? 0)")

                    XCTAssertEqual(Int64(size), details.bytesProcessed)
                    XCTAssertEqual(Int64(returnedSize), details.bytesReturned)
                case .end:
                    print("End")
                default:
                    break
                }
            }
        }
    }

    func testS3VirtualAddressing(_ urlString: String, s3URL: String, config: AWSServiceConfig = S3Tests.s3.config) async throws {
        let request = AWSHTTPRequest(
            url: URL(string: urlString)!,
            method: .GET,
            headers: [:],
            body: .init()
        )
        let context = AWSMiddlewareContext(
            operation: "TestOperation",
            serviceConfig: config,
            credential: EmptyCredential().getStaticCredential(),
            logger: TestEnvironment.logger
        )
        _ = try await config.middleware?.handle(request, context: context) { request, _ in
            XCTAssertEqual(request.url.absoluteString, s3URL)
            return AWSHTTPResponse(status: .ok, headers: ["RequestURL": request.url.absoluteString])
        }
    }

    func testS3VirtualAddressing() async throws {
        try await self.testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket", s3URL: "https://bucket.s3.us-east-1.amazonaws.com/")
        try await self.testS3VirtualAddressing(
            "https://s3.us-east-1.amazonaws.com/bucket//filename",
            s3URL: "https://bucket.s3.us-east-1.amazonaws.com//filename"
        )
        try await self.testS3VirtualAddressing(
            "https://s3.us-east-1.amazonaws.com/bucket/filename?test=test&test2=test2",
            s3URL: "https://bucket.s3.us-east-1.amazonaws.com/filename?test=test&test2=test2"
        )
        try await self.testS3VirtualAddressing(
            "https://s3.us-east-1.amazonaws.com/bucket/filename?test=%3D",
            s3URL: "https://bucket.s3.us-east-1.amazonaws.com/filename?test=%3D"
        )
        try await self.testS3VirtualAddressing(
            "https://s3.us-east-1.amazonaws.com/bucket/file%20name",
            s3URL: "https://bucket.s3.us-east-1.amazonaws.com/file%20name"
        )
        try await self.testS3VirtualAddressing("http://localhost:8000/bucket1/filename", s3URL: "http://localhost:8000/bucket1/filename")
        try await self.testS3VirtualAddressing("http://localhost:8000/bucket2//filename", s3URL: "http://localhost:8000/bucket2//filename")
        try await self.testS3VirtualAddressing("https://localhost:8000/bucket/file%20name", s3URL: "https://localhost:8000/bucket/file%20name")

        let s3 = Self.s3.with(options: .s3ForceVirtualHost)
        try await self.testS3VirtualAddressing(
            "https://localhost:8000/bucket/filename",
            s3URL: "https://bucket.localhost:8000/filename",
            config: s3.config
        )
    }

    func testMD5Calculation() throws {
        let s3 = Self.s3.with(options: .calculateMD5)
        let input = S3.PutObjectRequest(
            body: .init(string: "TestContent"),
            bucket: "testMD5Calculation",
            contentMD5: "6728ab89sfsdff==",
            key: "testMD5Calculation"
        )
        let request = try AWSHTTPRequest(
            operation: "PutObject",
            path: "/{Bucket}/{Key+}?x-id=PutObject",
            method: .PUT,
            input: input,
            configuration: s3.config
        )
        XCTAssertEqual(request.headers["Content-MD5"].first, "6728ab89sfsdff==")

        let input2 = S3.PutObjectRequest(
            body: .init(string: "TestContent"),
            bucket: "testMD5Calculation",
            key: "testMD5Calculation"
        )
        let request2 = try AWSHTTPRequest(
            operation: "PutObject",
            path: "/{Bucket}/{Key+}?x-id=PutObject",
            method: .PUT,
            input: input2,
            configuration: s3.config
        )
        XCTAssertEqual(request2.headers["Content-MD5"].first, "JhF7IaLE189bvT4/iv/iqg==")
    }

    func testGeneratePresignedPost() async throws {
        // Based on the example here: https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-post-example.html

        // Credentials are example only, from the above documentation
        let client = AWSClient(
            credentialProvider: .static(
                accessKeyId: "AKIAIOSFODNN7EXAMPLE",
                secretAccessKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            )
        )
        let s3 = S3(client: client, region: .useast1)

        try await withTeardown {
            let fields = [
                "acl": "public-read",
                "success_action_redirect": "http://sigv4examplebucket.s3.amazonaws.com/successful_upload.html",
                "x-amz-meta-uuid": "14365123651274",
                "x-amz-server-side-encryption": "AES256",
            ]

            let conditions: [S3.PostPolicyCondition] = [
                .match("acl", "public-read"),
                .match("success_action_redirect", "http://sigv4examplebucket.s3.amazonaws.com/successful_upload.html"),
                .match("x-amz-meta-uuid", "14365123651274"),
                .match("x-amz-server-side-encryption", "AES256"),
                .rule("starts-with", "$Content-Type", "image/"),
                .rule("starts-with", "$x-amz-meta-tag", ""),
            ]

            let expiresIn = 36.0 * 60.0 * 60.0
            var dateComponents = DateComponents()
            dateComponents.year = 2015
            dateComponents.month = 12
            dateComponents.day = 29
            dateComponents.timeZone = TimeZone(secondsFromGMT: 0)!

            let date = Calendar(identifier: .gregorian).date(from: dateComponents)!

            let presignedPost = try await s3.generatePresignedPost(
                key: "user/user1/${filename}",
                bucket: "sigv4examplebucket",
                fields: fields,
                conditions: conditions,
                expiresIn: expiresIn,
                date: date
            )

            let expectedURL = "https://sigv4examplebucket.s3.us-east-1.amazonaws.com"
            let expectedCredential = "AKIAIOSFODNN7EXAMPLE/20151229/us-east-1/s3/aws4_request"
            let expectedAlgorithm = "AWS4-HMAC-SHA256"
            let expectedDate = "20151229T000000Z"

            XCTAssertEqual(presignedPost.url, URL(string: expectedURL))
            XCTAssertEqual(presignedPost.fields["x-amz-credential"], expectedCredential)
            XCTAssertEqual(presignedPost.fields["x-amz-algorithm"], expectedAlgorithm)
            XCTAssertEqual(presignedPost.fields["x-amz-date"], expectedDate)

            XCTAssertNotNil(presignedPost.fields["x-amz-signature"])
            XCTAssertNotNil(presignedPost.fields["Policy"])
        } teardown: {
            try? await client.shutdown()
        }
    }

    func testGetSignature() {
        // Based on the example here: https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-post-example.html

        // Credentials are example only, from the above documentation
        let client = AWSClient(
            credentialProvider: .static(
                accessKeyId: "AKIAIOSFODNN7EXAMPLE",
                secretAccessKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            )
        )
        let s3 = S3(client: client, region: .useast1)

        defer { try? client.syncShutdown() }

        let policy =
            "eyAiZXhwaXJhdGlvbiI6ICIyMDE1LTEyLTMwVDEyOjAwOjAwLjAwMFoiLA0KICAiY29uZGl0aW9ucyI6IFsNCiAgICB7ImJ1Y2tldCI6ICJzaWd2NGV4YW1wbGVidWNrZXQifSwNCiAgICBbInN0YXJ0cy13aXRoIiwgIiRrZXkiLCAidXNlci91c2VyMS8iXSwNCiAgICB7ImFjbCI6ICJwdWJsaWMtcmVhZCJ9LA0KICAgIHsic3VjY2Vzc19hY3Rpb25fcmVkaXJlY3QiOiAiaHR0cDovL3NpZ3Y0ZXhhbXBsZWJ1Y2tldC5zMy5hbWF6b25hd3MuY29tL3N1Y2Nlc3NmdWxfdXBsb2FkLmh0bWwifSwNCiAgICBbInN0YXJ0cy13aXRoIiwgIiRDb250ZW50LVR5cGUiLCAiaW1hZ2UvIl0sDQogICAgeyJ4LWFtei1tZXRhLXV1aWQiOiAiMTQzNjUxMjM2NTEyNzQifSwNCiAgICB7IngtYW16LXNlcnZlci1zaWRlLWVuY3J5cHRpb24iOiAiQUVTMjU2In0sDQogICAgWyJzdGFydHMtd2l0aCIsICIkeC1hbXotbWV0YS10YWciLCAiIl0sDQoNCiAgICB7IngtYW16LWNyZWRlbnRpYWwiOiAiQUtJQUlPU0ZPRE5ON0VYQU1QTEUvMjAxNTEyMjkvdXMtZWFzdC0xL3MzL2F3czRfcmVxdWVzdCJ9LA0KICAgIHsieC1hbXotYWxnb3JpdGhtIjogIkFXUzQtSE1BQy1TSEEyNTYifSwNCiAgICB7IngtYW16LWRhdGUiOiAiMjAxNTEyMjlUMDAwMDAwWiIgfQ0KICBdDQp9"
        let signingKey = s3.signingKey(
            date: "20151229",
            secretAccessKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
        )
        let signature = s3.getSignature(
            policy: policy,
            signingKey: signingKey
        )

        let expectedSignature = "8afdbf4008c03f22c2cd3cdb72e4afbb1f6a588f3255ac628749a66d7f09699e"

        XCTAssertEqual(signature, expectedSignature)
    }

    func testGetPresignedPostCredential() {
        // Based on the example here: https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-post-example.html

        // Credentials are example only, from the above documentation
        let client = AWSClient(
            credentialProvider: .static(
                accessKeyId: "AKIAIOSFODNN7EXAMPLE",
                secretAccessKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            )
        )
        let s3 = S3(client: client, region: .useast1)

        defer { try? client.syncShutdown() }

        let credential = s3.getPresignedPostCredential(
            date: "20151229",
            accessKeyId: "AKIAIOSFODNN7EXAMPLE"
        )

        let expectedCredential = "AKIAIOSFODNN7EXAMPLE/20151229/us-east-1/s3/aws4_request"

        XCTAssertEqual(credential, expectedCredential)
    }

    func testGeneratePresignedPostWithSessionToken() async throws {
        let client = AWSClient(
            credentialProvider: .static(
                accessKeyId: "AKIAIOSFODNN7EXAMPLE",
                secretAccessKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
                sessionToken: "EXAMPLESESSIONTOKEN"
            )
        )

        let s3 = S3(client: client, region: .useast1)

        try await withTeardown {
            let fields = [
                "acl": "public-read",
                "success_action_redirect": "http://sigv4examplebucket.s3.amazonaws.com/successful_upload.html",
                "x-amz-meta-uuid": "14365123651274",
                "x-amz-server-side-encryption": "AES256",
            ]

            let conditions: [S3.PostPolicyCondition] = [
                .match("acl", "public-read"),
                .match("success_action_redirect", "http://sigv4examplebucket.s3.amazonaws.com/successful_upload.html"),
                .match("x-amz-meta-uuid", "14365123651274"),
                .match("x-amz-server-side-encryption", "AES256"),
                .rule("starts-with", "$Content-Type", "image/"),
                .rule("starts-with", "$x-amz-meta-tag", ""),
            ]

            let expiresIn = 36.0 * 60.0 * 60.0
            var dateComponents = DateComponents()
            dateComponents.year = 2015
            dateComponents.month = 12
            dateComponents.day = 29
            dateComponents.timeZone = TimeZone(secondsFromGMT: 0)!

            let date = Calendar(identifier: .gregorian).date(from: dateComponents)!

            let presignedPost = try await s3.generatePresignedPost(
                key: "user/user1/${filename}",
                bucket: "sigv4examplebucket",
                fields: fields,
                conditions: conditions,
                expiresIn: expiresIn,
                date: date
            )

            XCTAssertEqual(presignedPost.fields["x-amz-security-token"], "EXAMPLESESSIONTOKEN")
        } teardown: {
            try? await client.shutdown()
        }
    }
}
