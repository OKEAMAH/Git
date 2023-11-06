#!/bin/sh

set -u

if [ -n "${TRACE:-}" ]; then set -x; fi

usage() {
    echo "Usage: $0"
    echo
    echo "TODO: explain the command usage."
    echo ""

    exit 1
}

if [ "${1:-}" = "--help" ] || [ $# != 0 ]; then
    usage
fi

# TODO: assert dependencies
#         - node
#         - npm install -g kaitai-struct
#         - export node path, e.g. `export NODE_PATH="/usr/lib/node_modules"`

PARSE_AND_PRINT="contrib/lib_kaitai_of_data_encoding/test/parse_and_print.js"
KSY_DIR="contrib/lib_kaitai_of_data_encoding/test/expected"

parse_hex_input() {
    tmp=$1
    hex_file=$2
    encoding=$3
    parser=$4
    input_filename="$(basename "$hex_file" .hex)"
    # TODO: make sure there is no colision in valid and invalid names (!)
    bin_file=$(mktemp --tmpdir="${tmp}" --suffix ".${encoding}.${input_filename}.bin")
    xxd -r -p <"$hex_file" >"$bin_file"
    echo "Running validation of $encoding using valid '$encoding/$input_filename.hex' input."
    echo "Bin file path: $bin_file"
    echo "Expected ${encoding} hex input: "
    cat "$hex_file"
    echo
    echo "Expected ${encoding} input in binary: "
    xxd -b: <"${bin_file}"
    echo "Running \"ksdump \$bin_file \$ksy_file\":"
    # TODO: Sum-up what this script does.
    node "$PARSE_AND_PRINT" "$parser" "$bin_file"
}

# TODO: Do a temp files clean-up
validate_kaitai_spec() {
    encoding=$1
    tmp=$(mktemp -d)
    hex_input_dir="contrib/lib_kaitai_of_data_encoding/test/input"
    valid_input="${hex_input_dir}/valid/${encoding}"
    invalid_input="${hex_input_dir}/invalid/${encoding}"
    ksy_file="${KSY_DIR}/${encoding}.ksy"
    parser_dir="${tmp}/parsers/${encoding}"
    # ksc gives an auto-generated file a random name.
    # In order to get this filename at runtime, we
    # create a dummy `tmp/*/parser/${encoding}/` dir
    # and get an autogenerated file assuming that this
    # directory contains only one file.
    mkdir -p "$parser_dir"
    ksc "$ksy_file" -t javascript --outdir "$parser_dir"
    # TODO: Is this bash idiomatic && robust?
    parser_file_name="$(ls "$parser_dir" | head -n 1)"
    parser_path="$parser_dir/$parser_file_name"
    echo "Expected ${encoding} ksy file:"
    cat "$ksy_file"
    echo
    echo "Expected ${encoding} autogenerated parser"
    cat "$parser_path"
    echo
    for hex_file in "$valid_input"/*; do
        parse_hex_input "$tmp" "$hex_file" "$encoding" "$parser_path"
        validation_status=$?
        if [ $validation_status != 0 ]; then
            echo "$encoding: Autogenerated parser fails to parse valid binary blob."
            return 1
        fi
    done
    for hex_file in "$invalid_input"/*; do
        parse_hex_input "$tmp" "$hex_file" "$encoding" "$parser_path"
        validation_status=$?
        if [ $validation_status = 0 ]; then
            echo "$encoding: Autogenerated parser parses invalid(!) binary blob."
            return 1
        fi
    done
}

for ksy_file in "$KSY_DIR"/*; do
    encoding="$(basename "$ksy_file" .ksy)"
    validation_output=$(validate_kaitai_spec $encoding 2>&1)
    validation_status=$?
    if [ $validation_status -eq 0 ]; then
        echo "$encoding kaitai spec file is valid."
    else
        echo "$encoding kaitai spec files is not valid."
        echo "See the action log:"
        echo "$validation_output"
    fi
done

# TODO: Better logging/error reporting for better dev ux.
# TODO: Correct redirection of standard error.