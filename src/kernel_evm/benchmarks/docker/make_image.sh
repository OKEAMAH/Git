#!/bin/sh
cp _build/default/src/bin_evm_proxy/chunker/octez_evm_chunker.exe .
docker build -f src/kernel_evm/benchmarks/docker/bench.Dockerfile -t evm-benchmark .