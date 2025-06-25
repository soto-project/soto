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

usage() {
    echo "Usage: download_models.sh [-u]"
    exit 2
}

get_api_models_aws() {
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

get_endpoints_json() {
    DESTINATION_FOLDER=$1
    curl https://raw.githubusercontent.com/aws/aws-sdk-go-v2/refs/heads/main/codegen/smithy-aws-go-codegen/src/main/resources/software/amazon/smithy/aws/go/codegen/endpoints.json > "$DESTINATION_FOLDER"/endpoints.json
}

cleanup() {
    if [ -n "$TEMP_DIR" ]; then
        rm -rf $TEMP_DIR
    fi
}

trap cleanup EXIT $?

echo "Using temp folder $TEMP_DIR"

# if .aws-model-hash file exists use the hash in there as the commit hash for 
# the models to use
if [ -f .aws-model-hash ]; then
    AWS_MODELS_VERSION=$(cat .aws-model-hash)
else
    AWS_MODELS_VERSION=""
fi

while getopts 'u' option
do
    case $option in
        u) AWS_MODELS_VERSION="" ;;
        *) usage ;;
    esac
done

echo "Get api-models-aws"

API_MODEL_AWS_FOLDER=$TEMP_DIR/api-models-aws/
get_api_models_aws "$API_MODEL_AWS_FOLDER" "${AWS_MODELS_VERSION:-}"

rm -rf .build/aws

mkdir -p .build/aws/models
cp -r $API_MODEL_AWS_FOLDER/models/* .build/aws/models

mkdir -p .build/aws/endpoints
get_endpoints_json .build/aws/endpoints

