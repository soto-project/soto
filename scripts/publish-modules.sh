#!/bin/bash
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

#######################################################
#
# usage bash publish-module.sh /path/to/soto-project "sync with soto@1.0.2" 1.0.2
#  $1: path for aws partial modules are stored
#  $2: commit comment
#  $3: tag for release (if not included will not make a release)
#
#######################################################

set -eux

SOURCE_PATH="${1:-}"
COMMENT="${2:-}"
TAG="${3:-}"

if [ -z "${SOURCE_PATH}" ]; then
    echo "You should pass the source path for aws partial modules are stored as \$1"
    exit 1
fi

if [ -z "${COMMENT}" ]; then
    echo "You should pass the commit comment as \$2"
    exit 1
fi

if [ -z "${TAG}" ]; then
    echo "No release tag set so will not create release."
fi

for D in $(find $SOURCE_PATH -depth 1 -type d); do
    BASENAME=$(basename $D)
    pushd $D
    if [ ! -d "$D/.git" ]; then
        git init
    fi

    if [ -z "$(git remote -v | grep origin)" ]; then
        git remote add origin "https://github.com/soto-project/$BASENAME.git"
    else
        git remote set-url origin "https://github.com/soto-project/$BASENAME.git"
    fi

    GIT_STATUS_R=$(git status --porcelain)
    if [[ -z $GIT_STATUS_R ]]; then
        # need to add commit to create main to reset later
        git add .
        git commit -m "dummy commit"
    fi

    git fetch
    git branch --set-upstream-to=origin/main main
    git reset origin/main

    echo "Enter in $D"

    GIT_STATUS_R=$(git status --porcelain)
    if [[ -z $GIT_STATUS_R ]]; then
        echo "Nothing to commit. switch to the next module...."
        echo ""
        if [ -n "${TAG}" ]; then
            git tag $TAG
            git push origin $TAG
        fi
        popd
        continue
    fi

    echo "swift build start....."
    swift build
    echo "swift build done!"
    echo ""

    git add .
    git commit -am "$COMMENT"
    git push origin main
    if [ -n "${TAG}" ]; then
        git tag $TAG
        git push origin $TAG
    fi
    popd
done
