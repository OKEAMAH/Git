#!/bin/sh


usage() {
    echo "Usage: $0 INPUT_DIR"
    echo "       $(basename "$0") is a script that generates hex input samples inside \"INPUT_DIR\"."
    echo "       The intendent usage of this script is to populate input samples for e2e validation (\"kaitai_e2e.sh\")."
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

store_inputs () {
    index=0
    mkdir -p "$2"
     for json_arg in $1; do
        echo "$json_arg" > "$2/$index.hex"
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
# Generating valid input samples inside `INPUT_DIR/valid/ground__uint8/`
store_valid_inputs \
    "ground__uint8" \
    "$(
        ./octez-codec encode ground.uint8 from 0;
        ./octez-codec encode ground.uint8 from 1;
        ./octez-codec encode ground.uint8 from 11;
        ./octez-codec encode ground.uint8 from 255
    )"

# Generating invalid input samples inside `INPUT_DIR/invalid/ground__uint8/`
store_invalid_inputs \
    "ground__uint8" \
    "$(
        # test uint8 should be in 0-255 range.
        # ./octez-codec encode ground.uint16 from 256;
    )"

# GENERATING INPUT SAMPLES FOR 'ground.uint16':
# Generating valid input samples inside `INPUT_DIR/valid/ground__uint16/`
store_valid_inputs \
    "ground__uint16" \
    "$(
        ./octez-codec encode ground.uint16 from 0;
        ./octez-codec encode ground.uint16 from 1;
        ./octez-codec encode ground.uint16 from 256;
        ./octez-codec encode ground.uint16 from 65535
    )"

# Generating invalid input samples inside `INPUT_DIR/invalid/ground__uint16/`
store_invalid_inputs \
    "ground__uint16" \
    "$(
        # test uint16 should be in 0-65535 range.
        # ./octez-codec encode ground.uint16 from 65536;
    )"
