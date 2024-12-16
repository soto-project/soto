//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2024 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Crypto
import Foundation
import Logging
@_spi(SotoInternal) import SotoSignerV4

extension S3ErrorType {
    public enum presignedPost: Error {
        case malformedEndpointURL
        case malformedBucketURL
    }
}

extension S3 {
    /// An encodable struct that represents acceptable values for the fields
    /// supplied in a presigned POST request
    public struct PostPolicy: Encodable {
        let expiration: Date
        let conditions: [PostPolicyCondition]

        func stringToSign() throws -> String {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let policyData = try encoder.encode(self)
            let base64encoded = policyData.base64EncodedString()

            return base64encoded
        }
    }

    /// A condition for use in a PostPolicy, which can represent an exact match
    /// on the value for a particular field, or a rule that allows for other
    /// types of matches, eg. "starts-with"
    public enum PostPolicyCondition: Encodable {
        case match(String, String)
        case rule(String, String, String)

        public func encode(to encoder: Encoder) throws {
            switch self {
            case .match(let field, let value):
                let condition = [field: value]
                var container = encoder.singleValueContainer()
                try container.encode(condition)

            case .rule(let rule, let field, let value):
                let condition = [rule, field, value]
                var container = encoder.singleValueContainer()
                try container.encode(condition)
            }
        }
    }

    /// An encodable struct that represents the URL and form fields to use in a
    /// presigned POST request to S3
    public struct PresignedPostResponse: Encodable {
        public let url: URL
        public let fields: [String: String]
    }

    ///  Builds the url and the form fields used for a presigned s3 post
    /// - Parameters:
    ///   - key: Key name, optionally add ${filename} to the end to attach the
    ///     submitted filename. Note that key related conditions and fields are
    ///     filled out for you and should not be included in the Fields or
    ///     Conditions parameter.
    ///   - bucket: The name of the bucket to presign the post to. Note that
    ///     bucket related conditions should not be included in the conditions parameter.
    ///   - fields: A dictionary of prefilled form fields to build on top of.
    ///     Elements that may be included are acl, Cache-Control, Content-Type,
    ///     Content-Disposition, Content-Encoding, Expires,
    ///     success_action_redirect, redirect, success_action_status, and x-amz-meta-.
    ///
    ///     Note that if a particular element is included in the fields
    ///     dictionary it will not be automatically added to the conditions
    ///     list. You must specify a condition for the element as well.
    ///   - conditions: A list of conditions to include in the policy. Each
    ///     element can be either a match or a rule. For example:
    ///
    ///     ```
    ///     [
    ///         .match("acl", "public-read"),
    ///         .rule("content-length-range", "2", "5"),
    ///         .rule("starts-with", "$success_action_redirect", "")
    ///     ]
    ///     ```
    ///
    ///     Conditions that are included may pertain to acl, content-length-range,
    ///     Cache-Control, Content-Type, Content-Disposition, Content-Encoding,
    ///     Expires, success_action_redirect, redirect, success_action_status,
    ///     and/or x-amz-meta-.
    ///
    ///     Note that if you include a condition, you must specify the a valid
    ///     value in the fields dictionary as well. A value will not be added
    ///     automatically to the fields dictionary based on the conditions.
    ///   - expiresIn: The number of seconds the presigned post is valid for.
    /// - Returns: An encodable PresignedPostResponse with two properties: url
    ///   and fields. Url is the url to post to. Fields is a dictionary filled
    ///   with the form fields and respective values to use when submitting the post.
    public func generatePresignedPost(
        key: String,
        bucket: String,
        fields: [String: String] = [:],
        conditions: [PostPolicyCondition] = [],
        expiresIn: TimeInterval
    ) async throws -> PresignedPostResponse {
        try await self.generatePresignedPost(
            key: key,
            bucket: bucket,
            fields: fields,
            conditions: conditions,
            expiresIn: expiresIn,
            date: Date()
        )
    }

    // Private API adds date argument for testing
    func generatePresignedPost(
        key: String,
        bucket: String,
        fields: [String: String] = [:],
        conditions: [PostPolicyCondition] = [],
        expiresIn: TimeInterval,
        date: Date = Date()
    ) async throws -> PresignedPostResponse {
        // Copy the fields and conditions to a variable
        var fields = fields
        var conditions: [PostPolicyCondition] = conditions

        // Update endpoint URL to include the bucket
        guard let url = URL(string: endpoint) else {
            throw S3ErrorType.presignedPost.malformedEndpointURL
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw S3ErrorType.presignedPost.malformedEndpointURL
        }

        guard let host = components.host else {
            throw S3ErrorType.presignedPost.malformedEndpointURL
        }

        components.host = "\(bucket).\(host)"

        guard let url = components.url else {
            throw S3ErrorType.presignedPost.malformedBucketURL
        }

        // Gather canonical values
        let algorithm = "AWS4-HMAC-SHA256"  // Get signature version from client?

        let longDate = self.longDateFormat(date: date)
        let shortDate = self.shortDateFormat(date: date)

        let clientCredentials = try await client.getCredential()
        let presignedPostCredential = self.getPresignedPostCredential(date: shortDate, accessKeyId: clientCredentials.accessKeyId)

        var keyCondition: PostPolicyCondition
        let suffix = "${filename}"
        if key.hasSuffix(suffix) {
            keyCondition = .rule("starts-with", "$key", String(key.dropLast(suffix.count)))
        } else {
            keyCondition = .match("key", key)
        }

        // Add required conditions
        conditions.append(.match("bucket", bucket))
        conditions.append(keyCondition)
        conditions.append(.match("x-amz-algorithm", algorithm))
        conditions.append(.match("x-amz-date", longDate))
        conditions.append(.match("x-amz-credential", presignedPostCredential))

        // Add required fields
        fields["key"] = key
        fields["x-amz-algorithm"] = algorithm
        fields["x-amz-date"] = longDate
        fields["x-amz-credential"] = presignedPostCredential

        if let sessionToken = clientCredentials.sessionToken {
            conditions.append(.match("x-amz-security-token", sessionToken))
            fields["x-amz-security-token"] = sessionToken
        }

        // Create the policy and add to fields
        let policy = PostPolicy(expiration: date.addingTimeInterval(expiresIn), conditions: conditions)
        let stringToSign = try policy.stringToSign()

        fields["Policy"] = stringToSign

        // Create the signature and add to fields
        let signingKey = signingKey(date: shortDate, secretAccessKey: clientCredentials.secretAccessKey)
        let signature = self.getSignature(policy: stringToSign, signingKey: signingKey)
        fields["x-amz-signature"] = signature

        // Create the response
        let presignedPostResponse = PresignedPostResponse(url: url, fields: fields)

        return presignedPostResponse
    }

    func signingKey(date: String, secretAccessKey: String) -> SymmetricKey {
        let name = config.signingName
        let region = config.region.rawValue

        let kDate = HMAC<SHA256>.authenticationCode(for: [UInt8](date.utf8), using: SymmetricKey(data: Array("AWS4\(secretAccessKey)".utf8)))
        let kRegion = HMAC<SHA256>.authenticationCode(for: [UInt8](region.utf8), using: SymmetricKey(data: kDate))
        let kService = HMAC<SHA256>.authenticationCode(for: [UInt8](name.utf8), using: SymmetricKey(data: kRegion))
        let kSigning = HMAC<SHA256>.authenticationCode(for: [UInt8]("aws4_request".utf8), using: SymmetricKey(data: kService))
        return SymmetricKey(data: kSigning)
    }

    func getSignature(policy: String, signingKey key: SymmetricKey) -> String {
        let signature = HMAC<SHA256>.authenticationCode(for: [UInt8](policy.utf8), using: key).hexDigest()
        return signature
    }

    func getPresignedPostCredential(date: String, accessKeyId: String) -> String {
        let region = config.region.rawValue
        let service = config.signingName

        let credential = "\(accessKeyId)/\(date)/\(region)/\(service)/aws4_request"
        return credential
    }

    private func shortDateFormat(date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withYear)
        formatter.formatOptions.insert(.withMonth)
        formatter.formatOptions.insert(.withDay)
        formatter.formatOptions.remove(.withTime)
        formatter.formatOptions.remove(.withTimeZone)
        formatter.formatOptions.remove(.withDashSeparatorInDate)

        let formattedDate = formatter.string(from: date)

        return formattedDate
    }

    private func longDateFormat(date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withYear)
        formatter.formatOptions.insert(.withMonth)
        formatter.formatOptions.insert(.withDay)
        formatter.formatOptions.insert(.withTime)
        formatter.formatOptions.insert(.withTimeZone)
        formatter.formatOptions.remove(.withDashSeparatorInDate)
        formatter.formatOptions.remove(.withColonSeparatorInTime)

        let formattedDate = formatter.string(from: date)

        return formattedDate
    }
}
