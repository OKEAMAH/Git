// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
//
// SPDX-License-Identifier: MIT

const BASE_GAS = 21000
const CREATE_STORAGE_CUTOFF = 600_000


module.exports = {
    print_summary_errors, is_transfer, is_create, is_transaction, BASE_GAS
}

function is_transfer(record) {
    return record.gas_cost == BASE_GAS
}
function is_create(record) {
    return record.store_transaction_object_ticks > CREATE_STORAGE_CUTOFF
}

function is_transaction(record) {
    return !isNaN(record.gas_cost)
        || !isNaN(record.run_transaction_ticks)
        || !isNaN(record.signature_verification_ticks)
        || record.status
}

function print_summary_errors(data, compute_error) {
    let max_error_current = 0;
    let nb_error = 0
    for (datum of data) {
        let error = compute_error(datum)
        if (error > 0) nb_error += 1
        max_error_current = Math.max(max_error_current, error)
    }
    console.log(`nb of errors: ${nb_error} ; maximum error: ${max_error_current} ticks`)
    return nb_error
}