#!/bin/bash
##===----------------------------------------------------------------------===##
##
## This source file is part of the SwiftNIO open source project
##
## Copyright (c) 2017-2019 Apple Inc. and the SwiftNIO project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.txt for the list of SwiftNIO project authors
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
    REPODIR=$TMPDIR/$(basename $1)
    git clone $ADDRESS $REPODIR
    pushd $REPODIR
    git checkout aws-sdk-swift-master
    swift test
    popd
}

# Test latest code against
test_repository https://github.com/adam-fowler/s3-filesystem-kit
test_repository https://github.com/adam-fowler/aws-vapor-test
test_repository https://github.com/adam-fowler/aws-cognito-authentication-kit

rm -rf $TMPDIR

