# Michelson in Rust prototype

This is a rough prototype for MIR, primarily intended as a proof of concept, and
testing grounds for exploring possible designs. At the time of writing, large
parts of Michelson are not implemented, but it can run some basic code.

In particular, it can run code from `../test/fixtures/`, although it can't parse
`tzt` files. In order to run those, assuming you have Rust toolchain installed, you can do something like this:

```bash
pcregrep -o1 --multiline 'code\s*{((?:\n|.)*?)}\s*;\ninput' ../test/fixtures/factorial.tzt | cargo run nat 30
```

The code to run is accepted at stdin, and input type and value are accepted as
the first and the second command line arguments respectively.
