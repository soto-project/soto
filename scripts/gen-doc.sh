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

combine_docs_json() {
    jq -s '[.[][]]' ./*.json > awssdkswift.json;
}

run_jazzy() {
# use theme apple-thin-nav else docs are 50+ GB!
    jazzy --clean --theme jazzy/themes/apple-thin-nav/
}

tidy_up() {
    ls *.json | xargs rm -f
    rm -rf docs/docsets
}

FOLDER=3.x.x
BRANCH=gh-pages

move_docs_to_aws_sdk_swift_docs() {
    REVISION_HASH=$(git rev-parse HEAD)
    COMMIT_MSG="Documentation for https://github.com/swift-aws/aws-sdk-swift/tree/$REVISION_HASH"
    if [ -n "$1" ]; then
        COMMIT_MSG=$1
    fi

    git clone https://github.com/swift-aws/aws-sdk-swift-docs -b "$BRANCH"
    
    cd aws-sdk-swift-docs
    # copy contents of docs to docs/current replacing the ones that are already there
    rm -rf "$FOLDER"
    mv ../docs/ "$FOLDER"/
    # commit
    git add --all "$FOLDER"
    git commit -m "$COMMIT_MSG"
    git push
    
    cd ..
    rm -rf aws-sdk-swift-docs
}

COMMIT_MSG=""
while getopts 'm:' option
do
    case $option in
        m) COMMIT_MSG=$OPTARG ;;
        *) usage ;;
    esac
done

create_jazzy_yaml
create_aws_sdk_swift_docs_json
combine_docs_json
run_jazzy
tidy_up
move_docs_to_aws_sdk_swift_docs "$COMMIT_MSG"
