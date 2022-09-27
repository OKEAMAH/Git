#!/bin/sh

set -x

# This script launches a sandbox node, activates Protocol, starts rollup node
# and gets the RPC descriptions as JSON, and converts this JSON into an OpenAPI
# specification.

# Ensure we are running from the root directory of the Tezos repository.
cd "$(dirname "$0")"/../../../.. || exit

# Tezos binaries.
tezos_node=./tezos-node
tezos_client=./tezos-client
tezos_scoru_node=./tezos-sc-rollup-node-alpha

# Protocol configuration.
protocol_hash=ProtoALphaALphaALphaALphaALphaALphaALphaALphaDdp3zK
protocol_parameters=src/proto_alpha/parameters/sandbox-parameters.json

# Secret key to activate the protocol.
activator_secret_key="unencrypted:edsk31vznjHSSpGExDMHYASz45VZqXN4DPxvsa4hAyY8dHM28cZzp6"
bootstrap1_secret_key="unencrypted:edsk3gUfUPyBSfrS9CCgmCiQsTCHGkviBDusMxDJstFtojtc1zcpsh"

# RPC port of rollup node.
sc_rpc_port=9999

# Temporary files.
tmp=openapi-tmp
data_dir=$tmp/tezos-sandbox
client_dir=$tmp/tezos-client
sc_data_dir=$tmp/tezos-client
params=$tmp/params.json

# Generated files.
sc_openapi_json=docs/api/sc-rollup-node-rpc-openapi.json

# Get version = git revision.
version=$(git show -s --pretty=format:%H | head -c 8)

# Start a sandbox node.
$tezos_node config init --data-dir $data_dir \
    --network sandbox \
    --expected-pow 0 \
    --rpc-addr localhost:8732 \
    --no-bootstrap-peer \
    --synchronisation-threshold 0
$tezos_node identity generate --data-dir $data_dir
$tezos_node run --data-dir $data_dir &
node_pid="$!"

# Wait for the node to be ready.
sleep 1

# Activate the protocol.
mkdir $client_dir
$tezos_client --base-dir $client_dir import secret key activator $activator_secret_key
$tezos_client --base-dir $client_dir import secret key bootstrap1 $bootstrap1_secret_key
cat $protocol_parameters | jq '.sc_rollup_enable = true' > $params
$tezos_client --base-dir $client_dir activate protocol $protocol_hash \
    with fitness 1 \
    and key activator \
    and parameters $params \
    --timestamp "$(TZ='AAA+1' date +%FT%TZ)"

# Wait a bit again...
sleep 1

# Originate a sc rollup.
sc_addr=$($tezos_client -w none --base-dir $client_dir originate sc rollup from bootstrap1 of kind arith of type unit booting with '""' --burn-cap 10 | awk '/Address: / {print $NF}')
$tezos_client -w none --base-dir $client_dir bake for bootstrap1 --minimal-timestamp

# Start the sc rollup node.
$tezos_scoru_node --base-dir $client_dir init observer config for $sc_addr with operators bootstrap1 --data-dir $sc_data_dir --rpc-port $sc_rpc_port
$tezos_scoru_node --base-dir $client_dir run --data-dir $sc_data_dir &
sc_node_pid="$!"

# Wait for the sc rollup node to be ready.
sleep 1

# Get the RPC openapi.
curl -v "http://localhost:$sc_rpc_port/openapi" > $sc_openapi_json

# Kill the nodes.
kill -9 "$node_pid"
kill -9 "$sc_node_pid"

echo "Generated OpenAPI specification: $sc_openapi_json"
echo "You can now clean up with: rm -rf $tmp"
