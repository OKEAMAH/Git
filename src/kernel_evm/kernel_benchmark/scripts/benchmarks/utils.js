// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
//
// SPDX-License-Identifier: MIT

// Utilities module to create bench
// use transfer(A,B,N) to obtain a signed transaction where "A" sends "N" to "B"
//   - A and B are players (see ./players directory for examples)
//   - N is an amount
//   - "A" will see its nonce incremented
// use print_bench(inputs) to print a benchmark
//   - inputs is an array of array of transactions (as strings)
//   - see bench1.js
// The first byte of each message is either 0 or 1
//   - 0 means that the transaction is > 2kb and the current message isn't the last chunk of the transaction
//   - 1 means the the the current message is the last chunk of the transaction

const { sign } = require('../lib/signature');
const { legacy_contract_address } = require('../lib/contract');


const transfer_prototype_json = require('./transfer_prototype.json');
const create_prototype_json = require('./create_prototype.json');

const print_full = function (rawTx) {

    console.log(`tx = 0x${rawTx.rawTx}`);
    console.log("msgHash = " + rawTx.msgHash);
    console.log("r = " + rawTx.signature.slice(0, 32).toString('hex'));
    console.log("s = " + rawTx.signature.slice(32, 64).toString('hex'));
}

exports.transfer = function (playera, playerb, amount) {
    let tx = { ...transfer_prototype_json };
    tx.nonce = playera.nonce;
    playera.nonce += 1;
    tx.to = playerb.addr;
    tx.value = amount;
    let rawTx = sign(tx, playera.privateKey)
    return rawTx.rawTx;
}

exports.create = function (player, amount, data) {
    let tx = { ...create_prototype_json };
    tx.nonce = player.nonce;
    let address = legacy_contract_address(player.addr, player.nonce);
    player.nonce += 1;
    tx.value = amount;
    tx.data = data;
    let rawTx = sign(tx, player.privateKey)
    return {
        addr: address,
        tx: rawTx.rawTx
    };
}

exports.send = function (player, contract_addr, amount, data) {
    let tx = { ...transfer_prototype_json };
    tx.nonce = player.nonce;
    player.nonce += 1;
    tx.to = contract_addr;
    tx.value = amount;
    tx.data = data;
    let rawTx = sign(tx, player.privateKey)
    return rawTx.rawTx;
}

const print_list = function (src) {
    const txs = src.slice();
    console.log("[")
    const MESSAGE_CHUNK_MAX_SIZE = 2 * 2000;
    for (var i = 0; i < txs.length; i++) {
        transaction = txs[i];
        while (transaction.length >= MESSAGE_CHUNK_MAX_SIZE) {
            console.log(`{"external": "00${transaction.slice(0, MESSAGE_CHUNK_MAX_SIZE)}"}`);
            console.log(",");
            transaction = transaction.slice(MESSAGE_CHUNK_MAX_SIZE);
        }
        console.log(`{"external": "01${transaction}"}`);
        if (i < txs.length - 1) {
            console.log(",");
        }
    }
    console.log("]")
}

exports.print_bench = function (src) {
    const inputs = src.slice();
    console.log("[")
    while (inputs.length > 1) {
        print_list(inputs.shift())
        console.log(",")
    }
    print_list(inputs.shift())
    console.log("]")
}

exports.encode_number = function (n) {

    let s = "00000000000000000000000000000000"
    var zeroFilled = (s + n.toString(16)).slice(-32)
    return zeroFilled
}
