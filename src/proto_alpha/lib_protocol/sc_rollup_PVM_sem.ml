(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.tech>                       *)
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

type inbox_input = {
  payload : Sc_rollup_inbox_message_repr.serialized;
  message_counter : Z.t;
}

type dal_input = {
  content : Dal_slot_repr.Page.content;
  page : Dal_slot_repr.Page.t;
  last_page : bool;
}

type raw_input = Inbox_input of inbox_input | Dal_input of dal_input

(* FIXME: https://gitlab.com/tezos/tezos/-/issues/3649

   This type cannot be extended in a retro-compatible way. It should
   be put into a variant. *)
type input = {inbox_level : Raw_level_repr.t; raw_input : raw_input}

let raw_input_encoding =
  let open Data_encoding in
  union
    ~tag_size:`Uint8
    [
      case
        ~title:"Inbox_input"
        (Tag 0)
        (obj3
           (req "kind" (constant "inbox"))
           (req "message" string)
           (req "message_counter" n))
        (function
          | Inbox_input {payload; message_counter} ->
              Some ((), (payload :> string), message_counter)
          | _ -> None)
        (fun ((), payload, message_counter) ->
          let payload = Sc_rollup_inbox_message_repr.unsafe_of_string payload in
          Inbox_input {payload; message_counter});
      case
        ~title:"Dal_input"
        (Tag 1)
        (obj4
           (req "kind" (constant "dal"))
           (req "content" bytes)
           (req "page" Dal_slot_repr.Page.encoding)
           (req "last_page" bool))
        (function
          | Dal_input {content; page; last_page} ->
              Some ((), content, page, last_page)
          | _ -> None)
        (fun ((), content, page, last_page) ->
          Dal_input {content; page; last_page});
    ]

let input_encoding =
  let open Data_encoding in
  conv
    (fun {inbox_level; raw_input} -> (inbox_level, raw_input))
    (fun (inbox_level, raw_input) -> {inbox_level; raw_input})
    (obj2
       (req "inbox_level" Raw_level_repr.encoding)
       (req "raw_input" raw_input_encoding))

let raw_input_equal a b =
  match (a, b) with
  | Inbox_input {payload; message_counter}, Inbox_input i ->
      String.equal (payload :> string) (i.payload :> string)
      && Z.equal message_counter i.message_counter
  | Dal_input {content; page; last_page}, Dal_input d ->
      Bytes.equal content d.content
      && Dal_slot_repr.Page.equal page d.page
      && Compare.Bool.equal last_page d.last_page
  | _ -> false

let input_equal (a : input) (b : input) : bool =
  let {inbox_level; raw_input} = a in
  (* To be robust to the addition of fields in [input] *)
  Raw_level_repr.equal inbox_level b.inbox_level
  && raw_input_equal raw_input b.raw_input

type input_position = Inbox_counter of Z.t | Dal_page of Dal_slot_repr.Page.t

let pp_input_position fmt = function
  | Inbox_counter n -> Format.fprintf fmt "Inbox (counter: %a)" Z.pp_print n
  | Dal_page p -> Format.fprintf fmt "DAL (page: %a)" Dal_slot_repr.Page.pp p

let input_position_encoding =
  let open Data_encoding in
  union
    ~tag_size:`Uint8
    [
      case
        ~title:"Inbox_counter"
        (Tag 0)
        (obj2 (req "kind" (constant "inbox")) (req "message_counter" n))
        (function
          | Inbox_counter message_counter -> Some ((), message_counter)
          | _ -> None)
        (fun ((), message_counter) -> Inbox_counter message_counter);
      case
        ~title:"Dal_page"
        (Tag 1)
        (obj2
           (req "kind" (constant "dal"))
           (req "page" Dal_slot_repr.Page.encoding))
        (function Dal_page page -> Some ((), page) | _ -> None)
        (fun ((), page) -> Dal_page page);
    ]

let input_position_equal a b =
  match (a, b) with
  | Inbox_counter a, Inbox_counter b -> Z.equal a b
  | Dal_page a, Dal_page b -> Dal_slot_repr.Page.equal a b
  | _ -> false

type input_request =
  | No_input_required
  | Initial
  | First_after of Raw_level_repr.t * input_position

let input_request_encoding =
  let open Data_encoding in
  union
    ~tag_size:`Uint8
    [
      case
        ~title:"No_input_required"
        (Tag 0)
        (obj1 (req "kind" (constant "no_input_required")))
        (function No_input_required -> Some () | _ -> None)
        (fun () -> No_input_required);
      case
        ~title:"Initial"
        (Tag 1)
        (obj1 (req "kind" (constant "initial")))
        (function Initial -> Some () | _ -> None)
        (fun () -> Initial);
      case
        ~title:"First_after"
        (Tag 2)
        (obj3
           (req "kind" (constant "first_after"))
           (req "level" Raw_level_repr.encoding)
           (req "input_position" input_position_encoding))
        (function
          | First_after (level, input_pos) -> Some ((), level, input_pos)
          | _ -> None)
        (fun ((), level, input_pos) -> First_after (level, input_pos));
    ]

let pp_input_request fmt request =
  match request with
  | No_input_required -> Format.fprintf fmt "No_input_required"
  | Initial -> Format.fprintf fmt "Initial"
  | First_after (l, p) ->
      Format.fprintf
        fmt
        "First_after (level = %a, input_position = %a)"
        Raw_level_repr.pp
        l
        pp_input_position
        p

let input_request_equal a b =
  match (a, b) with
  | No_input_required, No_input_required -> true
  | No_input_required, _ -> false
  | Initial, Initial -> true
  | Initial, _ -> false
  | First_after (l, n), First_after (m, o) ->
      Raw_level_repr.equal l m && input_position_equal n o
  | First_after _, _ -> false

type output = {
  outbox_level : Raw_level_repr.t;
  message_index : Z.t;
  message : Sc_rollup_outbox_message_repr.t;
}

let output_encoding =
  let open Data_encoding in
  conv
    (fun {outbox_level; message_index; message} ->
      (outbox_level, message_index, message))
    (fun (outbox_level, message_index, message) ->
      {outbox_level; message_index; message})
    (obj3
       (req "outbox_level" Raw_level_repr.encoding)
       (req "message_index" n)
       (req "message" Sc_rollup_outbox_message_repr.encoding))

let pp_output fmt {outbox_level; message_index; message} =
  Format.fprintf
    fmt
    "@[%a@;%a@;%a@;@]"
    Raw_level_repr.pp
    outbox_level
    Z.pp_print
    message_index
    Sc_rollup_outbox_message_repr.pp
    message

module type S = sig
  type state

  val pp : state -> (Format.formatter -> unit -> unit) Lwt.t

  type context

  type hash = Sc_rollup_repr.State_hash.t

  type proof

  val proof_encoding : proof Data_encoding.t

  val proof_start_state : proof -> hash

  val proof_stop_state : proof -> hash option

  val proof_input_requested : proof -> input_request

  val proof_input_given : proof -> input option

  val state_hash : state -> hash Lwt.t

  val initial_state : context -> state Lwt.t

  val install_boot_sector : state -> string -> state Lwt.t

  val is_input_state : state -> input_request Lwt.t

  val set_input : input -> state -> state Lwt.t

  val eval : state -> state Lwt.t

  val verify_proof : proof -> bool Lwt.t

  val produce_proof :
    context -> input option -> state -> (proof, error) result Lwt.t

  val verify_origination_proof : proof -> string -> bool Lwt.t

  val produce_origination_proof :
    context -> string -> (proof, error) result Lwt.t

  type output_proof

  val output_proof_encoding : output_proof Data_encoding.t

  val output_of_output_proof : output_proof -> output

  val state_of_output_proof : output_proof -> hash

  val verify_output_proof : output_proof -> bool Lwt.t

  val produce_output_proof :
    context -> state -> output -> (output_proof, error) result Lwt.t

  module Internal_for_tests : sig
    val insert_failure : state -> state Lwt.t
  end
end
