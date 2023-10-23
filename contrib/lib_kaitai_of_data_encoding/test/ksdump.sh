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

# TODO: Do a temp files clean-up

validate_kaitai_spec() {
	encoding=$1
    tmp=$(mktemp -d)
    bin_file=$(mktemp --tmpdir="${tmp}" --suffix ".${encoding}.bin")
    ksy_file="contrib/lib_kaitai_of_data_encoding/test/expected/${encoding}.ksy"
    hex_file="contrib/lib_kaitai_of_data_encoding/test/input/${encoding}.hex"
    
    xxd -r -p < "$hex_file" > "$bin_file"
    
    echo "Expected ${encoding} ksy file:"
    cat "$ksy_file"
    echo "Expected ${encoding} hex input: "
    cat "$hex_file"
    echo
    echo "Expected ${encoding} input in binary: "
    xxd -b: < "${bin_file}"
    echo
    echo "Running \"ksdump \$bin_file \$ksy_file\":"
	# TODO: `ksdump` is not strict enough!!!
	#       I.e. it does not throw errors in case of too little/many bytes 
	#       as an input.
    ksdump "$bin_file" "$ksy_file"
}


# TODO: Make a loop: for every file inside `test/expected` do...
encoding=ground_uint8
validation_output=$(validate_kaitai_spec $encoding 2>&1 )
validation_status=$?
if [ $validation_status -eq 0 ];
then
    echo "$encoding kaitai spec file is valid."
else 
    echo "$encoding kaitai spec files is not valid."
	echo "See the action log:"
	echo "$validation_output"
fi


