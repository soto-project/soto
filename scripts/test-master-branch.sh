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

set -eux

HERE=$(dirname $0)
TMPDIR=$(mktemp -d /tmp/.workingXXXXXX)
BASEDIR=$HERE/..

test_repository()
{
    ADDRESS=$1
    BRANCH=$2
    REPODIR=$TMPDIR/$(basename $1)
    git clone $ADDRESS $REPODIR
    pushd $REPODIR
    git checkout $BRANCH
    swift test
    popd
}

# Test latest code against
test_repository https://github.com/adam-fowler/s3-filesystem-kit aws-sdk-swift-main
test_repository https://github.com/adam-fowler/aws-vapor-test main
test_repository https://github.com/adam-fowler/aws-cognito-authentication-kit aws-sdk-swift-main

rm -rf $TMPDIR
