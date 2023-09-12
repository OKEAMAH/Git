#!/bin/bash

function usage(){
    echo "Usage 1: $0 -p <name-prefix> -n <number-of-agents> -f <addr-from>"
}

# Checking args

if ! [ "$#" -eq "6" ] || [ "$1" != "-p" ] || [ "$3" != "-n" ]  || [ "$5" != "-f" ] ;
then
    echo "Wrong number of arguments or bad arguments!"
    usage
    exit 1
fi

prefix=$2
number_of_agents=$4
address_from=$6

# Main part

for i in `seq 0 $((number_of_agents - 1))`; do
    echo "  - name: \"$prefix$i\""
    echo "    address: %%ADDR_${address_from}%%"
    echo "    user: root"
    echo "    port: 30000"
    echo -e "    identity: ~/.ssh/tf\n"
    address_from=$(($address_from + 1))
done
