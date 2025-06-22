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

get_api_models_aws()
{
    DESTINATION_FOLDER=$1

    # clone api-models-aws into folder
    git clone --depth 1 https://github.com/aws/api-models-aws.git "$DESTINATION_FOLDER"
    git rev-parse HEAD > .aws-model-hash
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
echo "Get api-models-aws"
API_MODEL_AWS_FOLDER=$TEMP_DIR/api-models-aws/

get_api_models_aws "$API_MODEL_AWS_FOLDER"

mkdir -p .build/aws-models
copy_model_files $API_MODEL_AWS_FOLDER/models .build/aws-models

