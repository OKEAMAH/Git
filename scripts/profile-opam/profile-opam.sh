#!/bin/sh

OPAM_WRAP_LOG=${OPAM_WRAP_LOG:-/tmp/opam-wrap.log}

date_iso_notz() {
    date --iso-8601=seconds | cut -d '+' -f 1
}

typ="$1"
shift
start_ts=$(date +%s)
start_date=$(date --iso-8601=seconds -d@"$start_ts")
"$@"
duration=$(( $(date +%s) - start_ts ))
echo "${CI_PIPELINE_ID},${CI_JOB_ID},${CI_JOB_NAME},$typ,$*,$start_date,$duration" >> "$OPAM_WRAP_LOG"
