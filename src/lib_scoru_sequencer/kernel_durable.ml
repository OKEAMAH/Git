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
