#!/bin/sh

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
