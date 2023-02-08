(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 TriliTech, <contact@trili.tech>                        *)
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

module Plugin = struct
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

  module Protocol_reveal_hash = Protocol.Sc_rollup_reveal_hash
  module Proto = Registerer.Registered
  module RPC = RPC

  let serialize_payload cctxt dac_sk_uris reveal_data_dir
      (data, pagination_scheme) =
    let open Lwt_result_syntax in
    let open Dac_pages_encoding in
    let page_store = reveal_data_dir in
    let pagination_scheme =
      if String.equal pagination_scheme "Merkle_tree_V0" then Merkle_tree_V0
      else Hash_chain_V0
    in
    let* root_hash =
      Lwt.map Environment.wrap_tzresult
      @@
      match pagination_scheme with
      | Merkle_tree_V0 -> Merkle_tree.V0.serialize_payload ~page_store data
      | Hash_chain_V0 ->
          Hash_chain.V0.serialize_payload
            ~for_each_page:(fun (hash, content) ->
              Dac_preimage_data_manager.Reveal_hash.save_bytes
                page_store
                hash
                content)
            data
    in
    let* signature, witnesses =
      Lwt.map Environment.wrap_tzresult
      @@ Dac_manager.Reveal_hash.Signatures.sign_root_hash
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
      | Error _ -> error Cannot_construct_external_message
    in
    return (root_hash, external_message)
end

let () = Dac_plugin.register (module Plugin)
