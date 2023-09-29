
module.exports = { print_analysis }
const MLR = require("ml-regression-multivariate-linear")
const fs = require('fs');
const csv = require('csv-stringify/sync');
const utils = require("./utils")
const OUTPUT = 'tx_overhead_data.csv'


//[record.benchmark_name, record.tx_size, record.store_transaction_object_ticks])
function print_analysis(infos) {
    const data = infos.tx_overhead;
    for (datum of data) {
        datum.tx_overhead = datum.run_transaction_ticks - datum.sputnik_runtime_ticks
    }
    let lr = tx_overhead_lr(data)
    // console.log(JSON.stringify(mlr.toJSON(), null, 2))
    console.log(`Y = ${lr.weights[1][0]} + ${lr.weights[0][0]} * size `)
    const csv_config = {
        header: true,
        columns: ["benchmark_name", "status", "gas_cost", "tx_size", "run_transaction_ticks", "sputnik_runtime_ticks", "tx_overhead"]
    };
    fs.writeFileSync(OUTPUT, csv.stringify(data, csv_config))

    // console.log(`current model: Y = ${MODEL.intercept} + ${MODEL.coef} * nbtx `)
    // return utils.print_summary_errors(data, datum => { return datum.store_transaction_object_ticks - predict(MODEL, datum.tx_size) })
}


function tx_overhead_lr(data) {
    var X = []
    var Y = []
    for (datum of data) {
        X.push([datum.tx_size])
        Y.push([datum.tx_overhead])
    }
    let mlr = new MLR(X, Y)
    return mlr
}