let strip_0x s =
  if String.starts_with ~prefix:"0x" s then
    let n = String.length s in
    String.sub s 2 (n - 2)
  else s

module Signer = struct
  let path = "node"

  let sign chainId from to_ value nonce =
    let gasLimit = Z.format "#x" (Z.of_int 21000) in
    let gasPrice = Z.format "#x" (Z.of_int 21000) in
    let value = Z.format "#x" (Wei.of_eth_int value |> Wei.of_wei_z) in
    let tx_json =
      `O
        [
          ("to", `String to_);
          ("value", `String value);
          ("gasLimit", `String gasLimit);
          ("gasPrice", `String gasPrice);
          ("nonce", `Float (float_of_int nonce));
          ("data", `String "");
          ("chainId", `Float (float_of_int chainId));
        ]
    in
    let* output =
      Process.spawn
        path
        [
          "src/bin_evm_proxy/generator/signer.js";
          JSON.encode_u tx_json;
          strip_0x from;
        ]
      |> Process.check_and_read_stdout
    in
    return ("0x" ^ String.trim output)
end

let generate_signed_transactions chainId number_of_txs =
  let from = Eth_account.bootstrap_accounts.(0).private_key in
  let to_ = Eth_account.bootstrap_accounts.(1).address in
  let nonces = List.init number_of_txs Fun.id in
  Lwt_list.map_s (Signer.sign chainId from to_ 1) nonces

let generate_evm_rollup_transactions smart_rollup_address chainId number_of_txs
    =
  let open Evm_proxy_lib in
  let build_message tx =
    let msgs =
      Rollup_node.make_encoded_messages
        ~smart_rollup_address
        (Hash (Ethereum_types.strip_0x tx))
    in
    Result.get_ok msgs |> snd
  in
  let* txs = generate_signed_transactions chainId number_of_txs in
  let msgs = List.map build_message txs |> List.flatten in
  return msgs

let encode_for_debugger msgs =
  let exts =
    List.map (fun msg -> `O [("external", `String (strip_0x msg))]) msgs
  in
  `A [`A exts]

let zero_address =
  Tezos_crypto.Hashed.Smart_rollup_address.(zero |> to_b58check)

let encode_address address =
  let open Tezos_crypto.Hashed.Smart_rollup_address in
  let s = of_b58check_exn address in
  to_string s

let () =
  Background.start (fun e -> raise e) ;
  let rollup =
    Cli.get_string ~default:zero_address "rollup-address" |> encode_address
  in
  let number_of_txs = Cli.get_int ~default:100 "number-of-txs" in
  let raw_txs = Cli.get_bool ~default:false "raw" in
  let chain_id = Cli.get_int ~default:1337 "chain-id" in
  let msgs =
    Lwt_main.run
      (generate_evm_rollup_transactions rollup chain_id number_of_txs)
  in
  if raw_txs then List.iter (Format.printf "%s\n") msgs
  else Format.printf "%s\n%!" (JSON.encode_u (encode_for_debugger msgs))
