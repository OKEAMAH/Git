#!/bin/sh

set -x

# Check cache
check_execs() {
    for f in "$@"; do
        if ! test -f "$f"; then
            echo "Couldn't find $f"
            return 1
        fi
    done
    echo "Found all of $*"
    return 0
}

# EXECUTABLE_FILES may contain multiple paths and so must be split.
# shellcheck disable=SC2086,SC2046
if check_execs evm_kernel.wasm smart-rollup-installer sequenced_kernel.wasm tx_kernel.wasm tx_kernel_dal.wasm dal_echo_kernel.wasm risc-v-sandbox risc-v-dummy.elf src/risc_v/tests/inline_asm/rv64-inline-asm-tests ; then
    echo "Relying on cache"
    exit 0
else
    echo "Rebuilding"
fi

make -f kernels.mk build
