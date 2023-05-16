#!/bin/sh

set -eu

COVERAGE_MERGED=$(echo "$CI_JOB_NAME" | tr --squeeze-repeats '[\/_ @[]+' '-')

echo "Entering $0"

# If the ci--no-coverage label is set, we do not attempt to merge the coverage files
if echo "${CI_MERGE_REQUEST_LABELS:-}" | grep -q '\(^\|,\)ci--no-coverage\($\|,\)' ; then
    echo "Coverage is disabled."
    rm "$BISECT_FILE"*.coverage || true
else
    date
    echo "Trying to merge coverage files to ${BISECT_FILE}/${COVERAGE_MERGED}"
    echo Will run: bisect-ppx-report merge --coverage-path "$BISECT_FILE" "$COVERAGE_MERGED".coverage
    if bisect-ppx-report merge --coverage-path "$BISECT_FILE" "$COVERAGE_MERGED".coverage; then
        # Merge was successful, meaning that no corrupted files were found
        COVERAGE_MERGED="$COVERAGE_MERGED".coverage
        rm "$BISECT_FILE"*.coverage || true
        mv "$COVERAGE_MERGED" "$BISECT_FILE"
        echo "Merging coverage files to ${BISECT_FILE}/${COVERAGE_MERGED} SUCCEEDED"
    else
        # Merge was not successful, meaning that coverage was corrupted
        echo "Merging coverage files to ${BISECT_FILE}/${COVERAGE_MERGED} FAILED"
        rm "$BISECT_FILE"*.coverage || true
        echo "Corrupted coverage files were found, please report this in https://gitlab.com/tezos/tezos/-/issues/1529";
        if [ "${SLACK_COVERAGE_TOKEN:-}" != "" ]; then
            scripts/send_slack_alert_coverage.sh "$SLACK_COVERAGE_TOKEN" "$SLACK_COVERAGE_CHANNEL";
        fi
        exit 1
    fi
    date
fi
