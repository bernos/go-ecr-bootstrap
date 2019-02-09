#! /usr/bin/env bash

set -eou pipefail

[ $# -eq 0 ] && { echo "usage gh-release.sh <version>"; exit 1; }

version="${1}"
branch=${BUILDKITE_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}

#-------------------------------------------------------------------------------
# Ensure that we only cut github releases from the master branch
#-------------------------------------------------------------------------------
if [ "${branch}" != "master" ]; then
    echo "Github releases can only be cut from the master branch"
    exit 1
fi

#-------------------------------------------------------------------------------
# Calculate the tag message
#-------------------------------------------------------------------------------
if [ "${BUILDKITE}" = "true" ]; then
    tag_msg="Tagged by Buildkite ${BUILDKITE_BUILD_URL}"
    git config user.email "buildkite@seek.com.au"
    git config user.name "Buildkite"
else
    tag_msg="Tagged by $(git config --get user.email)"
fi

#-------------------------------------------------------------------------------
# Tag it!
#-------------------------------------------------------------------------------
tag_name="v${version}"
echo "Releasing ${tag_name} '${tag_msg}'"

git tag -a "${tag_name}" -m "${tag_msg}" && git push origin "${tag_name}"

echo "Done"
