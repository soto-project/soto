import Foundation
import AWSSDKSwiftCore

public struct S3RequestMiddleware: AWSServiceMiddleware {

    public init () {}

    /// edit request before sending to S3
    public func chain(request: AWSRequest) throws -> AWSRequest {
        var request = request

        virtualAddressFixup(request: &request)
        metadataFixup(request: &request)
        createBucketFixup(request: &request)
        calculateMD5(request: &request)

        return request
    }

    /// Edit responses coming back from S3
    public func chain(response: AWSResponse) throws -> AWSResponse {
        var response = response

        metadataFixup(response: &response)
        getLocationResponseFixup(response: &response)

        return response
    }

    func virtualAddressFixup(request: inout AWSRequest) {
        /// process URL into form ${bucket}.s3.amazon.com
        var paths = request.url.path.components(separatedBy: "/").filter({ $0 != "" })
        if paths.count > 0 {
            switch request.httpMethod.lowercased() {
            case "get":
                guard let host = request.url.host, host.contains("amazonaws.com") else { break }
                let query = request.url.query != nil ? "?\(request.url.query!)" : ""
                request.url = URL(string: "\(request.url.scheme ?? "https")://\(paths.removeFirst()).\(host)/\(paths.joined(separator: "/"))\(query)")!
            default:
                guard let host = request.url.host, host.contains("amazonaws.com") else { break }
                var pathes = request.url.path.components(separatedBy: "/")
                if paths.count > 1 {
                    _ = pathes.removeFirst() // /
                    let bucket = pathes.removeFirst() // bucket
                    var urlString: String
                    if let firstHostComponent = host.components(separatedBy: ".").first, bucket == firstHostComponent {
                        // Bucket name is part of host. No need to append bucket
                        urlString = "https://\(host)/\(pathes.joined(separator: "/"))"
                    } else {
                        urlString = "https://\(bucket).\(host)/\(pathes.joined(separator: "/"))"
                    }
                    if let query = request.url.query {
                        urlString += "?\(query)"
                    }
                    request.url = URL(string: urlString)!
                }
            }
        }
    }

    func metadataFixup(request: inout AWSRequest) {
        // add metadata to request
        if let metadata = request.httpHeaders["x-amz-meta-"] as? [String: String] {
            for (key,value) in metadata {
                // metadata keys have to be lowercase or signing fails
                request.httpHeaders["x-amz-meta-\(key.lowercased())"] = value
            }
            request.httpHeaders["x-amz-meta-"] = nil
        }
    }

    func createBucketFixup(request: inout AWSRequest) {
        switch request.operation {
        // fixup CreateBucket to include location
        case "CreateBucket":
            var xml = ""
            if request.region != .useast1 {
                xml += "<CreateBucketConfiguration xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">"
                xml += "<LocationConstraint>"
                xml += request.region.rawValue
                xml += "</LocationConstraint>"
                xml += "</CreateBucketConfiguration>"
            }
            request.body = .text(xml)

        default:
            break
        }
    }

    func calculateMD5(request: inout AWSRequest) {
        // if request has a body, calculate the MD5 for that body
        if let data = request.body.asData() {
            let encoded = Data(md5(data)).base64EncodedString()
            request.addValue(encoded, forHTTPHeaderField: "Content-MD5")
        }
    }

    func getLocationResponseFixup(response: inout AWSResponse) {
        if case .xml(let element) = response.body {
            // GetBucketLocation comes back without a containing xml element
            if element.name == "LocationConstraint" {
                let parentElement = XML.Element(name: "BucketLocation")
                parentElement.addChild(element)
                response.body = .xml(parentElement)
            }
        }
    }

    func metadataFixup(response: inout AWSResponse) {
        // convert x-amz-meta-* header values into a dictionary, which we add as a "x-amz-meta-" header. This is processed by AWSClient to fill metadata values in GetObject and HeadObject
        switch response.body {
        case .buffer(_), .empty:
            var metadata : [String: String] = [:]
            for (key, value) in response.headers {
                if key.hasPrefix("x-amz-meta-"), let value = value as? String {
                    let keyWithoutPrefix = key.dropFirst("x-amz-meta-".count)
                    metadata[String(keyWithoutPrefix)] = value
                }
            }
            if !metadata.isEmpty {
                response.headers["x-amz-meta-"] = metadata
            }
        default:
            break
        }
    }
}
