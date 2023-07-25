#!/bin/sh

set -eu

if [ -n "${TRACE:-}" ]; then set -x; fi

usage() {
    echo "Usage: $0 <tezt_cgmemtime_all.csv>"
    echo
    echo "Import the cgmemtime results from tezt_cgmemtime_all.csv into the sqlite3 database "
    echo "tezt_cgmemtime_all.db."
    echo "Requires csvkit."
    exit 1
}

if [ "${1:-}" = "--help" ]; then
    usage
fi

with_headers=$(mktemp)
{ echo "index;title;user;sys;wall;child_rss_high;group_mem_high" ; cat "$1" ; } > "$with_headers"
csvsql --tables tezt_cgmemtime -d';' "$with_headers" --insert --db sqlite:///tezt_cgmemtime_all.db
rm -f "$with_headers"
