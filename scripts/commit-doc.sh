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

FOLDER=5.x.x
BRANCH=gh-pages

move_docs_to_aws_sdk_swift_docs() {
    REVISION_HASH=$(git rev-parse HEAD)
    COMMIT_MSG="Documentation for https://github.com/soto-project/soto/tree/$REVISION_HASH"
    if [ -n "$1" ]; then
        COMMIT_MSG=$1
    fi

    git clone https://github.com/soto-project/soto-docs -b "$BRANCH"

    cd soto-docs
    # copy contents of docs to docs/current replacing the ones that are already there
    rm -rf "$FOLDER"
    mv ../docs/ "$FOLDER"/
    # commit
    git add --all "$FOLDER"
    git commit -m "$COMMIT_MSG"
    git push

    cd ..
    rm -rf soto-docs
}

COMMIT_MSG=""
while getopts 'm:' option
do
    case $option in
        m) COMMIT_MSG=$OPTARG ;;
        *) usage ;;
    esac
done

move_docs_to_aws_sdk_swift_docs "$COMMIT_MSG"
