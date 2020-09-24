# DynamoDB and Codable

Writing generic code while interacting with DynamoDB can be quite hard. For every model you want to upload to or download from DynamoDB, you need custom code for the conversion from model to `AttributeValue` dictionary and vice versa. To ease this process and remove the requirement for custom code, the DynamoDB library has a `Codable` extension. This is split into two parts: the encoder/decoder and custom versions of some of the key functions.

## Encoder and Decoder

The DynamoDB `Codable` extension comes with both an encoder, `DynamoDBEncoder`, which takes a Codable and generates an `AttributeValue` dictionary, and a decoder `DynamoDBDecoder`, which takes an `AttributeValue` dictionary and generates a Codable object. Imagine you have the following type:

```swift
struct Person: Codable {
    let id: Int
    let name: String
    let age: Int
}
```

The following code generates an `AttributeValue` dictionary which can be used in a DynamoDB operation:

```swift
let person = Person(id: 1, name: "John Smith", age: 35)
let personAttributes = try DynamoDBEncoder().encode(person)
```

The contents of `personAttributes` is as follows

```swift
["id": .n("1"), "name": .s("John Smith"), "age": .n("35")]

```
You can then use `DynamoDBDecoder` to convert back to your original `Person` type.

```swift
let person2 = try DynamoDBDecoder().decode(Person.self, from: personAttributes)
```

## Custom Codable functions

Now you have an `Encoder` and `Decoder` to move between `Codable` objects and `AttributeValue` dictionaries, you can generate the data in the required format for DynamoDB and parse the results sent back. The DynamoDB library extension gives you a little more help though. It implements custom versions of the most commonly used functions which take a `Codable` object instead of a `AttributeValue` dictionary. So the following code

```swift
let input = DynamoDB.PutItemInput(
    item: [
        "id": .n(person.id.description),
        "name": .s(person.name), 
        "age": .n(person.age.description)
    ], 
    tableName: "my-table"
)
let output = try dynamoDB.putItem(input).wait()
```

can be reduced to 

```swift
let input = DynamoDB.PutItemCodableInput(item: person, tableName: "my-table")
let output = try dynamoDB.putItem(input).wait()
```

Similarly when using `DynamoDB.getItem(_:)`, the code below which parses an `AttributeValue` dictionary returned

```swift
        let input = DynamoDB.GetItemInput(key: ["id": .n("1")], tableName: "my-table")
        let output = try Self.dynamoDB.getItem(input).wait()
        guard case .n(let idString) = output.item?["id"],
            case .s(let name) = output.item?["name"],
            case .n(let ageString) = output.item?["age"],
            let id = Int(idString),
            let age = Int(ageString) else { throw SomeError()}
        let person = Person(id: id, name: name, age: age)
```

can be reduced to

```swift
        let input = DynamoDB.GetItemInput(key: ["id": .n("1")], tableName: "my-table")
        let output = try Self.dynamoDB.getItem(input, type: Person.self).wait()
        let person = output2.item
```

There are custom `Codable` versions of `putItem`, `getItem`, `query`, `scan` and `updateItem` provided. There are also paginator versions of the `query` and `scan` functions supplied.
