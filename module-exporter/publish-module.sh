#!/usr/bin/env bash

#######################################################
#
# usage bash publish-module.sh /path/to/swift-aws "sync with aws-sdk-swift@1.0.2" 1.0.2
#  $1: path for aws partial modules are stored
#  $2: commit comment
#  $3: tag for release
#
#######################################################

set -e

if [ -z "$1" ]; then
    echo "You should pass the source path for aws partial modules are stored as \$1"
    exit 1
fi

if [ -z "$2" ]; then
    echo "You should pass the commit comment as \$2"
    exit 1
fi

if [ -z "$3" ]; then
    echo "You should pass the tag(version) for this release as \$3"
    exit 1
fi

SOURCE_PATH=$1
COMMENT=$2
TAG=$3

for D in $(find $SOURCE_PATH -maxdepth 1 -type d); do
  cd $D
  if [ -d "$D/.git" ]; then
    echo "Enter in $D"
    swift package update

    GIT_STATUS_R=`git status`
    if [[ $GIT_STATUS_R == *"nothing to commit"* ]]; then
      echo "Nothing to commit. switch to the next module...."
      echo ""
      continue
    fi

    echo "swift build start....."
    swift build
    echo "swift build done!"
    echo ""

    git add .
    git commit -am "$COMMENT"
    git push origin master
    git tag $TAG
    git push origin $TAG
  fi
done
