const glob = require('glob-promise');
const co = require('co');
const _ = require('lodash');
const fs = require('bluebird').promisifyAll(require('fs'));
const endpoints = require('./endpoints/endpoint.json');
const mkdirp = require('mkdirp-promise');
const typeConverter = require('./libs/type-converter/converter');

function pascalCase(s){
    return s.charAt(0).toUpperCase() + s.slice(1).replace(/-\w/g, function(m){return m[1].toUpperCase();});
}

function lowerFirst(string) {
  return string.charAt(0).toLowerCase() + string.slice(1);
}

function getServiceNamFromPath(path) {
  const paths = path.split("/");
  return paths[paths.length-3];
}

function getPahtsFor(pattern) {
  return co(function*(){
    const paths = yield glob(pattern);

    const groupedPaths = {};
    paths.forEach(function(p){
      const paths = p.split("/");
      const serviceName = paths[paths.length-3];
      if(!groupedPaths[serviceName]) {
        groupedPaths[serviceName] = [];
      }
      groupedPaths[serviceName].push(p);
    });

    const validPaths = [];
    _.each(groupedPaths, (paths, __) => {
      validPaths.push( paths[paths.length-1]);
    });

    return validPaths;
  });
}

function generateServiceClasses(paths) {
  return co(function*(){
    const classTemplate = (yield fs.readFileAsync(__dirname + "/templates/class.swift")).toString();
    const functionTemplate = (yield fs.readFileAsync(__dirname + "/templates/function.swift")).toString();
    const inputAndOutputTemplate = (yield fs.readFileAsync(__dirname + "/templates/input-and-output-struct.swift")).toString();

    const apiPaths = yield getPahtsFor(__dirname + "/apis/**/api-*.json");
    const Shapes = [];
    const dataSources = apiPaths.map(function(path){
      const api = require(path);
      const serviceName = getServiceNamFromPath(path);
      const definiations = _.map(api.operations, (struct, apiName) => {
        const inputType = struct.name+"Input";
        const outputType = struct.name+"Output";
        var inputTree = null;
        if(struct.input) {
          const shape = api.shapes[struct.input.shape];
          const members = [];
          _.each(shape.members, (struct, fieldName) => {
            const member = {
              fieldName: lowerFirst(fieldName),
              required: _.includes(shape.required, fieldName),
              type: typeConverter.getSwiftType(struct.shape)
            };
            typeConverter.extractTypeName(struct.shape).forEach(function(type){
              if(!_.includes(Shapes, type)) {
                Shapes.push(type);
              }
            });
          });

          inputTree = {
            template: _.template(inputAndOutputTemplate),
            data: {
              structName: inputType,
              members: members
            }
          }
        }

        var outputTree = null;
        if(struct.output) {
          const shape = api.shapes[struct.output.shape];
          const members = [];
          _.each(shape.members, (struct, fieldName) => {
            const member = {
              fieldName: lowerFirst(fieldName),
              required: _.includes(shape.required, fieldName),
              type: typeConverter.getSwiftType(struct.shape)
            };

            typeConverter.extractTypeName(struct.shape).forEach(function(type){
              if(!_.includes(Shapes, type)) {
                Shapes.push(type);
              }
            });
          });

          outputTree = {
            template: _.template(inputAndOutputTemplate),
            data: {
              structName: outputType,
              members: members
            }
          }
        }

        const functionTree = {
          template: _.template(functionTemplate),
          data: {
            functionName: lowerFirst(struct.name),
            inputType: inputType,
            outputType: outputType,
            httpMethod: struct.http.method,
            requestUri: struct.http.requestUri
          }
        };

        return {
          inputTree: inputTree,
          outputTree: outputTree,
          functionTree: functionTree,
        }
      });
    });

    console.log(Shapes);

// const shapes = _.flatten(dataSources.map((d) => {
//   return _.flatten(d.map((d) => {
//     return d.Shapes;
//   }));
// }));

//console.log(shapes);

    // const compile = _.template(classTemplate);
    // const fileContent = compile({
    //   functions: functions,
    //   className: pascalCase(serviceName)
    // });
    //
    // return {
    //   destination: `${__dirname}/../Sources/AWSSDKSwift/Services/${pascalCase(serviceName)}`,
    //   file: `${pascalCase(serviceName)}.swift`,
    //   fileContent: fileContent
    // }

    // const tasks = outputs.map(function(o){
    //   return mkdirp(o.destination).then(function(){
    //     return fs.writeFileAsync(`${o.destination}/${o.file}`, o.fileContent);
    //   });
    // });
    //
    // yield Promise.all(tasks);
  });
}

co(function*(){
  const docPaths = yield getPahtsFor(__dirname + "/apis/**/docs-*.json");
  yield generateServiceClasses();

  const path = docPaths[0];
  const doc = require(path);


  _.each(doc.shapes, (struct, fieldName) => {
    if(fieldName.substring(fieldName.length-"Exception".length) == "Exception") {
      return;
    }

//    console.log(fieldName, struct);
  });

  console.log("Done!");
})
.catch(function(error) {
  console.error(error);
  process.exit(1);
})
