(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2022 Marigold, <contact@marigold.dev>                       *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxhead-alpha.com>                   *)
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

open Protocol.Alpha_context
open Protocol.Apply_results
open Protocol_client_context
module Block_hash_map = Map.Make (Block_hash)

type t = {store : Stores.t; context_index : Context.index}

let rollup_operation_index = 3

let set_new_head state hash = Stores.Tezos_head.set state.store hash

let get_head state = Stores.Tezos_head.find state.store

let context_hash state block_hash =
  Stores.Context_hashes.find state.store block_hash

let block_already_seen state hash = context_hash state hash

let find_inbox state hash = Stores.Inboxes.find state.store hash

let save_inbox state hash inbox =
  let store = state.store in
  let open Lwt_result_syntax in
  let*! previous_inbox = Stores.Inboxes.find state.store hash in
  match previous_inbox with
  | None -> Stores.Inboxes.add store hash inbox
  | Some x ->
      let inbox =
        Inbox.
          {
            contents = x.contents @ inbox.contents;
            cumulated_size = x.cumulated_size + inbox.cumulated_size;
          }
      in
      Stores.Inboxes.add store hash inbox

let save_context_hash state block_hash context_hash =
  Stores.Context_hashes.add state.store block_hash context_hash

let check_origination_in_block_info rollup block_info =
  let extract_originated_tx_rollup :
      type kind. kind manager_operation_result -> Tx_rollup.t option = function
    | Applied (Tx_rollup_origination_result {originated_tx_rollup; _}) ->
        Some originated_tx_rollup
    | _ -> None
  in
  let check_origination_content_result : type kind. kind contents_result -> bool
      = function
    | Manager_operation_result {operation_result; _} ->
        operation_result |> extract_originated_tx_rollup
        |> Option.fold ~none:false ~some:(Tx_rollup.equal rollup)
    | _ -> false
  in
  let rec check_origination_content_result_list :
      type kind. kind contents_result_list -> bool = function
    | Single_result x -> check_origination_content_result x
    | Cons_result (x, xs) ->
        check_origination_content_result x
        || check_origination_content_result_list xs
  in
  let managed_operation =
    List.nth_opt
      block_info.Alpha_block_services.operations
      rollup_operation_index
  in
  let check_receipt operation =
    match operation.Alpha_block_services.receipt with
    | Some (Operation_metadata {contents}) ->
        check_origination_content_result_list contents
    | Some No_operation_metadata | None -> false
  in
  match Option.bind managed_operation @@ List.find_opt check_receipt with
  | Some _ -> return_unit
  | None -> fail @@ Error.Tx_rollup_not_originated_in_the_given_block rollup

let init_store ~data_dir ~context ~rollup ~rollup_genesis =
  let open Lwt_result_syntax in
  let block = `Hash (rollup_genesis, 0) in
  let* block_info =
    Alpha_block_services.info context ~chain:context#chain ~block ()
  in
  let* () = check_origination_in_block_info rollup block_info in
  Stores.load (Node_data.store_dir data_dir)

let init_context ~data_dir =
  let open Lwt_result_syntax in
  let*! index = Context.init (Node_data.context_dir data_dir) in
  return index

let init ~data_dir ~context ~rollup ~rollup_genesis =
  let open Lwt_result_syntax in
  let store = init_store ~data_dir ~context ~rollup ~rollup_genesis in
  let context_index = init_context ~data_dir in
  let* store = store in
  let* context_index = context_index in
  return {store; context_index}
