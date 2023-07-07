(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022-2023 TriliTech <contact@trili.tech>                    *)
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

open Protocol
open Alpha_context
open Octez_smart_rollup_node_alpha
open Kernel_durable
module Durable_state = Wasm_2_0_0_pvm.Durable_state

(* User state is supposed to be stored under /u *)
let lookup_user_kernel ctxt_tree key =
  Durable_state.lookup ctxt_tree @@ "/u" ^ key

(* User state is supposed to be stored under /u *)
let list_user_kernel ctxt_tree key = Durable_state.list ctxt_tree @@ "/u" ^ key

let lookup_queue_pointer ctxt_tree =
  let open Lwt_syntax in
  let* pointer_bytes =
    Durable_state.lookup ctxt_tree Delayed_inbox.Pointer.path
  in
  match pointer_bytes with
  | None -> return Delayed_inbox.Pointer.empty
  | Some pointer_bytes ->
      return
      @@ Option.value ~default:Delayed_inbox.Pointer.empty
      @@ Data_encoding.Binary.of_bytes_opt
           Delayed_inbox.Pointer.encoding
           pointer_bytes

let lookup_queue_element ctxt_tree element_id =
  let open Lwt_syntax in
  let* element =
    Durable_state.lookup ctxt_tree @@ Delayed_inbox.Element.path element_id
  in
  Lwt.return
  @@ Option.bind element (fun el_bytes ->
         Option.map (fun x -> x.Delayed_inbox.Element.user_message)
         @@ Data_encoding.Binary.of_bytes_opt
              Delayed_inbox.Element.encoding
              el_bytes)

let context_of node_ctxt (head : Layer1.head) =
  let open Lwt_result_syntax in
  if head.level < node_ctxt.Node_context.genesis_info.level then
    (* This is before we have interpreted the boot sector, so we start
       with an empty context in genesis *)
    return (Context.empty node_ctxt.context)
  else Node_context.checkout_context node_ctxt head.hash

let get_delayed_inbox_pointer node_ctxt (at : Layer1.head) =
  let open Lwt_result_syntax in
  let* ctxt = context_of node_ctxt at in
  let* _ctxt, state = Interpreter.state_of_head node_ctxt ctxt at in
  let*! pointer = lookup_queue_pointer state in
  return pointer

let get_pointer_elements state (p : Delayed_inbox.Pointer.t) =
  let open Lwt_result_syntax in
  let size = Int32.to_int @@ Delayed_inbox.Pointer.size p in
  List.init_ep
    ~when_negative_length:
      (Exn (Failure "Unexpected negative length of delayed inbox difference"))
    size
    (fun i ->
      let element_id = Int32.(add (of_int i) p.head) in
      let*! opt_el = lookup_queue_element state element_id in
      match opt_el with
      | None ->
          tzfail
          @@ Exn
               (Failure
                  (Format.asprintf
                     "Couldn't obtain delayed inbox element with index %ld"
                     element_id))
      | Some el -> return @@ Sc_rollup.Inbox_message.unsafe_of_string el)

let get_previous_delayed_inbox_pointer node_ctxt (head : Layer1.head) =
  let open Lwt_result_syntax in
  let*? () =
    error_unless
      (head.level >= node_ctxt.Node_context.genesis_info.level)
      (Exn (Failure "Cannot obtain delayed inbox before origination level"))
  in
  let* previous_head = Node_context.get_predecessor node_ctxt head in
  get_delayed_inbox_pointer node_ctxt previous_head

(* Returns newly added elements in the delayed inbox
   at block corresponding to the passed head. *)
let get_delayed_inbox_diff node_ctxt (head : Layer1.head) =
  let open Lwt_result_syntax in
  let level = head.level in
  if head.level < node_ctxt.Node_context.genesis_info.level then
    tzfail
      (Exn
         (Failure
            (Format.asprintf
               "Cannot obtain delayed inbox difference for level %ld"
               level)))
  else if level = node_ctxt.Node_context.genesis_info.level then
    return Delayed_inbox.{pointer = Delayed_inbox.Pointer.empty; elements = []}
  else
    let* previous_head = Node_context.get_predecessor node_ctxt head in
    let* previous_pointer = get_delayed_inbox_pointer node_ctxt previous_head in
    let* current_pointer = get_delayed_inbox_pointer node_ctxt head in
    let new_block_head = Int32.succ previous_pointer.tail in
    let new_block_tail = current_pointer.tail in
    let* ctxt = context_of node_ctxt head in
    let* _ctxt, state = Interpreter.state_of_head node_ctxt ctxt head in
    let pointer =
      Delayed_inbox.Pointer.{head = new_block_head; tail = new_block_tail}
    in
    let+ elements = get_pointer_elements state pointer in
    Delayed_inbox.{pointer; elements}
