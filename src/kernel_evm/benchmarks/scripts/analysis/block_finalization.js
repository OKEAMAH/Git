
module.exports = { print_analysis }
const MLR = require("ml-regression-multivariate-linear")
const fs = require('fs');
const csv = require('csv-stringify/sync')
const utils = require("./utils")
const OUTPUT = 'block_finalization_data.csv'
const MODEL_INTERCEPT = 500000
const MODEL_COEF_NB_TX = 36523

function predict_current(datum) {
    return MODEL_COEF_NB_TX * datum.nb_tx + MODEL_INTERCEPT
}

function print_analysis(infos) {
    let mlr = compute_lr(infos.block_finalization)
    console.log(`Linear Regression: Y = ${mlr.weights[1][0]} + ${mlr.weights[0][0]} * nbtx `)
    const csv_config = {
        header: true,
        columns: ["benchmark_name", "inbox_size", "nb_tx", "block_finalize"]
    };
    fs.writeFileSync(OUTPUT, csv.stringify(infos.block_finalization, csv_config))
    console.log(`current model: Y = ${MODEL_INTERCEPT} + ${MODEL_COEF_NB_TX} * nbtx `)
    return utils.print_summary_errors(infos.block_finalization, datum => { return datum.block_finalize - predict_current(datum) })
}


function compute_lr(data) {
    var X = []
    var Y = []
    for (datum of data) {
        X.push([datum.nb_tx])
        Y.push([datum.block_finalize])
    }
    let mlr = new MLR(X, Y)
    return mlr
}