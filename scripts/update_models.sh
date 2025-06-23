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

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEMP_DIR=$(mktemp -d)

usage() {
    echo "Usage: update_models.sh -gc [ -v MODELS_VERSION_NUMBER ]"
    exit 2
}

build_files() {
    echo "Run the code generator"
    rm -rf Sources/Soto/Services/*
    SotoCodeGenerator \
        --input-folder .build/aws/models \
        --output-folder Sources/Soto/Services \
        --endpoints .build/aws/endpoints/endpoints.json
}

compile_files() {
    echo "Compile service files"
    # build services after having generated the files
    swift build
}

check_for_local_changes() {
    LOCAL_CHANGES=$(git status --porcelain)
    if [ -n "$LOCAL_CHANGES" ]; then
        echo "You have local changes."
        read -p "Are you sure you want to continue [y/n]? " answer
        if [ "$answer" != "y" ]; then
            exit
        fi
    fi
}

commit_changes() {
    HASH=$(cat .aws-model-hash)
    COMMIT_MSG="Update models from api-models-aws. Commit ID $HASH"
    git add .aws-model-hash
    git add Sources/Soto
    git commit -m "$COMMIT_MSG"
}

cleanup() {
    if [ -n "$TEMP_DIR" ]; then
        rm -rf $TEMP_DIR
    fi
}

COMPILE_FILES=""
COMMIT_FILES=""

while getopts 'gc' option
do
    case $option in
        c) COMPILE_FILES=1 ;;
        g) COMMIT_FILES=1 ;;
        *) usage ;;
    esac
done


trap cleanup EXIT $?

check_for_local_changes

echo "Using temp folder $TEMP_DIR"

echo "Install code generator"
mint install https://github.com/soto-project/soto-codegenerator

echo "Get api models from api-models-aws.git"
source "${HERE}"/download_models.sh -u

echo "Building Service files"
build_files
echo "Building Package.swift"
"${HERE}"/generate-package.swift

if [ -n "$COMPILE_FILES" ]; then
    compile_files
fi
if [ -n "$COMMIT_FILES" ]; then
    commit_changes
fi
