# Michelson in Rust

This project implements a Michelson runtime as a Smart Rollup.

## Building

Running

```
cargo build
```

will automatically build the project for `wasm32-unknown-unknown` target,
installing all the necessary toolchain.

You will need `clang >= 11` installed in the system. This and other constraints
can be found mentioned in the
[Rust SDK](https://docs.rs/tezos-smart-rollup/latest/tezos_smart_rollup/).

TODO: how to run kernel.
