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

    let is_adjacent left right =
      Compare.Int32.(Int32.succ left.tail = right.head)

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

  type queue_slice = {
    pointer : Pointer.t;
    elements : Sc_rollup.Inbox_message.serialized list;
  }
end

module Durable_state = struct
  module Durable_state = Wasm_2_0_0_pvm.Durable_state

  (* User state is supposed to be stored under /u *)
  let lookup_user_kernel ctxt_tree key =
    Durable_state.lookup ctxt_tree @@ "/u" ^ key

  (* User state is supposed to be stored under /u *)
  let list_user_kernel ctxt_tree key =
    Durable_state.list ctxt_tree @@ "/u" ^ key

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

let get_delayed_inbox_pointer node_ctxt (at : Layer1.head) =
  let open Lwt_result_syntax in
  let* _ctxt, state = Interpreter.state_of_head node_ctxt at in
  let*! pointer = Durable_state.lookup_queue_pointer state in
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
    return Delayed_inbox.{pointer = Delayed_inbox.Pointer.empty; elements = []}
  else
    let* previous_head = Node_context.get_predecessor node_ctxt head in
    let* previous_pointer = get_delayed_inbox_pointer node_ctxt previous_head in
    let* current_pointer = get_delayed_inbox_pointer node_ctxt head in
    let new_block_head = Int32.succ previous_pointer.tail in
    let new_block_tail = current_pointer.tail in
    let* _ctxt, state = Interpreter.state_of_head node_ctxt head in
    let pointer =
      Delayed_inbox.Pointer.{head = new_block_head; tail = new_block_tail}
    in
    let+ elements = get_pointer_elements state pointer in
    Delayed_inbox.{pointer; elements}
