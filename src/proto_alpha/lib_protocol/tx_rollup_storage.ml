(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2021 Oxhead Alpha <info@oxheadalpha.com>                    *)
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

open Tx_rollup_inbox_repr

let init : Raw_context.t -> Tx_rollup_repr.t -> Raw_context.t tzresult Lwt.t =
 fun ctxt rollup ->
  let cost_per_byte =
    (Raw_context.constants ctxt).tx_rollup_initial_inbox_cost_per_byte
  in
  Storage.Tx_rollup.State.init ctxt rollup {cost_per_byte}

type error += Tx_rollup_does_not_exist of Tx_rollup_repr.t

let () =
  let open Data_encoding in
  (* Tx_rollup_does_not_exist *)
  register_error_kind
    `Temporary
    ~id:"tx_rollup_does_not_exist"
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
    (fun rollup -> Tx_rollup_does_not_exist rollup)

let get_state :
    Raw_context.t -> Tx_rollup_repr.t -> Tx_rollup_state_repr.t tzresult Lwt.t =
 fun ctxt rollup ->
  Storage.Tx_rollup.State.find ctxt rollup >>=? function
  | Some res -> return res
  | None -> fail (Tx_rollup_does_not_exist rollup)

(** [assert_tx_rollup_exist ctxt tx_rollup] fails with
    [Tx_rollup_does_not_exist] when [tx_rollup] is not a valid
    transaction rollup address. *)
let assert_tx_rollup_exist :
    Raw_context.t -> Tx_rollup_repr.t -> unit tzresult Lwt.t =
 fun ctxt tx_rollup ->
  Storage.Tx_rollup.State.mem ctxt tx_rollup >>= fun tx_rollup_exists ->
  fail_unless tx_rollup_exists (Tx_rollup_does_not_exist tx_rollup)

let get_state_opt :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Tx_rollup_state_repr.t option tzresult Lwt.t =
  Storage.Tx_rollup.State.find

type error +=
  | (* `Permanent *) Tx_rollup_hard_size_limit_reached of Tx_rollup_repr.t

type error +=
  | (* `Permanent *) Tx_rollup_inbox_does_not_exist of Tx_rollup_repr.t

let () =
  let open Data_encoding in
  (* Tx_rollup_hard_size_limit_reached *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_size_limit_reached"
    ~title:"Size limit reached for rollup"
    ~description:
      "Adding this transaction would make the transaction rollup use too much \
       size in this block"
    (obj1 (req "rollup_address" Tx_rollup_repr.encoding))
    (function
      | Tx_rollup_hard_size_limit_reached rollup -> Some rollup | _ -> None)
    (fun rollup -> Tx_rollup_hard_size_limit_reached rollup) ;
  (* Tx_rollup_inbox_does_not_exist *)
  register_error_kind
    `Permanent
    ~id:"Tx_rollup_inbox_does_not_exist"
    ~title:"Transaction Rollup does not exist"
    ~description:"The requested transaction rollup does not exist"
    (obj1 (req "tx_rollup_address" Tx_rollup_repr.encoding))
    (function
      | Tx_rollup_inbox_does_not_exist rollup -> Some rollup | _ -> None)
    (fun rollup -> Tx_rollup_inbox_does_not_exist rollup)

let append_message :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Tx_rollup_inbox_repr.message ->
    (int * Raw_context.t) tzresult Lwt.t =
 fun ctxt rollup message ->
  let level = (Raw_context.current_level ctxt).level in
  let hard_size_limit =
    Constants_storage.tx_rollup_hard_size_limit_per_inbox ctxt
  in
  Storage.Tx_rollup.Inbox_cumulated_size.find (ctxt, level) rollup
  >>=? fun msize ->
  let message_size = Tx_rollup_inbox_repr.message_size message in
  let new_size = Option.value ~default:0 msize + message_size in
  fail_when
    Compare.Int.(new_size > hard_size_limit)
    (Tx_rollup_hard_size_limit_reached rollup)
  >>=? fun () ->
  Storage.Tx_rollup.Inbox_rev_contents.find (ctxt, level) rollup
  >>=? fun (ctxt, mcontents) ->
  Storage.Tx_rollup.Inbox_rev_contents.add
    (ctxt, level)
    rollup
    (Tx_rollup_inbox_repr.hash_message message
     :: Option.value ~default:[] mcontents)
  >>=? fun (ctxt, _, _) ->
  Storage.Tx_rollup.Inbox_cumulated_size.add (ctxt, level) rollup new_size
  >>= fun ctxt -> return (message_size, ctxt)

let inbox_messages_opt :
    Raw_context.t ->
    ?level:Raw_level_repr.t ->
    Tx_rollup_repr.t ->
    (Raw_context.t * Tx_rollup_inbox_repr.message_hash list option) tzresult
    Lwt.t =
 fun ctxt ?(level = (Raw_context.current_level ctxt).level) tx_rollup ->
  Storage.Tx_rollup.Inbox_rev_contents.find (ctxt, level) tx_rollup
  >>=? function
  | (ctxt, Some rev_contents) -> return (ctxt, Some (List.rev rev_contents))
  | (ctxt, None) ->
      (*
        Prior to returning [None], we check whether or not the
        transaction rollup address is valid, to raise the appropriate
        if need be.
       *)
      assert_tx_rollup_exist ctxt tx_rollup >>=? fun () -> return (ctxt, None)

let inbox_messages :
    Raw_context.t ->
    ?level:Raw_level_repr.t ->
    Tx_rollup_repr.t ->
    (Raw_context.t * Tx_rollup_inbox_repr.message_hash list) tzresult Lwt.t =
 fun ctxt ?(level = (Raw_context.current_level ctxt).level) tx_rollup ->
  inbox_messages_opt ctxt ~level tx_rollup >>=? function
  | (ctxt, Some messages) -> return (ctxt, messages)
  | (_, None) -> fail (Tx_rollup_inbox_does_not_exist tx_rollup)

let inbox_cumulated_size :
    Raw_context.t ->
    ?level:Raw_level_repr.t ->
    Tx_rollup_repr.t ->
    int tzresult Lwt.t =
 fun ctxt ?(level = (Raw_context.current_level ctxt).level) tx_rollup ->
  Storage.Tx_rollup.Inbox_cumulated_size.find (ctxt, level) tx_rollup
  >>=? function
  | Some cumulated_size -> return cumulated_size
  | None ->
      (*
        Prior to raising an error related to the missing inbox, we
        check whether or not the transaction rollup address is valid,
        to raise the appropriate if need be.
       *)
      assert_tx_rollup_exist ctxt tx_rollup >>=? fun () ->
      fail (Tx_rollup_inbox_does_not_exist tx_rollup)

let inbox_opt :
    Raw_context.t ->
    ?level:Raw_level_repr.t ->
    Tx_rollup_repr.t ->
    (Raw_context.t * Tx_rollup_inbox_repr.t option) tzresult Lwt.t =
 fun ctxt ?(level = (Raw_context.current_level ctxt).level) tx_rollup ->
  (*
    [inbox_messages_opt] checks whether or not [tx_rollup] is valid, so
    we do not have to do it here.
   *)
  inbox_messages_opt ctxt ~level tx_rollup >>=? function
  | (ctxt, Some contents) ->
      inbox_cumulated_size ctxt ~level tx_rollup >>=? fun cumulated_size ->
      return (ctxt, Some {cumulated_size; contents})
  | (ctxt, None) -> return (ctxt, None)

let inbox :
    Raw_context.t ->
    ?level:Raw_level_repr.t ->
    Tx_rollup_repr.t ->
    (Raw_context.t * Tx_rollup_inbox_repr.t) tzresult Lwt.t =
 fun ctxt ?(level = (Raw_context.current_level ctxt).level) tx_rollup ->
  (*
    [inbox_opt] checks whether or not [tx_rollup] is valid, so we
    don’t have to do it here.
   *)
  inbox_opt ctxt ~level tx_rollup >>=? function
  | (ctxt, Some res) -> return (ctxt, res)
  | (_, None) -> fail (Tx_rollup_inbox_does_not_exist tx_rollup)

let fresh_tx_rollup_from_current_nonce ctxt =
  Raw_context.increment_origination_nonce ctxt >|? fun (ctxt, nonce) ->
  (ctxt, Tx_rollup_repr.originated_tx_rollup nonce)

let originate ctxt =
  fresh_tx_rollup_from_current_nonce ctxt >>?= fun (ctxt, tx_rollup) ->
  init ctxt tx_rollup >>=? fun ctxt -> return (ctxt, tx_rollup)

let finalize_rollup :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Tx_rollup_state_repr.t ->
    Raw_context.t tzresult Lwt.t =
 fun ctxt rollup state ->
  inbox ctxt rollup >>=? fun (ctxt, inbox) ->
  let hard_limit = Constants_storage.tx_rollup_hard_size_limit_per_inbox ctxt in
  let cost_per_byte = Constants_storage.cost_per_byte ctxt in
  let tx_rollup_cost_per_byte =
    Tx_rollup_state_repr.update_cost_per_byte
      ~cost_per_byte
      ~tx_rollup_cost_per_byte:state.cost_per_byte
      ~final_size:inbox.cumulated_size
      ~hard_limit
  in
  Storage.Tx_rollup.State.add
    ctxt
    rollup
    {cost_per_byte = tx_rollup_cost_per_byte}
  >|= ok

let update_tx_rollup_at_block_finalization :
    Raw_context.t -> Raw_context.t tzresult Lwt.t =
 fun ctxt ->
  let level = (Raw_context.current_level ctxt).level in
  Storage.Tx_rollup.fold ctxt level ~init:(ok ctxt) ~f:(fun tx_rollup ctxt ->
      ctxt >>?= fun ctxt ->
      Storage.Tx_rollup.State.get ctxt tx_rollup >>=? fun state ->
      finalize_rollup ctxt tx_rollup state)
