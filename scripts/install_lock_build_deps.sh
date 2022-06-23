#!/bin/sh

set -eu

script_dir="$(cd "$(dirname "$0")" && echo "$(pwd -P)/")"

temp_lock_file="tezos-tmp.opam.locked"
trap cleanup SIGINT SIGQUIT SIGABRT SIGTERM

cleanup () {
    # if any command fails, let's remove our temporary files
    rm -f "$temp_lock_file"
}

if [ "${1:-unset}" = "--dev" ]; then
    dev=yes
else
    dev=
fi

if [ "${1:-unset}" = "--tps" ]; then
    tps=yes
else
    tps=
fi

echo "Setting up switch"
"$script_dir"/setup_local_switch.sh
echo "Done setting up switch"

# Must be done first because some opam packages depend on Rust.
"$script_dir"/install_build_deps.rust.sh

if [ -n "$tps" ]; then
  cp tezos.opam.locked "$temp_lock_file"
else
  # remove postgres dependency if TPS is not going to be used
  cat tezos.opam.locked | \
  sed '/conf-postgresql/d' | \
  sed '/\["postgresql/d' | \
  cat > "$temp_lock_file"
fi

# Installs non-vendored dependencies such as ocaml and dune
opam install --deps-only --ignore-pin-depends ./"$temp_lock_file" --yes 2> /dev/null

# Installs the opam-monorepo plugin
opam install opam-monorepo.0.3.3 --yes

# Install locked external dependencies
opam monorepo depext --yes --lockfile "$temp_lock_file"

rm "$temp_lock_file"

# Pulls locked dependencies into the duniverse folder
# We can pull from the main lockfile because if it doesn't need TPS
# dependencies it will not build them
opam monorepo pull

# install dev dependencies if asked
if [ -n "$dev" ]; then
    # Note: ocaml-lsp-server.1.6.0 dependencies are not constrained
    # enough (for [ppx_yojson_conv_lib] in particular), so we add a
    # minimal bound to ensure it won’t be picked by opam.
    # utop is constrained to avoid reinstalling in all the times.
    opam install --yes merlin ometrics.0.2.1 utop.2.9.0 odoc ocp-indent "ocaml-lsp-server>=1.6.1" merge-fmt --criteria="-changed,-removed"
fi

# in case cleanup hasn't happened, do it now
cleanup
