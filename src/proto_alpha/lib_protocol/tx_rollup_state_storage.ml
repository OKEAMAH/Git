(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

type error +=
  | (* FIXME: register these two one. *)
      Tx_rollup_inbox_does_not_exist of
      Tx_rollup_repr.t * Raw_level_repr.t
  | Tx_rollup_inbox_already_exist of Tx_rollup_repr.t * Raw_level_repr.t
  | Tx_rollup_inbox_inconsistency of Tx_rollup_repr.t * Raw_level_repr.t
  | Tx_rollup_already_exists of Tx_rollup_repr.t
  | Tx_rollup_does_not_exist of Tx_rollup_repr.t

let init : Raw_context.t -> Tx_rollup_repr.t -> Raw_context.t tzresult Lwt.t =
 fun ctxt tx_rollup ->
  Storage.Tx_rollup.State.mem ctxt tx_rollup >>=? fun (ctxt, already_exists) ->
  fail_when already_exists (Tx_rollup_already_exists tx_rollup) >>=? fun () ->
  Storage.Tx_rollup.State.init ctxt tx_rollup Tx_rollup_state_repr.initial_state
  >|=? fst

let find :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    (Raw_context.t * Tx_rollup_state_repr.t option) tzresult Lwt.t =
  Storage.Tx_rollup.State.find

let get :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    (Raw_context.t * Tx_rollup_state_repr.t) tzresult Lwt.t =
 fun ctxt tx_rollup ->
  find ctxt tx_rollup >>=? fun (ctxt, state) ->
  match state with
  | Some state -> return (ctxt, state)
  | None -> fail (Tx_rollup_does_not_exist tx_rollup)

let assert_exist :
    Raw_context.t -> Tx_rollup_repr.t -> Raw_context.t tzresult Lwt.t =
 fun ctxt tx_rollup ->
  Storage.Tx_rollup.State.mem ctxt tx_rollup
  >>=? fun (ctxt, tx_rollup_exists) ->
  fail_unless tx_rollup_exists (Tx_rollup_does_not_exist tx_rollup)
  >>=? fun () -> return ctxt

module Comparable_raw_level_repr_opt = Compare.Option (Raw_level_repr)

let make_inbox ctxt rollup state =
  let last_inbox_level = Tx_rollup_state_repr.last_inbox_level state in
  let current_level = (Raw_context.current_level ctxt).level in
  let metadata =
    Tx_rollup_inbox_repr.
      {cumulated_size = 0; predecessor = last_inbox_level; successor = None}
  in
  let inbox = Tx_rollup_inbox_repr.{content = []; metadata} in
  let state = Tx_rollup_state_repr.append_inbox state current_level in
  (* We update the storage accordingly. *)
  match last_inbox_level with
  | None ->
      Storage.Tx_rollup.State.update ctxt rollup state >>=? fun (ctxt, _) ->
      return (ctxt, inbox)
  | Some last_inbox_level -> (
      (* This error should never occur, and is here as a safety net to
         avoid erasing an inbox. *)
      error_unless
        Raw_level_repr.(last_inbox_level <> current_level)
        (Tx_rollup_inbox_already_exist (rollup, current_level))
      >>?= fun () ->
      Storage.Tx_rollup.Inbox_metadata.find (ctxt, last_inbox_level) rollup
      >>=? fun (ctxt, metadata) ->
      match metadata with
      | None ->
          (* This error should never occur, and is caught here as a
             safety net. *)
          fail (Tx_rollup_inbox_does_not_exist (rollup, last_inbox_level))
      | Some metadata ->
          (* This error should never occur, and is caught here as a
             safety net. *)
          error_unless
            Comparable_raw_level_repr_opt.(metadata.successor = None)
            (Tx_rollup_inbox_inconsistency (rollup, current_level))
          >>?= fun () ->
          let metadata = {metadata with successor = Some current_level} in
          Storage.Tx_rollup.Inbox_metadata.add
            (ctxt, last_inbox_level)
            rollup
            metadata
          >>=? fun (ctxt, _, _) ->
          Storage.Tx_rollup.State.update ctxt rollup state >>=? fun (ctxt, _) ->
          return (ctxt, inbox))

(* ------ Error registration ------------------------------------------------ *)

let () =
  let open Data_encoding in
  (* Tx_rollup_already_exists *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_already_exists"
    ~title:"Transaction rollup was already created"
    ~description:
      "The protocol tried to originate the same transaction rollup twice"
    ~pp:(fun ppf addr ->
      Format.fprintf
        ppf
        "Transaction rollup %a is already used for an existing transaction \
         rollup. This should not happen, and indicates there is a bug in the \
         protocol. If you can, please report this bug \
         (https://gitlab.com/tezos/tezos/-/issues.)"
        Tx_rollup_repr.pp
        addr)
    (obj1 (req "rollup_address" Tx_rollup_repr.encoding))
    (function Tx_rollup_already_exists rollup -> Some rollup | _ -> None)
    (fun rollup -> Tx_rollup_already_exists rollup) ;
  (* Tx_rollup_does_not_exist *)
  register_error_kind
    `Temporary
    ~id:"tx_rollup_does_not_exist_"
    ~title:"Transaction rollup does not exist"
    ~description:"An invalid transaction rollup address was submitted"
    ~pp:(fun ppf addr ->
      Format.fprintf
        ppf
        "Invalid transaction rollup address %a"
        Tx_rollup_repr.pp
        addr)
    (obj1 (req "rollup_address" Tx_rollup_repr.encoding))
    (function Tx_rollup_does_not_exist rollup -> Some rollup | _ -> None)
    (fun rollup -> Tx_rollup_does_not_exist rollup) ;
  (*      Tx_rollup_inbox_does_not_exist *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_inbox_does_not_exist_"
    ~title:"The last inbox level recorded is not stored"
    ~description:
      "The state of the rollup references an inbox which is not stored in the \
       context"
    ~pp:(fun ppf (addr, level) ->
      Format.fprintf
        ppf
        "The rollup state for %a recorded that the last inbox level is %a, but \
         the inbox associated to was not stored."
        Tx_rollup_repr.pp
        addr
        Raw_level_repr.pp
        level)
    (obj2
       (req "rollup_address" Tx_rollup_repr.encoding)
       (req "level" Raw_level_repr.encoding))
    (function
      | Tx_rollup_inbox_does_not_exist (rollup, level) -> Some (rollup, level)
      | _ -> None)
    (fun (rollup, level) -> Tx_rollup_inbox_does_not_exist (rollup, level)) ;
  (*      Tx_rollup_inbox_already_exist *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_inbox_already_exist"
    ~title:"An inbox for the current level already exist"
    ~description:
      "We try to create a new inbox for the given level while an inbox already \
       existed for this level"
    ~pp:(fun ppf (addr, level) ->
      Format.fprintf
        ppf
        "The creation of a new inbox failed. The rollup state for %a already \
         has an inbox for the level %a."
        Tx_rollup_repr.pp
        addr
        Raw_level_repr.pp
        level)
    (obj2
       (req "rollup_address" Tx_rollup_repr.encoding)
       (req "level" Raw_level_repr.encoding))
    (function
      | Tx_rollup_inbox_already_exist (rollup, level) -> Some (rollup, level)
      | _ -> None)
    (fun (rollup, level) -> Tx_rollup_inbox_already_exist (rollup, level)) ;
  (*      Tx_rollup_inbox_inconsistency *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_inbox_inconsistency"
    ~title:"The internal storage for the inbox is consistent."
    ~description:
      "While creating an inbox, we have detected that the state is in an \
       inconsistent state."
    ~pp:(fun ppf (addr, level) ->
      Format.fprintf
        ppf
        "The creation of a new inbox failed. The rollup state for %a \
         references an inbox at level %a, but the internal storage contains no \
         metadata about this inbox."
        Tx_rollup_repr.pp
        addr
        Raw_level_repr.pp
        level)
    (obj2
       (req "rollup_address" Tx_rollup_repr.encoding)
       (req "level" Raw_level_repr.encoding))
    (function
      | Tx_rollup_inbox_inconsistency (rollup, level) -> Some (rollup, level)
      | _ -> None)
    (fun (rollup, level) -> Tx_rollup_inbox_inconsistency (rollup, level))
