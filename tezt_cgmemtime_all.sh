#!/bin/sh

set -eu

if [ -n "${TRACE:-}" ]; then set -x; fi

usage() {
    echo "Usage: $0 <commands passed to tezt>"
    echo
    echo "This script runs a set of Tezt tests and reports on their peak memory usage using cgmemtime. "
    echo "Each test is run in isolation."
    echo "Output is in CSV format, with the columns: "
    echo "USER;REAL;WALL;CHILD_RSS_HIGH;GROUP_MEM_HIGH"
    echo "For more info on CHILD_RSS_HIGH and GROUP_MEM_HIGH, see https://github.com/gsauthof/cgmemtime"
    exit 1
}

if [ "${1:-}" = "--help" ]; then
    usage
fi

tezt() {
    _build/default/tezt/tests/main.exe "$@"
}

tezt "$@" --list-tsv > tezts.tsv
cut -f 2 tezts.tsv | grep -v -i "random seed" > titles.txt
index_max=$(wc -l titles.txt | cut -d' ' -f1)
rm tezt_cgmemtime_all.log
mem=$(mktemp)
for index in $(seq "$index_max"); do
    title=$(sed "${index}!d" < titles.txt)
    # hacky title sanitation
    title=$(echo "$title" | sed 's@"@\\"@g')
    echo -n "${index}/${index_max};\"${title}\";"
    # Remove spurious output
    if { timeout 300 cgmemtime -t _build/default/tezt/tests/main.exe --title "$title" >> tezt_cgmemtime_all.log ; } 2>&1 | tail -n1 > "${mem}"; then
        cat "${mem}"
    else
        # user;real;wall;child_rss_high;group_mem_high
        echo ";;;;"
    fi
done
