import Foundation
import AWSSDKSwiftCore

struct S3RequestMiddleware: AWSRequestMiddleware {
    func chain(request: AWSRequest) throws -> AWSRequest {
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
                domain = "s3-\(request.region.rawValue).amazonaws.com"
            } else {
                let port = request.url.port == nil ? "" : ":\(request.url.port!)"
                domain = request.url.host!+port
            }
            request.url = URL(string: "\(request.url.scheme ?? "https")://\(paths.removeFirst()).\(domain)/\(paths.joined(separator: "/"))\(query)")!
        default:
            break
        }

        switch request.operation {
        case "CreateBucket":
            var xml = ""
            xml += "<CreateBucketConfiguration xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">"
            xml += "<LocationConstraint>"
            xml += request.region.rawValue
            xml += "</LocationConstraint>"
            xml += "</CreateBucketConfiguration>"
            request.body = .text(xml)
            
        case "PutObject":
            if let data = try request.body.asData() {
                let encoded = Data(bytes: md5(data)).base64EncodedString()
                request.addValue(encoded, forHTTPHeaderField: "Content-MD5")
            }
        default:
            break
        }
        
        return request
    }
}
