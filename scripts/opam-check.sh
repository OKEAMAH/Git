#!/bin/sh

script_dir="$(cd "$(dirname "$0")" && echo "$(pwd -P)/")"
src_dir="$(dirname "$script_dir")"

. "$script_dir"/version.sh

opams=$(find "$src_dir/vendors" "$src_dir/src" "$src_dir/tezt" "$src_dir/opam" -name \*.opam -print)

echo "## Checking installed dependencies..."
echo

if ! opam install $opams --deps-only --with-test --show-actions | grep "Nothing to do." > /dev/null 2>&1 ; then
    echo
    echo 'Failure! Missing actions:'
    echo
    opam install $opams --deps-only --with-test --show-actions
    echo
    echo 'Failed! Please read the doc in `./scripts/update_opam_repo.sh` and act accordingly.'
    echo
    exit 1
fi

echo '## Running `./scripts/update_opam_repo.sh`'
echo
./scripts/update_opam_repo.sh || exit 1

if [ -n "$(cat opam_repo.patch)" ] ; then

    echo "##################################################"
    cat opam_repo.patch
    echo "##################################################"

    echo 'Failed! The variables `opam_repository_tag` and `full_opam_repository_tag` are not synchronized. Please read the doc in `./scripts/update_opam_repo.sh` and act accordingly.'
    echo
    exit 1
fi

echo '## Checking lockfile is in sync'
echo

make lock || exit 1
if ! git diff --exit-code --quiet tezos.opam.locked ; then
    echo
    echo 'Failure! The lock file is out of sync with the packages defined in the repository'
    echo 'Please review the lock file and commit a version that is in sync with the packages in the opam files.'
    echo
    echo '`make lock` can be used to generate a lock file that is up-to-date with the packages.'
    echo
    exit 1
fi

echo "Ok."
