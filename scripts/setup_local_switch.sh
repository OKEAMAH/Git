#!/bin/sh

set -eu

script_dir="$(cd "$(dirname "$0")" && echo "$(pwd -P)/")"
src_dir="$(dirname "$script_dir")"

dune_universe="git+https://github.com/dune-universe/opam-overlays.git"

cd "$src_dir"
if [ ! -d "_opam" ]; then
  # Creates a local switch if there's none
  echo "Create a fresh local switch"
  opam switch create ./ --empty -y
else
  if [ "$(opam switch invariant)" != "[]" ]; then
    # If a local switch exists with an invariant, it likely pre-dates
    # opam-monorepo, therefore we create a fresh, empty one without
    # invariant
    echo "A local switch with an invariant already exists"
    opam switch remove ./
    opam switch create ./ --empty -y
  fi
fi
# Adds the dune-universe/opam-overlays repository for opam-monorepo, allowing it
# to use dune ports when upstream packages don't build with dune
opam repository add dune-universe $dune_universe 2> /dev/null
opam update --quiet > /dev/null
