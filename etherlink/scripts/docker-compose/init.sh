#!/usr/bin/env bash

set -e

script_dir="$(dirname "$0")"

#shellcheck source=etherlink/scripts/docker-compose/.env
. "${script_dir}/.env"

run_in_docker() {
  bin="$1"
  shift 1
  docker_run=(docker run --log-driver=json-file -v "${HOST_TEZOS_DATA_DIR}":/home/tezos tezos/tezos-bare:"${OCTEZ_TAG}")
  "${docker_run[@]}" "/usr/local/bin/${bin}" "$@"
}

docker_update_images() {
  # pull latest version
  docker pull tezos/tezos-bare:"${OCTEZ_TAG}"
  docker build -t tezos_with_curl:"${OCTEZ_TAG}" tezos_with_curl/ --build-arg OCTEZ_TAG="${OCTEZ_TAG}"
}

create_chain_id() {
  number="$1"
  # Convert the number to hexadecimal and little endian format
  hex_le=$(printf "%064x" "$number" | tac -rs ..)

  # Pad to 256 bits (64 hex characters)
  padded_hex_le=$(printf "%064s" "$hex_le")
  echo "$padded_hex_le"
}

create_kernel_config() {
  # chain ID config
  evm_chain_id=$(create_chain_id "${EVM_CHAIN_ID}")
  evm_chain_id_config="  - set:\n      # Chain ID: ${EVM_CHAIN_ID}\n      value: ${evm_chain_id}\n      to: /evm/chain_id\n"

  # ticketer config
  if [[ -n $BRIDGE_CONRTACT ]]; then
    bridge_hex="$(printf ${BRIDGE_CONTRACT} | xxd -p -c 36)"
    evm_ticketer_config="  - set:\n      value: ${bridge_hex}\n      to: /evm/ticketer\n"
  else
    bridge_address=$(run_in_docker octez-client --endpoint "${ENDPOINT}" show known contract "${BRIDGE_ALIAS}")
    if [[ $? -eq 0 ]]; then
      bridge_hex="$(printf ${bridge_address} | xxd -p -c 36)"
      evm_ticketer_config="  - set:\n      value: ${bridge_hex}\n      to: /evm/ticketer\n"
    else
      evm_ticketer=""
    fi
  fi

  # evm accounts config
  evm_accounts_config=""
  for account in ${EVM_ACCOUNTS[@]}; do
    evm_accounts_config="${evm_accounts_config}  - set:\n      value: 0000dc0a0713000c1e0200000000000000000000000000000000000000000000\n      to: /evm/eth_accounts/${account}/balance\n"
  done

  # sequencer_config
  if [[ -n $SEQUENCER_SECRET_KEY ]]; then
    run_in_docker octez-client --endpoint "${ENDPOINT}" import secret key "${SEQUENCER_ALIAS}" unencrypted:"${SEQUENCER_SECRET_KEY}"
    pubkey=$(run_in_docker octez-client --endpoint "${ENDPOINT}" show address "${SEQUENCER_ALIAS}" | grep Public | grep -oE "edpk.*")
    pubkey_hex="$(printf ${pubkey} | xxd -p -c 54)"
    evm_sequencer_config="\n  - set:\n      value: ${pubkey_hex}\n      to: /evm/sequencer\n"
  else
    evm_sequencer_config=""
  fi
  echo "instructions:\n${evm_sequencer_config}${evm_chain_id_config}${evm_ticketer_config}${evm_accounts_config}"
}

build_kernel() {
  evm_config=$(create_kernel_config)
  printf "EVM config:\n$evm_config"
  # build kernel in an image (e.g. tezos/tezos-bare:master) with new chain id
  docker build -t etherlink_kernel:"${OCTEZ_TAG}" evm_kernel_builder/ --build-arg OCTEZ_TAG="${OCTEZ_TAG}" --build-arg EVM_CONFIG="${evm_config}"
  container_name=$(docker create etherlink_kernel:"${OCTEZ_TAG}")
  docker cp "${container_name}":/kernel/ "${HOST_TEZOS_DATA_DIR}/"
}

generate_key() {
  alias=$1
  echo "Generate a ${alias} key. Nothing happens if key already exists"
  # if next command fails it's because the alias already
  # exists. Don't override it.
  run_in_docker octez-client --endpoint "${ENDPOINT}" gen keys "${alias}" || echo "${alias} already exists"
  echo "You can now top up the balance for ${alias}"
}

balance_account_is_enough() {
  address="$1"
  alias="$2"
  minimum="$3"
  balance=$(run_in_docker octez-client --endpoint "${ENDPOINT}" get balance for "${alias}")
  balance=${balance%" ꜩ"} # remove ꜩ
  balance=${balance%.*}   # remove floating part
  echo "balance of ${alias} is ${balance} ꜩ (truncated)."
  if [[ "${balance}" -ge "${minimum}" ]]; then
    return 0
  else
    echo "Top up the balance for ${address} at least with ${minimum}"
    return 1
  fi
}

originate_evm_rollup() {
  source="$1"
  rollup_alias="$2"
  kernel_path="$3"
  echo "originate a new evm rollup '${rollup_alias}' with '${source}', and kernel '${kernel_path}'"
  kernel="$(xxd -p "${kernel_path}" | tr -d '\n')"
  run_in_docker octez-client --endpoint "${ENDPOINT}" \
    originate smart rollup "${rollup_alias}" \
    from "${source}" \
    of kind wasm_2_0_0 of type "(or (or (pair bytes (ticket (pair nat (option bytes)))) bytes) bytes)" \
    with kernel "${kernel}" \
    --burn-cap 999 --force
}

init_rollup_node_config() {
  mode="$1"
  rollup_alias="$2"
  operators="$3"
  echo "create rollup node config and copy kernel preimage"
  run_in_docker octez-smart-rollup-node init "${mode}" config for "${rollup_alias}" with operators "${operators[@]}" --rpc-addr 0.0.0.0 --rpc-port 8733 --cors-origins '*' --cors-headers '*'
  cp -R "${HOST_TEZOS_DATA_DIR}"/kernel/_evm_installer_preimages/ "${HOST_TEZOS_DATA_DIR}"/.tezos-smart-rollup-node/wasm_2_0_0
}

init_octez_node() {
  docker_update_images
  mkdir -p $HOST_TEZOS_DATA_DIR
  # init octez node storage
  run_in_docker octez-node config init --network "${TZNETWORK}"
  # download snapshot
  if [[ -n ${SNAPSHOT_URL} ]]; then
    wget -O "${HOST_TEZOS_DATA_DIR}/snapshot" "${SNAPSHOT_URL}"
    run_in_docker octez-node snapshot import /home/tezos/snapshot
  fi
}

init_bridge() {
  generate_key "${BRIDGE_ORIGINATOR_ALIAS}"
  loop_until_balance_is_enough "${BRIDGE_ORIGINATOR_ALIAS}" 100
  originate_exchanger
  originate_bridge
}

# this function:
# 1/ updates the docker images/
# 2/ build the kernel based on latest octez master version.
#    kernels and pre-images are copied into "${HOST_TEZOS_DATA_DIR}/kernel"
# 3/ originate a new rollup with the build kernel
# 4/ initialise the octez-smart-rollup-node configuration
init_rollup() {
  docker_update_images
  build_kernel
  KERNEL="${HOST_TEZOS_DATA_DIR}"/kernel/sequencer.wasm
  originate_evm_rollup "${ORIGINATOR_ALIAS}" "${ROLLUP_ALIAS}" "${KERNEL}"
  init_rollup_node_config "${ROLLUP_NODE_MODE}" "${ROLLUP_ALIAS}" "${OPERATOR_ALIAS}"
}

loop_until_balance_is_enough() {
  alias=$1
  minimum_balance=$2
  address=$(run_in_docker octez-client --endpoint "${ENDPOINT}" show address "${alias}" | grep Hash | grep -oE "tz.*")
  until balance_account_is_enough "${address}" "${alias}" "${minimum_balance}"; do
    if [[ -n $FAUCET ]] && command -v npx &> /dev/null ; then
      npx @tacoinfra/get-tez -a $(($minimum_balance + 100)) -f $FAUCET $address
    fi
    sleep 10.
  done
}

originate_exchanger() {
  mkdir -p "${HOST_TEZOS_DATA_DIR}"/contracts
  cp ../../kernel_evm/l1_bridge/exchanger.tz "${HOST_TEZOS_DATA_DIR}"/contracts
  echo "originate exchanger contract"
  run_in_docker octez-client --endpoint "${ENDPOINT}" originate contract "${EXCHANGER_ALIAS}" transferring 0 from "${BRIDGE_ORIGINATOR_ALIAS}" running contracts/exchanger.tz --burn-cap 0.185
}

originate_bridge() {
  exchanger_address=$(run_in_docker octez-client --endpoint "${ENDPOINT}" show known contract "${EXCHANGER_ALIAS}")
  mkdir -p "${HOST_TEZOS_DATA_DIR}"/contracts
  cp ../../kernel_evm/l1_bridge/evm_bridge.tz "${HOST_TEZOS_DATA_DIR}"/contracts
  echo "originate evm bridge contract"
  run_in_docker octez-client --endpoint "${ENDPOINT}" originate contract "${BRIDGE_ALIAS}" transferring 0 from "${BRIDGE_ORIGINATOR_ALIAS}" running contracts/evm_bridge.tz --init "Pair \"${exchanger_address}\" None" --burn-cap 0.206
}

deposit() {
  amount=$1
  src=$2
  l2_address=$3
  rollup_address=$(run_in_docker octez-client --endpoint "${ENDPOINT}" show known smart rollup "${ROLLUP_ALIAS}")
  run_in_docker octez-client --endpoint "${ENDPOINT}" transfer $amount from $src to $BRIDGE_ALIAS --entrypoint deposit --arg "Pair \"${rollup_address}\" $l2_address" --burn-cap 0.03075
}

command=$1
shift 1

case $command in
generate_key)
  generate_key "$@"
  ;;
check_balance)
  loop_until_balance_is_enough "$@"
  ;;
originate_rollup)
  originate_evm_rollup "$@"
  ;;
init_rollup_node_config)
  init_rollup_node_config "$@"
  ;;
init_octez_node)
  init_octez_node
  ;;
init_rollup)
  if [[ -n ${OPERATOR_ALIAS} ]]; then
    generate_key "${OPERATOR_ALIAS}"
    loop_until_balance_is_enough "${OPERATOR_ALIAS}" "${MINIMUM_OPERATOR_BALANCE}"
  fi
  generate_key "${ORIGINATOR_ALIAS}"
  loop_until_balance_is_enough "${ORIGINATOR_ALIAS}" 100
  init_rollup
  echo "You can now start the docker with \"./init.sh run\""
  ;;
reset_rollup)
  docker-compose stop smart-rollup-node sequencer blockscout blockscout-db blockscout-redis-db

  rm -r "${HOST_TEZOS_DATA_DIR}/.tezos-smart-rollup-node" "${HOST_TEZOS_DATA_DIR}/.octez-evm-node" "${HOST_TEZOS_DATA_DIR}/kernel"

  init_rollup

  docker-compose up -d --remove-orphans
  ;;
init_bridge)
  init_bridge
  ;;
deposit)
  deposit "$@"
  ;;
run)
  docker compose up -d
  ;;
restart)
  docker compose restart
  ;;
*)
  cat << EOF
Available commands:
  - generate_key <alias>
  - check_balance <alias> <minimal balance>
  - originate_rollup <source> <rollup_alias>
  - init_rollup_node_config <rollup_mode> <rollup_alias> <operators>
  - init_octez_node:
    download snapshot, and init octez-node config
  - init_bridge:
    originate bridge contracts
  - init_rollup:
    build lastest evm kernel, originate the rollup, create operator, wait until operator balance
     is topped then create rollup node config.
  - reset_rollup:
    remove rollup node data dir, sequencer data dir, blockscout data dir,
    and existing kernel.
    Then build lastest evm kernel, originate a new rollup with it and
    initialise the rollup node config in:
     "${HOST_TEZOS_DATA_DIR}".
  - run
    execute docker compose up
  - restart
    execute docker compose restart
  - deposit <amount> <source: tezos address> <target: evm address>
    deposit xtz to etherlink via the ticketer
EOF
  ;;
esac
