import NIO
import AWSSDKSwiftCore

let MEGA_BYTE = 1024 * 1024

public enum GlacierMiddlewareErrorType: Error {
    case failedToAccessBytes
}

public struct GlacierRequestMiddleware: AWSServiceMiddleware {

    let apiVersion: String

    public init (apiVersion: String) {
        self.apiVersion = apiVersion
    }

    public func chain(request: AWSRequest) throws -> AWSRequest {
        var request = request
        request.addValue(apiVersion, forHTTPHeaderField: "x-amz-glacier-version")

        let treeHashHeader = "x-amz-sha256-tree-hash"

        if request.httpHeaders[treeHashHeader] == nil {
            if let byteBuffer = request.body.asByteBuffer() {
                let treeHash = try computeTreeHash(byteBuffer).hexdigest()
                request.addValue(treeHash, forHTTPHeaderField: treeHashHeader)
            }
        }

        return request
    }

    // ComputeTreeHash builds a tree hash root node given a Data Object
    // Glacier tree hash to be derived from SHA256 hashes of 1MB
    // chucks of the data.
    //
    // See http://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations.html for more information.
    //
    internal func computeTreeHash(_ byteBuffer: ByteBuffer) throws -> [UInt8] {
        var shas: [[UInt8]] = []

        if byteBuffer.readableBytes < MEGA_BYTE {
            let byteBufferView = byteBuffer.readableBytesView
            guard let _ = byteBufferView.withContiguousStorageIfAvailable({ bytes in
                shas.append(sha256(bytes))
            }) else {
                throw GlacierMiddlewareErrorType.failedToAccessBytes
            }
        } else {
            var numParts = byteBuffer.readableBytes / MEGA_BYTE
            if byteBuffer.readableBytes % MEGA_BYTE > 0 {
                numParts += 1
            }

            var start: Int
            var end: Int

            for partNum in 0..<numParts {
                start = partNum * MEGA_BYTE
                if partNum == numParts - 1 {
                    end = byteBuffer.readableBytes - 1
                } else {
                    end = start + MEGA_BYTE - 1
                }
                guard let byteBufferView = byteBuffer.viewBytes(at: byteBuffer.readerIndex+start, length: byteBuffer.readerIndex+end) else { throw GlacierMiddlewareErrorType.failedToAccessBytes }
                guard let _ = byteBufferView.withContiguousStorageIfAvailable({ bytes in
                    shas.append(sha256(bytes))
                }) else {
                    throw GlacierMiddlewareErrorType.failedToAccessBytes
                }
            }
        }

        while shas.count > 1 {
            var tmpShas: [[UInt8]] = []
            shas.forEachSlice(2, {
                let pair = $0
                guard let bytes1 = pair.first else { return }

                if pair.count > 1, let bytes2 = pair.last {
                    var context = sha256_Init()
                    sha256_Update(&context, bytes1)
                    sha256_Update(&context, bytes2)
                    let sha = sha256_Final(&context)
                    tmpShas.append(sha)
                } else {
                    tmpShas.append(bytes1)
                }
            })
            shas = tmpShas
        }

        return shas[0]
    }
}

extension Array {
    /*
     [1,2,3,4,5].forEachSlice(2, { print($0) })
     => [1, 2]
     => [3, 4]
     => [5]
    */
    public func forEachSlice(_ n: Int, _ body: (ArraySlice<Element>) throws -> Void) rethrows {
        assert(n > 0, "n require to be greater than 0")

        for from in stride(from: self.startIndex, to: self.endIndex, by: n) {
            let to = Swift.min(from + n, self.endIndex)
            try body(self[from..<to])
        }
    }
}
