This directory contains some script and Dockerfile used to start a evm
sequencer rollup.

This document does not explain how smart rollup, smart rollup node,
evm node and the sequencer kernel works.

The following directory allows to initialise an octez-node on a
specified network, originate a new evm rollup and start a rollup and
sequencer node.

The script assume the use of only 1 operator key for the rollup node.

First step is to create an `.env` containing all necessary variables:

```
# network to use
# warning: date dependent variables won't be correctly interpreted in compose.yml
NETWORK="ghostnet"

# tag to use for the tezos docker. default to `master`
OCTEZ_TAG=${OCTEZ_TAG:-master}

# directory where all data dir are placed, default to `./data`
HOST_TEZOS_DATA_DIR=${HOST_TEZOS_DATA_DIR:-$HOME/.etherlink-data}

# network used to initialize the octez node configuration
TZNETWORK=${TZNETWORK:-"https://teztnets.com/$NETWORK"}

# snapshot to use to start the octez node
SNAPSHOT_URL=${SNAPSHOT_URL-"https://snapshots.eu.tzinit.org/$NETWORK/rolling"}

# address of faucet to use with @tacoinfra/get-tez
FAUCET=${FAUCET:-"https://faucet.$NETWORK.teztnets.com"}

# endpoint to use to originate the smart rollup.
# it could be possible to use the local node but it
# would require then to first start the octez-node sepratatly from the docker compose.
ENDPOINT=${ENDPOINT:-"https://rpc.$NETWORK.teztnets.com"}

## Bridge options

# bridge contract already deployed
BRIDGE_CONTRACT=${BRIDGE_CONTRACT:-""}
# alias to use for the originator of bridge contracts
BRIDGE_ORIGINATOR_ALIAS=${BRIDGE_ALIAS:-"bridge_originator"}
# alias to use for the exchanger
EXCHANGER_ALIAS=${EXCHANGER_ALIAS:-"exchanger"}
# alias to use for the bridge
BRIDGE_ALIAS=${BRIDGE_ALIAS:-"bridge"}

## Rollup options

# alias to use for for rollup node operator default acount.
OPERATOR_ALIAS=${OPERATOR_ALIAS:-"operator"}
MINIMUM_OPERATOR_BALANCE=${MINIMUM_OPERATOR_BALANCE:-1000}
# alias to use for the address that originate the rollup. Different from
# the operator to prevent some failure with 1M when reseting the rollup node.
ORIGINATOR_ALIAS=${ORIGINATOR_ALIAS:-"originator"}
# alias to use for rollup.
ROLLUP_ALIAS=${ROLLUP_ALIAS:-"evm_rollup"}
# the used mode for the rollup node
ROLLUP_NODE_MODE=${ROLLUP_NODE_MODE:-"batcher"}
# the chain_id
EVM_CHAIN_ID=${EVM_CHAIN_ID:-123123}
# ethereum account
EVM_ACCOUNTS=()
# sequencer address alias
SEQUENCER_ALIAS=${SEQUENCER_ALIAS:-"sequencer"}
# sequencer secret key
SEQUENCER_SECRET_KEY=${SEQUENCER_SECRET_KEY:-"edsk3gUfUPyBSfrS9CCgmCiQsTCHGkviBDusMxDJstFtojtc1zcpsh"}
```

Then when the variables are defined, or default value is valid you can initialise the octez node with:
```
./init.sh init_octez_node
```
This initialise the octez-node configuration, download the snapshot
and import it.

If you need a bridge to deposit XTZ to etherlink, you can run the command:
```
./init.sh init_bridge
```
This originates the bridge contracts and will set up the the ticketer in the rollup config.

Last step before running the docker compose is to bootstrap the rollup environment:
```
./init.sh init_rollup
```
This generate a new account, wait until the address has enough tz.
Then it build the evm kernel and originate a new rollup with it.
And finally initialise the rollup node configuration.


then start all node:
```
docker compose up
```
