#!/bin/sh

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

docker build images/rust-toolchain \
  --build-arg=BUILDKIT_INLINE_CACHE=1 \
  --cache-from="${image_base}:${CI_COMMIT_REF_SLUG}" \
  --cache-from="${image_base}:${CI_DEFAULT_BRANCH}" \
  -t "${image_base}:${CI_COMMIT_REF_SLUG}" \
  -t "${image_name}"

# Push image
docker push --all-tags "${image_base}"
