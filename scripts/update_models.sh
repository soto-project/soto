#!/bin/sh

set -e

usage()
{
  echo "Usage: update_models.sh -c [ -v MODELS_VERSION_NUMBER ]"
  exit 2
}

get_aws_sdk_go()
{
  # clone aws-sdk-go into folder
  git clone https://github.com/aws/aws-sdk-go.git $1
  if [ -n "$2" ]; then
      pushd $1
      git checkout $2
      popd
  fi
  return 0
}

copy_model_files()
{
    rm -rf $2/apis/*
    rm -rf $2/endpoints/*
    cp -R $1/apis/* $2/apis/
    cp -R $1/endpoints/* $2/endpoints/
    rm $2/apis/*.go
    rm $2/endpoints/*.go
    return 0
}

build_files()
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

check_for_local_changes()
{
    LOCAL_CHANGES=`git status --porcelain`
    if [ -n "$LOCAL_CHANGES" ] && [ $COMMIT_CHANGES=1 ]; then
        echo "You have local changes already and you have requested to commit changes after this script has run.\nEither remove the -c option or stash your local changes."
        usage
        exit
    fi
}

commit_changes()
{
    COMMIT_MSG="Sync models with aws-sdk-go "$AWS_MODELS_VERSION
    git add models
    git add Sources/AWSSDKSwift
    git commit -m "$COMMIT_MSG"
}

cleanup()
{
    if [ -n "$TEMP_DIR" ]; then
        rm -rf $TEMP_DIR
    fi
}

while getopts 'cv:' option
do
    case $option in
        v) AWS_MODELS_VERSION=$OPTARG ;;
        c) COMMIT_CHANGES=1 ;;
        *)
        usage
        exit ;;
    esac
done


trap cleanup EXIT

check_for_local_changes

#create temp folder
TEMP_DIR=`mktemp -d`
echo "Using temp folder "$TEMP_DIR

#get aws-sdk-go models
echo "Get aws-sdk-go models"
AWS_SDK_GO=$TEMP_DIR/aws-sdk-go/
get_aws_sdk_go $AWS_SDK_GO $AWS_MODELS_VERSION

#copy aws-sdk-go models into aws-sdk-swift
echo "Copy models to aws-sdk-swift"
AWS_SDK_GO_MODELS=$AWS_SDK_GO/models
TARGET_MODELS=models
copy_model_files $AWS_SDK_GO_MODELS $TARGET_MODELS

#build service files from the models and check they compile
build_files

if [ $COMMIT_CHANGES=1 ]; then
    commit_changes
fi
