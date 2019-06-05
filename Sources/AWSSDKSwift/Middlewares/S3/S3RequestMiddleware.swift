import Foundation
import AWSSDKSwiftCore

public struct S3RequestMiddleware: AWSRequestMiddleware {

    public init () {}

    public func chain(request: AWSRequest) throws -> AWSRequest {
        var request = request

        var paths = request.url.path.components(separatedBy: "/").filter({ $0 != "" })
        if paths.count == 0 {
            return request
        }

        switch request.httpMethod.lowercased() {
        case "get":
            let query = request.url.query != nil ? "?\(request.url.query!)" : ""
            let domain: String
            if let host = request.url.host, host.contains("amazonaws.com") {
                domain = host
            } else {
                let port = request.url.port == nil ? "" : ":\(request.url.port!)"
                domain = request.url.host!+port
            }
            request.url = URL(string: "\(request.url.scheme ?? "https")://\(paths.removeFirst()).\(domain)/\(paths.joined(separator: "/"))\(query)")!
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

        switch request.operation {
        case "CreateBucket":
            if request.region != .useast1 {
                var xml = ""
                xml += "<CreateBucketConfiguration xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">"
                xml += "<LocationConstraint>"
                xml += request.region.rawValue
                xml += "</LocationConstraint>"
                xml += "</CreateBucketConfiguration>"
                request.body = .text(xml)
            }

        default:
            break
        }

        if let data = try request.body.asData() {
            let encoded = Data(md5(data)).base64EncodedString()
            request.addValue(encoded, forHTTPHeaderField: "Content-MD5")
        }

        return request
    }
}
