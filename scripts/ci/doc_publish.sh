#!/usr/bin/env bash

set -x

cd "${CI_PROJECT_DIR}" || exit 1

echo "State after unzipping cache:"
[ -d  _build/default/_doc/_html/tezos-base/Tezos_base/ ] &&
    ls _build/default/_doc/_html/tezos-base/Tezos_base/

make all
dune build @doc > odoc.log 2>&1
[ -f odoc.log ] && head odoc.log

echo "State 'dune build @doc':"
[ -d  _build/default/_doc/_html/tezos-base/Tezos_base/ ] &&
    ls _build/default/_doc/_html/tezos-base/Tezos_base/
