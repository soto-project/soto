import Atomics
import Logging
import NIOConcurrencyHelpers
import NIOCore
import NIOPosix
import SotoCore
import Foundation

import Crypto

extension S3ErrorType {
    public enum presignedPost: Error {
        case badURL
    }
}

extension S3 {
    public struct PostPolicy: Encodable {
        let expiration: Date
        let conditions: [PostPolicyCondition]

        func stringToSign() -> String {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let policyData = try? encoder.encode(self)
            guard let base64encoded = policyData?.base64EncodedString() else {
                // Couldn't make a string to sign
            }

            return base64encoded
        }
    }

    public enum PostPolicyCondition: Encodable {
        case match(String, String)
        case rule(String, String, String)

        public func encode(to encoder: Encoder) throws {
            switch self {
                case let .match(field, value):
                    let condition = [field: value]
                    var container = encoder.singleValueContainer()
                    try container.encode(condition)

                case let .rule(rule, field, value):
                    let condition = [rule, field, value]
                    var container = encoder.singleValueContainer()
                    try container.encode(condition)
            }
        }
    }

    public struct PresignedPostResponse: Encodable {
        let url: URL
        let fields: [String: String]
    }

    /// 
    @Sendable
    public func generatePresignedPost(key: String, bucket: String, fields: [String: String] = [:], conditions: [PostPolicyCondition] = [], expiresIn: TimeInterval) async throws -> PresignedPostResponse {
        // Copy the fields and conditions to a variable
        var fields = fields
        var conditions = conditions

        // Update endpoint URL to include the bucket
        guard let url = URL(string: "https://\(bucket).\(endpoint)/") else {
            throw S3ErrorType.presignedPost.badURL
        }

        // Gather canonical values
        let algorithm = "AWS4-HMAC-SHA256" // Get signature version from client?

        let date = Date.now
        let longDate = longDateFormat(date: date)
        let shortDate = shortDateFormat(date: date)

        let credential = await getCredential(date: shortDate)

        // Add required conditions
        conditions.append(.match("bucket", bucket))
        conditions.append(.match("key", key))
        conditions.append(.match("x-amz-algorithm", algorithm))
        conditions.append(.match("x-amz-date", longDate)) // TODO
        conditions.append(.match("x-amz-credential", credential))

        // Add required fields
        fields["key"] = key
        fields["x-amz-algorithm"] = algorithm
        fields["x-amz-date"] = longDate // TODO
        fields["x-amz-credential"] = credential

        // Create the policy and add to fields
        let policy = PostPolicy(expiration: date.addingTimeInterval(expiresIn), conditions: conditions)
        let stringToSign = policy.stringToSign()
        fields["Policy"] = stringToSign

        // Create the signature and add to fields
        let signature = await getSignature(policy: stringToSign, date: shortDate)
        fields["x-amz-signature"] = signature

        // Create the response
        let presignedPostResponse = PresignedPostResponse(url: url, fields: fields)

        return presignedPostResponse
    }

    private func signingKey(date: String) async -> SymmetricKey {
        let credentials = await client.credentialProvider.getCredential()
        let name = config.service
        let region = config.region.rawValue

        let kDate = HMAC<SHA256>.authenticationCode(for: [UInt8](date.utf8), using: SymmetricKey(data: Array("AWS4\(credentials.secretAccessKey)".utf8)))
        let kRegion = HMAC<SHA256>.authenticationCode(for: [UInt8](region.utf8), using: SymmetricKey(data: kDate))
        let kService = HMAC<SHA256>.authenticationCode(for: [UInt8](name.utf8), using: SymmetricKey(data: kRegion))
        let kSigning = HMAC<SHA256>.authenticationCode(for: [UInt8]("aws4_request".utf8), using: SymmetricKey(data: kService))
        return SymmetricKey(data: kSigning)
    }

    private func getSignature(policy: String, date: String) async -> String {
        let key = await signingKey(date: date)
        let signature = HMAC<SHA256>.authenticationCode(for: [UInt8](policy.utf8), using: key).hexDigest()
        return signature
    }

    private func getCredential(date: String) async -> String {
        let credentials = await client.credentialProvider.getCredential()

        let accessKeyID = credentials.accessKeyID
        let region = config.region.rawValue
        let service = config.service

        let credential = "\(accessKeyID)/\(date)/\(region)/\(service)"
        return credential
    }

    private func shortDateFormat(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyyMMdd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        return dateFormatter.string(from: date)
    }

    private func longDateFormat(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        return dateFormatter.string(from: date)
    }

}