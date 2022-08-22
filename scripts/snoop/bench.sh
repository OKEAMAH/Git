#!/bin/sh
set -x
mkdir data
jq -r '.[]|[.name, .nsamples, .bench_num, .seed, .ncores] | @tsv' config.json |
  while IFS=$(printf "\t") read -r name nsamples bench_num seed ncores; do
    filename="$name"_.workload
    ./tezos-snoop benchmark "$name" and save to "$filename" --bench-num "$bench_num" --nsamples "$nsamples" --seed "$seed"
  done
