
const MLR = require("ml-regression-multivariate-linear")
module.exports = { print_fetch_analysis }
const number_formatter_compact = Intl.NumberFormat('en', { notation: 'compact', compactDisplay: 'long' });
const fs = require('fs');
const csv = require('csv-stringify/sync')
const utils = require("./utils")
const OUTPUT = 'fetch_data.csv'
const MODEL_INTERCEPT = 165000
const MODEL_COEF_SIZE = 600
const MODEL_COEF_NB_TX = 0

function predict_current(fetch) {
    let nbtx = fetch.nb_tx
    let size = fetch.size
    // return 800000 + 160 * size + 140000 * nbtx
    // taken from MLR + maximum negative error (as constant)
    // return 1030000 + 140 * size + 145000 * nbtx
    return MODEL_INTERCEPT + nbtx * MODEL_COEF_NB_TX + size * MODEL_COEF_SIZE
}

function print_fetch_analysis(infos) {
    let mlr = compound_mlr(infos.fetch_data)
    console.log(`fetch model: Y = ${mlr.weights[2][0]} + ${mlr.weights[0][0]} * size + ${mlr.weights[1][0]} * nbtx`)
    let lr_nbtx = nb_tx_mlr(infos.fetch_data)
    console.log(`fetch model: Y = ${lr_nbtx.weights[1][0]} + ${lr_nbtx.weights[0][0]} * nbtx `)
    let size_lr = size_mlr(infos.fetch_data)
    console.log(`fetch model: Y = ${size_lr.weights[1][0]} + ${size_lr.weights[0][0]} * size `)
    const csv_config = {
        header: true,
        columns: ["benchmark_name", "size", "nb_tx", "ticks"]
    };
    fs.writeFileSync(OUTPUT, csv.stringify(infos.fetch_data, csv_config))

    console.log(`current model: Y = ${MODEL_INTERCEPT} + ${MODEL_COEF_NB_TX} * nbtx + ${MODEL_COEF_SIZE} * size`)
    return utils.print_summary_errors(infos.fetch_data, datum => { return datum.ticks - predict_current(datum) })
}

function compare(prediction, value) {
    let error = prediction - value;
    let error_pct = error * 100 / value
    let error_pct_fmted = number_formatter_compact.format(error_pct)
    return `${number_formatter_compact.format(error)} ${error_pct_fmted}%`

}

function compound_mlr(fetch_data) {
    var X = []
    var Y = []
    for (datum of fetch_data) {
        X.push([datum.size, datum.nb_tx])
        Y.push([datum.ticks])
    }
    let mlr = new MLR(X, Y)
    // console.log(JSON.stringify(mlr.toJSON(), null, 2))
    // Y = A + B X0 + C X1
    return mlr
}

function nb_tx_mlr(fetch_data) {
    var X = []
    var Y = []
    for (datum of fetch_data) {
        X.push([datum.nb_tx])
        Y.push([datum.ticks])
    }
    let mlr = new MLR(X, Y)
    return mlr
}

function size_mlr(fetch_data) {
    var X = []
    var Y = []
    for (datum of fetch_data) {
        X.push([datum.size])
        Y.push([datum.ticks])
    }
    let mlr = new MLR(X, Y)
    return mlr
}