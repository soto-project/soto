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

TEMP_DIR=$(mktemp -d)

set -eux

usage()
{
    echo "Usage: download_models.sh [-c]"
    exit 2
}

get_api_models_aws()
{
    DESTINATION_FOLDER=$1
    HASH=$2

    if [ -z "$HASH" ]; then
        # clone api-models-aws into folder
        git clone --depth 1 https://github.com/aws/api-models-aws.git "$DESTINATION_FOLDER"
        ROOT_FOLDER=$PWD
        pushd "$DESTINATION_FOLDER"
        git rev-parse HEAD > "$ROOT_FOLDER"/.aws-model-hash
        popd
    else
        # clone api-models-aws into folder
        git clone https://github.com/aws/api-models-aws.git "$DESTINATION_FOLDER"
        pushd "$DESTINATION_FOLDER"
        git checkout "$HASH"
        popd
    fi
}

copy_model_files()
{
    SOURCE_FOLDER=$1
    DESTINATION_FOLDER=$2
    rm -rf "$DESTINATION_FOLDER"/*
    cp -R "$SOURCE_FOLDER"/* "$DESTINATION_FOLDER"/
    return 0
}

cleanup()
{
    if [ -n "$TEMP_DIR" ]; then
        rm -rf $TEMP_DIR
    fi
}

trap cleanup EXIT $?

echo "Using temp folder $TEMP_DIR"

while getopts 'c' option
do
    case $option in
        c) AWS_MODELS_VERSION=$(cat .aws-model-hash) ;;
        *) usage ;;
    esac
done

echo "Get api-models-aws"

API_MODEL_AWS_FOLDER=$TEMP_DIR/api-models-aws/
get_api_models_aws "$API_MODEL_AWS_FOLDER" "${AWS_MODELS_VERSION:-}"

mkdir -p .build/aws-models
copy_model_files $API_MODEL_AWS_FOLDER/models .build/aws-models

