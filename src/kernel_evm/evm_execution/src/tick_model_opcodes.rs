// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
// SPDX-FileCopyrightText: 2022-2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! Ticks per gas per Opcode model for the EVM Kernel

// The values from this file have been autogenerated by a benchmark script. If
// it needs to be updated, please have a look at the script
// `src/kernel_evm/benchmarks/scripts/analysis/opcodes.js`.

use evm::Opcode;

// Default ticks per gas value
const DEFAULT_TICKS_PER_GAS: u64 = 2000;

// Average: 4710; Standard deviation: 0
const MODEL_0X00: u64 = 4710;

// Average: 3894; Standard deviation: 1
const MODEL_0X01: u64 = 3896;

// Average: 2958; Standard deviation: 0
const MODEL_0X02: u64 = 2958;

// Average: 3939; Standard deviation: 10
const MODEL_0X03: u64 = 3959;

// Average: 2713; Standard deviation: 349
const MODEL_0X04: u64 = 3411;

// No data
const MODEL_0X05: u64 = DEFAULT_TICKS_PER_GAS;

// Average: 3439; Standard deviation: 238
const MODEL_0X06: u64 = 3915;

// No data
const MODEL_0X07: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X08: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X09: u64 = DEFAULT_TICKS_PER_GAS;

// Average: 4633; Standard deviation: 1
const MODEL_0X0A: u64 = 4635;

// No data
const MODEL_0X0B: u64 = DEFAULT_TICKS_PER_GAS;

// Average: 3592; Standard deviation: 1
const MODEL_0X10: u64 = 3594;

// Average: 3592; Standard deviation: 2
const MODEL_0X11: u64 = 3596;

// Average: 7595; Standard deviation: 13
const MODEL_0X12: u64 = 7621;

// Average: 7591; Standard deviation: 0
const MODEL_0X13: u64 = 7591;

// Average: 5050; Standard deviation: 717
const MODEL_0X14: u64 = 6484;

// Average: 4087; Standard deviation: 759
const MODEL_0X15: u64 = 5605;

// Average: 3816; Standard deviation: 0
const MODEL_0X16: u64 = 3816;

// Average: 3816; Standard deviation: 0
const MODEL_0X17: u64 = 3816;

// Average: 3816; Standard deviation: 0
const MODEL_0X18: u64 = 3816;

// Average: 2723; Standard deviation: 1
const MODEL_0X19: u64 = 2725;

// Average: 24812; Standard deviation: 0
const MODEL_0X1A: u64 = 24812;

// Average: 11718; Standard deviation: 72
const MODEL_0X1B: u64 = 11862;

// Average: 12879; Standard deviation: 841
const MODEL_0X1C: u64 = 14561;

// No data
const MODEL_0X1D: u64 = DEFAULT_TICKS_PER_GAS;

// Average: 4259; Standard deviation: 174
const MODEL_0X20: u64 = 4607;

// Average: 2380; Standard deviation: 0
const MODEL_0X30: u64 = 2380;

// Average: 1307; Standard deviation: 0
const MODEL_0X31: u64 = 1307;

// Average: 2374; Standard deviation: 0
const MODEL_0X32: u64 = 2374;

// Average: 2380; Standard deviation: 0
const MODEL_0X33: u64 = 2380;

// Average: 2715; Standard deviation: 0
const MODEL_0X34: u64 = 2715;

// Average: 26846; Standard deviation: 2795
const MODEL_0X35: u64 = 32436;

// Average: 2495; Standard deviation: 2575
const MODEL_0X36: u64 = 7645;

// Average: 8529; Standard deviation: 4945
const MODEL_0X37: u64 = 18419;

// Average: 2495; Standard deviation: 0
const MODEL_0X38: u64 = 2495;

// Average: 583; Standard deviation: 890
const MODEL_0X39: u64 = 2363;

// Average: 2703; Standard deviation: 0
const MODEL_0X3A: u64 = 2703;

// Average: 1154; Standard deviation: 15
const MODEL_0X3B: u64 = 1184;

// Average: 733; Standard deviation: 3
const MODEL_0X3C: u64 = 739;

// Average: 13071; Standard deviation: 0
const MODEL_0X3D: u64 = 13071;

// Average: 26944; Standard deviation: 9923
const MODEL_0X3E: u64 = 46790;

// No data
const MODEL_0X3F: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X40: u64 = DEFAULT_TICKS_PER_GAS;

// Average: 2383; Standard deviation: 0
const MODEL_0X41: u64 = 2383;

// Average: 2721; Standard deviation: 0
const MODEL_0X42: u64 = 2721;

// Average: 2721; Standard deviation: 0
const MODEL_0X43: u64 = 2721;

// No data
const MODEL_0X44: u64 = DEFAULT_TICKS_PER_GAS;

// Average: 2833; Standard deviation: 0
const MODEL_0X45: u64 = 2833;

// Average: 12956; Standard deviation: 0
const MODEL_0X46: u64 = 12956;

// Average: 26060; Standard deviation: 234
const MODEL_0X47: u64 = 26528;

// Average: 12956; Standard deviation: 0
const MODEL_0X48: u64 = 12956;

// Average: 1719; Standard deviation: 0
const MODEL_0X50: u64 = 1719;

// Average: 15977; Standard deviation: 23
const MODEL_0X51: u64 = 16023;

// Average: 13540; Standard deviation: 4406
const MODEL_0X52: u64 = 22352;

// No data
const MODEL_0X53: u64 = DEFAULT_TICKS_PER_GAS;

// Average: 2178; Standard deviation: 51
const MODEL_0X54: u64 = 2280;

// Average: 6088; Standard deviation: 1032
const MODEL_0X55: u64 = 8152;

// Average: 954; Standard deviation: 0
const MODEL_0X56: u64 = 954;

// Average: 1283; Standard deviation: 48
const MODEL_0X57: u64 = 1379;

// No data
const MODEL_0X58: u64 = DEFAULT_TICKS_PER_GAS;

// Average: 2395; Standard deviation: 0
const MODEL_0X59: u64 = 2395;

// Average: 2969; Standard deviation: 0
const MODEL_0X5A: u64 = 2969;

// Average: 3354; Standard deviation: 0
const MODEL_0X5B: u64 = 3354;

// No data
const MODEL_0X5F: u64 = DEFAULT_TICKS_PER_GAS;

// Average: 1474; Standard deviation: 64
const MODEL_0X60: u64 = 1602;

// Average: 1508; Standard deviation: 93
const MODEL_0X61: u64 = 1694;

// Average: 1567; Standard deviation: 556
const MODEL_0X62: u64 = 2679;

// Average: 1574; Standard deviation: 0
const MODEL_0X63: u64 = 1574;

// No data
const MODEL_0X64: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X65: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X66: u64 = DEFAULT_TICKS_PER_GAS;

// Average: 1698; Standard deviation: 491
const MODEL_0X67: u64 = 2680;

// No data
const MODEL_0X68: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X69: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X6A: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X6B: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X6C: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X6D: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X6E: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X6F: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X70: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X71: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X72: u64 = DEFAULT_TICKS_PER_GAS;

// Average: 1841; Standard deviation: 538
const MODEL_0X73: u64 = 2917;

// No data
const MODEL_0X74: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X75: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X76: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X77: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X78: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X79: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X7A: u64 = DEFAULT_TICKS_PER_GAS;

// Average: 1875; Standard deviation: 66
const MODEL_0X7B: u64 = 2007;

// No data
const MODEL_0X7C: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X7D: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X7E: u64 = DEFAULT_TICKS_PER_GAS;

// Average: 1963; Standard deviation: 6
const MODEL_0X7F: u64 = 1975;

// Average: 1442; Standard deviation: 59
const MODEL_0X80: u64 = 1560;

// Average: 1444; Standard deviation: 140
const MODEL_0X81: u64 = 1724;

// Average: 1444; Standard deviation: 44
const MODEL_0X82: u64 = 1532;

// Average: 1444; Standard deviation: 159
const MODEL_0X83: u64 = 1762;

// Average: 1444; Standard deviation: 1108
const MODEL_0X84: u64 = 3660;

// Average: 1444; Standard deviation: 160
const MODEL_0X85: u64 = 1764;

// Average: 1444; Standard deviation: 315
const MODEL_0X86: u64 = 2074;

// Average: 1444; Standard deviation: 1
const MODEL_0X87: u64 = 1446;

// Average: 1444; Standard deviation: 1
const MODEL_0X88: u64 = 1446;

// Average: 1444; Standard deviation: 1
const MODEL_0X89: u64 = 1446;

// Average: 1444; Standard deviation: 1
const MODEL_0X8A: u64 = 1446;

// Average: 1444; Standard deviation: 1
const MODEL_0X8B: u64 = 1446;

// Average: 1444; Standard deviation: 0
const MODEL_0X8C: u64 = 1444;

// No data
const MODEL_0X8D: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X8E: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X8F: u64 = DEFAULT_TICKS_PER_GAS;

// Average: 1425; Standard deviation: 1
const MODEL_0X90: u64 = 1427;

// Average: 1425; Standard deviation: 1
const MODEL_0X91: u64 = 1427;

// Average: 1425; Standard deviation: 1
const MODEL_0X92: u64 = 1427;

// Average: 1425; Standard deviation: 1
const MODEL_0X93: u64 = 1427;

// Average: 1425; Standard deviation: 1
const MODEL_0X94: u64 = 1427;

// Average: 1425; Standard deviation: 1
const MODEL_0X95: u64 = 1427;

// Average: 1425; Standard deviation: 1
const MODEL_0X96: u64 = 1427;

// Average: 1425; Standard deviation: 1
const MODEL_0X97: u64 = 1427;

// Average: 1425; Standard deviation: 0
const MODEL_0X98: u64 = 1425;

// No data
const MODEL_0X99: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X9A: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X9B: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X9C: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X9D: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X9E: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0X9F: u64 = DEFAULT_TICKS_PER_GAS;

// No data
const MODEL_0XA0: u64 = DEFAULT_TICKS_PER_GAS;

// Average: 92; Standard deviation: 11
const MODEL_0XA1: u64 = 114;

// Average: 50; Standard deviation: 1
const MODEL_0XA2: u64 = 52;

// Average: 47; Standard deviation: 2
const MODEL_0XA3: u64 = 51;

// Average: 44; Standard deviation: 3
const MODEL_0XA4: u64 = 50;

// Average: 30; Standard deviation: 2
const MODEL_0XF0: u64 = 34;

// Average: 25; Standard deviation: 331
const MODEL_0XF1: u64 = 687;

// No data
const MODEL_0XF2: u64 = DEFAULT_TICKS_PER_GAS;

// Average: 45825; Standard deviation: 1917
const MODEL_0XF3: u64 = 49659;

// Average: 643; Standard deviation: 1654
const MODEL_0XF4: u64 = 3951;

// Average: 123; Standard deviation: 0
const MODEL_0XF5: u64 = 123;

// Average: 4124; Standard deviation: 1200
const MODEL_0XFA: u64 = 6524;

// Average: 50829; Standard deviation: 2299
const MODEL_0XFD: u64 = 55427;

// No data
const MODEL_0XFE: u64 = DEFAULT_TICKS_PER_GAS;

// Average: 101; Standard deviation: 0
const MODEL_0XFF: u64 = 101;

pub fn ticks(opcode: &Opcode, gas: u64) -> u64 {
    match opcode.as_u8() {
        0x0 => MODEL_0X00, // constant, no gas accounted
        0x1 => MODEL_0X01 * gas,
        0x2 => MODEL_0X02 * gas,
        0x3 => MODEL_0X03 * gas,
        0x4 => MODEL_0X04 * gas,
        0x5 => MODEL_0X05 * gas,
        0x6 => MODEL_0X06 * gas,
        0x7 => MODEL_0X07 * gas,
        0x8 => MODEL_0X08 * gas,
        0x9 => MODEL_0X09 * gas,
        0xa => MODEL_0X0A * gas,
        0xb => MODEL_0X0B * gas,
        0x10 => MODEL_0X10 * gas,
        0x11 => MODEL_0X11 * gas,
        0x12 => MODEL_0X12 * gas,
        0x13 => MODEL_0X13 * gas,
        0x14 => MODEL_0X14 * gas,
        0x15 => MODEL_0X15 * gas,
        0x16 => MODEL_0X16 * gas,
        0x17 => MODEL_0X17 * gas,
        0x18 => MODEL_0X18 * gas,
        0x19 => MODEL_0X19 * gas,
        0x1a => MODEL_0X1A * gas,
        0x1b => MODEL_0X1B * gas,
        0x1c => MODEL_0X1C * gas,
        0x1d => MODEL_0X1D * gas,
        0x20 => MODEL_0X20 * gas,
        0x30 => MODEL_0X30 * gas,
        0x31 => MODEL_0X31 * gas,
        0x32 => MODEL_0X32 * gas,
        0x33 => MODEL_0X33 * gas,
        0x34 => MODEL_0X34 * gas,
        0x35 => MODEL_0X35 * gas,
        0x36 => MODEL_0X36 * gas,
        0x37 => MODEL_0X37 * gas,
        0x38 => MODEL_0X38 * gas,
        0x39 => MODEL_0X39 * gas,
        0x3a => MODEL_0X3A * gas,
        0x3b => MODEL_0X3B * gas,
        0x3c => MODEL_0X3C * gas,
        0x3d => MODEL_0X3D * gas,
        0x3e => MODEL_0X3E * gas,
        0x3f => MODEL_0X3F * gas,
        0x40 => MODEL_0X40 * gas,
        0x41 => MODEL_0X41 * gas,
        0x42 => MODEL_0X42 * gas,
        0x43 => MODEL_0X43 * gas,
        0x44 => MODEL_0X44 * gas,
        0x45 => MODEL_0X45 * gas,
        0x46 => MODEL_0X46 * gas,
        0x47 => MODEL_0X47 * gas,
        0x48 => MODEL_0X48 * gas,
        0x50 => MODEL_0X50 * gas,
        0x51 => MODEL_0X51 * gas,
        0x52 => MODEL_0X52 * gas,
        0x53 => MODEL_0X53 * gas,
        0x54 => MODEL_0X54 * gas,
        0x55 => MODEL_0X55 * gas,
        0x56 => MODEL_0X56 * gas,
        0x57 => MODEL_0X57 * gas,
        0x58 => MODEL_0X58 * gas,
        0x59 => MODEL_0X59 * gas,
        0x5a => MODEL_0X5A * gas,
        0x5b => MODEL_0X5B * gas,
        0x5f => MODEL_0X5F * gas,
        0x60 => MODEL_0X60 * gas,
        0x61 => MODEL_0X61 * gas,
        0x62 => MODEL_0X62 * gas,
        0x63 => MODEL_0X63 * gas,
        0x64 => MODEL_0X64 * gas,
        0x65 => MODEL_0X65 * gas,
        0x66 => MODEL_0X66 * gas,
        0x67 => MODEL_0X67 * gas,
        0x68 => MODEL_0X68 * gas,
        0x69 => MODEL_0X69 * gas,
        0x6a => MODEL_0X6A * gas,
        0x6b => MODEL_0X6B * gas,
        0x6c => MODEL_0X6C * gas,
        0x6d => MODEL_0X6D * gas,
        0x6e => MODEL_0X6E * gas,
        0x6f => MODEL_0X6F * gas,
        0x70 => MODEL_0X70 * gas,
        0x71 => MODEL_0X71 * gas,
        0x72 => MODEL_0X72 * gas,
        0x73 => MODEL_0X73 * gas,
        0x74 => MODEL_0X74 * gas,
        0x75 => MODEL_0X75 * gas,
        0x76 => MODEL_0X76 * gas,
        0x77 => MODEL_0X77 * gas,
        0x78 => MODEL_0X78 * gas,
        0x79 => MODEL_0X79 * gas,
        0x7a => MODEL_0X7A * gas,
        0x7b => MODEL_0X7B * gas,
        0x7c => MODEL_0X7C * gas,
        0x7d => MODEL_0X7D * gas,
        0x7e => MODEL_0X7E * gas,
        0x7f => MODEL_0X7F * gas,
        0x80 => MODEL_0X80 * gas,
        0x81 => MODEL_0X81 * gas,
        0x82 => MODEL_0X82 * gas,
        0x83 => MODEL_0X83 * gas,
        0x84 => MODEL_0X84 * gas,
        0x85 => MODEL_0X85 * gas,
        0x86 => MODEL_0X86 * gas,
        0x87 => MODEL_0X87 * gas,
        0x88 => MODEL_0X88 * gas,
        0x89 => MODEL_0X89 * gas,
        0x8a => MODEL_0X8A * gas,
        0x8b => MODEL_0X8B * gas,
        0x8c => MODEL_0X8C * gas,
        0x8d => MODEL_0X8D * gas,
        0x8e => MODEL_0X8E * gas,
        0x8f => MODEL_0X8F * gas,
        0x90 => MODEL_0X90 * gas,
        0x91 => MODEL_0X91 * gas,
        0x92 => MODEL_0X92 * gas,
        0x93 => MODEL_0X93 * gas,
        0x94 => MODEL_0X94 * gas,
        0x95 => MODEL_0X95 * gas,
        0x96 => MODEL_0X96 * gas,
        0x97 => MODEL_0X97 * gas,
        0x98 => MODEL_0X98 * gas,
        0x99 => MODEL_0X99 * gas,
        0x9a => MODEL_0X9A * gas,
        0x9b => MODEL_0X9B * gas,
        0x9c => MODEL_0X9C * gas,
        0x9d => MODEL_0X9D * gas,
        0x9e => MODEL_0X9E * gas,
        0x9f => MODEL_0X9F * gas,
        0xa0 => MODEL_0XA0 * gas,
        0xa1 => MODEL_0XA1 * gas,
        0xa2 => MODEL_0XA2 * gas,
        0xa3 => MODEL_0XA3 * gas,
        0xa4 => MODEL_0XA4 * gas,
        0xf0 => MODEL_0XF0 * gas,
        0xf1 => MODEL_0XF1 * gas,
        0xf2 => MODEL_0XF2 * gas,
        0xf3 => MODEL_0XF3, // constant, no gas accounted
        0xf4 => MODEL_0XF4 * gas,
        0xf5 => MODEL_0XF5 * gas,
        0xfa => MODEL_0XFA * gas,
        0xfd => MODEL_0XFD, // constant, no gas accounted
        0xfe => MODEL_0XFE * gas,
        0xff => MODEL_0XFF * gas,
        _ => DEFAULT_TICKS_PER_GAS * gas,
    }
}
