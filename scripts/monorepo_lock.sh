#!/bin/sh
# shellcheck disable=SC2046
# for omitting quotes in: eval $(opam env)

script_dir="$(cd "$(dirname "$0")" && echo "$(pwd -P)/")"

#shellcheck source=scripts/version.sh
. "$script_dir"/version.sh

"$script_dir"/setup_local_switch.sh

eval $(opam env)

if [ "$1" = "--minimal-update" ]; then
  opam monorepo lock \
    --recurse \
    --lockfile tezos.opam.locked \
    --add-opam-provided ocamlfind \
    --minimal-update
else
  opam monorepo lock \
    --recurse \
    --lockfile tezos.opam.locked \
    --add-opam-provided ocamlfind
fi
