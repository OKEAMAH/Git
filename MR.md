
Temporary branch by hans for E2E test scenario.

Goal: Run VM to computation point, produce small computation tick



## TODO
- Which kernel?
- Simple test in lib_scoru_wasm itself?

## Running WASM tests

Hacky way of running a single WASM test suite test

    (dune build src/lib_webassembly && cd src/lib_webassembly/bin && poetry run ./test/core/run.py --wasm ../../../_build/default/src/lib_webassembly/bin/main.exe -- test/core/imports.wast)

To run all use
    (make && make test-webassembly)
