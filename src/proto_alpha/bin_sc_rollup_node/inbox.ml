(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

(* module Constants will be shadowed by Alpha_context.Constansts
   once we open Alpha_context, hence we we alias it to Rollup_node_constants
*)
open Protocol
open Alpha_context

let lift promise = Lwt.map Environment.wrap_tzresult promise

module State = struct
  let add_messages = Store.Messages.add

  let add_inbox = Store.Inboxes.add

  let save_history = Store.Inbox_history.set

  let level_of_hash = State.level_of_hash

  (** [inbox_of_head node_ctxt store block] returns the latest inbox at the
      given [block]. This function always returns [Some inbox] for all levels
      at and after the rollup genesis. *)
  let inbox_of_head node_ctxt Layer1.{hash = block_hash; level = block_level} =
    let open Lwt_result_syntax in
    let open Node_context in
    let*! possible_inbox = Store.Inboxes.find node_ctxt.store block_hash in
    (* Pre-condition: forall l. (l > genesis_level) => inbox[l] <> None. *)
    match possible_inbox with
    | None ->
        (* The inbox exists for each tezos block the rollup should care about.
           That is, every block after the origination level. We then join
           the bandwagon and build the inbox on top of the protocol's inbox
           at the end of the origination level. *)
        let genesis_level = Raw_level.to_int32 node_ctxt.genesis_info.level in
        if block_level = genesis_level then
          let Node_context.{cctxt; _} = node_ctxt in
          Plugin.RPC.Sc_rollup.inbox cctxt (cctxt#chain, `Level genesis_level)
        else if block_level > genesis_level then
          (* Invariant broken, the inbox for this level should exist. *)
          failwith
            "The inbox for block hash %a (level = %ld) is missing."
            Tezos_crypto.Block_hash.pp
            block_hash
            block_level
        else
          (* The rollup node should not care about levels before the genesis
             level. *)
          failwith
            "Asking for the inbox before the genesis level (i.e. %ld), out of \
             the scope of the rollup's node"
            block_level
    | Some inbox -> return inbox

  let history node_ctxt =
    let open Lwt_result_syntax in
    let open Node_context in
    let*! res = Store.Inbox_history.find node_ctxt.store in
    match res with
    | Some history -> return history
    | None -> return @@ Sc_rollup.Inbox.History.empty ~capacity:60000L
end

let get_messages Node_context.{l1_ctxt; _} head =
  let open Lwt_result_syntax in
  let* block = Layer1.fetch_tezos_block l1_ctxt head in
  let apply (type kind) accu ~source:_ (operation : kind manager_operation)
      _result =
    let open Result_syntax in
    let+ accu = accu in
    match operation with
    | Sc_rollup_add_messages {messages} ->
        let messages =
          List.map
            (fun message -> Sc_rollup.Inbox_message.External message)
            messages
        in
        List.rev_append messages accu
    | _ -> accu
  in
  let apply_internal (type kind) accu ~source
      (operation : kind Apply_internal_results.internal_operation)
      (result :
        kind Apply_internal_results.successful_internal_operation_result) =
    let open Result_syntax in
    let* accu = accu in
    match (operation, result) with
    | ( {
          operation = Transaction {destination = Sc_rollup rollup; parameters; _};
          source = Originated sender;
          _;
        },
        ITransaction_result (Transaction_to_sc_rollup_result _) ) ->
        let+ payload =
          Environment.wrap_tzresult @@ Script_repr.force_decode parameters
        in
        let message =
          Sc_rollup.Inbox_message.Transfer
            {destination = rollup; payload; sender; source}
        in
        Sc_rollup.Inbox_message.Internal message :: accu
    | _ -> return accu
  in
  let*? rev_messages =
    Layer1_services.(
      process_applied_manager_operations
        (Ok [])
        block.operations
        {apply; apply_internal})
  in
  let ({timestamp; predecessor; _} : Block_header.shell_header) =
    block.header.shell
  in
  return (List.rev rev_messages, timestamp, predecessor)

let same_inbox_as_layer_1 node_ctxt head_hash inbox =
  let open Lwt_result_syntax in
  let head_block = `Hash (head_hash, 0) in
  let Node_context.{cctxt; _} = node_ctxt in
  let* layer1_inbox =
    Plugin.RPC.Sc_rollup.inbox cctxt (cctxt#chain, head_block)
  in
  fail_unless
    (Sc_rollup.Inbox.equal layer1_inbox inbox)
    (Sc_rollup_node_errors.Inconsistent_inbox {layer1_inbox; inbox})

let add_messages ~timestamp ~predecessor inbox history messages =
  let open Lwt_result_syntax in
  lift
  @@ let*? ( messages_history,
             history,
             inbox,
             _witness,
             messages_with_protocol_internal_messages ) =
       Sc_rollup.Inbox.add_all_messages
         ~timestamp
         ~predecessor
         history
         inbox
         messages
     in
     let Sc_rollup.Inbox.{hash = witness_hash; _} =
       Sc_rollup.Inbox.current_level_proof inbox
     in
     return
       ( messages_history,
         witness_hash,
         history,
         inbox,
         messages_with_protocol_internal_messages )

let process_head (node_ctxt : _ Node_context.t)
    Layer1.({level; hash = head_hash} as head) =
  let open Lwt_result_syntax in
  let first_inbox_level =
    Raw_level.to_int32 node_ctxt.genesis_info.level |> Int32.succ
  in
  if level >= first_inbox_level then
    (*

          We compute the inbox of this block using the inbox of its
          predecessor. That way, the computation of inboxes is robust
          to chain reorganization.

    *)
    let* predecessor = Layer1.get_predecessor node_ctxt.l1_ctxt head in
    let* inbox = State.inbox_of_head node_ctxt predecessor in
    let* history = State.history node_ctxt in
    let*? level = Environment.wrap_tzresult @@ Raw_level.of_int32 level in
    let* ctxt =
      if Raw_level.(level <= node_ctxt.Node_context.genesis_info.level) then
        (* This is before we have interpreted the boot sector, so we start
           with an empty context in genesis *)
        return (Context.empty node_ctxt.context)
      else Node_context.checkout_context node_ctxt predecessor.hash
    in
    let* collected_messages, timestamp, predecessor_hash =
      get_messages node_ctxt head_hash
    in
    let*! () =
      Inbox_event.get_messages
        head_hash
        (Raw_level.to_int32 level)
        (List.length collected_messages)
    in
    let* ( _messages_history,
           messages_hash,
           history,
           inbox,
           messages_with_protocol_internal_messages ) =
      add_messages
        ~timestamp
        ~predecessor:predecessor_hash
        inbox
        history
        collected_messages
    in
    let*! () =
      State.add_messages
        node_ctxt.store
        head_hash
        messages_with_protocol_internal_messages
    in
    let* () = same_inbox_as_layer_1 node_ctxt head_hash inbox in
    let*! () = State.add_inbox node_ctxt.store head_hash inbox in
    let*! () = State.save_history node_ctxt.store history in
    let*! () =
      Store.Payloads_witness.add
        node_ctxt.store
        messages_hash
        (head_hash, Raw_level.to_int32 level, predecessor_hash, timestamp)
    in
    return ctxt
  else return (Context.empty node_ctxt.context)

let inbox_of_hash node_ctxt hash =
  let open Lwt_result_syntax in
  let* level = State.level_of_hash node_ctxt.Node_context.store hash in
  State.inbox_of_head node_ctxt {hash; level}

let inbox_of_head = State.inbox_of_head

let history = State.history

let start () = Inbox_event.starting ()
