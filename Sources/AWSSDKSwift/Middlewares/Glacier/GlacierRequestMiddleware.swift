import Foundation
import AWSSDKSwiftCore

let MEGA_BYTE = 1024 * 1024

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
            if let data = try request.body.asData() {
                let treeHash = computeTreeHash(data).hexdigest()
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
    fileprivate func computeTreeHash(_ data: Data) -> [UInt8] {
        var shas: [[UInt8]] = []

        if data.count < MEGA_BYTE {
            shas.append(sha256(data))
        } else {
            var numParts = data.count / MEGA_BYTE
            if data.count % MEGA_BYTE > 0 {
                numParts += 1
            }

            var start: Int
            var end: Int

            for partNum in 0..<numParts {
                start = partNum * MEGA_BYTE
                if partNum == numParts - 1 {
                    end = data.count - 1
                } else {
                    end = start + MEGA_BYTE - 1
                }
                shas.append(sha256(data.subdata(in: Range(start...end))))
            }
        }

        while shas.count > 1 {
            var tmpShas: [[UInt8]] = []
            shas.forEachSlice(2, {
                let pair = $0
                guard var bytes1 = pair.first else { return }

                if pair.count > 1, var bytes2 = pair.last {
                    tmpShas.append(sha256(&bytes1, &bytes2))
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
