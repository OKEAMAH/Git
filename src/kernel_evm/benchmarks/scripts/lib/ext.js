const path = require('node:path');
const in_prod = function () {
    return process.env.NODE_ENV == "production"
}

const bin_path = function (filepath) {
    if (in_prod()) {
        return path.basename(filepath)
    } else {
        return filepath
    }
}
const kernel_path = function (filepath) {
    if (in_prod() && process.env.KERNEL) {
        return path.format({
            dir: process.env.KERNEL,
            base: path.basename(filepath)
        })
    } else {
        return filepath
    }
}
module.exports = { bin_path, kernel_path }