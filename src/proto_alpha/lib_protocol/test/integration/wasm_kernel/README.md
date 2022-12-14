# About
This folder contains example test kernels, used for running `SCORU WASM` integration tests.

The test kernels have been built from [tezos/kernel](https://gitlab.com/trili/kernel.git), then manually edited to take into account a change in naming introduced by [this MR](https://gitlab.com/tezos/tezos/-/merge_requests/6914).

```terminal
wasm2wat ${OLD_KERNEL} -o tmp.wat
sed -i -e 's/kernel_next/kernel_run/g' -e 's/rollup_safe_core/smart_rollup_core/g' tmp.wast
wat2wasm tmp.wat -o {OLD_KERNEL}
```

# Available kernels
It is possible to build the test kernels manually, and verify that they are bit-for-bit identical.

## Prerequisites
You will need `docker`, `git` and `wasm-strip` installed, alongside either `bash` or `zsh`.
- `wasm-strip` is part of the [WebAssembly Binary Toolkit](https://github.com/WebAssembly/wabt).

Next, clone the *tezos/kernel* repository:
``` shell
git clone https://gitlab.com/tezos/kernel.git wasm_kernel
cd wasm_kernel
```
and then follow the instructions below for the required kernel.

## [computation.wasm](./computation.wasm)
The computation kernel performs a simple computation (addition) on each call to its `kernel_run` entrypoint.
It keeps the result on the heap, and therefore uses the allocator. It makes no use of any *PVM host-capabilities*.

It is designed to be small enough to be able to originate directly within a boot sector, but also large enough to be
used with the *gather-floppies* mechanism.

To build the `computation.wasm` kernel, run the following from the checked-out `tezos/kernel` repo:
``` shell
git checkout 60e2dedc2b5debb9a6add98038e52e4cd0a358a6

# Load the required rust toolchain dockerfile
source scripts/cargo-docker.sh

cargo build -p test_kernel --target wasm32-unknown-unknown --release \
    --no-default-features --features none,wee_alloc

# computation_kernel.wasm is a 1.6M wasm binary.
cp target/wasm32-unknown-unknown/release/test_kernel.wasm computation_kernel.wasm

# Strips binary down to 9.7K
wasm-strip computation_kernel.wasm
```
# echo.wasm

`echo.wasm` is the result of `wat2wasm echo.wast`.

This simple kernel writes the external messages it receives in its outbox.

To achieve that, it needs to take the encoding of the inputs into
account to extract the payload to push into the outbox.

# reveal_installer (p1 & p2)

The `reveal_installer` is a kernel that can be used to originate a rollup, and install a larger kernel leveraging the *DAC* mechanism.

To build, run the following from the checked-out `tezos/kernel` repo:
```shell
git checkout preimage-installer-v1

# Load the required rust toolchain dockerfile
source scripts/cargo-docker.sh

cargo make wasm-preimage-installer

cp target/wasm32-unknown-unknown/release/tezos_rollup_installer_kernel.wasm reveal_installer.wasm
wasm-strip reveal_installer.wasm
```

You then need to split the installer into two parts, at the value `1acaa995ef84bc24cc8bb545dd986082fbbec071ed1c3e9954abea5edc441ccd3a`.

To use, you need to concatenate the two parts, with the hex-encoded root reveal hash, for the kernel you'd like to install:
```
installer.wasm.p1 + <hex preimage DAC root hash> + installer.wasm.p2
```

See `prepare_installer_kernel` in [sc_rollup.ml](../../../../../../tezt/tests/sc_rollup.ml) for an example installation of a kernel.

# tx-kernel.wasm
The `tx-kernel` is a TORU-like program for transacting in a wasm rollup.

To build, run the following from the checked-out `tezos/kernel` repo:
```shell
git checkout preimage-installer-v1

# Load the required rust toolchain dockerfile
source scripts/cargo-docker.sh

cargo make wasm-tx-kernel

cp target/wasm32-unknown-unknown/release/kernel_core.wasm tx-kernel.wasm

wasm-strip tx-kernel.wasm
```

This can be installed using the *reveal_installer* described above.
