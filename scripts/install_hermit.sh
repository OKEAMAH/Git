#!/usr/bin/env bash

set -e

wget https://github.com/hermit-os/rust-std-hermit/releases/download/1.74.0/rust-std-1.74.0-riscv64gc-unknown-hermit.tar.gz
tar -xvf rust-std-1.74.0-riscv64gc-unknown-hermit.tar.gz
cd rust-std-1.74.0-riscv64gc-unknown-hermit && ./install.sh
