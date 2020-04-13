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

import Foundation
import AWSSDKSwiftCore
import AWSCrypto
import NIO

//MARK: SelectObjectContent EventStream

public enum S3SelectError: Error {
    case corruptHeader
    case corruptPayload
    case selectContentError(String)
}

// CRC32 calculation from https://gist.github.com/antfarm/695fa78e0730b67eb094c77d53942216
struct CRC32 {
    static var table: [UInt32] = {
        (0...255).map { i -> UInt32 in
            (0..<8).reduce(UInt32(i), { c, _ in
                (c % 2 == 0) ? (c >> 1) : (0xEDB88320 ^ (c >> 1))
            })
        }
    }()
    static func checksum<D: DataProtocol>(_ bytes: D) -> UInt32 {
        return ~(bytes.reduce(~UInt32(0), { crc, byte in
            (crc >> 8) ^ table[(Int(crc) ^ Int(byte)) & 0xFF]
        }))
    }
}

extension S3.SelectObjectContentEventStream: AWSClientStreamable {
    public static func consume(byteBuffer: inout ByteBuffer) throws -> Self? {
        
        // read header values from ByteBuffer. Format is uint8 name length, name, 7, uint16 value length, value
        func readHeaderValues(_ byteBuffer: ByteBuffer) throws -> [String: String] {
            var byteBuffer = byteBuffer
            var headers: [String: String] = [:]
            while(byteBuffer.readableBytes > 0) {
                guard let headerLength: UInt8 = byteBuffer.readInteger(),
                    let header: String = byteBuffer.readString(length: Int(headerLength)),
                    let byte: UInt8 = byteBuffer.readInteger(), byte == 7,
                    let valueLength: UInt16 = byteBuffer.readInteger(),
                    let value: String = byteBuffer.readString(length: Int(valueLength)) else {
                        throw S3SelectError.corruptHeader
                }
                headers[header] = value
            }
            return headers
        }
        
        let rootElement = XML.Element(name: "Payload")
        
        while(byteBuffer.readableBytes > 0) {
            // get prelude buffer and crc. Return nil if we don't have enough data
            guard var preludeBuffer = byteBuffer.getSlice(at: byteBuffer.readerIndex, length: 8) else { return nil }
            guard let preludeCRC: UInt32 = byteBuffer.getInteger(at: byteBuffer.readerIndex + 8) else { return nil }
            // verify crc
            let calculatedPreludeCRC = preludeBuffer.withUnsafeReadableBytes({ buffer in CRC32.checksum(buffer) })
            guard preludeCRC == calculatedPreludeCRC else { throw S3SelectError.corruptPayload }
            // get lengths
            guard let totalLength: Int32 = preludeBuffer.readInteger(),
                let headerLength: Int32 = preludeBuffer.readInteger() else { return nil }
            
            // get message and message CRC. Return nil if we don't have enough data
            guard var messageBuffer = byteBuffer.readSlice(length: Int(totalLength - 4)),
                let messageCRC: UInt32 = byteBuffer.readInteger()  else { return nil }
            // verify message CRC
            let calculatedCRC = messageBuffer.withUnsafeReadableBytes({ buffer in CRC32.checksum(buffer) })
            guard messageCRC == calculatedCRC else { throw S3SelectError.corruptPayload }

            // skip past prelude
            messageBuffer.moveReaderIndex(forwardBy: 12)

            // get headers
            guard let headerBuffer: ByteBuffer = messageBuffer.readSlice(length: Int(headerLength)) else {
                throw S3SelectError.corruptHeader
            }
            let headers = try readHeaderValues(headerBuffer)
            if headers[":message-type"] == "error" {
                throw S3SelectError.selectContentError(headers[":error-code"] ?? "Unknown")
            }

            let payloadSize = Int(totalLength - headerLength - 16)

            switch headers[":event-type"] {
            case "Records":
                guard let data = messageBuffer.readData(length: payloadSize) else { throw S3SelectError.corruptPayload }
                let payloadElement = XML.Element(name: "Payload", stringValue: data.base64EncodedString())
                let recordsElement = XML.Element(name: "Records")
                recordsElement.addChild(payloadElement)
                rootElement.addChild(recordsElement)
                
            case "Cont":
                guard payloadSize == 0 else { throw S3SelectError.corruptPayload }
                
            case "Progress":
                guard let data = messageBuffer.readData(length: payloadSize) else { throw S3SelectError.corruptPayload }
                let xmlElement = try XML.Element(xmlData: data)
                xmlElement.name = "Details"
                let progressElement = XML.Element(name: "Progress")
                progressElement.addChild(xmlElement)
                rootElement.addChild(progressElement)

            case "Stats":
                guard let data = messageBuffer.readData(length: payloadSize) else { throw S3SelectError.corruptPayload }
                let xmlElement = try XML.Element(xmlData: data)
                xmlElement.name = "Details"
                let progressElement = XML.Element(name: "Stats")
                progressElement.addChild(xmlElement)
                rootElement.addChild(progressElement)
                
            case "End":
                break
                
            default:
                throw S3SelectError.corruptPayload
            }
            
        }

        return try XMLDecoder().decode(Self.self, from: rootElement)
    }
}

extension S3 {
    /// This operation filters the contents of an Amazon S3 object based on a simple structured query language (SQL) statement. In the request, along with the SQL expression, you must also specify a data serialization format (JSON, CSV, or Apache Parquet) of the object. Amazon S3 uses this format to parse object data into records, and returns only records that match the specified SQL expression. You must also specify the data serialization format for the response. For more information about Amazon S3 Select, see Selecting Content from Objects in the Amazon Simple Storage Service Developer Guide. For more information about using SQL with Amazon S3 Select, see  SQL Reference for Amazon S3 Select and Glacier Select in the Amazon Simple Storage Service Developer Guide.   Permissions  You must have s3:GetObject permission for this operation. Amazon S3 Select does not support anonymous access. For more information about permissions, see Specifying Permissions in a Policy in the Amazon Simple Storage Service Developer Guide.   Object Data Formats  You can use Amazon S3 Select to query objects that have the following format properties:    CSV, JSON, and Parquet - Objects must be in CSV, JSON, or Parquet format.    UTF-8 - UTF-8 is the only encoding type Amazon S3 Select supports.    GZIP or BZIP2 - CSV and JSON files can be compressed using GZIP or BZIP2. GZIP and BZIP2 are the only compression formats that Amazon S3 Select supports for CSV and JSON files. Amazon S3 Select supports columnar compression for Parquet using GZIP or Snappy. Amazon S3 Select does not support whole-object compression for Parquet objects.    Server-side encryption - Amazon S3 Select supports querying objects that are protected with server-side encryption. For objects that are encrypted with customer-provided encryption keys (SSE-C), you must use HTTPS, and you must use the headers that are documented in the GetObject. For more information about SSE-C, see Server-Side Encryption (Using Customer-Provided Encryption Keys) in the Amazon Simple Storage Service Developer Guide. For objects that are encrypted with Amazon S3 managed encryption keys (SSE-S3) and customer master keys (CMKs) stored in AWS Key Management Service (SSE-KMS), server-side encryption is handled transparently, so you don't need to specify anything. For more information about server-side encryption, including SSE-S3 and SSE-KMS, see Protecting Data Using Server-Side Encryption in the Amazon Simple Storage Service Developer Guide.    Working with the Response Body  Given the response size is unknown, Amazon S3 Select streams the response as a series of messages and includes a Transfer-Encoding header with chunked as its value in the response. For more information, see RESTSelectObjectAppendix .   GetObject Support  The SelectObjectContent operation does not support the following GetObject functionality. For more information, see GetObject.    Range: While you can specify a scan range for a Amazon S3 Select request, see SelectObjectContentRequest$ScanRange in the request parameters below, you cannot specify the range of bytes of an object to return.    GLACIER, DEEP_ARCHIVE and REDUCED_REDUNDANCY storage classes: You cannot specify the GLACIER, DEEP_ARCHIVE, or REDUCED_REDUNDANCY storage classes. For more information, about storage classes see Storage Classes in the Amazon Simple Storage Service Developer Guide.     Special Errors  For a list of special errors for this operation and for general information about Amazon S3 errors and a list of error codes, see ErrorResponses   Related Resources     GetObject     GetBucketLifecycleConfiguration     PutBucketLifecycleConfiguration
    ///
    /// - Parameters:
    ///   - input: Request structure
    ///   - stream: callback to process events streamed
    /// - Returns: Response structure
    public func selectObjectContentEventStream(_ input: SelectObjectContentRequest, _ stream: @escaping (SelectObjectContentEventStream, EventLoop)->EventLoopFuture<Void>) -> EventLoopFuture<SelectObjectContentOutput> {
        return client.send(operation: "SelectObjectContent", path: "/{Bucket}/{Key+}?select&select-type=2", httpMethod: "POST", input: input, stream: stream)
    }
}
