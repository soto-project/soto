#!/bin/sh

set -e

function get_aws_sdk_go
{
  # clone aws-sdk-go into folder
  git clone --quiet --progress --depth=1 https://github.com/aws/aws-sdk-go.git $1
  return 0
}

function copy_model_files
{
    rm -rf $2/apis/*
    rm -rf $2/endpoints/*
    cp -R $1/apis/* $2/apis/
    cp -R $1/endpoints/* $2/endpoints/
    rm $2/apis/*.go
    rm $2/endpoints/*.go
  return 0
}

function build_files
{
    # build the code generator and run it
    echo "Build the code generator"
    swift build --product aws-sdk-swift-codegen
    echo "Run the code generator"
    swift run
    echo "Compile service files"
    # build services after having generated the files
    swift build
}

function cleanup
{
    rm -rf $TEMP_DIR
}

trap cleanup EXIT

#create temp folder
TEMP_DIR=`mktemp -d`
echo "Using temp folder "$TEMP_DIR

#get aws-sdk-go models
echo "Get aws-sdk-go models"
AWS_SDK_GO=$TEMP_DIR/aws-sdk-go/
get_aws_sdk_go $AWS_SDK_GO

#copy aws-sdk-go models into aws-sdk-swift
echo "Copy models to aws-sdk-swift"
AWS_SDK_GO_MODELS=$AWS_SDK_GO/models
TARGET_MODELS=models
copy_model_files $AWS_SDK_GO_MODELS $TARGET_MODELS

#build service files from the models and check they compile
build_files
