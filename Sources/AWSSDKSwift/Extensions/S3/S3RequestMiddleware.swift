//===----------------------------------------------------------------------===//
//
// This source file is part of the AWSSDKSwift open source project
//
// Copyright (c) 2017-2020 the AWSSDKSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of AWSSDKSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import AWSCrypto
import AWSSDKSwiftCore
import Foundation

public struct S3RequestMiddleware: AWSServiceMiddleware {

    public init() {}

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
            guard let host = request.url.host, host.contains("amazonaws.com") else { return }
            let bucket = paths.removeFirst()  // bucket
            // if bucket name contains a period don't do virtual address look up
            guard !bucket.contains(".") else { return }
            var urlPath: String
            if let firstHostComponent = host.components(separatedBy: ".").first, bucket == firstHostComponent {
                // Bucket name is part of host. No need to append bucket
                urlPath = "\(host)/\(paths.joined(separator: "/"))"
            } else {
                urlPath = "\(bucket).\(host)/\(paths.joined(separator: "/"))"
            }
            // add percent encoding back into path as converting from URL to String has removed it
            urlPath = urlPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? urlPath
            var urlString = "\(request.url.scheme ?? "https")://\(urlPath)"
            if let query = request.url.query {
                urlString += "?\(query)"
            }
            request.url = URL(string: urlString)!
        }
    }

    func metadataFixup(request: inout AWSRequest) {
        // add metadata to request
        if let metadata = request.httpHeaders["x-amz-meta-"] as? [String: String] {
            for (key, value) in metadata {
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
        if let byteBuffer = request.body.asByteBuffer() {
            let byteBufferView = byteBuffer.readableBytesView
            if let encoded = byteBufferView.withContiguousStorageIfAvailable({ bytes in
                return Data(Insecure.MD5.hash(data: bytes)).base64EncodedString()
            }) {
                request.addValue(encoded, forHTTPHeaderField: "Content-MD5")
            }
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
        case .raw(_), .empty:
            var metadata: [String: String] = [:]
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
