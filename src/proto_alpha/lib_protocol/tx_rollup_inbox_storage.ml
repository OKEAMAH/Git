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
  | Tx_rollup_inbox_does_not_exist of Tx_rollup_repr.t * Raw_level_repr.t
  | Tx_rollup_inbox_size_would_exceed_limit of Tx_rollup_repr.t
  | Tx_rollup_inbox_count_would_exceed_limit of Tx_rollup_repr.t
  | Tx_rollup_message_size_exceeds_limit

(** [prepare_metadata ctxt rollup state level] prepares the metadata for
    an inbox at [level]. This may involve updating the predecessor's
    successor pointer.  It also returns a new state which point
    the tail of the linked list of inboxes to this inbox. *)
let prepare_metadata :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Tx_rollup_state_repr.t ->
    Raw_level_repr.t ->
    (Raw_context.t * Tx_rollup_state_repr.t * Tx_rollup_inbox_repr.metadata)
    tzresult
    Lwt.t =
 fun ctxt rollup state level ->
  (* First, check if there are too many unfinalized levels. *)
  fail_when
    Compare.Int.(
      Tx_rollup_state_repr.unfinalized_level_count state
      > Constants_storage.tx_rollup_max_unfinalized_levels ctxt)
    Tx_rollup_commitment_repr.Too_many_unfinalized_levels
  >>=? fun () ->
  (* Consume a fix amount of gas. *)
  (* TODO/TORU: https://gitlab.com/tezos/tezos/-/issues/2340
     Extract the constant in a dedicated [Tx_rollup_cost] module, and
     refine it if need be. *)
  Raw_context.consume_gas
    ctxt
    Gas_limit_repr.(cost_of_gas @@ Arith.integral_of_int_exn 200)
  >>?= fun ctxt ->
  (* Opt-out gas accounting *)
  let save_gas_level = Raw_context.gas_level ctxt in
  let ctxt = Raw_context.set_gas_unlimited ctxt in
  (* Processing *)
  Storage.Tx_rollup.Inbox_metadata.find (ctxt, level) rollup
  >>=? fun (ctxt, metadata) ->
  (match metadata with
  | Some metadata ->
      Logging.(log Info "old metadata\n") ;
      return (ctxt, state, metadata)
  | None ->
      Logging.(log Info "first message\n") ;
      (* First message in inbox: need to update linked list and pending
         inbox count *)
      let predecessor = Tx_rollup_state_repr.last_inbox_level state in
      let new_state = Tx_rollup_state_repr.append_inbox state level in
      Tx_rollup_state_storage.update ctxt rollup new_state >>=? fun ctxt ->
      (match predecessor with
      | None -> return ctxt
      | Some predecessor_level ->
          Storage.Tx_rollup.Inbox_metadata.get (ctxt, predecessor_level) rollup
          >>=? fun (ctxt, predecessor_metadata) ->
          (* Here, we update the predecessor inbox's successor to point
             to this inbox. *)
          Storage.Tx_rollup.Inbox_metadata.add
            (ctxt, predecessor_level)
            rollup
            {predecessor_metadata with successor = Some level}
          >|=? fun (ctxt, _, _) -> ctxt)
      >>=? fun ctxt ->
      let new_metadata : Tx_rollup_inbox_repr.metadata =
        Tx_rollup_inbox_repr.empty_metadata predecessor
      in
      return (ctxt, new_state, new_metadata))
  >>=? fun (ctxt, new_state, new_metadata) ->
  (* Restore gas accounting. *)
  let ctxt =
    match save_gas_level with
    | Gas_limit_repr.Unaccounted -> ctxt
    | Gas_limit_repr.Limited {remaining = limit} ->
        Raw_context.set_gas_limit ctxt limit
  in
  return (ctxt, new_state, new_metadata)

(** [update_metadata metadata msg_size] updates [metadata] to account
    for a new message of [msg_size] bytes. *)
let update_metadata :
    Tx_rollup_inbox_repr.metadata ->
    Tx_rollup_message_repr.hash ->
    int ->
    Tx_rollup_inbox_repr.metadata tzresult =
 fun metadata msg_hash msg_size ->
  let hash = Tx_rollup_inbox_repr.extend_hash metadata.hash msg_hash in
  ok
    {
      metadata with
      inbox_length = Int32.succ metadata.inbox_length;
      cumulated_size = msg_size + metadata.cumulated_size;
      hash;
    }

let append_message :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Tx_rollup_state_repr.t ->
    Tx_rollup_message_repr.t ->
    (Raw_context.t * Tx_rollup_state_repr.t) tzresult Lwt.t =
 fun ctxt rollup state message ->
  let level = (Raw_context.current_level ctxt).level in
  Logging.(log Info "APPEND at level %a\n" Raw_level_repr.pp level) ;
  let message_size = Tx_rollup_message_repr.size message in
  prepare_metadata ctxt rollup state level
  >>=? fun (ctxt, new_state, metadata) ->
  Logging.(log Info "APPEND: l = %ld\n" metadata.inbox_length) ;
  fail_when
    Compare.Int.(
      Int32.to_int metadata.inbox_length
      >= Constants_storage.tx_rollup_max_messages_per_inbox ctxt)
    (Tx_rollup_inbox_count_would_exceed_limit rollup)
  >>=? fun () ->
  Tx_rollup_message_builder.hash ctxt message >>?= fun (ctxt, message_hash) ->
  update_metadata metadata message_hash message_size >>?= fun new_metadata ->
  Storage.Tx_rollup.Inbox_metadata.add (ctxt, level) rollup new_metadata
  >>=? fun (ctxt, _, already) ->
  Logging.(log Info "ALREADY: %b\n" already) ;
  let new_size = new_metadata.cumulated_size in
  let inbox_limit =
    Constants_storage.tx_rollup_hard_size_limit_per_inbox ctxt
  in
  fail_unless
    Compare.Int.(new_size < inbox_limit)
    (Tx_rollup_inbox_size_would_exceed_limit rollup)
  >>=? fun () ->
  Storage.Tx_rollup.Inbox_contents.add
    ((ctxt, level), rollup)
    metadata.inbox_length
    message_hash
  >>=? fun (ctxt, _, _) ->
  Logging.(log Info "EOF\n") ;
  return (ctxt, new_state)

let get_level :
    Raw_context.t -> [`Current | `Level of Raw_level_repr.t] -> Raw_level_repr.t
    =
 fun ctxt -> function
  | `Current -> (Raw_context.current_level ctxt).level
  | `Level lvl -> lvl

let messages_opt :
    Raw_context.t ->
    level:[`Current | `Level of Raw_level_repr.t] ->
    Tx_rollup_repr.t ->
    (Raw_context.t * Tx_rollup_message_repr.hash list option) tzresult Lwt.t =
 fun ctxt ~level tx_rollup ->
  let level = get_level ctxt level in
  Storage.Tx_rollup.Inbox_contents.list_values ((ctxt, level), tx_rollup)
  >>=? function
  | (ctxt, []) ->
      (*
        Prior to returning [None], we check whether or not the
        transaction rollup address is valid, to raise the appropriate
        if need be.
       *)
      Tx_rollup_state_storage.assert_exist ctxt tx_rollup >>=? fun ctxt ->
      return (ctxt, None)
  | (ctxt, contents) -> return (ctxt, Some contents)

let messages :
    Raw_context.t ->
    level:[`Current | `Level of Raw_level_repr.t] ->
    Tx_rollup_repr.t ->
    (Raw_context.t * Tx_rollup_message_repr.hash list) tzresult Lwt.t =
 fun ctxt ~level tx_rollup ->
  messages_opt ctxt ~level tx_rollup >>=? function
  | (ctxt, Some messages) -> return (ctxt, messages)
  | (_, None) ->
    let raw_level = get_level ctxt level in
    Logging.(log Info "Failed to find messages at level %a" Raw_level_repr.pp raw_level) ;
      fail (Tx_rollup_inbox_does_not_exist (tx_rollup, get_level ctxt level))

let size :
    Raw_context.t ->
    level:[`Current | `Level of Raw_level_repr.t] ->
    Tx_rollup_repr.t ->
    (Raw_context.t * int) tzresult Lwt.t =
 fun ctxt ~level tx_rollup ->
  let level = get_level ctxt level in
  Storage.Tx_rollup.Inbox_metadata.find (ctxt, level) tx_rollup >>=? function
  | (ctxt, Some {cumulated_size; _}) -> return (ctxt, cumulated_size)
  | (ctxt, None) ->
      (*
        Prior to raising an error related to the missing inbox, we
        check whether or not the transaction rollup address is valid,
        to raise the appropriate if need be.
       *)
      Tx_rollup_state_storage.assert_exist ctxt tx_rollup >>=? fun _ctxt ->
      fail (Tx_rollup_inbox_does_not_exist (tx_rollup, level))

let find :
    Raw_context.t ->
    level:[`Current | `Level of Raw_level_repr.t] ->
    Tx_rollup_repr.t ->
    (Raw_context.t * Tx_rollup_inbox_repr.t option) tzresult Lwt.t =
 fun ctxt ~level tx_rollup ->
  let open Tx_rollup_inbox_repr in
  (*
    [messages_opt] checks whether or not [tx_rollup] is valid, so
    we do not have to do it here.
   *)
  messages_opt ctxt ~level tx_rollup >>=? function
  | (ctxt, Some contents) ->
      size ctxt ~level tx_rollup >>=? fun (ctxt, cumulated_size) ->
      let hash = Tx_rollup_inbox_repr.hash_hashed_inbox contents in
      return (ctxt, Some {cumulated_size; contents; hash})
  | (ctxt, None) -> return (ctxt, None)

let get :
    Raw_context.t ->
    level:[`Current | `Level of Raw_level_repr.t] ->
    Tx_rollup_repr.t ->
    (Raw_context.t * Tx_rollup_inbox_repr.t) tzresult Lwt.t =
 fun ctxt ~level tx_rollup ->
  (*
    [inbox_opt] checks whether or not [tx_rollup] is valid, so we
    don’t have to do it here.
   *)
  find ctxt ~level tx_rollup >>=? function
  | (ctxt, Some res) -> return (ctxt, res)
  | (_, None) ->
      fail (Tx_rollup_inbox_does_not_exist (tx_rollup, get_level ctxt level))

let get_adjacent_levels :
    Raw_context.t ->
    Raw_level_repr.t ->
    Tx_rollup_repr.t ->
    (Raw_context.t * Raw_level_repr.t option * Raw_level_repr.t option) tzresult
    Lwt.t =
 fun ctxt level tx_rollup ->
  Storage.Tx_rollup.Inbox_metadata.find (ctxt, level) tx_rollup >>=? function
  | (ctxt, Some {predecessor; successor; _}) ->
      return (ctxt, predecessor, successor)
  | (_, None) -> fail @@ Tx_rollup_inbox_does_not_exist (tx_rollup, level)

let get_metadata :
    Raw_context.t ->
    Raw_level_repr.t ->
    Tx_rollup_repr.t ->
    (Raw_context.t * Tx_rollup_inbox_repr.metadata) tzresult Lwt.t =
 fun ctxt level tx_rollup ->
  Storage.Tx_rollup.Inbox_metadata.find (ctxt, level) tx_rollup >>=? function
  | (_, None) -> fail (Tx_rollup_inbox_does_not_exist (tx_rollup, level))
  | (ctxt, Some metadata) -> return (ctxt, metadata)

(* Error registration *)

let () =
  let open Data_encoding in
  (* Tx_rollup_inbox_does_not_exist *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_inbox_does_not_exist"
    ~title:"Missing transaction rollup inbox"
    ~description:"The transaction rollup does not have an inbox at this level"
    ~pp:(fun ppf (addr, level) ->
      Format.fprintf
        ppf
        "Transaction rollup %a does not have an inbox at level %a"
        Tx_rollup_repr.pp
        addr
        Raw_level_repr.pp
        level)
    (obj2
       (req "tx_rollup_address" Tx_rollup_repr.encoding)
       (req "raw_level" Raw_level_repr.encoding))
    (function
      | Tx_rollup_inbox_does_not_exist (rollup, level) -> Some (rollup, level)
      | _ -> None)
    (fun (rollup, level) -> Tx_rollup_inbox_does_not_exist (rollup, level)) ;
  register_error_kind
    `Permanent
    ~id:"tx_rollup_inbox_size_would_exceed_limit"
    ~title:"Transaction rollup inbox’s size would exceed the limit"
    ~description:"Transaction rollup inbox’s size would exceed the limit"
    ~pp:(fun ppf addr ->
      Format.fprintf
        ppf
        "Adding the submitted message would make the inbox of %a exceed the \
         authorized limit at this level"
        Tx_rollup_repr.pp
        addr)
    (obj1 (req "tx_rollup_address" Tx_rollup_repr.encoding))
    (function
      | Tx_rollup_inbox_size_would_exceed_limit rollup -> Some rollup
      | _ -> None)
    (fun rollup -> Tx_rollup_inbox_size_would_exceed_limit rollup) ;
  (* Tx_rollup_message_count_would_exceed_limit *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_inbox_count_would_exceed_limit"
    ~title:"Transaction rollup inbox’s size would exceed the limit"
    ~description:"Transaction rollup inbox’s size would exceed the limit"
    ~pp:(fun ppf addr ->
      Format.fprintf
        ppf
        "Adding the submitted message would make the inbox of %a exceed the \
         authorized limit at this level"
        Tx_rollup_repr.pp
        addr)
    (obj1 (req "tx_rollup_address" Tx_rollup_repr.encoding))
    (function
      | Tx_rollup_inbox_count_would_exceed_limit rollup -> Some rollup
      | _ -> None)
    (fun rollup -> Tx_rollup_inbox_count_would_exceed_limit rollup) ;
  (* Tx_rollup_message_size_exceeds_limit *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_message_size_exceeds_limit"
    ~title:"A message submtitted to a transaction rollup inbox exceeds limit"
    ~description:
      "A message submtitted to a transaction rollup inbox exceeds limit"
    empty
    (function Tx_rollup_message_size_exceeds_limit -> Some () | _ -> None)
    (fun () -> Tx_rollup_message_size_exceeds_limit)
