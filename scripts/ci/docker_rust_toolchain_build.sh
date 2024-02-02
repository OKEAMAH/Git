#!/bin/sh
#
# Build rust-toolchain image for CI jobs and Octez docker distribution.
#
# Reads the following environment variables:
#  - 'rust_toolchain_image_name'
#  - 'rust_toolchain_image_tag' (optional)
#  - 'CI_COMMIT_REF_SLUG': set by GitLab CI
#  - 'CI_DEFAULT_BRANCH': set by GitLab CI
#  - 'CI_PIPELINE_ID': set by GitLab CI
#  - 'CI_PIPELINE_URL': set by GitLab CI
#  - 'CI_JOB_ID': set by GitLab CI
#  - 'CI_JOB_URL': set by GitLab CI
#  - 'CI_COMMIT_SHA': set by GitLab CI
#
# The image is tagged with
# $rust_toolchain_image_name:$CI_COMMIT_REF_SLUG and
# $rust_toolchain_image_name:TAG. If $rust_toolchain_image_tag is set,
# then TAG contains this value. If not, TAG contains a hash of this
# image's inputs.
#
# The inputs of this image is the set of files in the directory
# 'images/rust-toolchain'.

set -eu

set -x

# rust_toolchain_image_name is set in the variables of '.gitlab-ci.yml'
# shellcheck disable=SC2154
image_base="${rust_toolchain_image_name}"

image_tag="${rust_toolchain_image_tag:-}"
if [ -z "$image_tag" ]; then
  # by default, tag with the hash of the [images/rust-toolchain] folder.
  image_tag=$(git ls-files -s images/rust-toolchain | git hash-object --stdin)
fi
image_name="${image_base}:${image_tag}"

# Store the image name for jobs that use it.
echo "rust_toolchain_image_tag=$image_tag" > rust_toolchain_tag.env

# Build image unless it already exists in the registry.
if docker manifest inspect "${image_name}" > /dev/null; then
  echo "Image ${image_name} already exists in the registry, do nothing."
  exit 0
fi

echo "Build ${image_name}"

./scripts/ci/docker_initialize.sh

docker build images/rust-toolchain \
  --build-arg=BUILDKIT_INLINE_CACHE=1 \
  --cache-from="${image_base}:${CI_COMMIT_REF_SLUG}" \
  --cache-from="${image_base}:${CI_DEFAULT_BRANCH}" \
  --label "com.tezos.build-pipeline-id"="${CI_PIPELINE_ID}" \
  --label "com.tezos.build-pipeline-url"="${CI_PIPELINE_URL}" \
  --label "com.tezos.build-job-id"="${CI_JOB_ID}" \
  --label "com.tezos.build-job-url"="${CI_JOB_URL}" \
  --label "com.tezos.build-tezos-revision"="${CI_COMMIT_SHA}" \
  -t "${image_base}:${CI_COMMIT_REF_SLUG}" \
  -t "${image_name}"

# Push image
docker push --all-tags "${image_base}"
