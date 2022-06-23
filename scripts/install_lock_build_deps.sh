#!/bin/sh

set -eu

script_dir="$(cd "$(dirname "$0")" && echo "$(pwd -P)/")"

echo "Setting up switch"
"$script_dir"/setup_local_switch.sh
echo "Done setting up switch"

# Must be done first because some opam packages depend on Rust.
"$script_dir"/install_build_deps.rust.sh

# Installs non-vendored dependencies such as ocaml and dune
opam install --deps-only --ignore-pin-depends ./tezos.opam.locked --yes

# Installs the opam-monorepo plugin
opam install opam-monorepo.0.3.3 --yes

# Install locked external dependencies
opam monorepo depext --yes

# Pulls locked dependencies into the duniverse folder
opam monorepo pull

if [ "${1:-unset}" = "--dev" ]; then
    dev=yes
else
    dev=
fi

# install dev dependencies if asked
if [ -n "$dev" ]; then
    # Note: ocaml-lsp-server.1.6.0 dependencies are not constrained
    # enough (for [ppx_yojson_conv_lib] in particular), so we add a
    # minimal bound to ensure it won’t be picked by opam.
    # utop is constrained to avoid reinstalling in all the times.
    opam install --yes merlin ometrics.0.2.1 utop.2.9.0 odoc ocp-indent "ocaml-lsp-server>=1.6.1" merge-fmt --criteria="-changed,-removed"
fi
