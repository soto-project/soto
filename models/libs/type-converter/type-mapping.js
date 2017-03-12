// AWSType: SwiftType
module.exports = {
  String: "String",
  Integer: "Int",
  Double: "Double",
  Boolean: "Bool",
  Timestamp: "Date",

  // AWS Custom types
  MapOfHeaderValues: {
    isDictionary: true,
    keyType: "String",
    valueType: "String"
  },
  MapOfMethod: "[String: Any]",
  MapOfIntegrationResponse: "[String: Any]",
  MapOfMethodResponse: "[String: Any]",
  MapOfMethodSettings: "[String: Any]",
  MapOfKeyUsages: "[String: Any]"
};
