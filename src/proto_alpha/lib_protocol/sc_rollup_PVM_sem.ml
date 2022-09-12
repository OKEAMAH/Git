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

(* FIXME: https://gitlab.com/tezos/tezos/-/issues/3649

   This type cannot be extended in a retro-compatible way. It should
   be put into a variant. *)
type inbox_message = {
  inbox_level : Raw_level_repr.t;
  message_counter : Z.t;
  payload : Sc_rollup_inbox_message_repr.serialized;
}

type input = Inbox_message of inbox_message | Preimage_revelation of string

let inbox_message_encoding =
  let open Data_encoding in
  conv
    (fun {inbox_level; message_counter; payload} ->
      (inbox_level, message_counter, (payload :> string)))
    (fun (inbox_level, message_counter, payload) ->
      let payload = Sc_rollup_inbox_message_repr.unsafe_of_string payload in
      {inbox_level; message_counter; payload})
    (obj3
       (req "inbox_level" Raw_level_repr.encoding)
       (req "message_counter" n)
       (req "payload" string))

let input_encoding =
  let open Data_encoding in
  let case_inbox_message =
    case
      ~title:"inbox msg"
      (Tag 0)
      inbox_message_encoding
      (function Inbox_message m -> Some m | _ -> None)
      (fun m -> Inbox_message m)
  and case_preimage_revelation =
    case
      ~title:"preimage"
      (Tag 1)
      string
      (function Preimage_revelation d -> Some d | _ -> None)
      (fun d -> Preimage_revelation d)
  in
  union [case_inbox_message; case_preimage_revelation]

let inbox_message_equal (a : inbox_message) (b : inbox_message) : bool =
  let {inbox_level; message_counter; payload} = a in
  (* To be robust to the addition of fields in [input] *)
  Raw_level_repr.equal inbox_level b.inbox_level
  && Z.equal message_counter b.message_counter
  && String.equal (payload :> string) (b.payload :> string)

let input_equal a b =
  match (a, b) with
  | Inbox_message a, Inbox_message b -> inbox_message_equal a b
  | Preimage_revelation a, Preimage_revelation b -> String.equal a b
  | _, _ -> false

module Input_hash =
  Blake2B.Make
    (Base58)
    (struct
      let name = "Sc_rollup_input_hash"

      let title = "A smart contract rollup input hash"

      let b58check_prefix =
        "\001\118\125\135" (* "scd1(37)" decoded from base 58. *)

      let size = Some 20
    end)

type input_request =
  | No_input_required
  | Initial
  | First_after of Raw_level_repr.t * Z.t
  | Needs_pre_image of Input_hash.t

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
           (req "counter" n))
        (function
          | First_after (level, counter) -> Some ((), level, counter)
          | _ -> None)
        (fun ((), level, counter) -> First_after (level, counter));
    ]

let pp_input_request fmt request =
  match request with
  | No_input_required -> Format.fprintf fmt "No_input_required"
  | Initial -> Format.fprintf fmt "Initial"
  | First_after (l, n) ->
      Format.fprintf
        fmt
        "First_after (level = %a, counter = %a)"
        Raw_level_repr.pp
        l
        Z.pp_print
        n
  | Needs_pre_image hash ->
      Format.fprintf fmt "Needs pre image of %a" Input_hash.pp hash

let input_request_equal a b =
  match (a, b) with
  | No_input_required, No_input_required -> true
  | No_input_required, _ -> false
  | Initial, Initial -> true
  | Initial, _ -> false
  | First_after (l, n), First_after (m, o) ->
      Raw_level_repr.equal l m && Z.equal n o
  | First_after _, _ -> false
  | Needs_pre_image h1, Needs_pre_image h2 -> Input_hash.equal h1 h2
  | Needs_pre_image _, _ -> false

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

  val proof_stop_state : input option -> proof -> hash option

  val proof_input_requested : proof -> input_request

  val state_hash : state -> hash Lwt.t

  val initial_state : context -> state Lwt.t

  val install_boot_sector : state -> string -> state Lwt.t

  val is_input_state : state -> input_request Lwt.t

  val set_input : input -> state -> state Lwt.t

  val eval : state -> state Lwt.t

  val verify_proof : input option -> proof -> bool Lwt.t

  val produce_proof : context -> input option -> state -> proof tzresult Lwt.t

  val verify_origination_proof : proof -> string -> bool Lwt.t

  val produce_origination_proof : context -> string -> proof tzresult Lwt.t

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
