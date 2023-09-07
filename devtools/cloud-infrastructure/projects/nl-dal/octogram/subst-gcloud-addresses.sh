#!/bin/bash

function usage(){
         echo "Usage 1: $0 -i <input-file> -o <output-file> -f <json-file-with-list-of-ip-addresses>"
         echo "Usage 2: $0 -i <input-file> -o <output-file> -s <json-string-with-list-of-ip-addresses>"
         echo "The addresses are typically the list returned by `terraform output -json` after `terraform apply`"
}

addresses=""
input=""
output=""

# Checking args

if ! [ "$#" -eq "6" ] || [ "$1" != "-i" ] || [ "$3" != "-o" ] ; then
    echo "Wrong number of arguments or Bad arguments!"
    usage
    exit 1
elif [ "$5" = "-f" ]; then
    addresses=`cat $6 | jq -c '.[]'`
elif [ "$5" = "-s" ] ; then
    addresses=`echo $6 | jq -c '.[]'`
else
    echo "Bad arguments!"
    usage
    exit 1
fi

input=$2
output=$4

# Main part

cp $input $output

count=1

for f in $addresses; do
    sed -i -e "s/%%ADDR_$count%%/$f/g" $output
    count=$(($count+1))
done


echo "Subst done!"

remaining=`grep -c "%%ADDR_" $output`
if ! [ "$remaining" = "0"  ]; then
    echo "Warning: ${remaining} remaining occurrences of %%ADDR_X%% in $output"
fi
