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

mkdir -p sourcekitten

moduleArray=( "SotoCore" )

for d in Sources/Soto/Services/*; do
    moduleName="$(basename "$d")"
    moduleArray+=($moduleName)
done;

chunkIndex=$1
numberOfChunks=$2
moduleArraySize=${#moduleArray[@]}
# work out the start and end index of the modules we are going to process
chunkStart=$(( $chunkIndex*$moduleArraySize/$numberOfChunks ))
chunkEnd=$(( (($chunkIndex+1)*$moduleArraySize/$numberOfChunks)-1 ))

for index in $(seq $chunkStart $chunkEnd)
do
    moduleName=${moduleArray[$index]}
    # if already prefixed with Soto dont add prefix
    if [[ $moduleName != Soto* ]] ;
    then
        sourcekitten doc --spm-module "Soto$moduleName" -- --target "Soto$moduleName" > sourcekitten/"$moduleName".json
    else
        sourcekitten doc --spm-module "$moduleName" -- --target "$moduleName" > sourcekitten/"$moduleName".json
    fi
done
