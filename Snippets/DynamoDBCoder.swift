import Foundation
import SotoDynamoDB

struct Header: Encodable {
    let id: String
    let createdAt: String
}

struct Body: Encodable {
    let title: String
}

/// Composite type that flattens its sub-values into a single keyed container
/// by letting each sub-value request its own keyed container on the shared encoder.
struct Document: Encodable {
    let header: Header
    let body: Body

    func encode(to encoder: Encoder) throws {
        // Sub-values share the same encoder; their fields should merge.
        try header.encode(to: encoder)
        try body.encode(to: encoder)
    }
}

let doc = Document(
    header: Header(id: "abc", createdAt: "2026-04-11"),
    body: Body(title: "hello")
)

// Foundation's JSONEncoder produces a flat object as expected:
let json = try JSONEncoder().encode(doc)
print(String(data: json, encoding: .utf8)!)

// Soto's DynamoDBEncoder traps:
let attrs = try DynamoDBEncoder().encode(doc)
