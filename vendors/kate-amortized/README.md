# Kate Amortized

`kate_amortized.ml` is the implementation of parts 2 and 3.2 of [Fast amortized Kate proofs](https://github.com/khovratovich/Kate/blob/master/Kate_amortized.pdf).

## Install

Follow [Privacy-team's readme](../README.md) instructions. An additionnal `opam install . --with-test` may be needed.

## Run tests

Run `dune build @kate-amortized/runtest` to run quick tests.
To run the slow test and evaluate performance run `dune build @kate-amortized/test/are_we_fast_yet -f`.

## Functions

### Part 2 proofs

`build_ct_list` builds part 2 multiple proofs.

### Part 3.2 proofs

`multiple_multi_reveals` builds part 3.2 multiple multi-reveals when `l` is a power of two.
`multiple_multi_reveals_with_preprocessed_srs` does the same thing but with the srs part of the computations preprocessed with `preprocess_multi_reveals`.

### Verifying

`verify` checks a proof returned by `multiple_multi_reveals`.

## Future optimizations

Performance could be improve by using fft with no allocations and pippenger.