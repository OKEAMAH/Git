# Testing `lib-kaitai-of-data-encoding`

## Context
Tezos `data-encoding` is a combinator library for defining octez encodings.
We have decided to use Kaitai struct description language to describe existing
chain encoding. Give a valid kaitai struct description file (`.ksy`) we can
autogenerate parsers in many mainstream languages. 

In the same manner `lib-kaitai-of-data-encoding` is a library, that in
combinatory fashion translates `data-encoding` AST to a valid Kaitai AST.
**It is thus important to guarantee that `lib-kaitai-of-data-encoding` generates
syntacticaly and semantically valid `.ksy` files.

## Testing

### Unit testing
There is a form of unit testing going on via `test_translation_of_*.ml` files.
Inside those tests, we guarantee that a valid data encoding definition is
translated to a expected kaitai specification file (`.ksy`). As stated above it
is critical to gurantee that the expeted `.ksy` file against which we assert is
also a semantically correct one. For more on that see **E2e testing** chapter
below.

### E2e testing
In order to guarantee semantic corectness of expected `.ksy` files the idea is
to have a kinda preprocessing step (done by `kaitai_e2e.sh` script) that should
be done before the actual unit tests (`dune test`):
I.e. `./contrib/lib_kaitai_of_data_encoding/test/kaitai_e2e.sh && dune test contrib/lib_kaitai_of_data_encoding/`