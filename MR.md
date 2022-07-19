
Temporary branch by hans for E2E test scenario.

Goal: Run VM to computation point, produce small computation tick



## TODO
- Which kernel?
  - Use test kernel by Emma
  - Can we look at it to see what it does?
    - Source code here:
      https://gitlab.com/trili/kernel/-/blob/main/test_kernel/src/lib.rs
    - No input, does not import any host functions
    - Addition and allocations, includes wee_alloc (small allocator)
    - See `foo.wast` for WAST form, plus some comments

  - Encoding for top-level execution state

  - Load kernel using floppy
  - Big tick parsing
  - Big tick init
  - Some eval steps

## WASM utils

### Binary to text

    (dune build src/lib_webassembly && _build/default/src/lib_webassembly/bin/main.exe -i src/proto_alpha/lib_protocol/test/integration/wasm_kernel/computation.wasm -o foo.wast)


## Running WASM tests

Hacky way of running a single WASM test suite test

    (dune build src/lib_webassembly && cd src/lib_webassembly/bin && poetry run ./test/core/run.py --wasm ../../../_build/default/src/lib_webassembly/bin/main.exe -- test/core/imports.wast)

To run all use
    (make && make test-webassembly)
