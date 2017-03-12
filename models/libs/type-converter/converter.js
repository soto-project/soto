const typeMapping = require('./type-mapping');

exports.extractTypeName = function(AWSType){
  if(typeMapping[AWSType]) {
    return [typeMapping[AWSType]];
  }

  var typeName;

  typeName = getSwiftTypeNameIfPrefixIsNullable(AWSType);
  if(typeName) {
    return [typeName];
  }

  typeName = getSwiftTypeNameIfSufixIsOptional(AWSType);
  if(typeName) {
    return [typeName];
  }

  typeName = getSwiftTypeNameIfPrefixIsListOf(AWSType);
  if(typeName) {
    return [typeName];
  }

  typeName = getSwiftTypeNameIfSufixIsList(AWSType);
  if(typeName) {
    return [typeName];
  }

  typeName = getSwiftTypeNameIfPrefixIsMapOf(AWSType);
  if(typeName) {
    return typeName;
  }

  return [AWSType];
}

exports.getSwiftType = function(AWSType){
  if(typeMapping[AWSType]) {
    return {
      typeName: typeMapping[AWSType],
      isStandard: true
    }
  }

  var typeName;

  typeName = getSwiftTypeNameIfPrefixIsNullable(AWSType);
  if(typeName) {
    return {
      typeName: typeName,
      isOptional: true,
    };
  }

  typeName = getSwiftTypeNameIfSufixIsOptional(AWSType);
  if(typeName) {
    return {
      typeName: typeName,
      isOptional: true,
    };
  }

  typeName = getSwiftTypeNameIfPrefixIsListOf(AWSType);
  if(typeName) {
    return {
      typeName: typeName,
      isArray: true,
    };
  }

  typeName = getSwiftTypeNameIfSufixIsList(AWSType);
  if(typeName) {
    return {
      typeName: typeName,
      isArray: true,
    };
  }

  typeName = getSwiftTypeNameIfPrefixIsMapOf(AWSType);
  if(typeName) {
    return {
      typeName: typeName[0],
      typeName2: typeName[1],
      isDictionary: true,
    };
  }

  return {
    typeName: AWSType,
    isStandard: true
  };
}

function mappedType(typeName) {
  if(typeMapping[typeName]) {
    return typeMapping[typeName];
  }
  return typeName;
}

function getSwiftTypeNameIfPrefixIsNullable(AWSType) {
  if(AWSType.substring(0, 8) == "Nullable") {
    return mappedType(AWSType.substring(8));
  }

  return null;
}

function getSwiftTypeNameIfSufixIsOptional(AWSType) {
  if(AWSType.substring(AWSType.length-8) == "Optional") {
    return mappedType(AWSType.substring(0, AWSType.length-8));
  }

  return null;
}

function getSwiftTypeNameIfPrefixIsListOf(AWSType) {
  if(AWSType.substring(0, 6) == "ListOf") {
    return mappedType(AWSType.substring(6));
  }

  return null;
}

function getSwiftTypeNameIfSufixIsList(AWSType) {
  if(AWSType.substring(AWSType.length-4) == "List") {
    return mappedType(AWSType.substring(0, AWSType.length-4));
  }

  return null;
}

function getSwiftTypeNameIfPrefixIsMapOf(AWSType) {
  if(AWSType.substring(0, 5) == "MapOf") {
    const types = AWSType.substring(5).split("To");
    const keyType = mappedType(types[0]);
    const valueType = mappedType(types[1]);

    return [keyType, valueType]
  }

  return null;
}
