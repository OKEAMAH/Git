// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
//
// SPDX-License-Identifier: MIT

function exactly_two(val) {
    return (`0${val}`).slice(-2);
}

function timestamp() {
    const dateObject = new Date();
    // current date
    // adjust 0 before single digit date
    const date = exactly_two(dateObject.getDate());
    const month = exactly_two(dateObject.getMonth() + 1);
    const year = dateObject.getFullYear();
    const hours = exactly_two(dateObject.getHours());
    const minutes = exactly_two(dateObject.getMinutes());
    const seconds = exactly_two(dateObject.getSeconds());

    // YYYY-MM-DDTHH-MM-SS
    return `${year}-${month}-${date}T${hours}-${minutes}-${seconds}`
}


module.exports = { timestamp }