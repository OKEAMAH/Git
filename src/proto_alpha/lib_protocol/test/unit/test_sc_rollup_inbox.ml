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

(** Testing
    -------
    Component:  Protocol (smart contract rollup inbox)
    Invocation: dune exec src/proto_alpha/lib_protocol/test/unit/main.exe \
                -- test "^\[Unit\] sc rollup inbox$"
    Subject:    These unit tests check the off-line inbox implementation for
                smart contract rollups
*)

open Protocol
open Sc_rollup_inbox_repr

(* HELPERS *)

exception Sc_rollup_inbox_test_error of string

let err x = Exn (Sc_rollup_inbox_test_error x)

let rollup = Sc_rollup_repr.Address.zero

let wrap_lwt v = Lwt.map Environment.wrap_tzresult v

let wrap m = Environment.wrap_tzresult m

let setup_inbox_with_messages ?(origination_level = Raw_level_repr.root)
    list_of_payloads f =
  let open Lwt_result_syntax in
  let* {context = ctxt; _}, _contract = Context.init1 () in
  let*! inbox = empty ctxt rollup origination_level in
  let rec aux level inbox level_tree = function
    | [] -> return (level_tree, inbox)
    | [] :: ps ->
        let level = Raw_level_repr.succ level in
        aux level inbox None ps
    | payloads :: ps ->
        let*? payloads =
          List.map_e
            (fun payload ->
              Sc_rollup_inbox_message_repr.(serialize @@ External payload)
              |> wrap)
            payloads
        in
        let* level_tree, inbox =
          add_messages_no_history ctxt inbox level payloads None |> wrap_lwt
        in
        let level = Raw_level_repr.succ level in
        aux level inbox (Some level_tree) ps
  in
  let* current_level_tree, inbox =
    aux origination_level inbox None list_of_payloads
  in
  f ctxt current_level_tree inbox

module Tree = struct
  open Tezos_context_memory.Context

  type nonrec t = t

  type nonrec tree = tree

  module Tree = struct
    include Tezos_context_memory.Context.Tree

    type nonrec t = t

    type nonrec tree = tree

    type key = string list

    type value = bytes
  end

  let commit_tree context key tree =
    let open Lwt_syntax in
    let* ctxt = Tezos_context_memory.Context.add_tree context key tree in
    let* _ = commit ~time:Time.Protocol.epoch ~message:"" ctxt in
    return ()

  let lookup_tree context hash =
    let open Lwt_syntax in
    let* _, tree =
      produce_tree_proof
        (index context)
        (`Node (Hash.to_context_hash hash))
        (fun x -> Lwt.return (x, x))
    in
    return (Some tree)

  type proof = Proof.tree Proof.t

  let verify_proof proof f =
    Lwt.map Result.to_option (verify_tree_proof proof f)

  let produce_proof context tree f =
    let open Lwt_syntax in
    let* proof =
      produce_tree_proof (index context) (`Node (Tree.hash tree)) f
    in
    return (Some proof)

  let kinded_hash_to_inbox_hash = function
    | `Value hash | `Node hash -> Hash.of_context_hash hash

  let proof_before proof = kinded_hash_to_inbox_hash proof.Proof.before

  let proof_encoding =
    Tezos_context_helpers.Context.Proof_encoding.V1.Tree32.tree_proof_encoding
end

(** This is a second instance of the inbox module. It uses the {!Tree}
    module above for its Irmin interface, which gives it a full context
    and the ability to generate tree proofs.

    It is intended to resemble (at least well enough for these tests)
    the rollup node's inbox instance. *)
module Node = Make_hashing_scheme (Tree)

(** This is basically identical to {!setup_inbox_with_messages}, except
    that it uses the {!Node} instance instead of the protocol instance. *)
let setup_node_inbox_with_messages ?(origination_level = Raw_level_repr.root)
    list_of_payloads f =
  let open Node in
  let open Lwt_result_syntax in
  let*! index = Tezos_context_memory.Context.init "foo" in
  let ctxt = Tezos_context_memory.Context.empty index in
  let*! inbox = empty ctxt rollup origination_level in
  let history = history_at_genesis ~capacity:10000L in
  let rec aux level history inbox inboxes level_tree = function
    | [] -> return (level_tree, history, inbox, inboxes)
    | payloads :: ps -> (
        let*? payloads =
          List.map_e
            (fun payload ->
              Sc_rollup_inbox_message_repr.(serialize @@ External payload)
              |> wrap)
            payloads
        in
        match payloads with
        | [] ->
            let level = Raw_level_repr.succ level in
            aux level history inbox inboxes level_tree ps
        | _ ->
            let* level_tree, history, new_inbox =
              add_messages ctxt history inbox level payloads level_tree
              |> wrap_lwt
            in
            let level = Raw_level_repr.succ level in
            aux level history new_inbox (inbox :: inboxes) (Some level_tree) ps)
  in
  let* level_tree, history, inbox, inboxes =
    aux origination_level history inbox [] None list_of_payloads
  in
  f ctxt level_tree history inbox inboxes

(* An external message is prefixed with a tag whose length is one byte, and
   whose value is 1. *)
let encode_external_message message =
  let prefix = "\001" in
  Bytes.of_string (prefix ^ message)

(** In the tests below we use the {!Node} inbox above to generate proofs,
    but we need to test that they can be interpreted and validated by
    the protocol instance of the inbox code. We rely on the two
    instances having the same encoding, and use this function to
    convert. *)
let node_proof_to_protocol_proof p =
  let open Data_encoding.Binary in
  let enc = serialized_proof_encoding in
  let bytes = Node.to_serialized_proof p |> to_bytes_exn enc in
  of_bytes_exn enc bytes |> of_serialized_proof
  |> WithExceptions.Option.get ~loc:__LOC__

let level_of_int n = Raw_level_repr.of_int32_exn (Int32.of_int n)

let level_to_int l = Int32.to_int (Raw_level_repr.to_int32 l)

let payload_string msg =
  Sc_rollup_inbox_message_repr.unsafe_of_string
    (Bytes.to_string (encode_external_message msg))

let next_input ps l n =
  let ( let* ) = Option.bind in
  let* level = List.nth ps (level_to_int l) in
  match List.nth level (Z.to_int n) with
  | Some msg ->
      let payload = payload_string msg in
      Some Sc_rollup_PVM_sem.{inbox_level = l; message_counter = n; payload}
  | None ->
      let rec aux l =
        let* payloads = List.nth ps l in
        match List.hd payloads with
        | Some msg ->
            let payload = payload_string msg in
            Some
              Sc_rollup_PVM_sem.
                {
                  inbox_level = level_of_int l;
                  message_counter = Z.zero;
                  payload;
                }
        | None -> aux (l + 1)
      in
      aux (level_to_int l + 1)

(* TEST *)

let test_empty () =
  setup_inbox_with_messages [] @@ fun _ctxt current_level_tree inbox ->
  fail_unless
    (Compare.Int64.(
       equal (number_of_messages_during_commitment_period inbox) 0L)
    && Option.is_none current_level_tree)
    (err "An empty inbox should have no available message.")

let test_add_messages payloads =
  let nb_payloads = List.length payloads in
  setup_inbox_with_messages [payloads] @@ fun _ctxt _current_level_tree inbox ->
  fail_unless
    Compare.Int64.(
      equal
        (number_of_messages_during_commitment_period inbox)
        (Int64.of_int nb_payloads))
    (err "Invalid number of messages during commitment period.")

let test_get_message_payload payloads =
  let open Lwt_syntax in
  setup_inbox_with_messages [payloads] @@ fun _ctxt current_level_tree _inbox ->
  List.iteri_es
    (fun i message ->
      let expected_payload = encode_external_message message in
      match current_level_tree with
      | Some messages -> (
          let* payload = get_message_payload messages (Z.of_int i) in
          match payload with
          | Some payload ->
              let payload =
                Sc_rollup_inbox_message_repr.unsafe_to_string payload
              in
              fail_unless
                (String.equal payload (Bytes.to_string expected_payload))
                (err (Printf.sprintf "Expected %s, got %s" message payload))
          | None ->
              fail
                (err
                   (Printf.sprintf "No message payload number %d in messages" i))
          )
      | None -> fail (err (Printf.sprintf "current message tree is empty")))
    payloads

let test_inclusion_proof_production (list_of_payloads, n) =
  setup_node_inbox_with_messages list_of_payloads
  @@ fun _ctxt _current_level_tree history inbox inboxes ->
  let old_inbox = Stdlib.List.nth inboxes n in
  produce_inclusion_proof
    history
    (old_levels_messages old_inbox)
    (old_levels_messages inbox)
  |> function
  | None ->
      fail
      @@ err
           "It should be possible to produce an inclusion proof between two \
            versions of the same inbox."
  | Some proof ->
      setup_inbox_with_messages list_of_payloads
      @@ fun _ctxt _current_level_tree proto_inbox ->
      fail_unless
        (equal inbox proto_inbox
        && verify_inclusion_proof
             proof
             (old_levels_messages old_inbox)
             (old_levels_messages inbox))
        (err "The produced inclusion proof is invalid for the protocol.")

let test_inclusion_proof_verification (list_of_payloads, n) =
  setup_node_inbox_with_messages list_of_payloads
  @@ fun _ctxt _current_level_tree history inbox inboxes ->
  let old_inbox = Stdlib.List.nth inboxes n in
  produce_inclusion_proof
    history
    (old_levels_messages old_inbox)
    (old_levels_messages inbox)
  |> function
  | None ->
      fail
      @@ err
           "It should be possible to produce an inclusion proof between two \
            versions of the same inbox."
  | Some proof ->
      let old_inbox' = Stdlib.List.nth inboxes (Random.int (1 + n)) in
      setup_inbox_with_messages list_of_payloads
      @@ fun _ctxt _current_level_tree proto_inbox ->
      fail_unless
        (equal old_inbox old_inbox'
        || (not (equal inbox proto_inbox))
        || not
             (verify_inclusion_proof
                proof
                (old_levels_messages old_inbox')
                (old_levels_messages inbox)))
        (err
           "Verification should rule out a valid proof which is not about the \
            given inboxes.")

let test_inbox_proof_production (list_of_payloads, l, n) =
  (* We begin with a Node inbox so we can produce a proof. *)
  let exp_input = next_input list_of_payloads l n in
  setup_node_inbox_with_messages list_of_payloads
  @@ fun ctxt current_level_tree history inbox _inboxes ->
  let open Lwt_syntax in
  let* history, history_proof =
    Node.form_history_proof ctxt history inbox current_level_tree
  in
  let* result = Node.produce_proof ctxt history history_proof (l, n) in
  match result with
  | Ok (proof, input) -> (
      (* We now switch to a protocol inbox built from the same messages
         for verification. *)
      setup_inbox_with_messages list_of_payloads
      @@ fun _ctxt _current_level_tree inbox ->
      let snapshot = take_snapshot inbox in
      let proof = node_proof_to_protocol_proof proof in
      let* verification = verify_proof (l, n) snapshot proof in
      match verification with
      | Ok v_input ->
          fail_unless
            (v_input = input && v_input = exp_input)
            (err "Proof verified but did not match")
      | Error _ -> fail (err "Proof verification failed"))
  | Error _ -> fail (err "Proof production failed")

let test_inbox_proof_verification (list_of_payloads, l, n) =
  (* We begin with a Node inbox so we can produce a proof. *)
  setup_node_inbox_with_messages list_of_payloads
  @@ fun ctxt current_level_tree history inbox inboxes ->
  let open Lwt_syntax in
  let* history, history_proof =
    Node.form_history_proof ctxt history inbox current_level_tree
  in
  let* result = Node.produce_proof ctxt history history_proof (l, n) in
  match result with
  | Ok (proof, _input) -> (
      (* Use the incorrect inbox *)
      let inbox = WithExceptions.Option.get ~loc:__LOC__ @@ List.hd inboxes in
      let snapshot = take_snapshot inbox in
      let proof = node_proof_to_protocol_proof proof in
      let* verification = verify_proof (l, n) snapshot proof in
      match verification with
      | Ok _ -> fail (err "Proof should not be valid")
      | Error _ -> return (ok ()))
  | Error _ -> fail (err "Proof production failed")

let test_empty_inbox_proof (origination_level, n) =
  let open Lwt_syntax in
  setup_node_inbox_with_messages ~origination_level []
  @@ fun ctxt current_level_tree history inbox inboxes ->
  assert (current_level_tree = None) ;
  assert (inboxes = []) ;
  let* history, history_proof =
    Node.form_history_proof ctxt history inbox current_level_tree
  in
  let* result =
    Node.produce_proof ctxt history history_proof (Raw_level_repr.root, n)
  in
  match result with
  | Ok (proof, input) -> (
      (* We now switch to a protocol inbox for verification. *)
      setup_inbox_with_messages ~origination_level []
      @@ fun _ctxt current_level_tree proto_inbox ->
      assert (current_level_tree = None) ;
      let snapshot = take_snapshot proto_inbox in
      let proof = node_proof_to_protocol_proof proof in
      let* verification =
        verify_proof (Raw_level_repr.root, n) snapshot proof
      in
      match verification with
      | Ok v_input ->
          fail_unless
            (v_input = input && v_input = None)
            (err "Proof verified but did not match")
      | Error _ -> fail (err "Proof verification failed"))
  | Error _ -> fail (err "Proof production failed")

let tests =
  let msg_size = QCheck2.Gen.(0 -- 100) in
  let bounded_string = QCheck2.Gen.string_size msg_size in
  [
    Tztest.tztest "Empty inbox" `Quick test_empty;
    Tztest.tztest_qcheck2
      ~name:"Added messages are available."
      QCheck2.Gen.(list_size (1 -- 50) bounded_string)
      test_add_messages;
    Tztest.tztest_qcheck2
      ~name:"Get message payload."
      QCheck2.Gen.(list_size (1 -- 50) bounded_string)
      test_get_message_payload;
  ]
  @
  let gen_inclusion_proof_inputs =
    QCheck2.Gen.(
      let small = 2 -- 10 in
      let* a = list_size small bounded_string in
      let* b = list_size small bounded_string in
      let* l = list_size small (list_size small bounded_string) in
      let l = a :: b :: l in
      let* n = 0 -- (List.length l - 2) in
      return (l, n))
  in
  let gen_proof_inputs =
    QCheck2.Gen.(
      let small = 0 -- 5 in
      let* level = 0 -- 8 in
      let* before = list_size (return level) (list_size small bounded_string) in
      let* at = list_size (2 -- 6) bounded_string in
      let* after = list_size small (list_size small bounded_string) in
      let payloads = List.append before (at :: after) in
      let* n = 0 -- (List.length at + 3) in
      return (payloads, level_of_int level, Z.of_int n))
  in
  [
    Tztest.tztest_qcheck2
      ~name:"Produce inclusion proof between two related inboxes."
      gen_inclusion_proof_inputs
      test_inclusion_proof_production;
    Tztest.tztest_qcheck2
      ~name:"Verify inclusion proofs."
      gen_inclusion_proof_inputs
      test_inclusion_proof_verification;
    Tztest.tztest_qcheck2
      ~count:10
      ~name:"Produce inbox proofs"
      gen_proof_inputs
      test_inbox_proof_production;
    Tztest.tztest_qcheck2
      ~count:10
      ~name:"Verify inbox proofs"
      gen_proof_inputs
      test_inbox_proof_verification;
    Tztest.tztest_qcheck2
      ~name:"An empty inbox is still able to produce proofs that return None"
      QCheck2.Gen.(
        let* n = 0 -- 2000 in
        let* m = 0 -- 1000 in
        return (level_of_int n, Z.of_int m))
      test_empty_inbox_proof;
  ]
