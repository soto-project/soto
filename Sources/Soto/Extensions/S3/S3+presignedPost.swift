import Crypto

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
    public func generatePresignedPost(key: String, bucket: String, fields: [String: String] = [:], conditions: [PostPolicyCondition] = [], expiresIn: TimeInterval) -> PresignedPostResponse {
        // Copy the fields and conditions to a variable
        var fields = fields
        var conditions = conditions

        // Update endpoint URL to include the bucket
        var url = URL(from: self.config.endpoint)
        url.host = [bucket, url.host].joined(separator: ".")

        // Gather canonical values
        let algorithm = "AWS4-HMAC-SHA256" // Get signature version from client?
        let date = Date.now
        let region = self.config.region

        // Add required conditions
        conditions.append(.match("bucket", bucket))
        conditions.append(.match("key", key))
        conditions.append(.match("x-amz-algorithm", algorithm))
        conditions.append(.match("x-amz-date", "")) // TODO
        conditions.append(.match("x-amz-credential", getCredential()))

        // Add required fields
        fields["key"] = key
        fields["x-amz-algorithm"] = algorithm
        fields["x-amz-date"] = "" // TODO
        fields["x-amz-credential"] = getCredential()

        // Create the policy and add to fields
        let policy = PostPolicy(expiration: date.adding(expiresIn), conditions: conditions)
        let stringToSign = policy.stringToSign()
        fields["Policy"] = stringToSign

        // Create the signature and add to fields
        let signature = getSignature(policy: stringToSign)
        fields["x-amz-signature"] = signature

        // Create the response
        let presignedPostResponse = PresignedPostResponse(url: url, fields: fields)

        return presignedPostResponse
    }

    private func signingKey(date: String) -> SymmetricKey {
        let credentials = await client.credentialProvider.getCredential()
        let name = client.config.name
        let region = client.config.region

        let kDate = HMAC<SHA256>.authenticationCode(for: [UInt8](date.utf8), using: SymmetricKey(data: Array("AWS4\(credentials.secretAccessKey)".utf8)))
        let kRegion = HMAC<SHA256>.authenticationCode(for: [UInt8](region.utf8), using: SymmetricKey(data: kDate))
        let kService = HMAC<SHA256>.authenticationCode(for: [UInt8](name.utf8), using: SymmetricKey(data: kRegion))
        let kSigning = HMAC<SHA256>.authenticationCode(for: [UInt8]("aws4_request".utf8), using: SymmetricKey(data: kService))
        return SymmetricKey(data: kSigning)
    }

    private func getSignature(policy: String, date: String) -> String {
        let key = signingKey(date: date)
        let signature = HMAC<SHA256>.authenticationCode(for: Data(stringToSign.utf8), using: key)
        return signature
    }

    private func getCredential() -> String {
        let credentials = await client.credentialProvider.getCredential()

        let accessKeyID = credentials.accessKeyID
        let date = date
        let region = config.region
        let service = config.name

        let credential = "\(accessKeyID)/\(date)/\(region)/\(service)"
        return credential
    }

}