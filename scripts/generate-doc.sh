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

DIRNAME=$(dirname "$0")

COMMIT_OPTS=""
while getopts 'm:' option
do
    case $option in
        m) COMMIT_OPTS="-m $OPTARG" ;;
        *) usage ;;
    esac
done

echo $COMMIT_OPTS
source "$DIRNAME"/build-json-doc.sh 0 1
source "$DIRNAME"/build-doc.sh
source "$DIRNAME"/commit-doc.sh $COMMIT_OPTS
