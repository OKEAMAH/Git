#!/bin/bash

#####
# This script aims at automating tests for mainnet migration
# and Adaptive issuance activation
#
# Prerequisite:
# - Patched branch with
#   + "baken <nb blocks> for" command
#   + adaptive-issuance-vote toggle for bake for command
#   + PoW deactivation (non-essential but speed-up the test a lot)
#   + Profiling patch (non-essential but alows profiling)
# - System with
#   - libfaketime installed
#   - default config use dpkg utility to locate libfaketime.so, update the
#     libfaketime variable if you are on an OS where it doesn't work.
#   - jq installed
#   - octez source and what is needed to build it


###########################
## Default configuration ##
###########################

export network=mainnet
export storage=~/tezos-storage/
export history_mode=rolling
export tarball_name=${network}-${history_mode}-$(date +"%y-%m-%d").tar.gz
export data_dir=/tmp/tezos-node-migration-$network
export yes_wallet=/tmp/yes-wallet-$network
export rolling_tarball_url=https://lambsonacid-octez.s3.us-east-2.amazonaws.com/${network}/${history_mode}/datadir.tar.gz

if [[ $(basename $0) == "mainnet_migration.sh" ]]; then
    ## this works well while calling the script but does'nt work if we want to source it
    export tezos_dir=$(dirname $0)/..
else
    # Wild heurisitic to be refined. Sourced script won't work with $0
    export tezos_dir=${HOME}/tezos
fi

export do_not_download_tarball=false
export patch_code=true
export apply_yes_patch=false

export starting_proto=PtNairo

# hackish debian-like OS only
# get libfaketime location
export libfaketime=$(dpkg --listfiles libfaketime | grep libfaketime.so.1)

export node_log=$data_dir/node.log
export client_log=$data_dir/client.log

export PROFILING=yes

######################################################
## User variable override should happen in this file #
######################################################
source $tezos_dir/scripts/migration_test_vars



###########################
### Utility functions   ###
###########################

function fail(){
    echo "$1" >&2
    echo "Exiting on failure. Additional info might be found in $node_log or $client_log"
    # don't exit when script has been sourced
    if [[ $(basename $0) == "mainnet_migration.sh" ]]; then
        exit 1
    fi
}


function ask(){
    read -p"$1 [y/N] " rep
    if [[ "$rep" =~ ^(y|Y|yes)$ ]]; then
        return 0
    else
        return 1
    fi
}

function config_datadir(){
    echo "Setting node config:"
    $tezos_dir/octez-node config init  --network "${network}" -d "${data_dir}" --rpc-addr localhost --connections=0 --synchronisation-threshold 0
}

function check_data_dir(){
    test -d "$data_dir" \
        || fail "$data_dir is not a directory. Quitting.."
}

function is_data_dir_populated(){
    test -d "$data_dir/store"
    return $?
}
function check_data_dir_populated(){
    is_data_dir_populated \
        || fail "$data_dir has no store directory. Quitting.."
}


## RPC calls
function rpc(){
    endpoint=""
    # endpoint="--endpoint https://rpc.tzbeta.net"
     $tezos_dir/octez-client $endpoint rpc get $1  || fail "failed to query octez-node"
}



function faketime(){

    if test -f "$libfaketime" ; then
        export LD_PRELOAD=$libfaketime
        export FAKETIME="+2000d"
    else
        fail "libfaketime is not available. suggestion:
sudo apt install libfaketime
"
    fi
}


function check_faketime(){
    if [[ "$LD_PRELOAD" =~ $libfaketime ]]; then
        return
    else
        echo -e "WARNING: octez-node has been launch while libfaketime is not loaded.\n\
 The chain will not be able to progress to blocks after the current date."
        return 1
    fi
}

## data dir backup
function may_copy_data_dir(){
    echo "Copying data_dir: cp $data_dir to $storage/${network}-${history_mode}-$1"
    test -d "$data_dir" \
        || fail "$data_dir is not a directory. Quitting.."
    if test -d  "$storage/${network}-${history_mode}-$1"; then
        echo "  Skipping backup: $storage/${network}-${history_mode}-$1 already exists."
    else
        cp -a $data_dir $storage/${network}-${history_mode}-$1
    fi
}


function check_for_data_dir_backup(){
    if test -d "$storage/${network}-${history_mode}-$1"; then
        echo "It seems that you created a backup of a storage at level $1."
        echo "  Your current storage requires $blocks_to_bake to get to this level"
        echo -e "  you could instead do:\n rm -rf $data_dir\ncp -a $storage/${network}-${history_mode}-$1 $data_dir\n"

        ask  "Do you really want to continue, and bake  $blocks_to_bake ?" || fail "restart the script when you replaced the data dir."
    fi
    }

###################
## node wrappers ##
###################

NODE_PID=""
### running a node, with logs redirected into a file in the data-dir
function node_run(){
    check_data_dir_populated
    check_faketime
    node_run="$tezos_dir/octez-node run -d ${data_dir} -v --rpc-addr localhost --connections=0 --synchronisation-threshold 0"
    echo -e "Running node:\n   with command $node_run  >> $node_log 2>&1 &"
    $node_run  >> $node_log 2>&1 &
    NODE_PID=$!
    echo "  octez-node run with PID $NODE_PID"

}

function node_stop(){
    echo "Killing the node: $NODE_PID"
    kill -TERM $NODE_PID
}


###################
## yes wallet    ##
###################

function yes_wallet_dir(){
    share=$1
    wallet=${yes_wallet}${share}
    echo $wallet
}

function build_yes-wallet(){
    share=$1
    echo "Building $share% Yes-wallet"
    ## yes-wallet
    ## stking share set to 99 as the tools seems to have it wrong when computing
    ## the stake share and below 99 is sometimes not enough to bake all blocks.
    wallet=$(yes_wallet_dir $share)
    share=${share:-75}
    FORCE=""
    if test -f $wallet/*_highwatermarks; then
        ask "   yes wallet $wallet contains highwatermarks, clean them ?" || return
        clean_yes-wallet
    fi
    if test -f $wallet/public_keys; then
        ask "   yes wallet $wallet already exists, force overwrite ?" || return
        FORCE="--force"
    fi
    eval $(opam env)
    dune exec devtools/yes_wallet/yes_wallet.exe -- create from context $data_dir in $wallet --active-bakers-only --staking-share $share --network  $network $FORCE
}

function clean_yes-wallet(){
    rm $yes_wallet/*_highwatermarks
}

###################
## baking        ##
###################

function bake(){
    block_count=$1
    wallet=$(yes_wallet_dir $2)
    # bake the number of provided blocks
    echo "  Baking: $1 blocks (no vote)"
    [[  "$block_count" -ge 0 ]] || fail "number of blocks to bake not well specified"
    echo "    $tezos_dir/octez-client -d $wallet baken $1 for --minimal-timestamp --ignore-node-mempool  >> $client_log  2>&1"
    $tezos_dir/octez-client -d $wallet baken $block_count for --minimal-timestamp --ignore-node-mempool >> $client_log  2>&1 || \
        fail "Failed to bake $block_count blocks (no vote)"
}


function bake_wt_ops(){
    block_count=$1
    wallet=$(yes_wallet_dir $2)
    # bake the number of provided blocks
    echo "  Baking: $1 blocks (no vote)"
    [[  "$block_count" -ge 0 ]] || fail "number of blocks to bake not well specified"
    echo "    $tezos_dir/octez-client -d $wallet baken $1 for --minimal-timestamp  >> $client_log  2>&1"
    $tezos_dir/octez-client -d $wallet baken $block_count for --minimal-timestamp >> $client_log  2>&1 || \
        fail "Failed to bake $block_count blocks (no vote)"
}

function bake_vote_on(){
    block_count=${1:-1}
    wallet=$(yes_wallet_dir $2)
    # bake the number of provided blocks
    echo "  Baking: $block_count blocks (adaptive-issuance voting on, wallet $wallet)"
    [[  "$block_count" -gt 0 ]] || fail "number of blocks to bake not specified"
    echo "    $tezos_dir/octez-client -d $wallet baken $1 for --minimal-timestamp --adaptive-issuance-vote on --ignore-node-mempool >> $client_log  2>&1 "
    $tezos_dir/octez-client -d $wallet baken $block_count for --minimal-timestamp --adaptive-issuance-vote on --ignore-node-mempool >> $client_log  2>&1 || \
        fail "Failed to bake $block_count blocks (adaptive-voting on) "
}

function bake_vote_on_wth_ops(){
    block_count=${1:-1}
    wallet=$(yes_wallet_dir $2)
    # bake the number of provided blocks
    echo "  Baking: $block_count blocks (adaptive-issuance voting on, wallet $wallet, including operations)"
    [[  "$block_count" -gt 0 ]] || fail "number of blocks to bake not specified"
    echo "    $tezos_dir/octez-client -d $wallet baken $1 for --minimal-timestamp --adaptive-issuance-vote on >> $client_log  2>&1 "
    $tezos_dir/octez-client -d $wallet baken $block_count for --minimal-timestamp --adaptive-issuance-vote on >> $client_log  2>&1 || \
        fail "Failed to bake $block_count blocks (adaptive-voting on) "
}

function unstake(){
    delegate=$1
    amount=$2
    wallet=$(yes_wallet_dir $3)
    echo "Unstaking $amount for $delegate"
    echo"    $tezos_dir/octez-client -d $wallet  unstake $amount for $delegate >> $client_log  2>&1"
    $tezos_dir/octez-client -d $wallet  unstake $amount for "$delegate" >> $client_log  2>&1 || \
        fail "Failed to unstake  $amount for $delegate"
}


function bake_until_cycle_end(){
    level_info=$(rpc /chains/main/blocks/head/helpers/current_level)
    cycle_position=$(echo "$level_info"| jq .cycle_position)
    cycle=$(echo "$level_info"| jq .cycle)
    blocks_per_cycle=$(rpc /chains/main/blocks/head/context/constants | jq .blocks_per_cycle)
    block_count=$(( blocks_per_cycle - cycle_position ))
    echo "Baking until end of cycle $cycle"
    bake_vote_on $block_count
}

function bake_cycles(){
    cycles_to_bake=$1
    level_info=$(rpc /chains/main/blocks/head/helpers/current_level)
    cycle_position=$(echo "$level_info"| jq .cycle_position)
    cycle=$(echo "$level_info"| jq .cycle)
    blocks_per_cycle=$(rpc /chains/main/blocks/head/context/constants | jq .blocks_per_cycle)
    block_count=$(( blocks_per_cycle - cycle_position + ( blocks_per_cycle * (cycles_to_bake - 1 ) ) ))
    echo "Baking until end of cycle +  $((cycles_to_bake -1)) cycles ($block_count blocks)"
    bake_vote_on $block_count
}

function stake(){
    delegate=$1
    amount=$2
    wallet=$(yes_wallet_dir $3)
    echo "Staking $amount for $delegate"
    $tezos_dir/octez-client -d $wallet  stake $amount for $delegate >> $client_log  2>&1 || \
        fail "Failed to stake  $amount for $delegate"
}


function finalize(){
    delegate=$1
    wallet=$(yes_wallet_dir $2)
    echo "Finalizing unstaked for $delegate"
    $tezos_dir/octez-client -d $wallet  finalize unstake for $delegate >> $client_log  2>&1 || \
        fail "Failed to stake  $amount for $delegate"
}

###########################
###   test preparation  ###
###########################

## Downloading data_dir tarball from a snapshot service
function download_tarball(){
    echo "Downloading tarball:"
    if $do_not_download_tarball; then
        echo "   skipping download: you set do_not_download_tarball to true."
        return ;
    else
        if test ! -e "$storage/$tarball_name" ||
                ask "   $storage/$tarball_name already exists, overwrite ?";
        then
            mkdir -p $storage
            echo "   downloading tarball for network $network into $storage/$tarball_name"
            wget -v "$rolling_tarball_url"  -O "$storage/$tarball_name"
        else
            ask "   Tarball not downloaded as it already exists, shall we continue ?" || \
                fail "Ok, exiting"
        fi
    fi
}

#checking current proto
function check_on_proto_with_AI(){
    protocol=$(rpc /chains/main/blocks/head/header | jq .protocol)
    [[ $protocol =~ "ProtoALpha" ]] || [[ $protocol =~ "Proxford" ]] || fail "/!\ Context is on $protocol,not proto_alpha. exiting."
    echo "Current protocol is $protocol, as expected at this point"
}

## extracting downloaded tarbal into data_dir
function extract_tarball(){
    echo "Extractiing tarball:"
    if  is_data_dir_populated ; then
        if ask "   Data_dir $data_dir already contains a store, shall we continue on it."; then
            return
        else
            fail "Data_dir $data_dir already contains a store, clear it before extracting tarball"
        fi
    fi
    mkdir -p $data_dir
    echo "   Extracting $storage/$tarball_name into $data_dir"
    tar xvf  $storage/$tarball_name -C $data_dir
    store_location=$(find $data_dir -iname store)
    extracted_store_dir=$(dirname $store_location)
    if test -d "$extracted_store_dir/store"; then
        echo "   Moving extracted data dir content into $data_dir"
        mv $extracted_store_dir/* $data_dir
    else
        fail "Invalid data_dir extracted in $extracted_store_dir or $data_dir "
    fi
}


## querying the node for cycles information
function compute_UAU_parameters(){
    echo "$1Computing UAU level"
    protocol=$(rpc /chains/main/blocks/head/header | jq .protocol)
    if [[ !  $protocol =~ $starting_proto ]]; then
        echo "  /!\ Context is on $protocol, not the expected $starting_proto"
        return 1
    fi
    level_info=$(rpc /chains/main/blocks/head/helpers/current_level)

    level=$(echo "$level_info"| jq .level)
    cycle_position=$(echo "$level_info"| jq .cycle_position)
    cycle=$(echo "$level_info"| jq .cycle)
    blocks_per_cycle=$(rpc /chains/main/blocks/head/context/constants | jq .blocks_per_cycle)

    # blocks_to_bake is set 2 blocks before  UAU
    blocks_to_bake=$(( blocks_per_cycle - cycle_position - 2 ))

    # UAU is at next cycle start
    uau=$((level + blocks_per_cycle - cycle_position))
    if [[ $blocks_to_bake -lt 0 &&  $uau -ge $level ]]; then
        blocks_to_bake=0
    fi
    echo "   current level : $level,
blocks per cycle:  $blocks_per_cycle,
current position cycle: $cycle_position,
current cycle: $cycle,
blocks to bake to approache UAU: $blocks_to_bake,
UAU level: $uau"

    [[ $uau -ge 0 ]] || fail "UAU level should be positive, not '$uau'"
    [[ $blocks_to_bake -ge 0 ]] || fail "blocks_to_bake should be positive, not '$blocks_to_bake'"

}

## patching octez for UAU and yes-node
function patch_node(){
    echo "Patching octez:"
    if [ $network == "mainnet" ]; then
        echo "   patching node for UAU at level $uau"
        ## set UAU
        cd "$tezos_dir"
        $tezos_dir/scripts/user_activated_upgrade.sh $tezos_dir/src/proto_alpha $uau
        cd -
    else
        ask "   User Activated upgrade patch only works for mainnet, press y to continue without  patching" || exit 1
    fi
    ## yes-patch
    if $apply_yes_patch; then
        echo "   applying yes-patch"
        $tezos_dir/scripts/patch-yes_node.sh
    fi
    if ask "   Do you want to rebuild octez ?"; then
        ## build
        make
    fi
}

## Adaptive issuance specifics
function compute_AI_activation_block(){
    echo "Computing AI activation block:"
    activation_cycle=$(rpc /chains/main/blocks/head/context/adaptive_issuance_launch_cycle)
    current_cycle=$(rpc /chains/main/blocks/head/helpers/current_level | jq .cycle);
    cycle_position=$(rpc /chains/main/blocks/head/helpers/current_level | jq .cycle_position);
    cycle_to_bake=$((activation_cycle - current_cycle))
    blocks_per_cycle=$(rpc /chains/main/blocks/head/context/constants | jq .blocks_per_cycle)
    blocks_to_bake=$(( ( cycle_to_bake * blocks_per_cycle ) - cycle_position))
    echo "   adaptive issuance will activate in $cycle_to_bake cycles at cycle $activation_cycle, current cycle is $current_cycle, baking $blocks_to_bake"
}

## bake until the vote for AI passes
function wait_adaptive_issuance_activation(){
    check_on_proto_with_AI
    echo "Baking until adaptive issuance activation:"
    while [[ $(rpc /chains/main/blocks/head/context/adaptive_issuance_launch_cycle) == "null" ]]; do
        #baking 1000 times before giving feedback
        echo "   $(date) - no known date for AI activation, baking 1000 blocks"
        bake_vote_on 998
        bake_vote_on 2 100
        date
        rpc /chains/main/blocks/head/helpers/current_level | jq -c;
    done
    compute_AI_activation_block
    bake_vote_on $((blocks_per_cycle - cycle_position))
    for (( cycle=0; cycle++ ; cycle < cycle_to_bake)); do
        bake_vote_on 100 100
        bake_vote_on $((blocks_per_cycle - 100))

    done

}

## bake until 2 blocks before UAU
function bake_until_just_before_UAU(){
    echo "Baking until just before user activated upgrade:"
    compute_UAU_parameters "   "
    if [[ $blocks_to_bake -lt 100 ]]; then
        bake $blocks_to_bake
    else
        bake $((blocks_to_bake - 100))
        echo "baking 100 blocks with full wallet to ensure activity for small bakers"
        bake 100 100
    fi
}

## bake until the first proto_alpha block
function bake_until_alpha(){
    echo "Baking until after user activated upgrade (should happen after level $uau ):"
    while [[ "$(rpc /chains/main/blocks/head/header | jq .protocol)" =~ $starting_proto ]]; do
        bake 1
    done
    echo "  Context is now on protocol $(rpc /chains/main/blocks/head/header | jq .protocol)"
    rpc /chains/main/blocks/head/helpers/current_level | jq
}


# TODO
# automatically apply patch that deactivate PoW
# ideally this script should work on any branch, not just this crafted branch with yes patch, UAU, ETC

function build_wallets(){

    build_yes-wallet
    build_yes-wallet 100
}

function activate_next_proto(){
    if compute_UAU_parameters; then
        check_for_data_dir_backup $((level + blocks_to_bake))
        if $patch_code; then
            node_stop
            patch_node
            echo '  Waiting 10 sec for the node to be stopped'
            sleep 10
            node_run
            echo '  Waiting 10 sec for the node to start'
            sleep 10
        fi
        bake_until_just_before_UAU
        level_info=$(rpc /chains/main/blocks/head/helpers/current_level)
        level=$(echo "$level_info"| jq .level)
        may_copy_data_dir "$level"
        bake_until_alpha
    else
        echo "  Context is no more on $starting_proto, trying to activate adaptive issuance"
    fi

}



function full_until_proto_activation(){
    download_tarball
    extract_tarball
    config_datadir
    build_wallets
    faketime
    node_run
    echo 'Waiting 10 sec for the node to start'
    sleep 10
    activate_next_proto
    node_stop
}

######################################################
#
# scenario that
#  - download a mainnet context
#  - build a minimal yes wallet from it
#  - build a full yes wallet from it
#  - compute UAU level to start at the begining of next cycle
#  - patch octez to set the UAU
#  - bake until alpha activation
#  - copy the data dir just before activation
#  - bake until adaptive issuance activation
#
######################################################
function full_scenario(){
    download_tarball
    extract_tarball
    config_datadir
    build_wallets
    faketime
    node_run
    echo 'Waiting 10 sec for the node to start'
    sleep 10
    activate_next_proto
    wait_adaptive_issuance_activation
    node_stop
}

function activate_ai(){
    faketime
    node_run
    echo 'Waiting 10 sec for the node to start'
    sleep 10
    wait_adaptive_issuance_activation
    node_stop
}

function scenario_scenario_on_extracted_data_dir(){
    config_datadir
    build_wallets
    faketime
    node_run
    echo 'Waiting 10 sec for the node to start'
    sleep 10
    activate_next_proto
    wait_adaptive_issuance_activation
    node_stop
}



if [[ $(basename $0) == "mainnet_migration.sh" ]]; then
    # full_scenario
    if [[ "$1" == "run node" ]]; then
        node_run
    elif [[ "$1" == "activate proto" ]]; then
        full_until_proto_activation
    elif [[ "$1" == "activate ai" ]]; then
        activate_ai
    else
        full_scenario
    fi
fi
