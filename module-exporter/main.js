const fs = require('fs-promise');
const co = require('co');
const _copydir = require('copy-dir');
const mkdirp = require('mkdirp-promise');
const _ = require('lodash');

_.templateSettings.interpolate = /{{([\s\S]+?)}}/g;

var currentAWSDKVersion = {
  major: "0",
  minor: "3"
};

const Template = {
  _tpls: {
    license: require('fs').readFileSync(__dirname+"/templates/LICENSE"),

    packageSwift: require('fs').readFileSync(__dirname+"/templates/Package.swift"),

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

if(_.isEmpty(dest)) {
  console.error("Please specify destination<directory> as a first argument");
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
  return `SwiftAWS${toClassCase(name)}`;
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
  const entries = yield fs.readdir(servicePath);
  for(var index in entries){
    var path = entries[index];
    var src = servicePath+"/"+path;
    var repoPath = dest+"/"+path;
    var sourceDestPath = repoPath+"/Sources";

    yield mkdirp(repoPath);
    yield mkdirp(sourceDestPath);

    // create files
    yield fs.writeFile(repoPath+"/Package.swift", Template.render("packageSwift", {
      name: moduleNamefy(path)
    }));

    yield fs.writeFile(repoPath+"/LICENSE", Template.render("license"));

    yield fs.writeFile(repoPath+"/README.md", Template.render("readme", {
      repositoryName: path,
      version: currentAWSDKVersion
    }));

    yield fs.writeFile(repoPath+"/.gitignore", [
      ".DS_Store",
      "/.build",
      "/Packages",
      "/*.xcodeproj"
    ].join("\n"));

    yield copydir(src, sourceDestPath);

    if (yield fs.exists(`${middlewarePath}/${path}`)) {
      yield copydir(`${middlewarePath}/${path}`, sourceDestPath);
    }
  }
})
.catch(function(error){
  console.error(error);
  process.exit(1);
});
