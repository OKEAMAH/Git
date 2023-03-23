#!/usr/bin/env bash

set -e

# This script assumes that [./install_build_deps.rust.sh] was called and
# rustup is available.

echo -e "<><> \033[1mInstall kernels dependencies\033[0m  ><><><><><><><><><><><><><><><><><><><><><><>"

success=0

if [ ! -x "$(command -v clang)" ]; then
    echo "Clang is not installed. Please install at least Clang >= 11."
    echo "See instructions at: https://clang.llvm.org/"
    success=1
fi

if [ ! -x "$(command -v wasm-strip)" ]; then
    echo "WABT is not installed."
    echo "See instructions at: https://github.com/WebAssembly/wabt"
    success=1
fi

if [ ! -x "$(command -v eth)" ]; then
    if [ ! -x "$(command -v npm)" ]; then
        echo "npm is required to install eth."
        echo "See instructions at: https://docs.npmjs.com/downloading-and-installing-node-js-and-npm"
        success=1
    else
        npm install eth-cli@2.0.2 --no-save
    fi
fi

echo "Done installing kernels dependencies."
exit $success
