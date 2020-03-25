#!/bin/sh

set -eux

COMMIT_OPTS=""
while getopts 'm:' option
do
    case $option in
        m) COMMIT_OPTS="-m $OPTARG" ;;
        *) usage ;;
    esac
done

echo $COMMIT_OPTS

source ./scripts/build-json-doc.sh 0 1
source ./scripts/build-doc.sh
source ./scripts/commit-doc.sh $COMMIT_OPTS
