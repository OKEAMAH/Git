#!/bin/sh
# shellcheck disable=SC2046
# for omitting quotes in: eval $(opam env)

set -eu

script_dir="$(cd "$(dirname "$0")" && echo "$(pwd -P)/")"
src_dir="$(dirname "$script_dir")"

#shellcheck source=scripts/version.sh
. "$script_dir"/version.sh

add_tezos_repo () {
  opam repository set-url tezos --dont-select "$opam_repository" || \
      opam repository add tezos --dont-select "$opam_repository" > /dev/null 2>&1
}

dune_universe="https://github.com/dune-universe/opam-overlays.git"

add_dune_repo () {
  # Adds the dune-universe/opam-overlays repository for opam-monorepo, allowing it
  # to use dune ports when upstream packages don't build with dune
  opam repository set-url dune-universe --dont-select "$dune_universe" || \
      opam repository add dune-universe --dont-select "$dune_universe" > /dev/null 2>&1
}

switch_create () {
  opam switch create ./ --empty -y --repositories=tezos,dune-universe
  eval $(opam env)
}

cd "$src_dir"
if [ ! -d "_opam" ]; then
  # Creates a local switch if there's none
  echo "Create a fresh local switch"
  switch_create
else
  if [ "$(opam switch invariant)" != "[]" ]; then
    # If a local switch exists with an invariant, it likely pre-dates
    # opam-monorepo, therefore we create a fresh, empty one without
    # invariant
    echo "A local switch with an invariant already exists"
    opam switch remove ./
    switch_create
  fi
fi

add_tezos_repo
add_dune_repo
opam update --quiet > /dev/null
#TEMP
opam repository list --all
#/TEMP
