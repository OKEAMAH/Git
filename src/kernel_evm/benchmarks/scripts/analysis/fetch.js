
const MLR = require("ml-regression-multivariate-linear")
module.exports = { print_fetch_analysis }
const number_formatter_compact = Intl.NumberFormat('en', { notation: 'compact', compactDisplay: 'long' });
const number_formatter = Intl.NumberFormat('en', {});

function predict_naive_fetch(fetch) {
    let nbtx = fetch[2]
    let size = fetch[1]
    // return 800000 + 160 * size + 140000 * nbtx
    // taken from MLR + maximum negative error (as constant)
    return 1030000 + 140 * size + 145000 * nbtx
}

function print_fetch_analysis(infos) {
    let mlr = fetch_mlr(infos.fetch_data)
    let lr_nbtx = fetch_regression_nb_tx(infos.fetch_data)
    console.log(infos.fetch_data)
    for (datum of infos.fetch_data) {
        let prediction = predict_naive_fetch(datum)
        let prediction2 = mlr.predict([datum[1], datum[2]])
        let prediction3 = lr_nbtx.predict([datum[2]])[0] + 1700000
        let value = datum[0]
        console.log(`prediction: ${prediction} (${compare(prediction, value)}) vs MLR ${prediction2} (${compare(prediction2, value)})  vs LR nbtx ${prediction3} (${compare(prediction3, value)})  vs value ${value}`)
    }
}

function compare(prediction, value) {
    let error = prediction - value;
    let error_pct = error * 100 / value
    let error_pct_fmted = number_formatter_compact.format(error_pct)
    return `${number_formatter_compact.format(error)} ${error_pct_fmted}%`

}

function fetch_mlr(fetch_data) {
    var X = []
    var Y = []
    for (datum of fetch_data) {
        X.push([datum[1], datum[2]])
        Y.push([datum[0]])
    }
    let mlr = new MLR(X, Y)
    // console.log(JSON.stringify(mlr.toJSON(), null, 2))
    // Y = A + B X0 + C X1
    console.log(`Y = ${mlr.weights[2][0]} + ${mlr.weights[0][0]} * size + ${mlr.weights[1][0]} * nbtx`)
    return mlr
}

function fetch_regression_nb_tx(fetch_data) {
    var X = []
    var Y = []
    for (datum of fetch_data) {
        X.push([datum[2]])
        Y.push([datum[0]])
    }
    let mlr = new MLR(X, Y)
    console.log(`Y = ${mlr.weights[1][0]} + ${mlr.weights[0][0]} * nbtx `)
    return mlr
}