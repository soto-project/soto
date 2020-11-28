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

import CSotoZlib
import Foundation
import NIO
import SotoCrypto
import SotoXML

// MARK: SelectObjectContent EventStream

public enum S3SelectError: Error {
    case corruptHeader
    case corruptPayload
    case selectContentError(String)
}

extension S3.SelectObjectContentEventStream {
    public static func consume(byteBuffer: inout ByteBuffer) throws -> Self? {
        // read header values from ByteBuffer. Format is uint8 name length, name, 7, uint16 value length, value
        func readHeaderValues(_ byteBuffer: ByteBuffer) throws -> [String: String] {
            var byteBuffer = byteBuffer
            var headers: [String: String] = [:]
            while byteBuffer.readableBytes > 0 {
                guard let headerLength: UInt8 = byteBuffer.readInteger(),
                      let header: String = byteBuffer.readString(length: Int(headerLength)),
                      let byte: UInt8 = byteBuffer.readInteger(), byte == 7,
                      let valueLength: UInt16 = byteBuffer.readInteger(),
                      let value: String = byteBuffer.readString(length: Int(valueLength))
                else {
                    throw S3SelectError.corruptHeader
                }
                headers[header] = value
            }
            return headers
        }

        let rootElement = XML.Element(name: "Payload")

        while byteBuffer.readableBytes > 0 {
            // get prelude buffer and crc. Return nil if we don't have enough data
            guard var preludeBuffer = byteBuffer.getSlice(at: byteBuffer.readerIndex, length: 8) else { return nil }
            guard let preludeCRC: UInt32 = byteBuffer.getInteger(at: byteBuffer.readerIndex + 8) else { return nil }
            // verify crc
            let preludeBufferView = ByteBufferView(preludeBuffer)
            let calculatedPreludeCRC = preludeBufferView.withContiguousStorageIfAvailable { bytes in crc32(0, bytes.baseAddress, uInt(bytes.count)) }
            guard UInt(preludeCRC) == calculatedPreludeCRC else { throw S3SelectError.corruptPayload }
            // get lengths
            guard let totalLength: Int32 = preludeBuffer.readInteger(),
                  let headerLength: Int32 = preludeBuffer.readInteger() else { return nil }

            // get message and message CRC. Return nil if we don't have enough data
            guard var messageBuffer = byteBuffer.readSlice(length: Int(totalLength - 4)),
                  let messageCRC: UInt32 = byteBuffer.readInteger() else { return nil }
            // verify message CRC
            let messageBufferView = ByteBufferView(messageBuffer)
            let calculatedCRC = messageBufferView.withContiguousStorageIfAvailable { bytes in crc32(0, bytes.baseAddress, uInt(bytes.count)) }
            guard UInt(messageCRC) == calculatedCRC else { throw S3SelectError.corruptPayload }

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
    /// This operation filters the contents of an Amazon S3 object based on a simple structured query language (SQL) statement. In the request, along with the SQL expression, you must also specify a data serialization format (JSON, CSV, or Apache Parquet) of the object. Amazon S3 uses this format to parse object data into records, and returns only records that match the specified SQL expression. You must also specify the data serialization format for the response.
    ///
    /// This action is not supported by Amazon S3 on Outposts.
    ///
    /// For more information about Amazon S3 Select, see <a href=\"https://docs.aws.amazon.com/AmazonS3/latest/dev/selecting-content-from-objects.html\">Selecting Content from Objects</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
    ///
    /// For more information about using SQL with Amazon S3 Select, see <a href=\"https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-glacier-select-sql-reference.html\"> SQL Reference for Amazon S3 Select and S3 Glacier Select</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.</p> <p/> <p> <b>Permissions</b>
    ///
    /// You must have `s3:GetObject` permission for this operation. Amazon S3 Select does not support anonymous access. For more information about permissions, see <a href=\"https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html\">Specifying Permissions in a Policy</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.</p> <p/> <p> <i>Object Data Formats</i>
    ///
    /// You can use Amazon S3 Select to query objects that have the following format properties:</p> <ul> <li> <p> <i>CSV, JSON, and Parquet</i> - Objects must be in CSV, JSON, or Parquet format.</p> </li> <li> <p> <i>UTF-8</i> - UTF-8 is the only encoding type Amazon S3 Select supports.</p> </li> <li> <p> <i>GZIP or BZIP2</i> - CSV and JSON files can be compressed using GZIP or BZIP2. GZIP and BZIP2 are the only compression formats that Amazon S3 Select supports for CSV and JSON files. Amazon S3 Select supports columnar compression for Parquet using GZIP or Snappy. Amazon S3 Select does not support whole-object compression for Parquet objects.</p> </li> <li> <p> <i>Server-side encryption</i> - Amazon S3 Select supports querying objects that are protected with server-side encryption.
    ///
    /// For objects that are encrypted with customer-provided encryption keys (SSE-C), you must use HTTPS, and you must use the headers that are documented in the <a href=\"https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html\">GetObject</a>. For more information about SSE-C, see <a href=\"https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html\">Server-Side Encryption (Using Customer-Provided Encryption Keys)</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
    ///
    /// For objects that are encrypted with Amazon S3 managed encryption keys (SSE-S3) and customer master keys (CMKs) stored in AWS Key Management Service (SSE-KMS), server-side encryption is handled transparently, so you don't need to specify anything. For more information about server-side encryption, including SSE-S3 and SSE-KMS, see <a href=\"https://docs.aws.amazon.com/AmazonS3/latest/dev/serv-side-encryption.html\">Protecting Data Using Server-Side Encryption</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.</p> </li> </ul> <p> <b>Working with the Response Body</b>
    ///
    /// Given the response size is unknown, Amazon S3 Select streams the response as a series of messages and includes a `Transfer-Encoding` header with `chunked` as its value in the response. For more information, see <a href=\"https://docs.aws.amazon.com/AmazonS3/latest/API/RESTSelectObjectAppendix.html\">Appendix: SelectObjectContent Response</a> .</p> <p/> <p> <b>GetObject Support</b>
    ///
    /// The `SelectObjectContent` operation does not support the following `GetObject` functionality. For more information, see <a href=\"https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html\">GetObject</a>.</p> <ul> <li> <p> `Range`: Although you can specify a scan range for an Amazon S3 Select request (see <a href=\"https://docs.aws.amazon.com/AmazonS3/latest/API/API_SelectObjectContent.html#AmazonS3-SelectObjectContent-request-ScanRange\">SelectObjectContentRequest - ScanRange</a> in the request parameters), you cannot specify the range of bytes of an object to return. </p> </li> <li> <p>GLACIER, DEEP_ARCHIVE and REDUCED_REDUNDANCY storage classes: You cannot specify the GLACIER, DEEP_ARCHIVE, or `REDUCED_REDUNDANCY` storage classes. For more information, about storage classes see <a href=\"https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMetadata.html#storage-class-intro\">Storage Classes</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.</p> </li> </ul> <p/> <p> <b>Special Errors</b>
    ///
    /// For a list of special errors for this operation, see <a href=\"https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#SelectObjectContentErrorCodeList\">List of SELECT Object Content Error Codes</a> </p> <p class=\"title\"> <b>Related Resources</b> </p> <ul> <li> <p> <a href=\"https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html\">GetObject</a> </p> </li> <li> <p> <a href=\"https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycleConfiguration.html\">GetBucketLifecycleConfiguration</a> </p> </li> <li> <p> <a href=\"https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html\">PutBucketLifecycleConfiguration</a> </p> </li> </ul>
    ///
    /// - Parameters:
    ///   - input: Request structure
    ///   - stream: callback to process events streamed
    /// - Returns: Response structure
    public func selectObjectContentEventStream(
        _ input: SelectObjectContentRequest,
        logger: Logger = AWSClient.loggingDisabled,
        on eventLoop: EventLoop? = nil,
        _ stream: @escaping (SelectObjectContentEventStream, EventLoop) -> EventLoopFuture<Void>
    ) -> EventLoopFuture<SelectObjectContentOutput> {
        // byte buffer for storing unprocessed data
        var selectByteBuffer: ByteBuffer?
        return client.execute(
            operation: "SelectObjectContent",
            path: "/{Bucket}/{Key+}?select&select-type=2",
            httpMethod: .POST,
            serviceConfig: config,
            input: input,
            logger: logger,
            on: eventLoop
        ) { (byteBuffer: ByteBuffer, eventLoop: EventLoop) in
            var byteBuffer = byteBuffer
            if var selectByteBuffer2 = selectByteBuffer {
                selectByteBuffer2.writeBuffer(&byteBuffer)
                byteBuffer = selectByteBuffer2
                selectByteBuffer = nil
            }
            do {
                if let event = try SelectObjectContentEventStream.consume(byteBuffer: &byteBuffer) {
                    if byteBuffer.readableBytes > 0 {
                        selectByteBuffer = byteBuffer
                    }
                    return stream(event, eventLoop)
                }
            } catch {
                return eventLoop.makeFailedFuture(error)
            }
            selectByteBuffer = byteBuffer
            return eventLoop.makeSucceededFuture(())
        }
    }
}
