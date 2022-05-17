#!/bin/sh

set -e

script_dir="$(cd "$(dirname "$0")" && echo "$(pwd -P)/")"
src_dir="$(dirname "$script_dir")"

if [ "$1" = "--dev" ]; then
    dev=yes
else
    dev=
fi

"$script_dir"/setup_local_switch.sh

eval "$(opam env --shell=sh)"

# Must be done first because some opam packages depend on Rust.
"$script_dir"/install_build_deps.rust.sh

# Installs non-vendored dependencies such as ocaml and dune
opam install --deps-only --ignore-pin-depends ./tezos.opam.locked

# Installs the opam-monorepo plugin
opam install opam-monorepo.0.3.1

# Installs all depexts and transitive depexts of the project
opam monorepo depext

# Pulls locked dependencies into the duniverse folder
opam monorepo pull

# install dev dependencies if asked
if [ -n "$dev" ]; then
    # Note: ocaml-lsp-server.1.6.0 dependencies are not constrained
    # enough (for [ppx_yojson_conv_lib] in particular), so we add a
    # minimal bound to ensure it won’t be picked by opam.
    # utop is constrained to avoid reinstalling in all the times.
    opam install --yes merlin ometrics.0.1.3 utop.2.9.0 odoc ocp-indent "ocaml-lsp-server>=1.6.1" merge-fmt --criteria="-changed,-removed"
fi

"$script_dir"/install_sapling_parameters.sh
