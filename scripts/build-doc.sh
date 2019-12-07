#!/bin/sh

set -eux

create_jazzy_yaml() {
    cd jazzy
    node create-jazzy.yaml.js
    cd ..
}

create_aws_sdk_swift_core_docs_json() {
    git clone https://github.com/swift-aws/aws-sdk-swift-core.git
    cd aws-sdk-swift-core
    sourcekitten doc --spm-module "AWSSDKSwiftCore" > ../AWSSDKSwiftCore.json;
    cd ..
    rm -rf aws-sdk-swift-core
}

create_aws_sdk_swift_docs_json() {
    for d in Sources/AWSSDKSwift/Services/*;
    do moduleName="$(basename "$d")";
        sourcekitten doc --spm-module "$moduleName" > "$moduleName".json;
    done;
}

run_jazzy() {
# use theme apple-thin-nav else docs are 50+ GB!
    jazzy --clean --theme jazzy/themes/apple-thin-nav/
}

tidy_up() {
    ls *.json | xargs rm -f
    rm -rf docs/docsets
    rm .jazzy.yaml
}

create_jazzy_yaml
create_aws_sdk_swift_core_docs_json
create_aws_sdk_swift_docs_json
run_jazzy
tidy_up
