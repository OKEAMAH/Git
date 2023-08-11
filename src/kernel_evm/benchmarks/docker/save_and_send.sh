#!/bin/bash
docker save evm-benchmark | gzip > evm-benchmark.tar.gz
scp evm-benchmark.tar.gz bench:/home/ubuntu/benchmark