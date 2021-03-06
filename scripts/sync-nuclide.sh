#!/bin/bash

set -e

SYNC_PATHS=(.eslintrc.js flow-libs flow-typed modules ':!modules/big-dig*')
SYNC_BRANCH=nuclide-sync
SYNC_MESSAGE="Sync with facebook/nuclide"

if [ -n "$(git status --porcelain)" ]; then
  echo "Uncommitted changes detected; exiting."
  exit 1
fi

git branch -f "$SYNC_BRANCH" master
echo "** Checking out branch $SYNC_BRANCH"
git checkout --quiet "$SYNC_BRANCH"

# Ensure that we have "nuclide" set up as a remote.
echo "** Fetching the latest Nuclide commits"
git remote add nuclide https://github.com/facebook/nuclide 2> /dev/null || true
git fetch nuclide

LAST_SYNC_MESSAGE=$(git log --pretty=%s | grep "$SYNC_MESSAGE" | head -n 1)
LAST_SYNC_COMMIT="${LAST_SYNC_MESSAGE##*@}"  # Everything after the "@".
HEAD_COMMIT=$(git rev-parse nuclide/master)

if [[ "$HEAD_COMMIT" == "$LAST_SYNC_COMMIT" ]]; then
  echo "Already up to date."
  exit 0
fi

echo "** Last sync was $LAST_SYNC_COMMIT"
echo "** Syncing with $HEAD_COMMIT"
git format-patch --stdout "$LAST_SYNC_COMMIT..nuclide/master" -- "${SYNC_PATHS[@]}" > /tmp/patches
git am --3way /tmp/patches

echo "** Merging back with master"
git checkout master
git merge --no-ff -m "$SYNC_MESSAGE@$HEAD_COMMIT" "$SYNC_BRANCH"
git branch -D "$SYNC_BRANCH"
