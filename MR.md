
Testing

How to run just a single Wasm test:

    (dune build src/lib_webassembly && cd src/lib_webassembly/bin && ../../../_build/default/src/lib_webassembly/bin/main.exe test/core/imports.wast)

