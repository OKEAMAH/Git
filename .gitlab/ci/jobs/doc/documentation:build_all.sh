#!/bin/sh

set -ex

eval "$(opam env)"

./scripts/remove-old-protocols.sh .trash
make all
./scripts/restore-old-protocols.sh .trash
make -C docs -j all
