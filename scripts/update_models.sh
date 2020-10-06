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
    echo "Usage: update_models.sh -c [ -v MODELS_VERSION_NUMBER ]"
    exit 2
}

get_aws_sdk_go()
{
    DESTIONATION_FOLDER=$1
    BRANCH_NAME=$2
    # clone aws-sdk-go into folder
    git clone https://github.com/aws/aws-sdk-go.git "$DESTIONATION_FOLDER"
    CURRENT_FOLDER=$(pwd)
    cd "$DESTIONATION_FOLDER"
    if [ -z "$BRANCH_NAME"]; then
        RELEASE_REVISION=$(git rev-list --tags --max-count=1)
        BRANCH_NAME=$(git describe --tags "$RELEASE_REVISION")
    fi
    git checkout "$BRANCH_NAME"
    cd "$CURRENT_FOLDER"

    echo $BRANCH_NAME
}

copy_model_files()
{
    SOURCE_FOLDER=$1
    DESTIONATION_FOLDER=$2
    rm -rf "$DESTIONATION_FOLDER"/apis/*
    rm -rf "$DESTIONATION_FOLDER"/endpoints/*
    cp -R "$SOURCE_FOLDER"/apis/* "$DESTIONATION_FOLDER"/apis/
    cp -R "$SOURCE_FOLDER"/endpoints/* "$DESTIONATION_FOLDER"/endpoints/
    rm "$DESTIONATION_FOLDER"/apis/*.go
    rm "$DESTIONATION_FOLDER"/endpoints/*.go
    return 0
}

build_files()
{
    # build the code generator and run it
    echo "Build the code generator"
    CURRENT_FOLDER=$(pwd)
    cd "$CURRENT_FOLDER"/CodeGenerator
    swift build
    echo "Run the code generator"
    swift run
    cd "$CURRENT_FOLDER"

    swiftformat Sources/Soto/Services
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
    COMMIT_MSG="Sync models with aws-sdk-go $MODELS_VERSION"
    BRANCH_NAME="aws-sdk-go-$MODELS_VERSION"
    git checkout -b $BRANCH_NAME
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

while getopts 'cv:' option
do
    case $option in
        v) AWS_MODELS_VERSION=$OPTARG ;;
        c) COMPILE_FILES=1 ;;
        *) usage ;;
    esac
done


trap cleanup EXIT

check_for_local_changes

TEMP_DIR=$(mktemp -d)
echo "Using temp folder $TEMP_DIR"

echo "Get aws-sdk-go models"
AWS_SDK_GO=$TEMP_DIR/aws-sdk-go/
AWS_MODELS_VERSION=$(get_aws_sdk_go "$AWS_SDK_GO" "$AWS_MODELS_VERSION")

echo "Copy models to soto"
AWS_SDK_GO_MODELS=$AWS_SDK_GO/models
TARGET_MODELS=models
copy_model_files "$AWS_SDK_GO_MODELS" "$TARGET_MODELS"

build_files
if [ -n "$COMPILE_FILES" ]; then
    compile_files
fi
commit_changes "$AWS_MODELS_VERSION"
