// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
//
// SPDX-License-Identifier: MIT

// create contract and call it
// example "storage.sol"

const utils = require('./utils');
const addr = require('../lib/address');
let faucet = require('./players/faucet.json');

let create_data = "0x608060405234801561001057600080fd5b50610150806100206000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c80632e64cec11461003b5780636057361d14610059575b600080fd5b610043610075565b60405161005091906100a1565b60405180910390f35b610073600480360381019061006e91906100ed565b61007e565b005b60008054905090565b8060008190555050565b6000819050919050565b61009b81610088565b82525050565b60006020820190506100b66000830184610092565b92915050565b600080fd5b6100ca81610088565b81146100d557600080fd5b50565b6000813590506100e7816100c1565b92915050565b600060208284031215610103576101026100bc565b5b6000610111848285016100d8565b9150509291505056fea26469706673582212208f6a6e5a1a593ae1ba29bd21e9d6e9092ae1df1986f8e8de139149a0e99dce1564736f6c63430008120033"
// call : store(42)
let call_data = "0x6057361d000000000000000000000000000000000000000000000000000000000000002A"
let nb_players = 10
let nb_calls = 5
let players = []
for (let i = 0; i < nb_players; i++) {
    players.push(addr.create_player())
}

let txs_1 = [];
// every player get the same amount
for (player of players) {
    txs_1.push(utils.transfer(faucet, player, 100000000))
}

// first player originates the contract
let create = utils.create(players[0], 0, create_data)
txs_1.push(create.tx)

let txs_2 = [];
// every player store 42 "nb_calls" times
for (player1 of players) {
    for (let index = 0; index < nb_calls; index++) {
        txs_2.push(utils.send(player1, create.addr, 0, call_data))
    }
}

// first set of messages: initialisation
// second set of messages: calls
utils.print_bench([txs_1, txs_2])
