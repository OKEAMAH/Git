(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

(* This type mimics [Sc_rollup_inbox_repr.internal_inbox_messages], without
   fully deserializing the `Deposit`, and is produced by reading the first bytes
   from the input:

   - `\000\000` corresponds to a deposit,
   - `\000\001` a start_of_level,
   - `\000\002` an end_of_level.
   - Any other tag will considered as an `Other message`. *)
type internal_message_kind = Deposit | Start_of_level | End_of_level

(* This type mimics [Sc_rollup_inbox_repr.t] and produced by reading the first
   bytes from the input:

   - `\000` corresponds to an internal message,
   - `\001` an external one, and its content includes the tag.
   - Any other tag is considered as an `Other message`. *)
type t = Internal of internal_message_kind | External | Other

let internal_from_raw payload =
  if Bytes.length payload < 2 then None
  else
    match Bytes.get payload 1 with
    | '\000' -> Some Deposit
    | '\001' when Bytes.length payload = 2 -> Some Start_of_level
    | '\002' when Bytes.length payload = 2 -> Some End_of_level
    | _ -> None

let from_raw_input payload =
  if Bytes.length payload < 1 then Other
  else
    match Bytes.get payload 0 with
    | '\000' ->
        Option.fold
          ~none:Other
          ~some:(fun msg -> Internal msg)
          (internal_from_raw payload)
    | '\001' -> External
    | _ -> Other

module Internal_for_tests = struct
  let prefix_message prefix message =
    let len_prefix = String.length prefix in
    Bytes.init (Bytes.length message + len_prefix) @@ fun index ->
    if index < len_prefix then String.get prefix index
    else Bytes.get message (index - len_prefix)

  let to_binary_input input message =
    match (input, message) with
    | Internal Deposit, Some message -> prefix_message "\000\000" message
    | External, Some message -> prefix_message "\001" message
    | Internal Start_of_level, None -> Bytes.of_string "\000\001"
    | Internal End_of_level, None -> Bytes.of_string "\000\002"
    | Other, _ ->
        Stdlib.failwith
          "`Other` messages are impossible cases from the PVM perspective."
    | Internal (Start_of_level | End_of_level), Some _ ->
        Stdlib.failwith
          "`Start_of_level` and `End_of_level` do not expect a payload"
    | Internal Deposit, None -> Stdlib.failwith "`Deposit` expects a payload"
    | External, None -> Stdlib.failwith "`External` expects a payload"
end
