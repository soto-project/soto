//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2026 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOConcurrencyHelpers
import NIOCore
import Testing

@testable import SotoCore
@testable import SotoS3

@Suite("S3 multipart resume")
struct S3MultipartResumeTests {
    struct InjectedError: Error {}

    /// Progress reported while resuming must count the real size of the parts already uploaded,
    /// including a last part that is smaller than `partSize`.
    @Test
    func progressWithShortLastPart() async throws {
        let partSize = 5 * 1024 * 1024
        let totalSize = 12 * 1024 * 1024  // parts of 5, 5 and 2 MiB
        let buffer = ByteBuffer(bytes: [UInt8](repeating: 7, count: totalSize))
        let name = TestEnvironment.generateResourceName()
        let failPart2 = NIOLockedValueBox(true)
        // Part 2 fails after a delay so that part 3 (the short last part) completes first.
        let middleware = AWSMiddleware { request, context, next in
            if failPart2.withLockedValue({ $0 }), request.url.absoluteString.contains("partNumber=2") {
                try await Task.sleep(for: .seconds(2))
                throw InjectedError()
            }
            return try await next(request, context)
        }

        let client = AWSClient(credentialProvider: TestEnvironment.credentialProvider, middleware: TestEnvironment.middlewares)
        let s3 = S3(
            client: client,
            region: .useast1,
            endpoint: TestEnvironment.getEndPoint(environment: "LOCALSTACK_ENDPOINT")
        ).with(middleware: middleware, timeout: .minutes(2))

        try await S3Tests.createBucket(name: name, s3: s3)
        do {
            let request = S3.CreateMultipartUploadRequest(bucket: name, key: name)
            let abortedUpload = await #expect(throws: S3ErrorType.MultipartError.self) {
                _ = try await s3.multipartUpload(
                    request,
                    partSize: partSize,
                    bufferSequence: buffer.asyncSequence(chunkSize: 64 * 1024),
                    abortOnFail: false,
                    logger: TestEnvironment.logger
                )
            }
            guard case .abortedUpload(let resumeRequest, _) = abortedUpload else {
                Issue.record("Expected an abortedUpload error, got \(String(describing: abortedUpload))")
                throw InjectedError()
            }
            #expect(resumeRequest.completedParts.compactMap(\.partNumber).sorted() == [1, 3])

            failPart2.withLockedValue { $0 = false }
            let progress = NIOLockedValueBox<[Int]>([])
            _ = try await s3.resumeMultipartUpload(
                resumeRequest,
                partSize: partSize,
                bufferSequence: buffer.asyncSequence(chunkSize: 64 * 1024),
                logger: TestEnvironment.logger
            ) { value in
                progress.withLockedValue { $0.append(value) }
            }
            let values = progress.withLockedValue { $0 }
            #expect(values.last == totalSize)
            #expect(values.allSatisfy { $0 <= totalSize })

            let response = try await s3.getObject(.init(bucket: name, key: name))
            let body = try await response.body.collect(upTo: .max)
            #expect(body == buffer)
        } catch {
            try? await S3Tests.deleteBucket(name: name, s3: s3)
            try await client.shutdown()
            throw error
        }
        try await S3Tests.deleteBucket(name: name, s3: s3)
        try await client.shutdown()
    }
}
