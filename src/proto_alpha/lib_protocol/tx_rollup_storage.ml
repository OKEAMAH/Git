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
      "Adding this transaction would make the rollup use too much size in this \
       block"
    (obj1 (req "rollup_address" Tx_rollup_repr.encoding))
    (function
      | Tx_rollup_hard_size_limit_reached rollup -> Some rollup | _ -> None)
    (fun rollup -> Tx_rollup_hard_size_limit_reached rollup) ;
  (* Tx_rollup_inbox_does_not_exist *)
  register_error_kind
    `Permanent
    ~id:"Tx_rollup_inbox_does_not_exist"
    ~title:"Rollup does not exist"
    ~description:"The requested rollup does not exist"
    (obj1 (req "tx_rollup_address" Tx_rollup_repr.encoding))
    (function
      | Tx_rollup_inbox_does_not_exist rollup -> Some rollup | _ -> None)
    (fun rollup -> Tx_rollup_inbox_does_not_exist rollup)

let empty_inbox = {cumulated_size = 0; length = 0l}

type inbox_status = {cumulated_size : int; last_message_size : int}

let append_message :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    message ->
    (inbox_status * Raw_context.t) tzresult Lwt.t =
 fun ctxt rollup message ->
  let level = (Raw_context.current_level ctxt).level in
  let hard_size_limit =
    Constants_storage.tx_rollup_hard_size_limit_per_inbox ctxt
  in
  let size_of_message =
    match message with
    | Batch content -> String.length content
    | Deposit _ -> 48 + 32
    (* FIXME: we should not use magic numbers here *)
  in

  let append_message {length; cumulated_size} message =
    let new_size = cumulated_size + size_of_message in
    fail_when
      Compare.Int.(new_size > hard_size_limit)
      (Tx_rollup_hard_size_limit_reached rollup)
    >>=? fun () ->
    Storage.Tx_rollup.Message.init
      ((ctxt, level), rollup)
      (Int32.to_int length)
      message
    >>=? fun ctxt ->
    Storage.Tx_rollup.Inbox_info.add
      (ctxt, level)
      rollup
      {length = Int32.succ length; cumulated_size = new_size}
    >|= fun ctxt ->
    ok ({cumulated_size = new_size; last_message_size = size_of_message}, ctxt)
  in

  Storage.Tx_rollup.Inbox_info.find (ctxt, level) rollup >>=? fun maybe_inbox ->
  append_message (Option.value ~default:empty_inbox maybe_inbox) message

let get_inbox_opt :
    Raw_context.t ->
    ?level:Raw_level_repr.t ->
    Tx_rollup_repr.t ->
    Tx_rollup_inbox_repr.t option tzresult Lwt.t =
 fun ctxt ?(level = (Raw_context.current_level ctxt).level) tx_rollup ->
  Storage.Tx_rollup.Inbox_info.find (ctxt, level) tx_rollup >>=? function
  | Some res -> return (Some res)
  | None -> get_state ctxt tx_rollup >>=? fun _state -> return None

let get_full_inbox_opt :
    Raw_context.t ->
    ?level:Raw_level_repr.t ->
    Tx_rollup_repr.t ->
    full option tzresult Lwt.t =
 fun ctxt ?(level = (Raw_context.current_level ctxt).level) rollup ->
  get_inbox_opt ctxt ~level rollup >>=? function
  | None -> return None
  | Some {cumulated_size; _} ->
      Storage.Tx_rollup.Message.fold
        ((ctxt, level), rollup)
        ~order:`Sorted
        ~init:[]
        ~f:(fun _ m acc -> Lwt.return (m :: acc))
      >>= fun rev_messages ->
      return (Some {content = List.rev rev_messages; cumulated_size})

let get_inbox :
    Raw_context.t ->
    ?level:Raw_level_repr.t ->
    Tx_rollup_repr.t ->
    t tzresult Lwt.t =
 fun ctxt ?level rollup ->
  get_inbox_opt ctxt rollup ?level >>=? function
  | Some inbox -> return inbox
  | None -> fail @@ Tx_rollup_inbox_does_not_exist rollup

let get_full_inbox :
    Raw_context.t ->
    ?level:Raw_level_repr.t ->
    Tx_rollup_repr.t ->
    full tzresult Lwt.t =
 fun ctxt ?level rollup ->
  get_full_inbox_opt ctxt rollup ?level >>=? function
  | Some inbox -> return inbox
  | None -> fail @@ Tx_rollup_inbox_does_not_exist rollup

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
  get_inbox ctxt rollup >>=? fun inbox ->
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

let finalize_block : Raw_context.t -> Raw_context.t tzresult Lwt.t =
 fun ctxt ->
  let level = (Raw_context.current_level ctxt).level in
  Storage.Tx_rollup.fold
    (ctxt, level)
    ~order:`Undefined
    ~init:(ok ctxt)
    ~f:(fun tx_rollup ctxt ->
      ctxt >>?= fun ctxt ->
      Storage.Tx_rollup.State.get ctxt tx_rollup >>=? fun state ->
      finalize_rollup ctxt tx_rollup state)

let hash_ticket :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    contents:Script_repr.node ->
    ticketer:Script_repr.node ->
    ty:Script_repr.node ->
    (Ticket_repr.key_hash * Raw_context.t) tzresult =
 fun ctxt tx_rollup ~contents ~ticketer ~ty ->
  let open Micheline in
  let owner = String (dummy_location, Tx_rollup_repr.to_b58check tx_rollup) in
  Ticket_storage.make_key_hash ctxt ~ticketer ~typ:ty ~contents ~owner
