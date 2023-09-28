
module.exports = { print_analysis }
const MLR = require("ml-regression-multivariate-linear")
const fs = require('fs');
const csv = require('csv-stringify/sync');
const utils = require("./utils")
const OUTPUT = 'register_tx_data.csv'
const MODEL = { intercept: 500000, coef: 36523 }

function predict(model, x) {
    return model.intercept + model.coef * x
}


//[record.benchmark_name, record.tx_size, record.store_transaction_object_ticks])
function print_analysis(infos) {
    let mlr = store_obj_lr(infos.tx_register)
    // console.log(JSON.stringify(mlr.toJSON(), null, 2))
    console.log(`Y = ${mlr.weights[1][0]} + ${mlr.weights[0][0]} * size `)
    const csv_config = {
        header: true,
        columns: ["benchmark_name", "tx_size", "store_transaction_object_ticks"]
    };
    fs.writeFileSync(OUTPUT, csv.stringify(infos.tx_register, csv_config))

    console.log(`current model: Y = ${MODEL.intercept} + ${MODEL.coef} * nbtx `)
    return utils.print_summary_errors(infos.tx_register, datum => { return datum.store_transaction_object_ticks - predict(MODEL, datum.tx_size) })
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