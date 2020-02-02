const _ = require('lodash');
const fs = require('fs');
const globby = require('globby');

async function main() {
  const content = fs.readFileSync("./jazzy.yaml.stub", 'utf-8');
  const compile = _.template(content);

  const entries = await globby("../sourcekitten/*.json");
  const apiNames = entries.map((path) => {
    const components = path.split("/");
    const fileName = components[components.length-1];
    const name = fileName.split(".")[0];
    return name;
  });
  var apiNamesSet = new Set(apiNames)
  apiNamesSet.delete("AWSSDKSwiftCore")

  const yamlContent = compile({services: apiNamesSet});
  fs.writeFileSync("../.jazzy.yaml", yamlContent, "utf-8");
}

main();
