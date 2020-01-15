const _ = require('lodash');
const fs = require('fs');
const globby = require('globby');

async function main() {
  const content = fs.readFileSync("./jazzy.yaml.stub", 'utf-8');
  const compile = _.template(content);

  const entries = await globby("../Sources/AWSSDKSwift/Services/**/*_API.swift");
  const apiNames = entries.map((path) => {
    const components = path.split("/");
    const fileName = components[components.length-2];
    return fileName;
  });
  var apiNamesSet = new Set(apiNames)
  const yamlContent = compile({services: apiNamesSet});
  fs.writeFileSync("../.jazzy.yaml", yamlContent, "utf-8");
}

main();
