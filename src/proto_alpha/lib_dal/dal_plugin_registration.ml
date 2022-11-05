(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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
  module Proto = Registerer.Registered

  let get_constants chain block ctxt =
    let cpctxt = new Protocol_client_context.wrap_full ctxt in
    let open Lwt_result_syntax in
    let* constants = Protocol.Constants_services.all cpctxt (chain, block) in
    return constants.parametric.dal.cryptobox_parameters

  let get_published_slot_headers block ctxt =
    let open Lwt_result_syntax in
    let open Protocol.Alpha_context in
    let cpctxt = new Protocol_client_context.wrap_full ctxt in
    let* block =
      Protocol_client_context.Alpha_block_services.info
        cpctxt
        ~block
        ~metadata:`Always
        ()
    in
    let apply_internal acc ~source:_ _op _res = acc in
    let apply (type kind) acc ~source:_ (op : kind manager_operation) _res =
      match op with
      | Dal_publish_slot_header {slot_header} -> slot_header :: acc
      | _ -> acc
    in
    Layer1_services.(
      process_manager_operations [] block.operations {apply; apply_internal})
    |> List.map_es (fun slot ->
           return
             ( Dal.Slot_index.to_int slot.Dal.Slot.Header.id.index,
               slot.Dal.Slot.Header.commitment ))

  let serialize_dac_reveal_data ~max_page_size data ~for_each_page =
    let open Lwt_result_syntax in
    let+ rh =
      Dac_pages_encoding.Merkle_tree.V0.serialize_payload
        ~max_page_size
        data
        ~for_each_page
    in
    Protocol.Sc_rollup_PVM_sig.Reveal_hash.(to_b58check rh, to_bytes rh)

  let recover_dac_reveal_data b58_root_hash ~retrieve_page_from_hash =
    let open Lwt_result_syntax in
    let open Protocol in
    let root_hash =
      Sc_rollup_PVM_sig.Reveal_hash.of_b58check_exn b58_root_hash
    in
    let+ payload =
      Dac_pages_encoding.Merkle_tree.V0.deserialize_payload
        root_hash
        ~retrieve_page_from_hash
    in
    payload

  let sc_rollup_message_size_limit =
    Protocol.Alpha_context.Constants.sc_rollup_message_size_limit

  let b58_rollup_address_to_bytes b58_sc_rollup_address =
    let open Protocol.Alpha_context.Sc_rollup.Address in
    b58_sc_rollup_address |> of_b58check_opt |> Option.map to_bytes
end

let () = Dal_plugin.register (module Plugin)
