#!/bin/sh

set -e

usage() {
    echo "Usage: $0 INPUT_DIR"
    echo "       $(basename "$0") is a script that generates hex input samples inside \"INPUT_DIR\"."
    echo "       The intended usage of this script is to populate input samples for e2e validation (\"kaitai_e2e.sh\")."
    exit 1
}

# Check we receive valid INPUT_DIR else print usage.
if [ "${1:-}" = "--help" ] || [ $# != 1 ]; then
    usage
fi

INPUT_DIR="$1"

if [ ! -d "$INPUT_DIR" ]; then
   echo "\"$INPUT_DIR\" directory does not exist"
   exit 1
fi

# Build bin-codec-kaitai if not already.
dune build contrib/bin_codec_kaitai/codec.exe
# Make an alias to the executable.
alias octez-codec='_build/default/contrib/bin_codec_kaitai/codec.exe'

store_inputs () {
    index=0
    mkdir -p "$2"
    for hex_input in $1; do
        echo "$hex_input" > "$2/$index.hex"
        index=$((index + 1))
    done
}

store_valid_inputs () {
    escaped_encoding_id="$1"
    input_dir="$INPUT_DIR/valid/$escaped_encoding_id"
    store_inputs "$2" "$input_dir"
}

store_invalid_inputs () {
    escaped_encoding_id="$1"
    input_dir="$INPUT_DIR/invalid/$escaped_encoding_id"
    store_inputs "$2" "$input_dir"
}

# GENERATING INPUT SAMPLES FOR 'ground.uint8':

# test uint8 should be in 0-255 range.
valid_inputs="$(
    octez-codec encode ground.uint8 from 0;
    octez-codec encode ground.uint8 from 1;
    octez-codec encode ground.uint8 from 255;
    )"

# TODO: https://gitlab.com/tezos/tezos/-/issues/6730
#       `.ksy` files for ground int encodings should throw an error when too many
#        bytes are provided for the input.
invalid_inputs="$(
    # octez-codec encode ground.uint16 from 256;
    )"

# Generating valid input samples inside `INPUT_DIR/valid/ground__uint8/`.
store_valid_inputs "ground__uint8" "$valid_inputs"

# Generating invalid input samples inside `INPUT_DIR/invalid/ground__uint8/`.
store_invalid_inputs "ground__uint8" "$invalid_inputs"

# GENERATING INPUT SAMPLES FOR 'ground.uint16':

# test uint16 should be in 0-65535 range.
valid_inputs="$(
    octez-codec encode ground.uint16 from 0;
    octez-codec encode ground.uint16 from 1;
    octez-codec encode ground.uint16 from 256;
    octez-codec encode ground.uint16 from 65535
    )"

# TODO: https://gitlab.com/tezos/tezos/-/issues/6730
#       `.ksy` files for ground int encodings should throw an error when too many
#        bytes are provided for the input.
invalid_inputs="$(
    # octez-codec encode ground.uint16 from 65536;
    )"

# Generating valid input samples inside `INPUT_DIR/valid/ground__uint16/`.
store_valid_inputs "ground__uint16" "$valid_inputs"

# Generating invalid input samples inside `INPUT_DIR/invalid/ground__uint16/`.
store_invalid_inputs "ground__uint16" "$invalid_inputs"


# GENERATING INPUT SAMPLES FOR 'ground.int8':

# test int8 should be in -128 to 127 range.
valid_inputs="$(
    octez-codec encode ground.int8 from -128;
    octez-codec encode ground.int8 from -14;
    octez-codec encode ground.int8 from -1;
    octez-codec encode ground.int8 from 0;
    octez-codec encode ground.int8 from 1;
    octez-codec encode ground.int8 from 14;
    octez-codec encode ground.int8 from 127;
    )"

# TODO: https://gitlab.com/tezos/tezos/-/issues/6730
#       `.ksy` files for ground int encodings should throw an error when too many
#        bytes are provided for the input.
invalid_inputs="$(
    # octez-codec encode ground.int16 from 128;
    # octez-codec encode ground.int16 from -129;
    )"

# Generating valid input samples inside `INPUT_DIR/valid/ground__int8/`.
store_valid_inputs "ground__int8" "$valid_inputs"

# Generating invalid input samples inside `INPUT_DIR/invalid/ground_int8/`.
store_invalid_inputs "ground__int8" "$invalid_inputs"

INT16_MIN=-32768
INT16_MAX=32767
INT32_MIN=-2147483648
INT32_MAX=2147483647
INT31_MIN=-1073741824
INT31_MAX=1073741823
INT64_MIN=-9223372036854775808
INT64_MAX=9223372036854775807

# GENERATING INPUT SAMPLES FOR 'ground.int16':

# Test int16 should be in -32768 to 32767 range.
valid_inputs="$(
    octez-codec encode ground.int16 from $INT16_MIN;
    octez-codec encode ground.int16 from -128;
    octez-codec encode ground.int16 from -1;
    octez-codec encode ground.int16 from 0;
    octez-codec encode ground.int16 from 1;
    octez-codec encode ground.int16 from $INT16_MAX;
    )"

# TODO: https://gitlab.com/tezos/tezos/-/issues/6730
#       `.ksy` files for ground int encodings should throw an error when too many
#        bytes are provided for the input.
invalid_inputs="$(
    # octez-codec encode ground.int32 from $((INT16_MAX+1));
    # octez-codec encode ground.int32 from $((INT16_MIN-1))
    )"

# Generating valid input samples inside `INPUT_DIR/valid/ground__int16/`.
store_valid_inputs "ground__int16" "$valid_inputs"

# Generating invalid input samples inside `INPUT_DIR/invalid/ground_int16/`.
store_invalid_inputs "ground__int16" "$invalid_inputs"


# GENERATING INPUT SAMPLES FOR 'ground.int32':

# test int32 should be in INT32_MIN to INT32_MAX range.
valid_inputs="$(
    octez-codec encode ground.int32 from $INT32_MIN;
    octez-codec encode ground.int32 from $INT16_MIN;
    octez-codec encode ground.int32 from -1;
    octez-codec encode ground.int32 from 0;
    octez-codec encode ground.int32 from 1;
    octez-codec encode ground.int32 from $INT16_MAX;
    octez-codec encode ground.int32 from $INT32_MAX;
    )"

# TODO: https://gitlab.com/tezos/tezos/-/issues/6730
#       `.ksy` files for ground int encodings should throw an error when too many
#        bytes are provided for the input.
invalid_inputs="$(
    # octez-codec encode ground.int64 from  \"$((INT32_MAX+1))\";
    # octez-codec encode ground.int64 from \"$((INT32_MIN-1))\";
    )"

# Generating valid input samples inside `INPUT_DIR/valid/ground__int32/`.
store_valid_inputs "ground__int32" "$valid_inputs"

# Generating invalid input samples inside `INPUT_DIR/invalid/ground_int32/`.
store_invalid_inputs "ground__int32" "$invalid_inputs"


# GENERATING INPUT SAMPLES FOR 'ground.int31':

# test int31 should be in INT31_MIN to INT31_MAX range.
valid_inputs="$(
    octez-codec encode ground.int31 from $INT31_MIN;
    octez-codec encode ground.int31 from $INT16_MIN;
    octez-codec encode ground.int31 from -1;
    octez-codec encode ground.int31 from 0;
    octez-codec encode ground.int31 from 1;
    octez-codec encode ground.int31 from $INT16_MAX;
    octez-codec encode ground.int31 from $INT31_MAX;
    )"

# TODO: https://gitlab.com/tezos/tezos/-/issues/6730
#       `.ksy` files for ground int encodings should throw an error when too many
#        bytes are provided for the input.
invalid_inputs="$(
    # Test that guard of int31 works.
    octez-codec encode ground.int32 from $INT32_MAX;
    octez-codec encode ground.int32 from $INT32_MIN;
    # Parsing 64 bit number should fail.
    # octez-codec encode ground.int64 from \"$INT32_MAX\";
    # octez-codec encode ground.int64 from \"$INT32_MIN\";
    )"

# Generating valid input samples inside `INPUT_DIR/valid/ground__int31/`.
store_valid_inputs "ground__int31" "$valid_inputs"

# Generating invalid input samples inside `INPUT_DIR/invalid/ground_int31/`.
store_invalid_inputs "ground__int31" "$invalid_inputs"


# GENERATING INPUT SAMPLES FOR 'ground.int64':

# test int64 should be in INT64_MIN to INT64_MAX range.
valid_inputs="$(
    octez-codec encode ground.int64 from \"$INT64_MIN\";
    octez-codec encode ground.int64 from \"$INT32_MIN\";
    octez-codec encode ground.int64 from \"-1\";
    octez-codec encode ground.int64 from \"0\";
    octez-codec encode ground.int64 from \"1\";
    octez-codec encode ground.int64 from \"$INT16_MAX\";
    octez-codec encode ground.int64 from \"$INT64_MAX\";
    )"

# TODO: https://gitlab.com/tezos/tezos/-/issues/6730
#       `.ksy` files for ground int encodings should throw an error when too many
#        bytes are provided for the input.
invalid_inputs="$(
    # Int64 should not decode 12 bytes:
    # octez-codec encode ground.bytes from "\"0000000000000000\""
    )"

# Generating valid input samples inside `INPUT_DIR/valid/ground__int31/`.
store_valid_inputs "ground__int64" "$valid_inputs"

# Generating invalid input samples inside `INPUT_DIR/invalid/ground_int31/`.
store_invalid_inputs "ground__int64" "$invalid_inputs"
