#!/bin/sh

# Update the repository of opam packages used by tezos.  Tezos uses a
# private, shrunk down, opam repository to store all its
# dependencies. This is generated by the official opam repository
# (branch master) and then filtered using opam admin to include only
# the cone of tezos dependencies.  This repository is then used to
# create the based opam image used by the CI to compile tezos and to
# generate the docker images.  From time to time, when it is necessary
# to update a dependency, this repository should be manually
# refreshed. This script takes care of generating a patch for the
# private opam tezos repository. This patch must be applied manually
# w.r.t. the master branch. The procedure is as follows :
#
# 1. Update the variable `full_opam_repository_tag` in `version.sh` to
#    a commit hash from the master branch of the official
#    opam-repository. All the required packages will be extracted from
#    this snapshot to the repo.
#
# 2. Run this script, it will generate a file `opam_repo.patch`
#
# 3. Review the patch.
#
# 4. In the tezos opam-repository, create a new branch from master and
#    apply this patch. Push the patch and create a merge request. A
#    new docker image with all the prebuilt dependencies will be
#    created by the CI.
#
# 5. Update the variable `opam_repository_tag` in `scripts/version.sh` 
#    and the variable `build_deps_image_version` in `.gitlab/ci/templates.yml` 
#    with the hash of the newly created commit in `tezos/opam-repository`.
#
# 6. Enjoy your new dependencies

set -e

target="$(pwd)"/opam_repo.patch tmp_dir=$(mktemp -dt tezos_deps_opam.XXXXXXXX)

cleanup () {
    set +e
    echo Cleaning up...
    rm -rf "$tmp_dir"
    rm -rf Dockerfile
}
trap cleanup EXIT INT

script_dir="$(cd "$(dirname "$0")" && echo "$(pwd -P)/")"
src_dir="$(dirname "$script_dir")"

. "$script_dir"/version.sh

## Shallow clone of opam repository (requires git protocol version 2)
export GIT_WORK_TREE="$tmp_dir"
export GIT_DIR="$GIT_WORK_TREE/.git"
git init
git config --local protocol.version 2
git remote add origin https://github.com/ocaml/opam-repository
git fetch --depth 1 origin "$full_opam_repository_tag"

## Adding the various tezos packages

mkdir -p "$tmp_dir"/packages/octez-deps/octez-deps.dev
cp opam/virtual/octez-deps.opam "$tmp_dir"/packages/octez-deps/octez-deps.dev/opam

## Filtering unrequired packages
cd $tmp_dir
git reset --hard "$full_opam_repository_tag"

## we add a dummy package that conflict with all "hidden" packages
dummy_pkg=dummy-tezos
dummy_path=packages/$dummy_pkg/$dummy_pkg.dev
dummy_opam=$dummy_path/opam
mkdir -p $dummy_path
echo 'opam-version: "2.0"' > $dummy_opam
# Opam doesn't seem to be deterministic when resolving constraints from mirage-crypto-pk
# (("mirage-no-solo5" & "mirage-no-xen") | "zarith-freestanding" | "mirage-runtime" {>= "4.0"})
# - Sometime installing mirage-no-xen + mirage-no-solo5
# - Sometime installing mirage-runtime
# According to mirage devs, mirage-runtime is the correct dependency to install.
# In addition "inotify" is a "{os = linux}" dependency that has to be
# in the repo for irmin to be installable on linux but is not selected
# by the solver.
echo 'depends: [ "mirage-runtime" { >= "4.0.0" } "inotify" ]' >> $dummy_opam
echo 'conflicts:[' >> $dummy_opam
grep -r "^flags: *\[ *avoid-version *\]" -l ./ | LC_COLLATE=C sort -u | while read -r f;
do
    f=$(dirname $f)
    f=$(basename $f)
    p=$(echo $f | cut -d '.' -f '1')
    v=$(echo $f | cut -d '.' -f '2-')
    echo "\"$p\" {= \"$v\"}" >> $dummy_opam
done
echo ']' >> $dummy_opam

# Opam < 2.1 requires opam-depext as a plugin, later versions include it
# natively:
case $(opam --version) in
    2.0.* ) opam_depext_dep="opam-depext," ;;
    * )     opam_depext_dep="" ;;
esac
#shellcheck disable=SC2086
OPAMSOLVERTIMEOUT=600 opam admin filter --yes --resolve \
  octez-deps,ocaml,ocaml-base-compiler,odoc,${opam_depext_dep}ledgerwallet-tezos,caqti-driver-postgresql,js_of_ocaml-lwt,$dummy_pkg
## - ocaml-base-compiler has to be explicitely listed for the solver
##   to not prefer the "variant" `system` of the compiler
## - odoc is used by the CI to generate the doc
## - ledgerwallet-tezos is an optional dependency of signer-services
##   we want to have when building released binaries
## - caqti-driver-postgresq is needed by tps measurement software to
##   read tezos-indexer databases
## - js_of_ocaml-lwt is an optional dependency of tezt which is needed
##   to build tezt.js, and we do want to run some tests using nodejs

## Adding useful compiler variants
for variant in afl flambda fp ; do
    git checkout packages/ocaml-option-$variant/ocaml-option-$variant.1
done

## Removing temporary hacks
rm -r "$tmp_dir"/packages/octez-deps
rm -r "$tmp_dir"/packages/$dummy_pkg

## Generating the diff!
git remote add tezos $opam_repository_git
git fetch --depth 1 tezos "$opam_repository_tag"
git reset "$opam_repository_tag"

## opam.2.1 will try to delete opam-depext, we should restore it.
if [ ! -d packages/opam-depext ]; then
    git checkout HEAD -- packages/opam-depext
fi

## Adding safer hashes
cp -rf packages packages.bak

opam admin add-hashes sha256 sha512

(cd "$src_dir" && dune build src/tooling/opam-lint/opam_lint.exe)
for i in $(cd packages && find ./ -name opam);
do
    "$src_dir/_build/default/src/tooling/opam-lint/opam_lint.exe" "packages/$i" "packages.bak/$i"
done
rm -rf packages.bak

##
git add packages
git diff HEAD -- packages > "$target"

echo
echo "Wrote proposed update in: $target."
echo 'Please add this patch to: `https://gitlab.com/tezos/opam-repository`'
echo 'And update accordingly the commit hash in: `.gitlab/ci/templates.yml` and `scripts/version.sh`'
echo
