use std::env;

use tezos_core::internal::coder::Decoder;
use tezos_core::types::encoded::Address;
use tezos_core::types::encoded::Encoded;
use tezos_core::types::hex_string::HexString;
// use tezos_core::internal::coder::Encoder;
use tezos_core::internal::coder::AddressBytesCoder;
use tezos_core::internal::coder::IntegerBytesCoder;
use tezos_core::types::number::Int;
use tezos_core::Error;

fn is_case_contract(args: &Vec<String>) -> bool {
    return args.len() >= 5
        && (args[2] == "005-PsBabyM1.contract"
            || args[2] == "006-PsCARTHA.contract"
            || args[2] == "007-PsDELPH1.contract"
            || args[2] == "008-PtEdo2Zk.contract"
            || args[2] == "009-PsFLoren.contract"
            || args[2] == "010-PtGRANAD.contract"
            || args[2] == "011-PtHangz2.contract"
            || args[2] == "012-Psithaca.contract"
            || args[2] == "013-PtJakart.contract"
            || args[2] == "014-PtKathma.contract"
            || args[2] == "015-PtLimaPt.contract"
            || args[2] == "016-PtMumbai.contract"
            || args[2] == "017-PtNairob.contract"
            || args[2] == "alpha.contract"
            || args[2] == "contract")
        && args[3] == "from";
}

fn decode_contract(args: &Vec<String>) {
    for arg in &args[4..] {
        let hex: Result<HexString, _> = HexString::new(arg.to_string());
        match hex {
            Ok(hex) => {
                let bin_addr: Result<Address, _> =
                    <AddressBytesCoder as Decoder<Address, [u8], Error>>::decode(
                        hex.to_bytes().as_slice(),
                    );
                match bin_addr {
                    Ok(addr) => {
                        println!("\"{}\"", addr.value());
                    }
                    Err(error) => {
                        println!("Error: {}", error);
                    }
                }
            }
            Err(error) => {
                println!("Error: {}", error);
            }
        }
    }
}

fn encode_contract(args: &Vec<String>) {
    for arg in &args[4..] {
        if arg.starts_with('"') && arg.ends_with('"') {
            let addr: Result<Address, _> = Address::try_from((&arg[1..arg.len() - 1]).to_string());
            match addr {
                Ok(addr) => {
                    let hex_addr: Result<Vec<u8>, _> = <Address as Encoded>::to_bytes(&addr);
                    match hex_addr {
                        Ok(addr) => {
                            for byte in &addr {
                                print!("{:02x}", byte);
                            }
                            println!();
                        }
                        Err(error) => {
                            println!("Error: {}", error);
                        }
                    }
                }
                Err(error) => {
                    println!("Error: {}", error);
                }
            }
        } else {
            println!("Error: JSON.of_buffer illegal literal ({})", arg);
        }
    }
}

fn is_case_integer(args: &Vec<String>) -> bool {
    return args.len() >= 5
        && (args[2] == "ground.int16"
            || args[2] == "ground.int31"
            || args[2] == "ground.int32"
            || args[2] == "ground.int64"
            || args[2] == "ground.int8"
            || args[2] == "ground.uint16"
            || args[2] == "ground.uint8")
        && args[3] == "from";
}

fn decode_integer(args: &Vec<String>) {
    for arg in &args[4..] {
        // let hex: Result<HexString, _> = HexString::new(arg.to_string());
        // match hex {
        //     Ok(hex) => {
        //         let bin_addr: Result<Address, _> =
        //             <AddressBytesCoder as Decoder<Address, [u8], Error>>::decode(
        //                 hex.to_bytes().as_slice()
        //             );
        //         match bin_addr {
        //             Ok(addr) => {
        //                 println!("\"{}\"", addr.value());
        //             }
        //             Err(error) => {
        //                 println!("Error: {}", error);
        //             }
        //         }
        //     }
        //     Err(error) => {
        //         println!("Error: {}", error);
        //     }
        // }

        let hex: Result<HexString, _> = HexString::new(arg.to_string());
        match hex {
            Ok(hex) => {
                let bytes: Vec<u8> = hex.to_bytes();
                let i: Result<Int, _> = IntegerBytesCoder::decode(&bytes);
                // let b : Vec<u8> = arg.clone().into_bytes();
                // let i : Result<Int, _> = IntegerBytesCoder::decode(&b);
                match i {
                    Ok(i) => {
                        println!("{}", i.to_str());
                    }
                    Err(error) => {
                        println!("Error (cannot decode): {}", error);
                    }
                }
            }
            Err(error) => {
                println!("Error (wrong format): {}", error);
            }
        }
    }
}

fn encode_integer(args: &Vec<String>) {
    for arg in &args[4..] {
        let addr: Result<Address, _> = Address::try_from((&arg[1..arg.len() - 1]).to_string());
        match addr {
            Ok(addr) => {
                let hex_addr: Result<Vec<u8>, _> = <Address as Encoded>::to_bytes(&addr);
                match hex_addr {
                    Ok(addr) => {
                        for byte in &addr {
                            print!("{:02x}", byte);
                        }
                        println!();
                    }
                    Err(error) => {
                        println!("Error: {}", error);
                    }
                }
            }
            Err(error) => {
                println!("Error: {}", error);
            }
        }
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();

    // let case_list_encodings : bool = args.len() > 2 && args[1] == "list" && args[2] == "encodings";
    let case_encode = args.len() >= 5 && args[1] == "encode";
    let case_decode = args.len() >= 5 && args[1] == "decode";
    let case_integer = args.len() >= 5 && is_case_integer(&args);
    let case_contract = is_case_contract(&args);

    if case_decode {
        if case_contract {
            decode_contract(&args);
        }
        if case_integer {
            decode_integer(&args);
        }
    }

    if case_encode {
        if case_contract {
            encode_contract(&args);
        }
        if case_integer {
            encode_integer(&args);
        }
    }
}
