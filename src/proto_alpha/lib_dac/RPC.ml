(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Trili Tech  <contact@trili.tech>                       *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

open Environment
open Error_monad

type error += Cannot_deserialize_external_message

let () =
  register_error_kind
    `Permanent
    ~id:"dac_cannot_deserialize_rollup_external_message"
    ~title:"External rollup message could not be deserialized"
    ~description:"External rollup message could not be deserialized"
    ~pp:(fun ppf () ->
      Format.fprintf ppf "External rollup message could not be deserialized")
    Data_encoding.unit
    (function Cannot_deserialize_external_message -> Some () | _ -> None)
    (fun () -> Cannot_deserialize_external_message)

module Registration = struct
  let register0_noctxt ~chunked s f dir =
    RPC_directory.register ~chunked dir s (fun _rpc_ctxt q i -> f q i)
end

module DAC = struct
  let external_message_query =
    let open RPC_query in
    query (fun hex_string -> hex_string)
    |+ opt_field "external_message" RPC_arg.string (fun s -> s)
    |> seal

  module S = struct
    (* DAC/FIXME: https://gitlab.com/tezos/tezos/-/issues/4263
       remove this endpoint once end-to-end tests are in place. *)
    let verify_external_message_signature =
      RPC_service.get_service
        ~description:"Verify signature of an external message to inject in L1"
        ~query:external_message_query
        ~output:Data_encoding.bool
        RPC_path.(open_root / "verify_signature")
  end

  let handle_verify_external_message_signature public_keys_opt
      encoded_l1_message =
    let open Lwt_result_syntax in
    let open Dac_manager.Reveal_hash in
    let external_message =
      let open Option_syntax in
      let* encoded_l1_message in
      let* as_bytes = Hex.to_bytes @@ `Hex encoded_l1_message in
      External_message.of_bytes as_bytes
    in
    match external_message with
    | None -> tzfail @@ Cannot_deserialize_external_message
    | Some (External_message.Dac_message {root_hash; signature; witnesses}) ->
        Signatures.verify ~public_keys_opt root_hash signature witnesses

  let register_verify_external_message_signature public_keys_opt =
    Registration.register0_noctxt
      ~chunked:false
      S.verify_external_message_signature
      (fun external_message () ->
        handle_verify_external_message_signature
          public_keys_opt
          external_message)

  let register _reveal_data_dir _cctxt dac_public_keys_opt _dac_sk_uris =
    (RPC_directory.empty : unit RPC_directory.t)
    |> register_verify_external_message_signature dac_public_keys_opt
end

let rpc_services ~reveal_data_dir cctxt dac_public_keys_opt dac_sk_uris
    _threshold =
  DAC.register reveal_data_dir cctxt dac_public_keys_opt dac_sk_uris
