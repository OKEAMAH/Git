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

let sequencer_prefix = "/__sequencer"

module Delayed_inbox = struct
  let path = String.concat "/" [sequencer_prefix; "delayed-inbox"]

  module Pointer = struct
    let path = String.concat "/" [path; "pointer"]

    type t = {head : int32; tail : int32}

    let empty = {head = 0l; tail = -1l}

    let size x = Int32.(succ @@ sub x.tail x.head)

    let encoding =
      let open Data_encoding in
      conv (fun {head; tail} -> (head, tail)) (fun (head, tail) -> {head; tail})
      @@ obj2 (req "head" int32) (req "tail" int32)
  end

  module Element = struct
    let path element_id =
      String.concat "/" [path; "elements"; Int32.to_string element_id]

    type t = {timeout_level : int32; user_message : string}

    let encoding =
      let open Data_encoding in
      conv
        (fun {timeout_level; user_message} -> (timeout_level, user_message))
        (fun (timeout_level, user_message) -> {timeout_level; user_message})
      @@ obj2 (req "timeout_level" int32) (req "user_message" Variable.string)
  end
end

module Durable_state = struct
  module Durable_state = Wasm_2_0_0_pvm.Durable_state

  (* User state is supposed to be stored in the root, so no additional prefixes needed *)
  let lookup_user_kernel ctxt_tree key = Durable_state.lookup ctxt_tree key

  (* User state is supposed to be stored in the root, so no additional prefixes needed *)
  let list_user_kernel ctxt_tree key = Durable_state.list ctxt_tree key

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
end

let context_of node_ctxt (at : Layer1.head) =
  let open Lwt_result_syntax in
  let*? level = Environment.wrap_tzresult @@ Raw_level.of_int32 at.level in
  let first_inbox_level =
    Raw_level.succ node_ctxt.Node_context.genesis_info.level
  in
  if Raw_level.(level < first_inbox_level) then
    (* This is before we have interpreted the boot sector, so we start
       with an empty context in genesis *)
    return (Context.empty node_ctxt.context)
  else Node_context.checkout_context node_ctxt at.hash

let get_delayed_inbox_pointer node_ctxt (at : Layer1.head) =
  let open Lwt_result_syntax in
  let* ctxt = context_of node_ctxt at in
  let* _ctxt, state = Interpreter.state_of_head node_ctxt ctxt at in
  let*! pointer = Durable_state.lookup_queue_pointer state in
  return pointer

let get_previous_delayed_inbox_pointer node_ctxt (head : Layer1.head) =
  let open Lwt_result_syntax in
  let*? level = Environment.wrap_tzresult @@ Raw_level.of_int32 head.level in
  let*? () =
    error_unless
      Raw_level.(level >= node_ctxt.Node_context.genesis_info.level)
      (Exn (Failure "Cannot obtain delayed inbox before origination level"))
  in
  let* previous_head = Node_context.get_predecessor node_ctxt head in
  get_delayed_inbox_pointer node_ctxt previous_head

type queue_slice = {
  pointer : Delayed_inbox.Pointer.t;
  elements : Sc_rollup.Inbox_message.serialized list;
}

(* Returns newly added elements in the delayed inbox
   at block corresponding to the passed head. *)
let get_delayed_inbox_diff node_ctxt (head : Layer1.head) =
  let open Lwt_result_syntax in
  let*? level = Environment.wrap_tzresult @@ Raw_level.of_int32 head.level in
  if Raw_level.(level < node_ctxt.Node_context.genesis_info.level) then
    tzfail
      (Exn
         (Failure
            (Format.asprintf
               "Cannot obtain delayed inbox difference for level %a"
               Raw_level.pp
               level)))
  else if Raw_level.(level = node_ctxt.Node_context.genesis_info.level) then
    return {pointer = Delayed_inbox.Pointer.empty; elements = []}
  else
    let* previous_head = Node_context.get_predecessor node_ctxt head in
    let* previous_pointer = get_delayed_inbox_pointer node_ctxt previous_head in
    let* current_pointer = get_delayed_inbox_pointer node_ctxt head in
    let new_block_head = Int32.succ previous_pointer.tail in
    let new_block_tail = current_pointer.tail in
    let size = Int32.(to_int new_block_tail - to_int new_block_head + 1) in
    let* ctxt = context_of node_ctxt head in
    let* _ctxt, state = Interpreter.state_of_head node_ctxt ctxt head in
    let+ elements =
      List.init_ep
        ~when_negative_length:
          (Exn
             (Failure "Unexpected negative length of delayed inbox difference"))
        size
        (fun i ->
          let element_id = Int32.(add (of_int i) new_block_head) in
          let*! opt_el = Durable_state.lookup_queue_element state element_id in
          match opt_el with
          | None ->
              tzfail
              @@ Exn
                   (Failure
                      (Format.asprintf
                         "Couldn't obtain delayed inbox element with index %ld"
                         element_id))
          | Some el -> return @@ Sc_rollup.Inbox_message.unsafe_of_string el)
    in
    {
      pointer =
        Delayed_inbox.Pointer.{head = new_block_head; tail = new_block_tail};
      elements;
    }
