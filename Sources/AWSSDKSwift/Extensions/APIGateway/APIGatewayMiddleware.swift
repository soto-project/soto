import AWSSDKSwiftCore

public struct APIGatewayMiddleware: AWSServiceMiddleware {
    public func chain(request: AWSRequest) throws -> AWSRequest {
        var request = request
        // have to set Accept header to application/json otherwise errors are not returned correctly
        if request.httpHeaders["Accept"] == nil {
            request.httpHeaders["Accept"] = "application/json"
        }
        return request
    }
}
