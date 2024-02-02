#!bash

node_dir=/tmp/customnet-node
client_dir=/tmp/customnet-client
export PROFILING=yes:/Users/diana/Documents/features/reduce_blocktime

rm -rf $node_dir
mkdir -p $node_dir
rm -rf $client_dir
mkdir -p $client_dir

./octez-node config init --data-dir $node_dir

config='{
  "rpc": {
    "listen-addrs": [
      "127.0.0.1:8732"
    ],
    "local-listen-addrs": []
  },
  "p2p": {
    "bootstrap-peers": [],
    "listen-addr": "[::]:9732"
  },
  "shell": {
    "chain_validator": {
      "synchronisation_threshold": 0
    },
    "history_mode": "rolling"
  },
  "network": {
    "genesis": {
      "timestamp": "2023-07-24T12:50:27Z",
      "block": "BLockGenesisGenesisGenesisGenesisGenesisf79b5d1CoW2",
      "protocol": "Ps9mPmXaRzmzk35gbAYNCAw6UXdE2qoABTHbN2oEEc1qM7CwT9P"
    },
    "genesis_parameters": {
      "values": {
        "genesis_pubkey": "edpkv8Sixoq7LPAYsgFGWaFzs1Rvw5HV7a3aWKPtd3Noz9ENFycqz4"
      }
    },
    "chain_name": "TEZOS_CUSTOM",
    "incompatible_chain_name": "INCOMPATIBLE",
    "sandboxed_chain_name": "SANDBOXED_CUSTOM"
  }
}'

parameters='{ "bootstrap_accounts": [
    [
      "edpkv8Sixoq7LPAYsgFGWaFzs1Rvw5HV7a3aWKPtd3Noz9ENFycqz4",
      "4000000000000"
    ]
  ], 
  "preserved_cycles": 5,
  "blocks_per_cycle": 16384, "blocks_per_commitment": 128,
  "nonce_revelation_threshold": 512, "blocks_per_stake_snapshot": 1024,
  "cycles_per_voting_period": 5, "hard_gas_limit_per_operation": "1040000",
  "hard_gas_limit_per_block": "2600000",
  "proof_of_work_threshold": "281474976710655",
  "minimal_stake": "6000000000", "vdf_difficulty": "8000000000",
  "seed_nonce_revelation_tip": "125000", "origination_size": 257,
  "baking_reward_fixed_portion": "5000000",
  "baking_reward_bonus_per_slot": "2143",
  "endorsing_reward_per_slot": "1428", "cost_per_byte": "250",
  "hard_storage_limit_per_operation": "60000", "quorum_min": 2000,
  "quorum_max": 7000, "min_proposal_quorum": 500,
  "liquidity_baking_subsidy": "1250000",
  "liquidity_baking_toggle_ema_threshold": 1000000000,
  "max_operations_time_to_live": 240, "minimal_block_delay": "1",
  "delay_increment_per_round": "8", "consensus_committee_size": 7000,
  "consensus_threshold": 4667,
  "minimal_participation_ratio": { "numerator": 2, "denominator": 3 },
  "max_slashing_period": 2, "frozen_deposits_percentage": 10,
  "double_baking_punishment": "640000000",
  "ratio_of_frozen_deposits_slashed_per_double_endorsement":
    { "numerator": 1, "denominator": 2 }, "cache_script_size": 100000000,
  "cache_stake_distribution_cycles": 8, "cache_sampler_state_cycles": 8,
  "tx_rollup_enable": false, "tx_rollup_origination_size": 4000,
  "tx_rollup_hard_size_limit_per_inbox": 500000,
  "tx_rollup_hard_size_limit_per_message": 5000,
  "tx_rollup_max_withdrawals_per_batch": 15,
  "tx_rollup_commitment_bond": "10000000000",
  "tx_rollup_finality_period": 40000, "tx_rollup_withdraw_period": 40000,
  "tx_rollup_max_inboxes_count": 40100,
  "tx_rollup_max_messages_per_inbox": 1010,
  "tx_rollup_max_commitments_count": 80100,
  "tx_rollup_cost_per_byte_ema_factor": 120,
  "tx_rollup_max_ticket_payload_size": 2048,
  "tx_rollup_rejection_max_proof_size": 30000,
  "tx_rollup_sunset_level": 3473409,
  "dal_parametric":
    { "feature_enable": false, "number_of_slots": 256, "attestation_lag": 1,
      "attestation_threshold": 50, "blocks_per_epoch": 32,
      "redundancy_factor": 16, "page_size": 4096, "slot_size": 1048576,
      "number_of_shards": 2048 }, "smart_rollup_enable": true,
  "smart_rollup_arith_pvm_enable": false,
  "smart_rollup_origination_size": 6314,
  "smart_rollup_challenge_window_in_blocks": 80640,
  "smart_rollup_stake_amount": "10000000000",
  "smart_rollup_commitment_period_in_blocks": 60,
  "smart_rollup_max_lookahead_in_blocks": 172800,
  "smart_rollup_max_active_outbox_levels": 80640,
  "smart_rollup_max_outbox_messages_per_level": 100,
  "smart_rollup_number_of_sections_in_dissection": 32,
  "smart_rollup_timeout_period_in_blocks": 40320,
  "smart_rollup_max_number_of_cemented_commitments": 5,
  "smart_rollup_max_number_of_parallel_games": 32, "zk_rollup_enable": false,
  "zk_rollup_origination_size": 4000,
  "zk_rollup_min_pending_to_process": 10 }'


echo $config > $node_dir/config.json
echo $parameters > $node_dir/parameters.json



# run octez node 
./octez-node identity generate --data-dir $node_dir 0
./octez-node run  --data-dir  $node_dir --rpc-addr localhost:8732 &
node_pid=$!
echo "node_pid=$node_pid"
sleep 2

# point client at localhost:8732
client="./octez-client --endpoint http://localhost:8732 -d $client_dir"

# import secret
$client import secret key customnet_key unencrypted:edsk4JdHNxy8pvkt176P4q8UrR5pfHw81jdRFTSCD4yyVq9fttqDrA --force

$client activate protocol PtNairobiyssHuh87hEhfVBGCVrK3WnS8Z2FT4ymB5tAa4r1nQf with fitness 1 and key customnet_key and parameters $node_dir/parameters.json


# run baker
./octez-baker-PtNairob -d $client_dir run with local node $node_dir --liquidity-baking-toggle-vote pass customnet_key &
baker_pid=$!
echo "baker_pid=$baker_pid"

cleanup() {
  kill $baker_pid
}

# run cleanup on Ctrl+C 
trap cleanup SIGTERM SIGINT

wait $node_pid