#!/bin/sh

set -eux

TEMP_DIR=""
COMMIT_CHANGES=""

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
    if [ -n "$BRANCH_NAME" ]; then
        CURRENT_FOLDER=$(pwd)
        cd "$DESTIONATION_FOLDER"
        git checkout "$BRANCH_NAME"
        cd "$CURRENT_FOLDER"
    fi
    return 0
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
    swift build --product aws-sdk-swift-codegen
    echo "Run the code generator"
    swift run
    echo "Compile service files"
    # build services after having generated the files
    swift build
}

check_for_local_changes()
{
    if [ "$COMMIT_CHANGES" = 1 ]; then
        LOCAL_CHANGES=$(git status --porcelain)
        if [ -n "$LOCAL_CHANGES" ]; then
            printf "You have local changes already and you have requested to commit changes after this script has run.\nEither remove the -c option or stash your local changes."
            usage
        fi
    fi
}

commit_changes()
{
    COMMIT_MSG="Sync models with aws-sdk-go $AWS_MODELS_VERSION"
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
        *) usage ;;
    esac
done


trap cleanup EXIT

check_for_local_changes

TEMP_DIR=$(mktemp -d)
echo "Using temp folder $TEMP_DIR"

echo "Get aws-sdk-go models"
AWS_SDK_GO=$TEMP_DIR/aws-sdk-go/
get_aws_sdk_go "$AWS_SDK_GO" "$AWS_MODELS_VERSION"

echo "Copy models to aws-sdk-swift"
AWS_SDK_GO_MODELS=$AWS_SDK_GO/models
TARGET_MODELS=models
copy_model_files "$AWS_SDK_GO_MODELS" "$TARGET_MODELS"

build_files

if [ "$COMMIT_CHANGES" = 1 ]; then
    commit_changes
fi
