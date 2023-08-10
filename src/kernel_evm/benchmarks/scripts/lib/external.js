// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
//
// SPDX-License-Identifier: MIT

const path = require('node:path');

const in_prod = function () {
    return process.env.NODE_ENV == "production"
}

const bin = function (filepath) {
    if (in_prod()) {
        return path.basename(filepath)
    } else {
        return filepath
    }
}

const ressource = function (filepath) {
    if (in_prod() && process.env.EXTERNAL_RESSOURCES) {
        return path.format({
            dir: process.env.EXTERNAL_RESSOURCES,
            base: path.basename(filepath)
        })
    } else {
        return filepath
    }
}

const output = function () {
    if (process.env.OUTPUT) {
        return process.env.OUTPUT
    } else {
        return "."
    }

}
module.exports = { bin, ressource, output }