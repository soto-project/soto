#!/bin/sh
##===----------------------------------------------------------------------===##
##
## This source file is part of the Soto for AWS open source project
##
## Copyright (c) 2020 the Soto project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.txt for the list of Soto project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

set -eux

TEMP_DIR=""

usage()
{
    echo "Usage: update_models.sh -bupc [ -v MODELS_VERSION_NUMBER ]"
    exit 2
}

get_aws_sdk_go_v2()
{
    DESTIONATION_FOLDER=$1
    BRANCH_NAME=$2
    # clone aws-sdk-go-v2 into folder
    git clone --depth 1 https://github.com/aws/aws-sdk-go-v2.git "$DESTIONATION_FOLDER"
    CURRENT_FOLDER=$(pwd)
    cd "$DESTIONATION_FOLDER"
    if [ -z "$BRANCH_NAME"]; then
        RELEASE_REVISION=$(git rev-list --tags --max-count=1)
        if [ -n "$RELEASE_REVISION" ]; then
            BRANCH_NAME=$(git describe --tags "$RELEASE_REVISION")
        else
            BRANCH_NAME=$(git rev-parse HEAD)
        fi
    fi
    git checkout "$BRANCH_NAME"
    cd "$CURRENT_FOLDER"

    echo $BRANCH_NAME
}

copy_model_files()
{
    SOURCE_FOLDER=$1
    ENDPOINT_FILE=$2
    DESTINATION_FOLDER=$3
    rm -rf "$DESTINATION_FOLDER"/*
    cp -R "$SOURCE_FOLDER"/* "$DESTINATION_FOLDER"/
    mkdir "$DESTINATION_FOLDER"/endpoints/
    cp "$ENDPOINT_FILE" "$DESTINATION_FOLDER"/endpoints/
    return 0
}

build_files()
{
    echo "Run the code generator"
    rm -rf Sources/Soto/Services/*
    SotoCodeGenerator \
        --input-folder models \
        --output-folder Sources/Soto/Services \
        --endpoints models/endpoints/endpoints.json
}

compile_files()
{
    echo "Compile service files"
    # build services after having generated the files
    swift build
}

check_for_local_changes()
{
    LOCAL_CHANGES=$(git status --porcelain)
    if [ -n "$LOCAL_CHANGES" ]; then
        echo "You have local changes."
        read -p "Are you sure you want to continue [y/n]? " answer
        if [ "$answer" != "y" ]; then
            exit
        fi
    fi
}

commit_changes()
{
    MODELS_VERSION=$1
    COMMIT_MSG="Sync models with aws-sdk-go-v2 $MODELS_VERSION"
    git add models
    git add Sources/Soto
    git commit -m "$COMMIT_MSG"
}

cleanup()
{
    if [ -n "$TEMP_DIR" ]; then
        rm -rf $TEMP_DIR
    fi
}

AWS_MODELS_VERSION=""
COMPILE_FILES=""
COMMIT_FILES=""

while getopts 'gcv:' option
do
    case $option in
        v) AWS_MODELS_VERSION=$OPTARG ;;
        c) COMPILE_FILES=1 ;;
        g) COMMIT_FILES=1 ;;
        *) usage ;;
    esac
done


trap cleanup EXIT $?

check_for_local_changes

TEMP_DIR=$(mktemp -d)
echo "Using temp folder $TEMP_DIR"

echo "Install code generator"
mint install https://github.com/soto-project/soto-codegenerator

echo "Get aws-sdk-go models"
AWS_SDK_GO=$TEMP_DIR/aws-sdk-go-v2/
AWS_MODELS_VERSION=$(get_aws_sdk_go_v2 "$AWS_SDK_GO" "$AWS_MODELS_VERSION")

# required by update_models.yml to extract the version number of the models
echo "AWS_MODELS_VERSION=$AWS_MODELS_VERSION"
echo "Copy models to soto"
AWS_SDK_GO_MODELS=$AWS_SDK_GO/codegen/sdk-codegen/aws-models
AWS_SDK_GO_ENDPOINT=$AWS_SDK_GO/codegen/smithy-aws-go-codegen/src/main/resources/software/amazon/smithy/aws/go/codegen/endpoints.json
TARGET_MODELS=models
copy_model_files "$AWS_SDK_GO_MODELS" "$AWS_SDK_GO_ENDPOINT" "$TARGET_MODELS"

echo "Building Service files"
build_files
echo "Building Package.swift"
./scripts/generate-package.swift

if [ -n "$COMPILE_FILES" ]; then
    compile_files
fi
if [ -n "$COMMIT_FILES" ]; then
    commit_changes "$AWS_MODELS_VERSION"
fi
