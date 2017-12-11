const _ = require('lodash');
const fs = require('fs');
const globby = require('globby');

async function main() {
  const content = fs.readFileSync("./jazzy.yaml.stub", 'utf-8');
  const compile = _.template(content);

  const entiries = await globby("../Sources/AWSSDKSwift/Services/**/*_API.swift");
  const apiNames = entiries.map((path) => {
    const components = path.split("/");
    const fileName = components[components.length-1];
    const components2 = fileName.split("_");
    const APIName = components2[0];
    return APIName;
  });

  const yamlContent = compile({services: apiNames});
  fs.writeFileSync("../.jazzy.yaml", yamlContent, "utf-8");
}

main();
