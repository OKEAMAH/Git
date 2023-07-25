#!/bin/sh

set -eu

if [ -n "${TRACE:-}" ]; then set -x; fi

usage() {
    echo "Usage: $0 [PIPELINE_VARIABLES+]"
    echo
    echo "Launches N (defaults to 1) pipelines of 'before_merging' type."
    echo "Requires setting PRIVATE_TOKEN"
    exit 1
}

if [ $# = 0 ] || [ "${1:-}" = "--help" ]; then
    usage
fi

if [ -z "${PRIVATE_TOKEN:-}" ]; then
    echo "GitLab token has not been supplied through PRIVATE_TOKEN. See $0 --help."
    exit 1
fi

silent() {
    log=$(mktemp)
    if ! "$@" > "$log" ; then
        cat "$log"
        rm "$log"
        exit 1
    fi
    rm "$log"
}

N=${N:-1}

pipeline_set_csv="pipeline-set-$(date --iso-8601=seconds).csv"
echo "Writing pipeline set to $pipeline_set_csv"

echo "Run ${N} pipeline(s)"
for _ in $(seq "${N}"); do
    pipeline=$(mktemp)
    if ! PROJECT=tezos/tezos \
         ~/dev/nomadic-labs/tezos/scripts/run_pipeline.sh --csv \
         CI_PROJECT_NAMESPACE="tezos" \
         CI_PIPELINE_SOURCE="merge_request_event" \
         CI_PIPELINE__TYPE="before_merging" "$@" > "$pipeline"; then
        cat "$pipeline"
        exit 1
    else
        tee -a "$pipeline_set_csv" < "$pipeline"
    fi
    rm "$pipeline"
done
