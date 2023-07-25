#!/bin/sh

set -eu

if [ -n "${TRACE:-}" ]; then set -x; fi

usage() {
    echo "Usage: $0 [<tezt_cgmemtime_all.db>]"
    echo
    echo "Prints the top N  (defaults to 10) tests in terms of memory consumption (CHILD_RSS_HIGH and GROUP_MEM_HIGH)"
    exit 1
}

if [ "${1:-}" = "--help" ]; then
    usage
fi


db=${1:-tezt_cgmemtime_all.db}
N=${N:-10}


echo "Largest test consumers in terms of CHILD_RSS_HIGH:"
echo
sqlite3 --header --column "$db" "select title, child_rss_high / 1024 as child_rss_high_mb from tezt_cgmemtime order by child_rss_high desc limit ${N}"
echo

echo "Largest test consumers in terms of GROUP_MEM_HIGH:"
echo
sqlite3 --header --column "$db" "select title, group_mem_high / 1024 as group_mem_high_mb from tezt_cgmemtime order by group_mem_high desc limit ${N}"
