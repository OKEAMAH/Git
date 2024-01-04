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

store_valid_empty_input () {
    escaped_encoding_id="$1"
    input_dir="$INPUT_DIR/valid/$escaped_encoding_id"
    mkdir -p "$input_dir"
    touch "$input_dir/empty.hex"
}

store_invalid_empty_input () {
    escaped_encoding_id="$1"
    input_dir="$INPUT_DIR/invalid/$escaped_encoding_id"
    mkdir -p "$input_dir"
    touch "$input_dir/empty.hex"
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


# GENERATING INPUT SAMPLES FOR 'ground.float':

valid_inputs="$(
    octez-codec encode ground.float from 1;
    octez-codec encode ground.float from 130984703219.09842;
    )"

# TODO: https://gitlab.com/tezos/tezos/-/issues/6730
#       `.ksy` files for ground encodings should throw an error when too many
#        bytes are provided for the input.
invalid_inputs="$(
    # Running 'octez-codec decode ground.float from 000000080000000000000000'
    # should fail. Float should decode at max 8 bytes.
    # octez-codec encode ground.bytes from \"0000000000000000\"
    )"

# Generating valid input samples inside `INPUT_DIR/valid/ground__float/`.
store_valid_inputs "ground__float" "$valid_inputs"

# Generating invalid input samples inside `INPUT_DIR/invalid/ground_float/`.
store_invalid_inputs "ground__float" "$invalid_inputs"


# GENERATING INPUT SAMPLES FOR 'ground.empty':

# Generating valid empty input sample: `INPUT_DIR/valid/ground_empty/empty.hex`.
store_valid_empty_input "ground__empty"

# TODO: https://gitlab.com/tezos/tezos/-/issues/6730
#       `.ksy` files for ground encodings should throw an error when too many
#        bytes are provided for the input.
invalid_inputs="$(
    # Running 'octez-codec decode ground.empty from 000000080000000000000000'
    # should fail. Empty expects 0 bytes.
    # octez-codec encode ground.bytes from \"0000000000000000\"
    )"

# Generating invalid input samples inside `INPUT_DIR/invalid/ground_empty/`.
store_invalid_inputs "ground__empty" "$invalid_inputs"


# GENERATING INPUT SAMPLES FOR 'ground.null':

# Generating valid null input sample: `INPUT_DIR/valid/ground_null/empty.hex`.
store_valid_empty_input "ground__null"

# TODO: https://gitlab.com/tezos/tezos/-/issues/6730
#       `.ksy` files for ground encodings should throw an error when too many
#        bytes are provided for the input.
invalid_inputs="$(
    # Running 'octez-codec decode ground.null from 000000080000000000000000'
    # should fail. Null expects 0 bytes.
    # octez-codec encode ground.bytes from \"0000000000000000\"
    )"

# Generating invalid input samples inside `INPUT_DIR/invalid/ground_null/`.
store_invalid_inputs "ground__null" "$invalid_inputs"


# GENERATING INPUT SAMPLES FOR 'ground.unit':

# Generating valid unit input sample: `INPUT_DIR/valid/ground_unit/empty.hex`.
store_valid_empty_input "ground__unit"

# TODO: https://gitlab.com/tezos/tezos/-/issues/6730
#       `.ksy` files for ground encodings should throw an error when too many
#        bytes are provided for the input.
invalid_inputs="$(
    # Running 'octez-codec decode ground.unit from 000000080000000000000000'
    # should fail. Unit expects 0 bytes.
    # octez-codec encode ground.bytes from \"0000000000000000\"
    )"

# Generating invalid input samples inside `INPUT_DIR/invalid/ground_unit/`.
store_invalid_inputs "ground__unit" "$invalid_inputs"



# GENERATING INPUT SAMPLES FOR 'ground.bytes':

valid_inputs="$(
    octez-codec encode ground.bytes from \"f1010101\"
    octez-codec encode ground.bytes from \"f101010190283147283149732098147098321742319847132098473219847123084723104987321098471324\"
    )"

# Generating valid input samples inside `INPUT_DIR/valid/ground__bytes/`.
store_valid_inputs "ground__bytes" "$valid_inputs"

# Generating invalid empty bytes input sample: `INPUT_DIR/invalid/ground_bytes/empty.hex`.
store_invalid_empty_input "ground__bytes" "$valid_inputs"


# GENERATING INPUT SAMPLES FOR 'ground.string':

valid_inputs="$(
    octez-codec encode ground.string from \"f1010101\"
    octez-codec encode ground.string from \"f101010190283147283149732098147098321742319847132098473219847123084723104987321098471324\"
    octez-codec encode ground.string from "\"This is a test\""
    )"

# Generating valid input samples inside `INPUT_DIR/valid/ground__string/`.
store_valid_inputs "ground__string" "$valid_inputs"

# Generating invalid empty string input sample: `INPUT_DIR/invalid/ground_string/empty.hex`.
store_invalid_empty_input "ground__string" "$valid_inputs"


# GENERATING INPUT SAMPLES FOR 'ground.N':

valid_inputs="$(
    octez-codec encode ground.N from \"0\"
    octez-codec encode ground.N from \"1\"
    octez-codec encode ground.N from "\"8321740983217598321750983217509832175098321750983217509832175098321750329875098321750239873210\""
    )"

invalid_inputs="$(
    # Running 'octez-codec decode ground.N from 000000080000000000000000'
    # should fail.
    # TODO: ground.N parses invalid input.
    # octez-codec encode ground.bytes from \"0000000000000000\"
    )"

# Generating valid input samples inside `INPUT_DIR/valid/ground__n/`.
store_valid_inputs "ground__n" "$valid_inputs"

# Generating invalid input sample: `INPUT_DIR/invalid/ground__n/`.
store_invalid_inputs "ground__n" "$invalid_inputs"


# GENERATING INPUT SAMPLES FOR 'ground.Z':

valid_inputs="$(
    octez-codec encode ground.Z from \"0\"
    octez-codec encode ground.Z from \"1\"
    octez-codec encode ground.Z from \"-1\"
    octez-codec encode ground.Z from "\"8321740983217598321750983217509832175098321750983217509832175098321750329875098321750239873210\""
    octez-codec encode ground.Z from "\"-927459832175983217598321750983217509832175321\""

    )"

invalid_inputs="$(
    # Running 'octez-codec decode ground.Z from 000000080000000000000000'
    # should fail.
    # TODO: ground.Z parses invalid input.
    # octez-codec encode ground.bytes from \"0000000000000000\"
    )"

# Generating valid input samples inside `INPUT_DIR/valid/ground__z/`.
store_valid_inputs "ground__z" "$valid_inputs"

# Generating invalid input samples: `INPUT_DIR/invalid/ground__z/`.
store_invalid_inputs "ground__z" "$invalid_inputs"


# GENERATING INPUT SAMPLES FOR 'ground.bool':

valid_inputs="$(
    # "00" is false
    octez-codec encode ground.uint8 from 0
    # "ff" is true
    octez-codec encode ground.uint8 from 255
    )"

invalid_inputs="$(
    # Anything else then "00" and "ff" should fail
    # TODO: ground.bool parses invalid input.
    # octez-codec encode ground.uint8 from 10
    # octez-codec encode ground.int16 from -23421
    # octez-codec encode ground.bytes from \"0000000000000000\"
    )"

# Generating valid input samples inside `INPUT_DIR/valid/ground__bool/`.
store_valid_inputs "ground__bool" "$valid_inputs"

# Generating invalid input samples: `INPUT_DIR/invalid/ground__bool/`.
store_invalid_inputs "ground__bool" "$invalid_inputs"
