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

type error += Cannot_construct_external_message

let () =
  register_error_kind
    `Permanent
    ~id:"dac_cannot_construct_external_message"
    ~title:"External rollup message could not be constructed"
    ~description:"External rollup message could not be constructed"
    ~pp:(fun ppf () ->
      Format.fprintf ppf "External rollup message could not be constructed")
    Data_encoding.unit
    (function Cannot_construct_external_message -> Some () | _ -> None)
    (fun () -> Cannot_construct_external_message)

module Registration = struct
  let register0_noctxt ~chunked s f dir =
    RPC_directory.register ~chunked dir s (fun _rpc_ctxt q i -> f q i)
end

module DAC = struct
  module Hash_storage = Dac_preimage_data_manager.Reveal_hash

  let store_preimage_request_encoding =
    Data_encoding.(
      obj2
        (req "payload" Data_encoding.(bytes Hex))
        (req "pagination_scheme" Dac_pages_encoding.pagination_scheme_encoding))

  let store_preimage_response_encoding =
    Data_encoding.(
      obj2
        (req "root_hash" Protocol.Sc_rollup_reveal_hash.encoding)
        (req "external_message" (bytes Hex)))

  module S = struct
    let dac_store_preimage =
      RPC_service.put_service
        ~description:"Split DAC reveal data"
        ~query:RPC_query.empty
        ~input:store_preimage_request_encoding
        ~output:store_preimage_response_encoding
        RPC_path.(open_root / "dac" / "store_preimage")
  end

  let handle_serialize_dac_store_preimage cctxt dac_sk_uris reveal_data_dir
      (data, pagination_scheme) =
    let open Lwt_result_syntax in
    let open Dac_pages_encoding in
    let for_each_page (hash, page_contents) =
      Dac_manager.Reveal_hash.Storage.save_bytes
        reveal_data_dir
        hash
        page_contents
    in
    let* root_hash =
      match pagination_scheme with
      | Merkle_tree_V0 ->
          let size =
            Protocol.Alpha_context.Constants.sc_rollup_message_size_limit
          in
          Merkle_tree.V0.serialize_payload
            ~max_page_size:size
            data
            ~for_each_page
      | Hash_chain_V0 -> Hash_chain.V0.serialize_payload ~for_each_page data
    in
    let* signature, witnesses =
      Dac_manager.Reveal_hash.Signatures.sign_root_hash
        cctxt
        dac_sk_uris
        root_hash
    in
    let*? external_message =
      match
        Dac_manager.Reveal_hash.External_message.make
          root_hash
          signature
          witnesses
      with
      | Ok external_message -> Ok external_message
      | Error _ -> Error_monad.error Cannot_construct_external_message
    in
    return (root_hash, external_message)

  let register_serialize_dac_store_preimage cctxt dac_sk_uris reveal_data_dir =
    Registration.register0_noctxt
      ~chunked:false
      S.dac_store_preimage
      (fun () input ->
        handle_serialize_dac_store_preimage
          cctxt
          dac_sk_uris
          reveal_data_dir
          input)

  let register reveal_data_dir cctxt _dac_public_keys_opt dac_sk_uris =
    (RPC_directory.empty : unit RPC_directory.t)
    |> register_serialize_dac_store_preimage cctxt dac_sk_uris reveal_data_dir
end

let rpc_services ~reveal_data_dir cctxt dac_public_keys_opt dac_sk_uris
    _threshold =
  DAC.register reveal_data_dir cctxt dac_public_keys_opt dac_sk_uris
