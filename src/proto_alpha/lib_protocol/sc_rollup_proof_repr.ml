(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

type error += Sc_rollup_proof_check of string

type error += Sc_rollup_invalid_serialized_inbox_proof

let () =
  register_error_kind
    `Permanent
    ~id:"Sc_rollup_proof_check"
    ~title:"Invalid proof"
    ~description:"An invalid proof has been submitted"
    ~pp:(fun fmt msg -> Format.fprintf fmt "Invalid proof: %s" msg)
    Data_encoding.(obj1 @@ req "reason" string)
    (function Sc_rollup_proof_check msg -> Some msg | _ -> None)
    (fun msg -> Sc_rollup_proof_check msg) ;

  register_error_kind
    `Permanent
    ~id:"Sc_rollup_invalid_serialized_inbox_proof"
    ~title:"Invalid serialized inbox proof"
    ~description:"The serialized inbox proof can not be de-serialized"
    ~pp:(fun fmt () -> Format.fprintf fmt "Invalid serialized inbox proof")
    Data_encoding.unit
    (function Sc_rollup_invalid_serialized_inbox_proof -> Some () | _ -> None)
    (fun () -> Sc_rollup_invalid_serialized_inbox_proof)

module Dal_proofs = Dal_slot_repr.Slots_history

type input_proof =
  | Inbox_proof of Sc_rollup_inbox_repr.serialized_proof
  | Postulate_proof of
      [`Preimage_proof of string | `Dal_page_proof of Dal_proofs.proof]

let postulate_proof_encoding =
  let open Data_encoding in
  let case_preimage_proof =
    case
      ~title:"preimage proof"
      (Tag 0)
      string
      (function `Preimage_proof m -> Some m | _ -> None)
      (fun m -> `Preimage_proof m)
  and case_dal_page_proof =
    case
      ~title:"dal_page proof"
      (Tag 1)
      Dal_proofs.proof_encoding
      (function `Dal_page_proof p -> Some p | _ -> None)
      (fun p -> `Dal_page_proof p)
  in
  union [case_preimage_proof; case_dal_page_proof]

let input_proof_encoding =
  let open Data_encoding in
  let case_inbox_proof =
    case
      ~title:"inbox proof"
      (Tag 0)
      Sc_rollup_inbox_repr.serialized_proof_encoding
      (function Inbox_proof s -> Some s | _ -> None)
      (fun s -> Inbox_proof s)
  in
  let case_postulate_proof =
    case
      ~title:"postulate proof"
      (Tag 1)
      postulate_proof_encoding
      (function Postulate_proof s -> Some s | _ -> None)
      (fun s -> Postulate_proof s)
  in
  union [case_inbox_proof; case_postulate_proof]

type t = {pvm_step : Sc_rollups.wrapped_proof; input_proof : input_proof option}

let encoding =
  let open Data_encoding in
  conv
    (fun {pvm_step; input_proof} -> (pvm_step, input_proof))
    (fun (pvm_step, input_proof) -> {pvm_step; input_proof})
    (obj2
       (req "pvm_step" Sc_rollups.wrapped_proof_encoding)
       (opt "input_proof" input_proof_encoding))

let pp ppf _ = Format.fprintf ppf "Refutation game proof"

let start proof =
  let (module P) = Sc_rollups.wrapped_proof_module proof.pvm_step in
  P.proof_start_state P.proof

let stop input proof =
  let (module P) = Sc_rollups.wrapped_proof_module proof.pvm_step in
  P.proof_stop_state input P.proof

(* This takes an [input] and checks if it is at or above the given level.
   It returns [None] if this is the case.

   We use this to check that the PVM proof is obeying [commit_level]
   correctly---if the message obtained from the inbox proof is at or
   above [commit_level] the [input_given] in the PVM proof should be
   [None]. *)
let cut_at_level level input =
  match input with
  | Sc_rollup_PVM_sig.Inbox_message input ->
      let input_level = Sc_rollup_PVM_sig.(input.inbox_level) in
      if Raw_level_repr.(level <= input_level) then None
      else Some (Sc_rollup_PVM_sig.Inbox_message input)
  | Sc_rollup_PVM_sig.Postulate_revelation _data -> Some input

let proof_error reason =
  let open Lwt_tzresult_syntax in
  fail (Sc_rollup_proof_check reason)

let check p reason =
  let open Lwt_tzresult_syntax in
  if p then return () else proof_error reason

let check_inbox_proof snapshot serialized_inbox_proof (level, counter) =
  match Sc_rollup_inbox_repr.of_serialized_proof serialized_inbox_proof with
  | None -> fail Sc_rollup_invalid_serialized_inbox_proof
  | Some inbox_proof ->
      Sc_rollup_inbox_repr.verify_proof (level, counter) snapshot inbox_proof

let pp_inbox_proof fmt serialized_inbox_proof =
  match Sc_rollup_inbox_repr.of_serialized_proof serialized_inbox_proof with
  | None -> Format.pp_print_string fmt "<invalid-proof-serialization>"
  | Some proof -> Sc_rollup_inbox_repr.pp_proof fmt proof

let pp_proof fmt = function
  | Inbox_proof p -> pp_inbox_proof fmt p
  | Postulate_proof (`Preimage_proof p) ->
      Format.fprintf fmt "postulate: Preimage (%s)" p
  | Postulate_proof (`Dal_page_proof p) ->
      Format.fprintf fmt "postulate: Dal_page(%a)" Dal_proofs.pp_proof p

let valid snapshot commit_level ~pvm_name proof =
  let open Lwt_tzresult_syntax in
  let (module P) = Sc_rollups.wrapped_proof_module proof.pvm_step in
  let* () = check (String.equal P.name pvm_name) "Incorrect PVM kind" in
  let (input_requested : Sc_rollup_PVM_sig.input_request) =
    P.proof_input_requested P.proof
  in
  let* input =
    match (input_requested, proof.input_proof) with
    | No_input_required, None -> return None
    | Initial, Some (Inbox_proof inbox_proof) -> (
        let* input =
          check_inbox_proof snapshot inbox_proof (Raw_level_repr.root, Z.zero)
        in
        match input with
        | None -> return_none
        | Some input -> return_some (Sc_rollup_PVM_sig.Inbox_message input))
    | First_after (level, counter), Some (Inbox_proof inbox_proof) -> (
        let* input =
          check_inbox_proof snapshot inbox_proof (level, Z.succ counter)
        in
        match input with
        | None -> return_none
        | Some input -> return_some (Sc_rollup_PVM_sig.Inbox_message input))
    | ( Needs_postulate (`Preimage_hash expected_hash),
        Some (Postulate_proof (`Preimage_proof data)) ) ->
        let data_hash = Sc_rollup_PVM_sig.Input_hash.hash_string [data] in
        if Sc_rollup_PVM_sig.Input_hash.equal data_hash expected_hash then
          return
            (Some (Sc_rollup_PVM_sig.Postulate_revelation (`Preimage data)))
        else proof_error "Invalid postulate"
    | ( Needs_postulate (`Dal_page_request _p_id),
        Some (Postulate_proof (`Dal_page_proof _p_proof)) ) ->
        (* FIXME/DAL-REFUTATION: TODO *)
        assert false
    | No_input_required, Some _
    | Initial, _
    | First_after (_, _), (Some (Postulate_proof _) | None)
    | Needs_postulate _, (Some (Inbox_proof _) | None)
    | ( Needs_postulate (`Preimage_hash _),
        Some (Postulate_proof (`Dal_page_proof _)) )
    | ( Needs_postulate (`Dal_page_request _),
        Some (Postulate_proof (`Preimage_proof _)) ) ->
        proof_error
          (Format.asprintf
             "input_requested is %a, input proof is %a"
             Sc_rollup_PVM_sig.pp_input_request
             input_requested
             (Format.pp_print_option pp_proof)
             proof.input_proof)
  in
  let input = Option.bind input (cut_at_level commit_level) in
  let*! valid = P.verify_proof input P.proof in
  return (valid, input)

(*
Needs_postulate
Postulate_proof
Postulate_revelation
*)
module type PVM_with_context_and_state = sig
  include Sc_rollups.PVM.S

  val context : context

  val state : state

  val proof_encoding : proof Data_encoding.t

  val postulate : Sc_rollup_PVM_sig.Input_hash.t -> string option

  module Inbox_with_history : sig
    include
      Sc_rollup_inbox_repr.Merkelized_operations
        with type inbox_context = context

    val inbox : Sc_rollup_inbox_repr.history_proof

    val history : Sc_rollup_inbox_repr.History.t
  end

  module Dal_with_history : sig
    val confirmed_slots_history : Dal_slot_repr.Slots_history.t

    val history_cache : Dal_slot_repr.Slots_history.History_cache.t

    val page_content_of :
      Dal_slot_repr.Page.id ->
      [ `Attested of Dal_slot_repr.Page.content
      | `Unattested of Dal_slot_repr.t option * Dal_slot_repr.t option ]
  end
end

let produce pvm_and_state commit_level =
  let open Lwt_tzresult_syntax in
  let (module P : PVM_with_context_and_state) = pvm_and_state in
  let open P in
  let*! (request : Sc_rollup_PVM_sig.input_request) =
    P.is_input_state P.state
  in
  let* input_proof, input_given =
    match request with
    | No_input_required -> return (None, None)
    | Initial ->
        let* p, i =
          Inbox_with_history.(
            produce_proof context history inbox (Raw_level_repr.root, Z.zero))
        in
        let i = Option.map (fun msg -> Sc_rollup_PVM_sig.Inbox_message msg) i in
        return (Some (Inbox_proof (Inbox_with_history.to_serialized_proof p)), i)
    | First_after (l, n) ->
        let* p, i =
          Inbox_with_history.(produce_proof context history inbox (l, Z.succ n))
        in
        let i = Option.map (fun msg -> Sc_rollup_PVM_sig.Inbox_message msg) i in
        return (Some (Inbox_proof (Inbox_with_history.to_serialized_proof p)), i)
    | Sc_rollup_PVM_sig.Needs_postulate (`Preimage_hash h) -> (
        match postulate h with
        | None -> proof_error "No postulate"
        | Some data ->
            return
              ( Some (Postulate_proof (`Preimage_proof data)),
                Some (Sc_rollup_PVM_sig.Postulate_revelation (`Preimage data))
              ))
    | Sc_rollup_PVM_sig.Needs_postulate (`Dal_page_request page_id) ->
        (* should provide the page + the proof of ?    *)
        (* FIXME/DAL-REFUTATION *)
        let open Dal_with_history in
        let* proof, page_opt =
          Dal_proofs.produce_proof
            ~page_content_of
            page_id
            confirmed_slots_history
            history_cache
        in
        let i =
          Option.map
            (fun msg ->
              Sc_rollup_PVM_sig.Postulate_revelation (`Dal_page (Some msg)))
            page_opt
        in
        (* FIXME/DAL-REFUTATION: proof should be serialized? *)
        return (Some (Postulate_proof (`Dal_page_proof proof)), i)
  in

  let input_given = Option.bind input_given @@ cut_at_level commit_level in
  let* pvm_step_proof = P.produce_proof P.context input_given P.state in
  let module P_with_proof = struct
    include P

    let proof = pvm_step_proof
  end in
  match Sc_rollups.wrap_proof (module P_with_proof) with
  | Some pvm_step -> return {pvm_step; input_proof}
  | None -> proof_error "Could not wrap proof"
