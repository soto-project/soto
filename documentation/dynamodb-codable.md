# DynamoDB and Codable

Writing generic code while interacting with DynamoDB can be quite hard. For every model you want to upload to or download from DynamoDB you need custom code for the conversion from model to `AttributeValue` dictinary and vice versa. To ease this process and remove the requirement for custom code. The DynamoDB library has a Codable extension. This is split into two parts: the encoder/decoder and custom versions of some of the key functions.

# Encoder and Decoder

The DynamoDB Codable extension comes with both an encoder `DynamoDBEncoder` which takes a Codable and generates an `AttributeValue` dictionary and a decoder `DynamoDBDecoder` which takes an `AttributeValue` dictionary and generates a Codable object. If I have the following struct
```swift
struct Person: Codable {
    let name: String
    let age: Int
}
```
The following code would generate an `AttributeValue` dictionary which can be used in a DynamoDB operation
```swift
let person = Person(name: "John Smith", age: 35)
let personAttributes = try DynamoDBEncoder().encode(person)
```
The contents of `personAttributes` is as follows
```swift
["name": .s("John Smith"), "age": .n("35")]
```
You can then use `DynamoDBDecoder` to convert back to your original `Person` struct.
```swift
let person2 = try DynamoDBDecoder().decode(Person.self, from: personAttributes)
```
