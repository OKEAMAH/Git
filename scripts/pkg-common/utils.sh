#!/bin/sh

# Initialise from active protocol versions
#
proto_file="script-inputs/active_protocol_versions_without_number"

if [ ! -f $proto_file ]; then
        echo "Cannot find active protocol list"
        exit 2
fi
protocols=$(tr '\n' ' ' < $proto_file | sed -e 's/ $//g')


# Expand protocols in configuration and init files
#
expand_PROTOCOL() {
    file="$1"

    protocols_formatted=""
    protocols_list=""
    for i in $protocols; do

	if [ "$protocols_list" = "" ]; then 
		protocols_list="$i";
	else
		protocols_list="$protocols_list $i"
	fi

       	if [ "$i" != "alpha" ]; then
		# Alpha is handled in an experimental package
		protocols_formatted=$protocols_formatted'\'"1${i}"'\'"2\n"
	fi

    done

    sed -e "s/@PROTOCOLS@/$protocols_list/g" \
	    -e "/@PROTOCOL@/ { s/^\(.*\)@PROTOCOL@\(.*\)$/$protocols_formatted/; s/\\n$//; }" \
	    "$file"

}

# Issue Warnings
#

warnings() {
	# BETA WARNING
	echo "WARNING: This build script should be considered beta for now"

	# Generic warning about BLST_PORTABLE=yes
	#
	BLST_PORTABLE=${BLST_PORTABLE:-notused}
	if [ "$BLST_PORTABLE" != "yes" ]; then
       		echo "WARNING: BLST_PORTABLE is not set to yes in your environment"
	        echo "If the binaries were not made with BLST_PORTABLE=yes then they"
	        echo "might not run on some platforms."
	fi
}
