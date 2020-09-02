//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import SotoCrypto
import SotoCore
import SotoXML
import Foundation
import NIO

public struct S3RequestMiddleware: AWSServiceMiddleware {
    public init() {}

    /// edit request before sending to S3
    public func chain(request: AWSRequest, context: AWSMiddlewareContext) throws -> AWSRequest {
        var request = request

        self.virtualAddressFixup(request: &request, context: context)
        self.createBucketFixup(request: &request)
        self.calculateMD5(request: &request)

        return request
    }

    /// Edit responses coming back from S3
    public func chain(response: AWSResponse, context: AWSMiddlewareContext) throws -> AWSResponse {
        var response = response

        self.metadataFixup(response: &response)
        self.getLocationResponseFixup(response: &response)

        return response
    }

    func virtualAddressFixup(request: inout AWSRequest, context: AWSMiddlewareContext) {
        /// process URL into form ${bucket}.s3.amazon.com
        let paths = request.url.path.split(separator: "/", omittingEmptySubsequences: true)
        if paths.count > 0 {
            guard var host = request.url.host else { return }
            if let port = request.url.port {
                host = "\(host):\(port)"
            }
            let bucket = paths[0]
            var urlPath: String
            var urlHost: String
            // if host name contains amazonaws.com and bucket name doesn't contain a period do virtual address look up
            if host.contains("amazonaws.com") || context.options.contains(.s3ForceVirtualHost), !bucket.contains(".") {
                let pathsWithoutBucket = paths.dropFirst() // bucket
                urlPath = pathsWithoutBucket.joined(separator: "/")
                if let firstHostComponent = host.split(separator: ".").first, bucket == firstHostComponent {
                    // Bucket name is part of host. No need to append bucket
                    urlHost = host
                } else {
                    urlHost = "\(bucket).\(host)"
                }
            } else {
                urlPath = paths.joined(separator: "/")
                urlHost = host
            }
            // add percent encoding back into path as converting from URL to String has removed it
            let percentEncodedUrlPath = urlPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? urlPath
            var urlString = "\(request.url.scheme ?? "https")://\(urlHost)/\(percentEncodedUrlPath)"
            if let query = request.url.query {
                urlString += "?\(query)"
            }
            request.url = URL(string: urlString)!
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
        if let byteBuffer = request.body.asByteBuffer(byteBufferAllocator: ByteBufferAllocator()) {
            let byteBufferView = byteBuffer.readableBytesView
            if let encoded = byteBufferView.withContiguousStorageIfAvailable({ bytes in
                return Data(Insecure.MD5.hash(data: bytes)).base64EncodedString()
            }) {
                request.httpHeaders.replaceOrAdd(name: "Content-MD5", value: encoded)
            }
        }
    }

    func getLocationResponseFixup(response: inout AWSResponse) {
        if case .xml(let element) = response.body {
            // GetBucketLocation comes back without a containing xml element
            if element.name == "LocationConstraint" {
                if element.stringValue == "" {
                    element.addChild(.text(stringValue: "us-east-1"))
                }
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
