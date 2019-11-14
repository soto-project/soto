const fs = require('fs-promise');
const co = require('co');
const _copydir = require('copy-dir');
const mkdirp = require('mkdirp-promise');
const _ = require('lodash');

_.templateSettings.interpolate = /{{([\s\S]+?)}}/g;

const Template = {
  _tpls: {
    license: require('fs').readFileSync(__dirname+"/templates/LICENSE"),

    packageSwift: require('fs').readFileSync(__dirname+"/templates/Package.swift"),

    packageWithMiddlewareSwift: require('fs').readFileSync(__dirname+"/templates/packageWithMiddleware.swift"),

    readme: require('fs').readFileSync(__dirname+"/templates/README.md")
  },

  render(name, params) {
    var compiled = _.template(Template._tpls[name]);
    return compiled(params);
  }
}

function copydir(from, to) {
  return new Promise(function(resolve, reject){
    _copydir(from, to, (err) => {
      if(err) {
        return reject(err);
      }
      resolve();
    });
  });
}

const dest = process.argv[2];
const version = process.argv[3];

if(_.isEmpty(dest)) {
  console.error("Please specify destination<directory> as a first argument");
  process.exit(1);
}

if(_.isEmpty(version)) {
  console.error("Please specify AWSSDK version as second argument");
  process.exit(1);
}

function toClassCase(str) {
  const find = /(\-\w)/g;
  const convert =  function(matches){
      return matches[1].toUpperCase();
  };
  str = str.replace(find, convert);
  return str.charAt(0).toUpperCase() + str.slice(1);;
}

function moduleNamefy(name) {
  return `${toClassCase(name)}`;
}

function middlewareNamefy(name) {
  return `${toClassCase(name)}Middleware`;
}

fs.exists = function(path){
  return new Promise(function(resolve){
    fs.stat(path)
      .then(function(){
        resolve(true);
      })
      .catch(function(){
        resolve(false);
      });
  })
}

co(function *() {
  const servicePath = __dirname + "/../Sources/AWSSDKSwift/Services";
  const middlewarePath = __dirname + "/../Sources/AWSSDKSwift/Middlewares";
  //const entries = yield fs.readdir(servicePath);
  const entries = [
      "Kinesis",
      "S3",
      "EC2",
      "APIGateway",
      "Lambda",
      "ECS",
      "DynamoDB",
      "ECR",
      "CloudFront",
      "IAM",
  ]
  for(var index in entries){
    var path = entries[index];
    var src = servicePath+"/"+path;
    var repoPath = dest+"/"+path;
    var middlewareExists = yield fs.exists(`${middlewarePath}/${path}`)
    var sourceDestPath = repoPath+"/Sources/"+moduleNamefy(path);
    var middlewareDestPath = repoPath+"/Sources/"+middlewareNamefy(path);

    yield mkdirp(repoPath);
    yield mkdirp(sourceDestPath);

    if (middlewareExists) {
        yield mkdirp(middlewareDestPath);
    }

    // create files
    if (middlewareExists) {
        yield fs.writeFile(repoPath+"/Package.swift", Template.render("packageWithMiddlewareSwift", {
          name: moduleNamefy(path),
          middleware: middlewareNamefy(path),
          version: version
        }));
    } else {
        yield fs.writeFile(repoPath+"/Package.swift", Template.render("packageSwift", {
          name: moduleNamefy(path),
          version: version
        }));
    }
    yield fs.writeFile(repoPath+"/LICENSE", Template.render("license"));

    yield fs.writeFile(repoPath+"/README.md", Template.render("readme", {
      repositoryName: moduleNamefy(path),
      version: version
    }));

    yield fs.writeFile(repoPath+"/.gitignore", [
      ".DS_Store",
      "/.build",
      "/Packages",
      "/*.xcodeproj"
    ].join("\n"));

    yield copydir(src, sourceDestPath);

    if (middlewareExists) {
      yield copydir(`${middlewarePath}/${path}`, middlewareDestPath);
    }
  }
})
.catch(function(error){
  console.error(error);
  process.exit(1);
});
