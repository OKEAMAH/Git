//   Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

/*
  Usage: node signer.js <transaction> <private key>

  - transaction: '{
     "to": (ex: "0xB53dc01974176E5dFf2298C5a94343c2585E3c54"),
     "value": (ex: "0xde0b6b3a7640000", in Wei) ,
     "gasLimit": (ex: "0x5208"),
     "gasPrice": (ex: "0x5208"),
     "nonce": (ex: 0),
     "data": (ex: ""),
     "chainId": (ex: 1337)
     }'
     Numerical values can be either hexadecimal encoding prefixed with `0x`, or a numerical value directly.

   - private key: key without the `0x` prefix
   (ex: 9722f6cc9ff938e63f8ccb74c3daa6b45837e5c5e3835ac08c44c50ab5f39dc0)

  */

const { Common } = require('@ethereumjs/common');
const { Transaction } = require('@ethereumjs/tx');

const json = JSON.parse(process.argv[2]);
const tx = Transaction.fromTxData(json, { common: Common.custom({ chainId: json.chainId }) });

const privateKey = Buffer.from(process.argv[3], 'hex');

console.log(tx.sign(privateKey).serialize().toString('hex'))
