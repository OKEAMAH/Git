
module.exports = { print_analysis }
const MLR = require("ml-regression-multivariate-linear")
const fs = require('fs');
const csv = require('csv-stringify/sync');
const OUTPUT = 'register_tx_data.csv'

function print_analysis(infos) {
    let mlr = compute_lr(infos.tx_register)
    // console.log(JSON.stringify(mlr.toJSON(), null, 2))
    console.log(`Y = ${mlr.weights[1][0]} + ${mlr.weights[0][0]} * size `)
    const csv_config = {
        header: true,
        columns: ["benchmark_name", "tx size", "store tx ticks"]
    };
    fs.writeFileSync(OUTPUT, csv.stringify(infos.tx_register, csv_config))
}


function compute_lr(data) {
    var X = []
    var Y = []
    for (datum of data) {
        X.push([datum[1]])
        Y.push([datum[2]])
    }
    let mlr = new MLR(X, Y)
    return mlr
}