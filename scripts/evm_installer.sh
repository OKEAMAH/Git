#!/usr/bin/env bash

set -e

# This file is used to generate the EVM kernel to deploy.
# It will be used to properly call the smart-rollup-installer with a
# configuration adapted to the EVM kernel, e.g. set the dictator key.

declare -a instructions

create_installer_config() {
    n=${#instructions[@]}
    config_file=$1

    echo "instructions:" > "$config_file"
    for ((i=0; i<n; i+=2)) do
        echo "  - set:
      value: ${instructions[$i]}
      to: ${instructions[$i+1]}" >> "$config_file"
    done

    echo "Configuration wrote to $config_file:"
    cat "$config_file"
}

config_to_instructions() {
    # Ticketer
    ticketer=$(jq -r ".ticketer" < "$1" | xxd -ps -c 40)
    instructions+=("$ticketer" "/evm/ticketer")
}

print_usage() {
    echo "Usage: ${0}"
    echo "Options:"
    echo "  --evm-kernel <kernel.wasm>"
    echo "  --preimages-dir <dir>           [OPTIONAL]"
    echo "  --output <file>                 [OPTIONAL]"
    echo "  --config <config.json>          [OPTIONAL]"
}

option_error () {
    echo "Incorrect option ${1}"
    print_usage
    exit 1
}

if [ $# -eq 0 ];
then
    print_usage
    exit 1
fi

while [ $# -gt 0 ]; do
  curr="$1"

  case $curr in
      --evm-kernel)
          evm_kernel="$2"
          shift 2
          ;;
      --preimages-dir)
          preimages_dir="$2"
          shift 2;
          ;;
      --output)
          output="$2"
          shift 2;
          ;;
      --config)
          config_json="$2"
          shift 2;
          ;;
      *)    # unknown option
          option_error "$1"
          ;;
  esac
done

preimages_dir=${preimages_dir:-/tmp}
mkdir -p "$preimages_dir"
output=${output:-evm_installer.wasm}

config=
if [ -n "$config_json" ]; then
    config_to_instructions "$config_json"
    config_file=$(mktemp --suffix .yaml)
    config="--setup-file ${config_file}"
    create_installer_config "$config_file"
fi

# Calls the installer
#shellcheck disable=SC2086
./smart-rollup-installer get-reveal-installer \
                         --upgrade-to "$evm_kernel" \
                         --output "$output" \
                         --preimages-dir "$preimages_dir" \
                         ${config}

echo "Installer ready at ${output} with preimages in ${preimages_dir}."
