#!/bin/sh

file="script-inputs/active_protocol_versions_without_number"

if [ ! -f $file ]; then
        echo "Cannot find active protocol list"
        exit 2
fi
protocols=$(tr '\n' ' ' < $file | sed -e 's/ $//g')

expand_PROTOCOL() {
    file="$1"

    protocols_formatted=""
    for i in $protocols; do
        protocols_formatted="$protocols_formatted\\1${i}\\2\\n"
    done

    sed -e "/@PROTOCOL@/ { s/^\(.*\)@PROTOCOL@\(.*\)$/$protocols_formatted/; s/\\n$//; }" "$file"

    sed -e "s/@PROTOCOLS@/$protocols_formatted/g" "$file"
}
