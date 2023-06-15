#!/bin/sh

set -e

create_installer_config() { 
    echo "instructions:" >> $config_file
    echo "  - set:" >> $config_file
    echo "      value: ${l1_bridge}" >> $config_file
    echo "      to: /evm/l1_bridge_address" >> $config_file

    echo "Configuration wrote to ${config_file}:"
    cat $config_file
}

usage="${0} <KERNEL> <KT1> <PREIMAGES_DIR> <OUTPUT>"
example="${0} evm_kernel.wasm KT1KqcpWDCy8A3MSAPcxDFkg3LSSgFokTb12 /tmp evm_installer.hex"

if [ "$#" -ne 4 ]; then
    echo "The script lacks some arguments, usage":
    echo $usage
    echo "example:"
    echo $example
    exit 1
fi

config_file=$(mktemp --suffix .yaml)

evm_kernel="$1"
l1_bridge=$(echo "$2"| xxd -ps -c 40)
preimages_dir="$3"
evm_installer="$4"

create_installer_config

./smart-rollup-installer get-reveal-installer \
                         --upgrade-to $evm_kernel \
                         --output $evm_installer \
                         --preimages-dir $preimages_dir \
                         --setup-file $config_file
