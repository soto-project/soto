#!/bin/sh

#######################################################
#
# usage bash publish-module.sh /path/to/swift-aws "sync with aws-sdk-swift@1.0.2" 1.0.2
#  $1: path for aws partial modules are stored
#  $2: commit comment
#  $3: tag for release
#
#######################################################

set -eux

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
for D in $(find $SOURCE_PATH -depth 1 -type d); do
    BASENAME=$(basename $D)
    pushd $D
    if [ ! -d "$D/.git" ]; then
        git init
    fi

    if [ -z "$(git remote -v | grep origin)" ]; then
        git remote add origin "https://github.com/swift-aws/$BASENAME.git"
    else
        git remote set-url origin "https://github.com/swift-aws/$BASENAME.git"
    fi

    GIT_STATUS_R=$(git status)
    if [[ $GIT_STATUS_R != *"nothing to commit"* ]]; then
        # need to add commit to create master to reset later
        git add .
        git commit -m "dummy commit"
    fi

    git fetch
    git branch --set-upstream-to=origin/master master
    git reset origin/master

    echo "Enter in $D"
    swift package update

    GIT_STATUS_R=$(git status)
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
    #git push origin master
    #git tag $TAG
    #git push origin $TAG
    popd
done
