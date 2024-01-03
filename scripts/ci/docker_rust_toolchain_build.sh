#!/bin/sh

set -eu

set -x

image_base="${CI_REGISTRY_IMAGE}/rust-toolchain"
image_tag="${CI_COMMIT_SHA}"
image_name="${image_base}:${image_tag}"

# Get SHA of the latest merge parent, to fetch cache from
if [ -n "${CI_MERGE_REQUEST_DIFF_BASE_SHA:-}" ]; then
    # This script is running in a MR before_merging pipeline.
    # Attempt to fetch cache from the predecessor of the base of this MR.
    git fetch origin "${CI_MERGE_REQUEST_DIFF_BASE_SHA}"
    merge_parent=$(git show -s --pretty=format:%H "${CI_MERGE_REQUEST_DIFF_BASE_SHA}^2" || echo "not_found")
else
    # This script is running in a master_branch pipelines.
    # Attempt to fetch cache from the predecessor of this commit.
    git fetch origin "${CI_COMMIT_BRANCH}" --depth 2
    merge_parent=$(git show -s --pretty=format:%H HEAD^2 || echo "not_found")
fi

# Build image
docker build images/rust-toolchain \
       --build-arg=BUILDKIT_INLINE_CACHE=1 \
       --cache-from="${image_base}:${CI_COMMIT_REF_SLUG}" \
       --cache-from="${image_base}:${merge_parent}" \
       --cache-from="${image_base}:${CI_DEFAULT_BRANCH}" \
       -t "${image_base}:${CI_COMMIT_REF_SLUG}" \
       -t "${image_name}"

# Push image
docker push --all-tags "${image_base}"
