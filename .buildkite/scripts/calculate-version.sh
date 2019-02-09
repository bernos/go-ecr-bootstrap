#! /usr/bin/env bash

set -eou pipefail

CURDIR=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)
branch=${BUILDKITE_BRANCH:-"$(git rev-parse --abbrev-ref HEAD)"}
safe_branch="$(echo "${branch}" | tr " " "-" | tr "/" "-")"
commit_sha="$(git rev-parse --short HEAD)"

# Ensure tags are up to date
git fetch --tags

# Get current version from git tags, default to "none"
current_version=$(git describe                        \
                      --match "v[0-9].*[0-9].*[0-9]*" \
                      --abbrev=0 HEAD 2> /dev/null    \
                      || echo "none")

if [ "${current_version}" = "none" ]; then
    next_version="0.0.0"
else
    current_version=${current_version:1}

    message=$(git log -n 1 --pretty="%s %b")

    echo "MESSAGE:" >&2
    echo "${message}" >&2

    mode="patch"

    if echo "${message}" | grep -q '\[major\]'; then
        mode=major
    elif echo "${message}" | grep -q '\[minor\]'; then
        mode=minor
    fi

    # Use semver to calculate the next version number
    next_version=$(${CURDIR}/semver.sh bump "${mode}" "${current_version}")
fi

if [ "${branch}" == "master" ]; then
    echo "${next_version}"
else
    echo "branch-${safe_branch}-${current_version}-${commit_sha}"
fi


