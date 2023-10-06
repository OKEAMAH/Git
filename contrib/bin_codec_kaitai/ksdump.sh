#!/bin/sh

set -eu

if [ -n "${TRACE:-}" ]; then set -x; fi

usage() {
	echo "Usage: $0 <encoding> <data>"
	echo
	echo "Encodes the JSON <data> using the provided encoding identifier, "
	echo "dumps the Kaitai struct of that same encoding, and finally uses "
	echo "ksdump to decode the <data> as per the Kaitai struct."
	echo ""
	echo "Example:"
	echo ""
	echo "    $0 ground.Z '\"-12345\"'"

	exit 1
}

if [ "${1:-}" = "--help" ] || [ $# != 2 ]; then
	usage
fi

encoding=$1
sample=$2

tmp=$(mktemp -d)
hex_file=$(mktemp --tmpdir="${tmp}" --suffix ".${encoding}.hex")
bin_file=$(mktemp --tmpdir="${tmp}" --suffix ".${encoding}.bin")
ksy_file=$(mktemp --tmpdir="${tmp}" --suffix ".${encoding}.ksy")

cleanup() {
	rm -f "$bin_file" "$hex_file" "$ksy_file"
	rm -rf "${tmp}"
}
trap cleanup EXIT INT

dune exec contrib/bin_codec_kaitai/codec.exe -- encode "$encoding" from "$sample" > "$hex_file"
xxd -r -p < "$hex_file" > "$bin_file"

echo "Sample ${sample} in binary: "
xxd -p -b < "${bin_file}"
echo

dune exec contrib/bin_codec_kaitai/codec.exe -- dump kaitai for "$encoding" > "$ksy_file"
echo "Encoding '${encoding}' in Kaitai: "
cat "$ksy_file"
echo

echo "Sample ${sample}'s Kaitai interpretation:"
ksdump "$bin_file" "$ksy_file"
