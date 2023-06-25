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
import Foundation
import NIOFoundationCompat
@testable import SotoCore
@testable import SotoS3
import XCTest

extension S3Tests {
    /// test bucket location is correctly returned.
    func testGetBucketLocation() async throws {
        try XCTSkipIf(true, "Not implemented yet")
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
            XCTAssert(FileManager.default.fileExists(atPath: filename))
            try FileManager.default.removeItem(atPath: filename)
        }
    }

    func testMultipartDownloadFailure() async throws {
        let name = TestEnvironment.generateResourceName()
        try await testBucket(name) { name in
            await XCTAsyncExpectError(S3ErrorType.notFound) {
                let request = S3.GetObjectRequest(bucket: name, key: name)
                _ = try await Self.s3.multipartDownload(request, partSize: 1024 * 1024, filename: name, logger: TestEnvironment.logger) { print("Progress \($0 * 100)%") }
            }
        }
        try FileManager.default.removeItem(atPath: name)
    }

    func testMultipartUploadFile() async throws {
        let s3 = Self.s3.with(timeout: .minutes(2))
        let buffer = Self.randomBytes!
        let data = Data(buffer: buffer)
        let name = TestEnvironment.generateResourceName()
        let filename = "S3MultipartUploadTest"

        XCTAssertNoThrow(try data.write(to: URL(fileURLWithPath: filename)))
        defer {
            XCTAssertNoThrow(try FileManager.default.removeItem(atPath: filename))
        }

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
            let responseBody = try await getResponse.body?.collect(upTo: .max)
            XCTAssertEqual(responseBody, buffer)
        }
    }

    func testResumeMultipartUpload() async throws {
        struct CancelError: Error {}
        let s3 = Self.s3.with(timeout: .minutes(2))
        let buffer = Self.randomBytes!
        let data = Data(buffer: buffer)
        let name = TestEnvironment.generateResourceName()
        let filename = "testResumeMultiPartUpload"

        XCTAssertNoThrow(try data.write(to: URL(fileURLWithPath: filename)))
        defer {
            XCTAssertNoThrow(try FileManager.default.removeItem(atPath: filename))
        }
        try await testBucket(name) { name in
            do {
                let request = S3.CreateMultipartUploadRequest(bucket: name, key: filename)
                _ = try await s3.multipartUpload(
                    request,
                    filename: filename,
                    abortOnFail: false,
                    logger: TestEnvironment.logger
                ) {
                    guard $0 < 0.45 else { throw CancelError() }
                    print("Progress \($0 * 100)")
                }

                XCTFail("First multipartUpload was successful")
            } catch S3ErrorType.multipart.abortedUpload(let resumeRequest, _) {
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
                } catch S3ErrorType.multipart.abortedUpload(let resumeRequest, _) {
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
            let responseBody = try await getResponse.body?.collect(upTo: .max)
            XCTAssertEqual(responseBody, buffer)
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
            let responseBody = try await response.body?.collect(upTo: .max)
            XCTAssertEqual(responseBody?.readableBytes, 0) // Empty
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
            let responseBuffer = try await getResponse.body?.collect(upTo: .max)
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

    /*
     func testSelectObjectContent() throws {
         // doesnt work with LocalStack
         try XCTSkipIf(TestEnvironment.isUsingLocalstack)

         let s3 = Self.s3.with(timeout: .minutes(2))
         let strings = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.".split(separator: " ")
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
         let runOnEventLoop = s3.client.eventLoopGroup.next()

         let response = S3Tests.createBucket(name: name, s3: s3)
             .hop(to: runOnEventLoop)
             .flatMap { _ -> EventLoopFuture<S3.PutObjectOutput> in
                 let putRequest = S3.PutObjectRequest(body: .string(file10), bucket: name, key: "file.csv")
                 return s3.putObject(putRequest, on: runOnEventLoop)
             }
             .flatMap { _ -> EventLoopFuture<S3.SelectObjectContentOutput> in
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
                 return s3.selectObjectContentEventStream(request, logger: TestEnvironment.logger, on: runOnEventLoop) { eventStream, eventLoop in
                     XCTAssertTrue(eventLoop === runOnEventLoop)
                     switch eventStream {
                     case .records(let records):
                         if let payload = records.payload {
                             if let decodedCount = payload.decoded()?.count {
                                 returnedSize += decodedCount
                                 print("Record size: \(decodedCount)")
                             } else {
                                 XCTFail("Failed to decode Base64 data in payload")
                             }
                         }
                     case .stats(let stats):
                         if let details = stats.details {
                             print("Stats: ")
                             print("  processed: \(details.bytesProcessed ?? 0)")
                             print("  returned: \(details.bytesReturned ?? 0)")
                             print("  scanned: \(details.bytesScanned ?? 0)")

                             XCTAssertEqual(Int64(size), details.bytesProcessed)
                             XCTAssertEqual(Int64(returnedSize), details.bytesReturned)
                         }
                     case .end:
                         print("End")
                     default:
                         break
                     }
                     return eventLoop.makeSucceededFuture(())
                 }
             }
             .flatAlways { _ in
                 return S3Tests.deleteBucket(name: name, s3: s3)
             }
         XCTAssertNoThrow(try response.wait())
     }*/

    func testS3VirtualAddressing(_ urlString: String, config: AWSServiceConfig = S3Tests.s3.config) throws -> String {
        let url = URL(string: urlString)!
        let request = try AWSRequest(
            region: .useast1,
            url: url,
            serviceProtocol: Self.s3.config.serviceProtocol,
            operation: "TestOperation",
            httpMethod: .GET,
            httpHeaders: [:],
            body: .init()
        ).applyMiddlewares(Self.s3.config.middlewares, config: config)
        return request.url.relativeString
    }

    func testS3VirtualAddressing() {
        XCTAssertEqual(try self.testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket"), "https://bucket.s3.us-east-1.amazonaws.com/")
        XCTAssertEqual(try self.testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket//filename"), "https://bucket.s3.us-east-1.amazonaws.com/filename")
        XCTAssertEqual(try self.testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket/filename?test=test&test2=test2"), "https://bucket.s3.us-east-1.amazonaws.com/filename?test=test&test2=test2")
        XCTAssertEqual(try self.testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket/filename?test=%3D"), "https://bucket.s3.us-east-1.amazonaws.com/filename?test=%3D")
        XCTAssertEqual(try self.testS3VirtualAddressing("https://s3.us-east-1.amazonaws.com/bucket/file%20name"), "https://bucket.s3.us-east-1.amazonaws.com/file%20name")
        XCTAssertEqual(try self.testS3VirtualAddressing("http://localhost:8000/bucket/filename"), "http://localhost:8000/bucket/filename")
        XCTAssertEqual(try self.testS3VirtualAddressing("http://localhost:8000//bucket/filename"), "http://localhost:8000/bucket/filename")
        XCTAssertEqual(try self.testS3VirtualAddressing("http://localhost:8000/bucket//filename"), "http://localhost:8000/bucket/filename")
        XCTAssertEqual(try self.testS3VirtualAddressing("https://localhost:8000/bucket/file%20name"), "https://localhost:8000/bucket/file%20name")

        let s3 = Self.s3.with(options: .s3ForceVirtualHost)
        XCTAssertEqual(try self.testS3VirtualAddressing("https://localhost:8000/bucket/filename", config: s3.config), "https://bucket.localhost:8000/filename")
    }

    func testMD5Calculation() throws {
        let s3 = Self.s3.with(options: .calculateMD5)
        let input = S3.PutObjectRequest(
            body: .init(string: "TestContent"),
            bucket: "testMD5Calculation",
            contentMD5: "6728ab89sfsdff==",
            key: "testMD5Calculation"
        )
        let request = try AWSRequest(operation: "PutObject", path: "/{Bucket}/{Key+}?x-id=PutObject", httpMethod: .PUT, input: input, configuration: s3.config)
        XCTAssertEqual(request.httpHeaders["Content-MD5"].first, "6728ab89sfsdff==")

        let input2 = S3.PutObjectRequest(
            body: .init(string: "TestContent"),
            bucket: "testMD5Calculation",
            key: "testMD5Calculation"
        )
        let request2 = try AWSRequest(operation: "PutObject", path: "/{Bucket}/{Key+}?x-id=PutObject", httpMethod: .PUT, input: input2, configuration: s3.config)
        XCTAssertEqual(request2.httpHeaders["Content-MD5"].first, "JhF7IaLE189bvT4/iv/iqg==")
    }
}
