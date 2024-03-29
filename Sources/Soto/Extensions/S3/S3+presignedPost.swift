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
    public func generatePresignedPost(key: String, bucket: String, fields: [String: String] = [:], conditions: [PostPolicyCondition] = []) -> PresignedPostResponse {
        // Copy the fields and conditions to a variable
        var fields = fields
        var conditions = conditions

        // Gather canonical values
        let url = URL(from: self.config.endpoint)
        let algorithm = "AWS4-HMAC-SHA256" // Get signature version from client?
        let date = Date.now

        // Add required conditions
        conditions.append(.match("bucket", bucket))
        conditions.append(.match("key", key))
        conditions.append(.match("x-amz-algorithm", algorithm))
        conditions.append(.match("x-amz-date", "")) // TODO
        conditions.append(.match("x-amz-credential", "")) // TODO

        // Add required fields
        fields["key"] = key
        fields["x-amz-algorithm"] = algorithm
        fields["x-amz-date"] = "" // TODO
        fields["x-amz-credential"] = "" // TODO

        // Create the policy and add to fields
        let policy = PostPolicy(expiration: Date(), conditions: conditions)
        let stringToSign = policy.stringToSign()
        fields["Policy"] = stringToSign

        // Create the signature and add to fields
        let signature = getSignature(policy: stringToSign)
        fields["x-amz-signature"] = signature

        // Create the response
        let presignedPostResponse = PresignedPostResponse(url: url, fields: fields)

        return presignedPostResponse
    }

    private func getSigningKey() -> SymmetricKey {

    }

    private func getSignature(policy: String) -> String {
        return ""
    }

    private func getCredential() -> String {
        return ""
    }

}