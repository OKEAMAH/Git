
module.exports = { print_analysis }
const MLR = require("ml-regression-multivariate-linear")
const fs = require('fs');
const csv = require('csv-stringify/sync');
const utils = require("./utils")
const OUTPUT = 'register_tx_data.csv'
const MODEL_OBJ = { intercept: 500000, coef: 36523 }
const MODEL_RECEIPT = { intercept: 500000, coef: 36523 }

function predict_obj(model, x) {
    return model.intercept + model.coef * x
}

function predict_register(datum) {
    return predict_obj(MODEL_OBJ, datum.tx_size) + predict_obj(MODEL_RECEIPT, datum.receipt_size)
}

//[record.benchmark_name, record.tx_size, record.store_transaction_object_ticks])
function print_analysis(infos) {
    let obj_lr = store_obj_lr(infos.tx_register)
    let receipt_lr = store_receipt_lr(infos.tx_register)
    // console.log(JSON.stringify(mlr.toJSON(), null, 2))
    console.log(`object LR: Y = ${obj_lr.weights[1][0]} + ${obj_lr.weights[0][0]} * size `)
    console.log(`receipt LR: Y = ${receipt_lr.weights[1][0]} + ${receipt_lr.weights[0][0]} * size `)
    const csv_config = {
        header: true,
        columns: ["benchmark_name", "tx_size", "store_transaction_object_ticks", "receipt_size", "store_receipt_ticks", "register_tx_ticks"]
    };
    fs.writeFileSync(OUTPUT, csv.stringify(infos.tx_register, csv_config))
    fs.writeFileSync("object_" + OUTPUT, csv.stringify(infos.tx_register, {
        header: true,
        columns: ["benchmark_name", "tx_size", "store_transaction_object_ticks",]
    }))
    fs.writeFileSync("receipt_" + OUTPUT, csv.stringify(infos.tx_register, {
        header: true,
        columns: ["benchmark_name", "receipt_size", "store_receipt_ticks"]
    }))

    console.log(`current model: Y = ${MODEL_OBJ.intercept} + ${MODEL_OBJ.coef} * nbtx `)
    return utils.print_summary_errors(infos.tx_register, datum => { return datum.register_tx_ticks - predict_register(datum) })
}


function store_obj_lr(data) {
    var X = []
    var Y = []
    for (datum of data) {
        X.push([datum.tx_size])
        Y.push([datum.store_transaction_object_ticks])
    }
    let mlr = new MLR(X, Y)
    return mlr
}

function store_receipt_lr(data) {
    var X = []
    var Y = []
    for (datum of data) {
        X.push([datum.receipt_size])
        Y.push([datum.store_receipt_ticks])
    }
    let mlr = new MLR(X, Y)
    return mlr
}