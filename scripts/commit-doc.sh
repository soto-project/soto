#!/bin/sh

set -eux

FOLDER=5.x.x

move_docs_to_gh_pages() {
    # stash everything that isn't in docs, store result in STASH_RESULT
    STASH_RESULT=$(git stash push -- ":(exclude)docs")
    # get branch name
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    REVISION_HASH=$(git rev-parse HEAD)
    COMMIT_MSG="Documentation for https://github.com/swift-aws/aws-sdk-swift/tree/$REVISION_HASH"
    if [ -n "$1" ]; then
        COMMIT_MSG=$1
    fi

    git checkout gh-pages
    # copy contents of docs to docs/current replacing the ones that are already there
    rm -rf "$FOLDER"
    mv docs/ "$FOLDER"/
    # commit
    git add --all "$FOLDER"
    git commit -m "$COMMIT_MSG"
    git push
    # return to branch
    git checkout "$CURRENT_BRANCH"

    if [ "$STASH_RESULT" != "No local changes to save" ]; then
        git stash pop
    fi
}

COMMIT_MSG=""
while getopts 'm:' option
do
    case $option in
        m) COMMIT_MSG=$OPTARG ;;
        *) usage ;;
    esac
done

move_docs_to_gh_pages "$COMMIT_MSG"
