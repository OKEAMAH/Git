#!/bin/sh

set -eu

script_dir="$(cd "$(dirname "$0")" && echo "$(pwd -P)/")"
tezt_dir="$(dirname "$script_dir")"
root_dir="$(dirname "$tezt_dir")"

if [ -n "${TRACE:-}" ]; then set -x; fi

codeowners=${tezt_dir}/TESTOWNERS.json
products() {
    jq -r 'keys|join(", ")' < "$codeowners"
}

usage() {
    cat <<EOF
Usage: $0 PRODUCT [PRODUCT ...]

Prints the list of Tezt tests associated with PRODUCT(s) as defined in
'${codeowners#"$root_dir"/}'. Tests are printed in the TSV format used by Tezt's
'--list-tsv', with an additional initial column containing the product
name.
EOF
    products=$(products)
    if [ -n "$products" ]; then
        echo
        echo "The defined set of products are: $products."
    fi

    exit 1
}

if [ "${1:-}" = "--help" ] || [ "$#" -lt 1 ] ; then
    usage
fi

codeowners=${tezt_dir}/TESTOWNERS.json
if ! [ -f "$codeowners" ]; then
    echo "No TESTOWNERS.json"
    exit 1
fi

tezt() {
    if ! [ -f "${root_dir}"_build/default/tezt/tests/main.exe ]; then
        dune exec "${root_dir}"tezt/tests/main.exe -- "$@"
    else
        "${root_dir}"_build/default/tezt/tests/main.exe "$@"
    fi
}

while [ "$#" -gt 0 ]; do
    product="$1"
    shift

    if ! jq -e --arg product "$product" 'has($product)' < "$codeowners" > /dev/null ; then
        echo "No product '$product' defined. Defined products: $(products)"
        exit 1
    fi

    # For each tag
    jq -r --arg product "$product" '.[$product].tags[]' < "$codeowners" | while read -r tag; do
        tezt --list-tsv "${tag}" | sed "s/^/${product}\t/"
    done

    # For each file
    jq -r --arg product "$product" '.[$product].path_prefixes[]' < "$codeowners" | while read -r file; do
        tezt --list-tsv --match "^${file}" | sed "s/^/${product}\t/"
    done
done
