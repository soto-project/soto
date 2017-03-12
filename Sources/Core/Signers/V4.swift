//
//  V4.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/13.
//
//

import Foundation
import CLibreSSL

extension Signers {
    public final class V4 {
        
        public let credentials: CredentialProvider
        
        public let region: Region
        
        public let service: String
        
        let identifier = "aws4_request"
        
        let algorithm = "AWS4-HMAC-SHA256"
        
        func hexEncodedBodyHash(digest: String) -> String {
            if digest.isEmpty && service == "s3" {
                return "UNSIGNED-PAYLOAD"
            }
            return digest
        }
        
        public init(credentials: CredentialProvider, region: Region, service: String) {
            self.credentials = credentials
            self.region = region
            self.service = service
        }
        
        public func signedURLWithQueryParams(url: URL, date: Date = Date()) -> URL {
            let datetime = timestamp(date)
            let headers = ["Host": url.host!]
            let bodyDigest = hexEncodedBodyHash(digest: "")
            
            var queries = [
                URLQueryItem(name: "X-Amz-Algorithm", value: algorithm),
                URLQueryItem(name: "X-Amz-Credential", value: credential(datetime).replacingOccurrences(of: "/", with: "%2F")),
                URLQueryItem(name: "X-Amz-Date", value: datetime),
                URLQueryItem(name: "X-Amz-Expires", value: "86400"),
                URLQueryItem(name: "X-Amz-SignedHeaders", value: "host"),
            ]
            
            url.query?.components(separatedBy: "&").forEach {
                var q = $0.components(separatedBy: "=")
                if q.count == 2 {
                    queries.append(URLQueryItem(name: q[0], value: q[1]))
                } else {
                    queries.append(URLQueryItem(name: q[0], value: nil))
                }
            }
            
            let url = URL(string: url.absoluteString.components(separatedBy: "?")[0]+"?"+queries.asStringForURL)!
            
            let sig = signature(
                url: url,
                headers: headers,
                datetime: datetime,
                method: "GET",
                bodyDigest: bodyDigest
            )
            
            return URL(string: url.absoluteString+"&X-Amz-Signature="+sig)!
        }
        
        public func signedHeaders(url: URL, bodyDigest: String, method: String, date: Date = Date()) -> [String: String] {
            let datetime = timestamp(date)
            
            var headers = [
                "x-amz-content-sha256": bodyDigest,
                "x-amz-date": datetime,
                "Host": url.host!,
            ]
            
            headers["Authorization"] = authorization(
                url: url,
                headers: headers,
                datetime: datetime,
                method: method,
                bodyDigest: hexEncodedBodyHash(digest: bodyDigest)
            )
            
            return headers
        }
        
        func timestamp(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            formatter.timeZone = TimeZone(abbreviation: "UTC")
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter.string(from: date)
        }
        
        func authorization(url: URL, headers: [String: String], datetime: String, method: String, bodyDigest: String) -> String {
            let cred = credential(datetime)
            let shead = signedHeaders(headers)
            
            let sig = signature(
                url: url,
                headers: headers,
                datetime: datetime,
                method: method,
                bodyDigest: bodyDigest
            )
            
            return [
                "AWS4-HMAC-SHA256 Credential=\(cred)",
                "SignedHeaders=\(shead)",
                "Signature=\(sig)",
            ].joined(separator: ", ")
        }
        
        func credential(_ datetime: String) -> String {
            return "\(credentials.accessKeyId)/\(credentialScope(datetime))"
        }
        
        func signedHeaders(_ headers: [String:String]) -> String {
            var list = Array(headers.keys).map { $0.lowercased() }.sorted()
            if let index = list.index(of: "authorization") {
                list.remove(at: index)
            }
            return list.joined(separator: ";")
        }
        
        func canonicalHeaders(_ headers: [String: String]) -> String {
            var list = [String]()
            let keys = Array(headers.keys).sorted {$0.localizedCompare($1) == ComparisonResult.orderedAscending }
            
            for key in keys {
                if key.caseInsensitiveCompare("authorization") != ComparisonResult.orderedSame {
                    list.append("\(key.lowercased()):\(headers[key]!)")
                }
            }
            return list.joined(separator: "\n")
        }
        
        func signature(url: URL, headers: [String: String], datetime: String, method: String, bodyDigest: String) -> String {
            let secretBytes = Array(String(format: "AWS4%@", self.credentials.secretAccessKey).utf8)
            let date = hmac(string: datetime.substring(to: datetime.index(datetime.startIndex, offsetBy: 8)), key: secretBytes)
            
            let region = hmac(string: self.region.rawValue, key: date)
            let service = hmac(string: self.service, key: region)
            let credentials = hmac(string: identifier, key: service)
            let string = stringToSign(
                datetime: datetime,
                url: url,
                headers: headers,
                method: method,
                bodyDigest: bodyDigest
            )
            
            return hmac(string: string, key: credentials).hexdigest()
        }
        
        func credentialScope(_ datetime: String) -> String {
            return [
                datetime.substring(to: datetime.index(datetime.startIndex, offsetBy: 8)),
                region.rawValue,
                service,
                identifier
            ].joined(separator: "/")
        }
        
        func stringToSign(datetime: String, url: URL, headers: [String: String], method: String, bodyDigest: String) -> String {
            
            let canonicalRequestString = canonicalRequest(url: url, headers: headers, method: method, bodyDigest: bodyDigest)
            var canonicalRequestBytes = Array(canonicalRequestString.utf8)
            
            return [
                "AWS4-HMAC-SHA256",
                datetime,
                credentialScope(datetime),
                sha256(&canonicalRequestBytes).hexdigest(),
            ].joined(separator: "\n")
        }
        
        func canonicalRequest(url: URL, headers: [String: String], method: String, bodyDigest: String) -> String {
            return [
                method,
                url.path,
                url.query ?? "",
                "\(canonicalHeaders(headers))\n",
                signedHeaders(headers),
                bodyDigest
            ].joined(separator: "\n")
        }
    }
}


extension Collection where Iterator.Element == URLQueryItem {
    var asStringForURL: String {
        return self.flatMap({ "\($0.name)=\($0.value ?? "")" }).joined(separator: "&")
    }
}
