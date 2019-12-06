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
./build-doc.sh
./commit-doc.sh $COMMIT_OPTS
