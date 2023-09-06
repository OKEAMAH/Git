# M.I.R - Michelson In Rust

This repo hosts the Rust implementation of the typechecker and interpreter for
Michelson smart contract language and implements a Michelson runtime as a
Smart Rollup.

This project implements a Michelson runtime as a Smart Rollup.

## Building

Running

```
cargo build --target wasm32-unknown-unknown
```

will build the project in wasm, installing all the necessary toolchain.

You will need `clang >= 11` installed in the system. This and other constraints
can be found mentioned in the
[Rust SDK for Smart Rollups](https://docs.rs/tezos-smart-rollup/latest/tezos_smart_rollup/).

That build command will also automatically install the standard library for
`wasm32-unknown-unknown` target since compiling to that target is necessary for
actually using the produced kernel in Tezos network.

## Automatic testing

You can run the included tests by the following command.

`cargo test`

Some tests print gas consumption information (in addition to testing it), but `cargo test` omits output from successful tests by default. To see it, run

`cargo test -- --show-output`
