#!/bin/bash

set -eux

mkdir -p sourcekitten

moduleArray=( "AWSSDKSwiftCore" )

for d in Sources/AWSSDKSwift/Services/*; do
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
    # if already prefixed with AWS dont add prefix
    if [[ $moduleName != AWS* ]] ;
    then
        sourcekitten doc --spm-module "AWS$moduleName" -- --target "AWS$moduleName" > sourcekitten/"$moduleName".json
    else
        sourcekitten doc --spm-module "$moduleName" -- --target "$moduleName" > sourcekitten/"$moduleName".json
    fi
done
