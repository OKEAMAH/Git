#!/bin/sh

set -eu

if [ -z "$(find "$BISECT_FILE" -maxdepth 1 -name '*.corrupt.json' -print -quit)" ]; then
    # Compute coverage
    make coverage-report
    # Rewrite the summary output to remove information points matching the coverage regexp below
    make coverage-report-summary | sed 's@Coverage: [[:digit:]]\+/[[:digit:]]\+ (\(.*%\))@Coverage: \1@'
    make coverage-report-cobertura
    exit 0
else
    # Corrupt coverage files were detected
    echo "Corrupted coverage files were found, please report this in https://gitlab.com/tezos/tezos/-/issues/1529";
    slack_msg=$(
        echo "⚠️ Corrupted coverage file(s) found in pipeline <$CI_PIPELINE_URL|#$CI_PIPELINE_ID> ⚠️"
        echo
        find "$BISECT_FILE" -maxdepth 1 -name '*.corrupt.json' -exec \
             jq -r '"  • Job <" + .job_web_url + "|#" + .job_id + "> (`" + .job_name + "`)"' \{\} \;
    )
    if [ "${SLACK_COVERAGE_TOKEN:-}" != "" ]; then
        # :
        curl --silent \
             -H "Authorization: Bearer $SLACK_COVERAGE_TOKEN" \
             -d "channel=$CHANNEL_ID" \
             -d "text=${slack_msg}" \
             -X POST https://slack.com/api/chat.postMessage -o slack-response.json
        jq --exit-status '.ok' < slack-response.json > /dev/null || {
            echo "Slack notification unsuccessful, response received:";
            cat slack-response.json;
            exit 1;
        }
        echo "Slack notification posted to channel $CHANNEL_ID"
    fi

    exit 64
fi
