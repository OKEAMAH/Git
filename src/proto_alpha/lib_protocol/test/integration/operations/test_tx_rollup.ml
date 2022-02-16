(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxheadalpha.com>                    *)
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
    Component:    Rollup layer 1 logic
    Invocation:   dune exec \
                  src/proto_alpha/lib_protocol/test/integration/operations/main.exe \
                  -- test "^tx rollup$"
    Subject:      Test rollup
*)

open Protocol
open Alpha_context
open Test_tez

(** [check_tx_rollup_exists ctxt tx_rollup] returns [()] iff [tx_rollup]
    is a valid address for a transaction rollup. Otherwise, it fails. *)
let check_tx_rollup_exists ctxt tx_rollup =
  Context.Tx_rollup.state ctxt tx_rollup >|=? fun _ -> ()

(** [check_proto_error f t] checks that the first error of [t]
    satisfies the boolean function [f]. *)
let check_proto_error f t =
  match t with
  | Environment.Ecoproto_error e :: _ when f e ->
      Assert.test_error_encodings e ;
      return_unit
  | _ -> failwith "Unexpected error: %a" Error_monad.pp_print_trace t

(** [test_disable_feature_flag] try to originate a tx rollup with the feature
    flag is deactivated and check it fails *)
let test_disable_feature_flag () =
  Context.init 1 >>=? fun (b, contracts) ->
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  Incremental.begin_construction b >>=? fun i ->
  Op.tx_rollup_origination (I i) contract >>=? fun (op, _tx_rollup) ->
  Incremental.add_operation
    ~expect_failure:
      (check_proto_error (function
          | Apply.Tx_rollup_feature_disabled -> true
          | _ -> false))
    i
    op
  >>= fun _i -> return_unit

let message_hash_testable : Tx_rollup_message.hash Alcotest.testable =
  Alcotest.testable Tx_rollup_message.pp_hash ( = )

let wrap m = m >|= Environment.wrap_tzresult

(** [inbox_fees state size] computes the fees (per byte of message)
    one has to pay to submit a message to the current inbox. *)
let inbox_fees state size =
  Environment.wrap_tzresult (Tx_rollup_state.fees state size)

(** [fees_per_byte state] returns the cost to insert one byte inside
    the inbox. *)
let fees_per_byte state = inbox_fees state 1

(** [check_batch_in_inbox inbox n expected] checks that the [n]th
    element of [inbox] is a batch equal to [expected]. *)
let check_batch_in_inbox :
    Tx_rollup_inbox.t -> int -> string -> unit tzresult Lwt.t =
 fun inbox n expected ->
  let (expected_batch, _) = Tx_rollup_message.make_batch expected in
  let expected_hash = Tx_rollup_message.hash expected_batch in
  match List.nth inbox.contents n with
  | Some content ->
      Alcotest.(
        check
          message_hash_testable
          "Expected batch with a different content"
          content
          expected_hash) ;
      return_unit
  | _ -> Alcotest.fail "Selected message in the inbox is not a batch"

(** [context_init n] initializes a context with no consensus rewards
    to not interfere with balances prediction. It returns the created
    context and [n] contracts. *)
let context_init n =
  Context.init
    ~consensus_threshold:0
    ~tx_rollup_enable:true
    ~endorsing_reward_per_slot:Tez.zero
    ~baking_reward_bonus_per_slot:Tez.zero
    ~baking_reward_fixed_portion:Tez.zero
    n

(** [originate b contract] originates a tx_rollup from [contract],
    and returns the new block and the tx_rollup address. *)
let originate b contract =
  Op.tx_rollup_origination (B b) contract >>=? fun (operation, tx_rollup) ->
  Block.bake ~operation b >>=? fun b -> return (b, tx_rollup)

(** Initializes the context, originates a tx_rollup and submits a batch.

    Returns the first contract and its balance, the originated tx_rollup,
    the state with the tx_rollup, and the baked block with the batch submitted.
*)
let init_originate_and_submit ?(batch = String.make 5 'c') () =
  context_init 1 >>=? fun (b, contracts) ->
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b contract >>=? fun (b, tx_rollup) ->
  Context.Contract.balance (B b) contract >>=? fun balance ->
  Context.Tx_rollup.state (B b) tx_rollup >>=? fun state ->
  Op.tx_rollup_submit_batch (B b) contract tx_rollup batch >>=? fun operation ->
  Block.bake ~operation b >>=? fun b ->
  return ((contract, balance), state, tx_rollup, b)

let commitment_hash_testable =
  Alcotest.testable
    Tx_rollup_commitments.Commitment_hash.pp
    Tx_rollup_commitments.Commitment_hash.( = )

let public_key_hash_testable =
  Alcotest.testable Signature.Public_key_hash.pp Signature.Public_key_hash.( = )

let raw_level_testable = Alcotest.testable Raw_level.pp Raw_level.( = )

let rng_state = Random.State.make_self_init ()

let gen_l2_account () =
  let seed =
    Bytes.init 32 (fun _ -> char_of_int @@ Random.State.int rng_state 255)
  in
  let secret_key = Bls12_381.Signature.generate_sk seed in
  let public_key = Bls12_381.Signature.derive_pk secret_key in
  (secret_key, public_key, Tx_rollup_l2_address.of_bls_pk public_key)

let is_implicit_exn x =
  match Alpha_context.Contract.is_implicit x with
  | Some x -> x
  | None -> raise (Invalid_argument "is_implicit_exn")

let assert_ok res = match res with Ok r -> r | Error _ -> assert false

let raw_level level = assert_ok @@ Raw_level.of_int32 level

let public_key_hash_exn contract =
  match Contract.is_implicit contract with
  | None -> assert false
  | Some public_key_hash -> public_key_hash

let check_bond ctxt tx_rollup contract count =
  let pkh = public_key_hash_exn contract in
  wrap (Tx_rollup_commitments.pending_bonded_commitments ctxt tx_rollup pkh)
  >>=? fun (_, pending) ->
  Alcotest.(check int "Pending commitment count correct" count pending) ;
  return ()

let rec bake_until i top =
  let level = Incremental.level i in
  if level >= top then return i
  else
    Incremental.finalize_block i >>=? fun b ->
    Incremental.begin_construction b >>=? fun i -> bake_until i top

let assert_retired retired =
  match retired with
  | `Retired -> return_unit
  | _ -> failwith "Expected retired"

(* Make a valid commitment for a batch.  TODO/TORU: roots are still
   wrong, of course, until we get Merkle proofs*)
let make_commitment_for_batch i level tx_rollup =
  let ctxt = Incremental.alpha_ctxt i in
  wrap
    (Alpha_context.Tx_rollup_inbox.Internal_for_tests.get_metadata
       ctxt
       level
       tx_rollup)
  >>=? fun (ctxt, metadata) ->
  Lwt.return
  @@ List.init ~when_negative_length:[] metadata.count (fun i ->
         let batch : Tx_rollup_commitments.Commitment.batch_commitment =
           {root = Bytes.make 20 (Char.chr i)}
         in
         batch)
  >>=? fun batches ->
  (match metadata.predecessor with
  | None -> return_none
  | Some predecessor_level -> (
      wrap
        (Lwt.return
        @@ Raw_level.of_int32 (Raw_level_repr.to_int32 predecessor_level))
      >>=? fun predecessor_level ->
      wrap
        (Tx_rollup_commitments.get_commitments ctxt tx_rollup predecessor_level)
      >|=? function
      | (_, []) -> None
      | (_, hd :: _) -> Some hd.hash))
  >>=? fun predecessor ->
  let commitment : Tx_rollup_commitments.Commitment.t =
    {level; batches; predecessor; inbox_hash = metadata.hash}
  in
  return commitment

let constants =
  {
    Tezos_protocol_alpha_parameters.Default_parameters.constants_test with
    consensus_threshold = 0;
    endorsing_reward_per_slot = Tez.zero;
    baking_reward_bonus_per_slot = Tez.zero;
    baking_reward_fixed_portion = Tez.zero;
    tx_rollup_enable = true;
  }

let originate_with_constants constants n =
  Context.init_with_constants constants n >>=? fun (b, contracts) ->
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b contract >>=? fun (b, tx_rollup) ->
  return (b, tx_rollup, contracts)

let range start top =
  let rec aux n acc = if n < start then acc else aux (n - 1) (n :: acc) in
  aux top []

(** ---- TESTS -------------------------------------------------------------- *)

(** [test_origination] originates a transaction rollup and checks that
    it burns the expected quantity of xtz. *)
let test_origination () =
  Context.init ~tx_rollup_enable:true 1 >>=? fun (b, contracts) ->
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  Context.get_constants (B b)
  >>=? fun {parametric = {tx_rollup_origination_size; cost_per_byte; _}; _} ->
  Context.Contract.balance (B b) contract >>=? fun balance ->
  Incremental.begin_construction b >>=? fun i ->
  Op.tx_rollup_origination (I i) contract >>=? fun (op, tx_rollup) ->
  Incremental.add_operation i op >>=? fun i ->
  check_tx_rollup_exists (I i) tx_rollup >>=? fun () ->
  cost_per_byte *? Int64.of_int tx_rollup_origination_size
  >>?= fun tx_rollup_origination_burn ->
  Assert.balance_was_debited
    ~loc:__LOC__
    (I i)
    contract
    balance
    tx_rollup_origination_burn

(** [test_two_originations] originates two transaction rollups in the
    same operation and checks that they have a different address. *)
let test_two_originations () =
  Context.init ~tx_rollup_enable:true 1 >>=? fun (b, contracts) ->
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  Incremental.begin_construction b >>=? fun i ->
  Op.tx_rollup_origination (I i) contract >>=? fun (op1, _false_tx_rollup1) ->
  (* tx_rollup1 and tx_rollup2 are equal and both are false. The addresses are
     derived from a value called `origination_nonce` that is dependent of the
     tezos operation hash. Also each origination increment this value.

     Here the origination_nonce is wrong because it's not based on the injected
     operation (the combined one. Also the used origination nonce is not
     incremented between _false_tx_rollup1 and _false_tx_rollup2 as the protocol
     do. *)
  Op.tx_rollup_origination (I i) contract >>=? fun (op2, _false_tx_rollup2) ->
  Op.combine_operations ~source:contract (B b) [op1; op2] >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  let nonce =
    Origination_nonce.Internal_for_tests.initial (Operation.hash_packed op)
  in
  let txo1 = Tx_rollup.Internal_for_tests.originated_tx_rollup nonce in
  let nonce = Origination_nonce.Internal_for_tests.incr nonce in
  let txo2 = Tx_rollup.Internal_for_tests.originated_tx_rollup nonce in
  Assert.not_equal
    ~loc:__LOC__
    Tx_rollup.equal
    "Two transaction rollups originated in one operation have different \
     addresses"
    Tx_rollup.pp
    txo1
    txo2
  >>=? fun () ->
  check_tx_rollup_exists (I i) txo1 >>=? fun () ->
  check_tx_rollup_exists (I i) txo2 >>=? fun () -> return_unit

(** [test_fees_per_byte_update] checks [update_fees_per_byte] behaves
    according to its docstring. *)
let test_fees_per_byte_update () =
  let test ~inbox_ema ~fees_per_byte ~final_size ~hard_limit ~result =
    let fees_per_byte = Tez.of_mutez_exn fees_per_byte in
    let result = Tez.of_mutez_exn result in
    let state =
      Alpha_context.Tx_rollup_state.Internal_for_tests.make
        ~fees_per_byte
        ~inbox_ema
        ~last_inbox_level:None
    in
    let state =
      Alpha_context.Tx_rollup_state.Internal_for_tests.update_fees_per_byte
        state
        ~final_size
        ~hard_limit
    in
    let new_fees =
      match Alpha_context.Tx_rollup_state.fees state 1 with
      | Ok x -> x
      | Error _ ->
          Stdlib.failwith "could not compute the fees for a message of 1 byte"
    in
    Assert.equal_tez ~loc:__LOC__ result new_fees
  in

  (* Fees per byte should remain constant *)
  test
    ~inbox_ema:1_000
    ~fees_per_byte:1_000L
    ~final_size:1_000
    ~hard_limit:1_100
    ~result:1_000L
  >>=? fun () ->
  (* Fees per byte should increase *)
  test
    ~inbox_ema:1_000
    ~fees_per_byte:1_000L
    ~final_size:1_000
    ~hard_limit:1_000
    ~result:1_050L
  >>=? fun () ->
  (* Fees per byte should decrease *)
  test
    ~inbox_ema:1_000
    ~fees_per_byte:1_000L
    ~final_size:1_000
    ~hard_limit:1_500
    ~result:950L
  >>=? fun () ->
  (* Fees per byte should increase even with [0] as its initial value *)
  test
    ~inbox_ema:1_000
    ~fees_per_byte:0L
    ~final_size:1_000
    ~hard_limit:1_000
    ~result:1L
  >>=? fun () -> return_unit

(** [test_add_batch] originates a tx rollup and fills one of its inbox
    with an arbitrary batch of data. *)
let test_add_batch () =
  let contents_size = 5 in
  let contents = String.make contents_size 'c' in
  init_originate_and_submit ~batch:contents ()
  >>=? fun ((contract, balance), state, tx_rollup, b) ->
  Context.Tx_rollup.inbox (B b) tx_rollup >>=? fun {contents; cumulated_size} ->
  let length = List.length contents in
  Alcotest.(check int "Expect an inbox with a single item" 1 length) ;
  Alcotest.(check int "Expect cumulated size" contents_size cumulated_size) ;
  inbox_fees state contents_size >>?= fun cost ->
  Assert.balance_was_debited ~loc:__LOC__ (B b) contract balance cost

(** [test_add_two_batches] originates a tx rollup and adds two
    arbitrary batches to one of its inboxes. Ensure that their order
    is correct. *)
let test_add_two_batches () =
  (*
    TODO: https://gitlab.com/tezos/tezos/-/issues/2331
    This test can be generalized using a property-based approach.
   *)
  let contents_size1 = 5 in
  let contents1 = String.make contents_size1 'c' in
  init_originate_and_submit ~batch:contents1 ()
  >>=? fun ((contract, balance), state, tx_rollup, b) ->
  Op.tx_rollup_submit_batch (B b) contract tx_rollup contents1 >>=? fun op1 ->
  Context.Contract.counter (B b) contract >>=? fun counter ->
  let contents_size2 = 6 in
  let contents2 = String.make contents_size2 'd' in
  Op.tx_rollup_submit_batch
    ~counter:Z.(add counter (of_int 1))
    (B b)
    contract
    tx_rollup
    contents2
  >>=? fun op2 ->
  Block.bake ~operations:[op1; op2] b >>=? fun b ->
  Context.Tx_rollup.inbox (B b) tx_rollup >>=? fun inbox ->
  let length = List.length inbox.contents in
  let expected_cumulated_size = contents_size1 + contents_size2 in

  Alcotest.(check int "Expect an inbox with two items" 2 length) ;
  Alcotest.(
    check
      int
      "Expect cumulated size"
      expected_cumulated_size
      inbox.cumulated_size) ;

  Context.Tx_rollup.inbox (B b) tx_rollup >>=? fun {contents; _} ->
  Alcotest.(check int "Expect an inbox with two items" 2 (List.length contents)) ;
  check_batch_in_inbox inbox 0 contents1 >>=? fun () ->
  check_batch_in_inbox inbox 1 contents2 >>=? fun () ->
  inbox_fees state expected_cumulated_size >>?= fun cost ->
  Assert.balance_was_debited ~loc:__LOC__ (B b) contract balance cost

(** Try to add a batch too large in an inbox. *)
let test_batch_too_big () =
  context_init 1 >>=? fun (b, contracts) ->
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b contract >>=? fun (b, tx_rollup) ->
  Context.get_constants (B b) >>=? fun constant ->
  let contents =
    String.make constant.parametric.tx_rollup_hard_size_limit_per_message 'd'
  in
  Incremental.begin_construction b >>=? fun i ->
  Op.tx_rollup_submit_batch (I i) contract tx_rollup contents >>=? fun op ->
  Incremental.add_operation i op >>= function
  | Ok _ -> assert false
  | Error trace ->
      check_proto_error
        (function
          | Tx_rollup_inbox.Tx_rollup_message_size_exceeds_limit -> true
          | _ -> false)
        trace

(** [fill_inbox b tx_rollup contract contents k] fills the inbox of
    [tx_rollup] with batches containing [contents] sent by [contract].
    Before exceeding the limit size of the inbox, the continuation [k]
    is called with two parameters: the incremental state of the block
    with the almost full inboxes, and an operation that would cause an
    error if applied. *)
let fill_inbox b tx_rollup contract contents k =
  let message_size = String.length contents in
  Context.get_constants (B b) >>=? fun constant ->
  let tx_rollup_inbox_limit =
    constant.parametric.tx_rollup_hard_size_limit_per_inbox
  in
  Context.Contract.counter (B b) contract >>=? fun counter ->
  Incremental.begin_construction b >>=? fun i ->
  let rec fill_inbox i inbox_size counter =
    (* By default, the [gas_limit] is the maximum gas that can be
       consumed by an operation. We set a lower (arbitrary) limit to
       be able to reach the size limit of an operation. *)
    Op.tx_rollup_submit_batch
      ~gas_limit:(Gas.Arith.integral_of_int_exn 100_000)
      ~counter
      (I i)
      contract
      tx_rollup
      contents
    >>=? fun op ->
    let new_inbox_size = inbox_size + message_size in
    if new_inbox_size < tx_rollup_inbox_limit then
      Incremental.add_operation i op >>=? fun i ->
      fill_inbox i new_inbox_size (Z.succ counter)
    else k i inbox_size op
  in

  fill_inbox i 0 counter

(** Try to add enough batch to reach the size limit of an inbox. *)
let test_inbox_too_big () =
  context_init 1 >>=? fun (b, contracts) ->
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  Context.get_constants (B b) >>=? fun constant ->
  let tx_rollup_batch_limit =
    constant.parametric.tx_rollup_hard_size_limit_per_message - 1
  in
  let contents = String.make tx_rollup_batch_limit 'd' in
  originate b contract >>=? fun (b, tx_rollup) ->
  fill_inbox b tx_rollup contract contents (fun i _ op ->
      Incremental.add_operation
        i
        op
        ~expect_failure:
          (check_proto_error (function
              | Tx_rollup_inbox.Tx_rollup_inbox_size_would_exceed_limit _ ->
                  true
              | _ -> false))
      >>=? fun _i -> return_unit)

(** Test that block finalization changes gas rates. *)
let test_finalization () =
  context_init 2 >>=? fun (b, contracts) ->
  let filler = WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0 in
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b contract >>=? fun (b, tx_rollup) ->
  Context.get_constants (B b)
  >>=? fun {parametric = {tx_rollup_hard_size_limit_per_inbox; _}; _} ->
  (* Get the initial fees_per_byte. *)
  Context.Tx_rollup.state (B b) tx_rollup >>=? fun state ->
  fees_per_byte state >>?= fun cost ->
  Assert.equal_tez ~loc:__LOC__ Tez.zero cost >>=? fun () ->
  (* Fill the inbox. *)
  Context.get_constants (B b) >>=? fun constant ->
  let tx_rollup_batch_limit =
    constant.parametric.tx_rollup_hard_size_limit_per_message - 1
  in
  let contents = String.make tx_rollup_batch_limit 'd' in

  (* Repeating fill inbox and finalize block to increase EMA
     until EMA is enough to provoke a change of fees. *)
  let rec increase_ema n b tx_rollup f =
    f b tx_rollup >>=? fun (inbox_size, i) ->
    Incremental.finalize_block i >>=? fun b ->
    Context.Tx_rollup.state (B b) tx_rollup >>=? fun state ->
    let inbox_ema =
      Alpha_context.Tx_rollup_state.Internal_for_tests.get_inbox_ema state
    in
    if tx_rollup_hard_size_limit_per_inbox * 91 / 100 < inbox_ema then
      return (b, n, inbox_size)
    else increase_ema (n + 1) b tx_rollup f
  in
  ( increase_ema 1 b tx_rollup @@ fun b tx_rollup ->
    fill_inbox b tx_rollup filler contents (fun i size _ -> return (size, i)) )
  >>=? fun (b, n, inbox_size) ->
  let rec update_fees_per_byte_n_time n state =
    if n > 0 then
      let state =
        Alpha_context.Tx_rollup_state.Internal_for_tests.update_fees_per_byte
          state
          ~final_size:inbox_size
          ~hard_limit:tx_rollup_hard_size_limit_per_inbox
      in
      update_fees_per_byte_n_time (n - 1) state
    else state
  in
  (* Check the fees we are getting after finalization are (1) strictly
     positive, and (2) the one we can predict with
     [update_fees_per_byte]. *)
  let expected_state = update_fees_per_byte_n_time n state in
  fees_per_byte expected_state >>?= fun expected_fees_per_byte ->
  Context.Tx_rollup.state (B b) tx_rollup >>=? fun state ->
  fees_per_byte state >>?= fun fees_per_byte ->
  assert (Tez.(zero < fees_per_byte)) ;
  Assert.equal_tez ~loc:__LOC__ expected_fees_per_byte fees_per_byte
  >>=? fun () ->
  (* Insert a small batch in a new block *)
  let contents_size = 5 in
  let contents = String.make contents_size 'c' in
  Context.Contract.balance (B b) contract >>=? fun balance ->
  Context.Contract.counter (B b) contract >>=? fun counter ->
  Op.tx_rollup_submit_batch ~counter (B b) contract tx_rollup contents
  >>=? fun op ->
  Block.bake b ~operation:op >>=? fun b ->
  (* Predict the cost we had to pay. *)
  inbox_fees state contents_size >>?= fun cost ->
  Assert.balance_was_debited ~loc:__LOC__ (B b) contract balance cost

let test_inbox_linked_list () =
  let assert_level_equals ~loc expected actual =
    match actual with
    | None -> assert false
    | Some level ->
        Assert.equal
          ~loc
          Raw_level.equal
          "expected same level"
          Raw_level.pp
          expected
          level
  in
  context_init 1 >>=? fun (b, contracts) ->
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b contract >>=? fun (b, tx_rollup) ->
  Context.Tx_rollup.state (B b) tx_rollup >>=? fun state ->
  let last_inbox_level = Tx_rollup_state.last_inbox_level state in
  Assert.is_none ~loc:__LOC__ ~pp:Raw_level.pp last_inbox_level >>=? fun () ->
  Op.tx_rollup_submit_batch (B b) contract tx_rollup "batch"
  >>=? fun operation ->
  Block.bake ~operation b >>=? fun b ->
  Incremental.begin_construction b >>=? fun i ->
  Context.Tx_rollup.state (B b) tx_rollup >>=? fun state ->
  let last_inbox_level = Tx_rollup_state.last_inbox_level state in
  assert_level_equals ~loc:__LOC__ (raw_level 2l) last_inbox_level
  >>=? fun () ->
  (* This inbox has no predecessor link because it's the first inbox in
     this rollup, and no successor because no other inbox has yet been
     created. *)
  wrap
    (Tx_rollup_inbox.get_adjacent_levels
       (Incremental.alpha_ctxt i)
       (raw_level 2l)
       tx_rollup)
  >>=? fun (_, before, after) ->
  Assert.is_none ~loc:__LOC__ ~pp:Raw_level.pp before >>=? fun () ->
  Assert.is_none ~loc:__LOC__ ~pp:Raw_level.pp after >>=? fun () ->
  (* Bake an empty block so that we skip a level*)
  Block.bake b >>=? fun b ->
  Op.tx_rollup_submit_batch (B b) contract tx_rollup "batch"
  >>=? fun operation ->
  Block.bake ~operation b >>=? fun b ->
  Incremental.begin_construction b >>=? fun i ->
  Context.Tx_rollup.state (B b) tx_rollup >>=? fun state ->
  let last_inbox_level = Tx_rollup_state.last_inbox_level state in
  assert_level_equals ~loc:__LOC__ (raw_level 4l) last_inbox_level
  >>=? fun () ->
  (* The new inbox has a predecessor of the previous one *)
  wrap
    (Tx_rollup_inbox.get_adjacent_levels
       (Incremental.alpha_ctxt i)
       (raw_level 4l)
       tx_rollup)
  >>=? fun (_, before, after) ->
  assert_level_equals ~loc:__LOC__ (raw_level 2l) before >>=? fun () ->
  Assert.is_none ~loc:__LOC__ ~pp:Raw_level.pp after >>=? fun () ->
  (* And now the old inbox has a successor but still no predecessor*)
  wrap
    (Tx_rollup_inbox.get_adjacent_levels
       (Incremental.alpha_ctxt i)
       (raw_level 2l)
       tx_rollup)
  >>=? fun (_, before, after) ->
  Assert.is_none ~loc:__LOC__ ~pp:Raw_level.pp before >>=? fun () ->
  assert_level_equals ~loc:__LOC__ (raw_level 4l) after >>=? fun () -> return ()

(** [test_commitment_duplication] originates a rollup, and makes a
   commitment. It attempts to have a second contract make the same
   commitment, and ensures that this fails (and the second contract is
   not charged). It also tests that the same contract can't submit
   a different commitment*)
let test_commitment_duplication () =
  context_init 2 >>=? fun (b, contracts) ->
  let contract1 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  let contract2 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 1
  in
  let pkh1 = public_key_hash_exn contract1 in
  originate b contract1 >>=? fun (b, tx_rollup) ->
  Context.Contract.balance (B b) contract1 >>=? fun balance ->
  Context.Contract.balance (B b) contract2 >>=? fun balance2 ->
  (* In order to have a permissible commitment, we need a transaction. *)
  let contents = "batch" in
  Op.tx_rollup_submit_batch (B b) contract1 tx_rollup contents
  >>=? fun operation ->
  let level = raw_level 2l in
  Block.bake ~operation b >>=? fun b ->
  Incremental.begin_construction b >>=? fun i ->
  make_commitment_for_batch i level tx_rollup >>=? fun commitment ->
  let submitted_level = (Level.current (Incremental.alpha_ctxt i)).level in
  Op.tx_rollup_commit (I i) contract1 tx_rollup commitment >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  let cost = Tez.of_mutez_exn 10_000_000_000L in
  Assert.balance_was_debited ~loc:__LOC__ (I i) contract1 balance cost
  >>= fun _ ->
  (* Successfully fail to submit a duplicate commitment *)
  Op.tx_rollup_commit (I i) contract2 tx_rollup commitment >>=? fun op ->
  Incremental.add_operation i op ~expect_failure:(function
      | Environment.Ecoproto_error
          (Tx_rollup_commitments.Commitment_hash_already_submitted as e)
        :: _ ->
          Assert.test_error_encodings e ;
          return_unit
      | t -> failwith "Unexpected error: %a" Error_monad.pp_print_trace t)
  >>=? fun i ->
  let batches2 : Tx_rollup_commitments.Commitment.batch_commitment list =
    [{root = Bytes.make 20 '1'}]
  in
  let commitment2 = {commitment with batches = batches2} in
  (* Successfully fail to submit a different commitment from contract1 *)
  Op.tx_rollup_commit (I i) contract1 tx_rollup commitment2 >>=? fun op ->
  Incremental.add_operation i op ~expect_failure:(function
      | Environment.Ecoproto_error
          (Tx_rollup_commitments.Two_commitments_from_one_committer as e)
        :: _ ->
          Assert.test_error_encodings e ;
          return_unit
      | t -> failwith "Unexpected error: %a" Error_monad.pp_print_trace t)
  >>=? fun i ->
  let batches3 : Tx_rollup_commitments.Commitment.batch_commitment list =
    [{root = Bytes.make 20 '1'}; {root = Bytes.make 20 '2'}]
  in
  let commitment3 : Tx_rollup_commitments.Commitment.t =
    {commitment2 with batches = batches3}
  in
  (* Successfully fail to submit a different commitment from contract2 *)
  Op.tx_rollup_commit (I i) contract2 tx_rollup commitment3 >>=? fun op ->
  Incremental.add_operation i op ~expect_failure:(function
      | Environment.Ecoproto_error
          (Tx_rollup_commitments.Wrong_batch_count as e)
        :: _ ->
          Assert.test_error_encodings e ;
          return_unit
      | t -> failwith "Unexpected error: %a" Error_monad.pp_print_trace t)
  >>=? fun i ->
  (* No charge. *)
  Assert.balance_was_debited ~loc:__LOC__ (I i) contract2 balance2 Tez.zero
  >>=? fun () ->
  let ctxt = Incremental.alpha_ctxt i in
  wrap (Tx_rollup_commitments.get_commitments ctxt tx_rollup level)
  >>=? fun (ctxt, commitments) ->
  (Alcotest.(check int "Expected one commitment" 1 (List.length commitments)) ;
   let expected_hash = Tx_rollup_commitments.Commitment.hash commitment in
   match List.nth commitments 0 with
   | None -> assert false
   | Some {hash; committer; submitted_at; _} ->
       Alcotest.(
         check commitment_hash_testable "Commitment hash" expected_hash hash) ;

       Alcotest.(check public_key_hash_testable "Committer" pkh1 committer) ;

       Alcotest.(
         check raw_level_testable "Submitted" submitted_level submitted_at) ;
       return ())
  >>=? fun () ->
  check_bond ctxt tx_rollup contract1 1 >>=? fun () ->
  check_bond ctxt tx_rollup contract2 0 >>=? fun () ->
  ignore i ;
  return ()

let make_transactions_in tx_rollup contract blocks b =
  let contents = "batch " in
  let rec aux cur blocks b =
    match blocks with
    | [] -> return b
    | hd :: rest when hd = cur ->
        Op.tx_rollup_submit_batch (B b) contract tx_rollup contents
        >>=? fun operation ->
        Block.bake ~operation b >>=? fun b -> aux (cur + 1) rest b
    | blocks ->
        let operations = [] in
        Block.bake ~operations b >>=? fun b -> aux (cur + 1) blocks b
  in
  aux 2 blocks b

let assert_ok res = match res with Ok r -> r | Error _ -> assert false

let raw_level level = assert_ok @@ Raw_level.of_int32 level

(** [test_commitment_predecessor] tests commitment predecessor edge cases  *)
let test_commitment_predecessor () =
  context_init 1 >>=? fun (b, contracts) ->
  let contract1 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b contract1 >>=? fun (b, tx_rollup) ->
  (* Transactions in blocks 2, 3, 6 *)
  make_transactions_in tx_rollup contract1 [2; 3; 6] b >>=? fun b ->
  Incremental.begin_construction b >>=? fun i ->
  (* Check error: Commitment for nonexistent block *)
  let some_hash =
    Tx_rollup_commitments.Commitment_hash.of_bytes_exn
      (Bytes.of_string "tcu1deadbeefdeadbeefdeadbeefdead")
  in
  make_commitment_for_batch i (raw_level 2l) tx_rollup >>=? fun commitment ->
  let commitment =
    {commitment with level = raw_level 1l; predecessor = Some some_hash}
  in
  Op.tx_rollup_commit (I i) contract1 tx_rollup commitment >>=? fun op ->
  let error =
    Tx_rollup_inbox.Tx_rollup_inbox_does_not_exist (tx_rollup, raw_level 1l)
  in
  Incremental.add_operation i op ~expect_failure:(function
      | Environment.Ecoproto_error e :: _ when e = error ->
          Assert.test_error_encodings error ;
          return_unit
      | _ -> failwith "Need to check commitment predecessor")
  >>=? fun i ->
  (* Commitment without predecessor for block with predecessor*)
  make_commitment_for_batch i (raw_level 3l) tx_rollup >>=? fun commitment ->
  let commitment = {commitment with predecessor = None} in
  Op.tx_rollup_commit (I i) contract1 tx_rollup commitment >>=? fun op ->
  Incremental.add_operation i op ~expect_failure:(function
      | Environment.Ecoproto_error
          (Tx_rollup_commitments.Wrong_commitment_predecessor_level as e)
        :: _ ->
          Assert.test_error_encodings e ;
          return_unit
      | _ -> failwith "Need to check commitment predecessor")
  >>=? fun i ->
  (* Commitment  refers to a predecessor which does not exist *)
  make_commitment_for_batch i (raw_level 3l) tx_rollup >>=? fun commitment ->
  let commitment = {commitment with predecessor = Some some_hash} in
  Op.tx_rollup_commit (I i) contract1 tx_rollup commitment >>=? fun op ->
  Incremental.add_operation i op ~expect_failure:(function
      | Environment.Ecoproto_error
          (Tx_rollup_commitments.Missing_commitment_predecessor as e)
        :: _ ->
          Assert.test_error_encodings e ;
          return_unit
      | _ -> failwith "Need to check commitment predecessor")
  >>=? fun i ->
  (* Try to commit to an empty level between full ones *)
  let commitment : Tx_rollup_commitments.Commitment.t =
    {commitment with level = raw_level 5l}
  in
  Op.tx_rollup_commit (I i) contract1 tx_rollup commitment >>=? fun op ->
  let error =
    Tx_rollup_inbox.Tx_rollup_inbox_does_not_exist (tx_rollup, raw_level 5l)
  in
  Incremental.add_operation i op ~expect_failure:(function
      | Environment.Ecoproto_error e :: _ when e = error ->
          Assert.test_error_encodings e ;
          return_unit
      | _ -> failwith "Need to check for skipped levels")
  >>=? fun i ->
  ignore i ;
  return ()

(** [test_commitment_retire_simple] tests commitment retirement simple cases.
    Note that it manually retires commitments rather than waiting for them to
    age out. *)
let test_commitment_retire_simple () =
  context_init 1 >>=? fun (b, contracts) ->
  let contract1 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b contract1 >>=? fun (b, tx_rollup) ->
  (* In order to have a permissible commitment, we need a transaction. *)
  let contents = "batch" in
  Op.tx_rollup_submit_batch (B b) contract1 tx_rollup contents
  >>=? fun operation ->
  Block.bake ~operation b >>=? fun b ->
  Incremental.begin_construction b >>=? fun i ->
  let level = raw_level 2l in
  (* Test retirement with no commitment *)
  wrap
    (Tx_rollup_commitments.Internal_for_tests.retire_rollup_level
       (Incremental.alpha_ctxt i)
       tx_rollup
       level
       (raw_level @@ Incremental.level i))
  >>=? fun (_ctxt, retired) ->
  (match retired with
  | `No_commitment -> return_unit
  | _ -> failwith "Expected no commitment")
  >>=? fun () ->
  make_commitment_for_batch i level tx_rollup >>=? fun commitment ->
  Op.tx_rollup_commit (I i) contract1 tx_rollup commitment >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  let commitment_submit_level =
    (Level.current (Incremental.alpha_ctxt i)).level
  in
  check_bond (Incremental.alpha_ctxt i) tx_rollup contract1 1 >>=? fun () ->
  (* We can retire this level *)
  wrap
    (Tx_rollup_commitments.Internal_for_tests.retire_rollup_level
       (Incremental.alpha_ctxt i)
       tx_rollup
       level
       commitment_submit_level)
  >>=? fun (ctxt, retired) ->
  assert_retired retired >>=? fun () ->
  check_bond ctxt tx_rollup contract1 0 >>=? fun () ->
  ignore i ;
  return ()

(** [test_commitment_retire_complex] tests a complicated commitment
    retirement scenario:

    We have inboxes at 2, 3, and 6.

    - A: Contract 1 commits to 2.
    - B: Contract 2 commits to 2 (after A; this commitment is
    necessarily bogus, but we will assume that nobody notices)
    - C: Contract 2 commits to 3 (atop A).
    - D: Contract 1 commits to 3 (atop bogus commit B)
    - E: Contract 2 commits to 6 (atop D).
    - F: Contract 1 commits to 6 (atop C).

    So now we retire 2.  We want nobody to get a bond back, but D and
    E are gone.  Then we retire 3, which will enable 2 to get its bond
    back.  Then we retire 6, which lets Contract 1 get its bond back.
*)
let test_commitment_retire_complex () =
  context_init 2 >>=? fun (b, contracts) ->
  let contract1 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  let contract2 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 1
  in
  originate b contract1 >>=? fun (b, tx_rollup) ->
  (* Transactions in blocks 2, 3, 6 *)
  make_transactions_in tx_rollup contract1 [2; 3; 6] b >>=? fun b ->
  Incremental.begin_construction b >>=? fun i ->
  let batches : Tx_rollup_commitments.Commitment.batch_commitment list =
    [{root = Bytes.make 20 '5'}]
  in
  make_commitment_for_batch i (raw_level 2l) tx_rollup >>=? fun commitment_a ->
  Op.tx_rollup_commit (I i) contract1 tx_rollup commitment_a >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  let commitment_b = {commitment_a with batches} in
  Op.tx_rollup_commit (I i) contract2 tx_rollup commitment_b >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  make_commitment_for_batch i (raw_level 3l) tx_rollup >>=? fun commitment_c ->
  Op.tx_rollup_commit (I i) contract2 tx_rollup commitment_c >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  let predecessor = Tx_rollup_commitments.Commitment.hash commitment_b in

  let commitment_d : Tx_rollup_commitments.Commitment.t =
    {commitment_c with predecessor = Some predecessor}
  in
  Op.tx_rollup_commit (I i) contract1 tx_rollup commitment_d >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  (* Need to bake to avoid running out of gas *)
  Incremental.finalize_block i >>=? fun b ->
  Incremental.begin_construction b >>=? fun i ->
  let predecessor = Tx_rollup_commitments.Commitment.hash commitment_d in
  make_commitment_for_batch i (raw_level 6l) tx_rollup >>=? fun commitment_e ->
  let commitment_e : Tx_rollup_commitments.Commitment.t =
    {commitment_e with predecessor = Some predecessor}
  in
  Op.tx_rollup_commit (I i) contract2 tx_rollup commitment_e >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  let predecessor = Tx_rollup_commitments.Commitment.hash commitment_c in
  make_commitment_for_batch i (raw_level 6l) tx_rollup >>=? fun commitment_f ->
  let commitment_f : Tx_rollup_commitments.Commitment.t =
    {commitment_f with predecessor = Some predecessor}
  in
  Op.tx_rollup_commit (I i) contract1 tx_rollup commitment_f >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  wrap
    (Tx_rollup_commitments.Internal_for_tests.retire_rollup_level
       (Incremental.alpha_ctxt i)
       tx_rollup
       (raw_level 2l)
       (raw_level 10l))
  >>=? fun (ctxt, retired) ->
  assert_retired retired >>=? fun () ->
  check_bond ctxt tx_rollup contract1 1 >>=? fun () ->
  check_bond ctxt tx_rollup contract2 1 >>=? fun () ->
  wrap
    (Tx_rollup_commitments.Internal_for_tests.retire_rollup_level
       ctxt
       tx_rollup
       (raw_level 3l)
       (raw_level 10l))
  >>=? fun (ctxt, retired) ->
  assert_retired retired >>=? fun () ->
  check_bond ctxt tx_rollup contract1 1 >>=? fun () ->
  check_bond ctxt tx_rollup contract2 0 >>=? fun () ->
  wrap
    (Tx_rollup_commitments.Internal_for_tests.retire_rollup_level
       ctxt
       tx_rollup
       (raw_level 6l)
       (raw_level 10l))
  >>=? fun (ctxt, retired) ->
  assert_retired retired >>=? fun () ->
  check_bond ctxt tx_rollup contract1 0 >>=? fun () ->
  check_bond ctxt tx_rollup contract2 0 >>=? fun () ->
  ignore ctxt ;
  ignore i ;
  return ()

(** [test_commitment_acceptance] tests a case where there are multiple
   nonrejected commitments at finalization time.
- A: Contract 1 commits to 2 (this will be accepted)
- B: Contract 2 commits to 2 (this will removed but not rejected)
- C: Contract 2 commits to 3 (atop A).
- D: Contract 3 commits to 3 (atop B, to be removed)
*)
let test_commitment_acceptance () =
  context_init 3 >>=? fun (b, contracts) ->
  let contract1 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  let contract2 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 1
  in
  let contract3 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 2
  in
  originate b contract1 >>=? fun (b, tx_rollup) ->
  make_transactions_in tx_rollup contract1 [2; 3] b >>=? fun b ->
  Incremental.begin_construction b >>=? fun i ->
  make_commitment_for_batch i (raw_level 2l) tx_rollup >>=? fun commitment_a ->
  Op.tx_rollup_commit (I i) contract1 tx_rollup commitment_a >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  let batches : Tx_rollup_commitments.Commitment.batch_commitment list =
    [{root = Bytes.make 20 '1'}]
  in
  let commitment_b : Tx_rollup_commitments.Commitment.t =
    {commitment_a with batches}
  in
  Op.tx_rollup_commit (I i) contract2 tx_rollup commitment_b >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  make_commitment_for_batch i (raw_level 3l) tx_rollup >>=? fun commitment_c ->
  Op.tx_rollup_commit (I i) contract2 tx_rollup commitment_c >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  let predecessor = Tx_rollup_commitments.Commitment.hash commitment_b in
  let commitment_d : Tx_rollup_commitments.Commitment.t =
    {commitment_c with predecessor = Some predecessor}
  in
  Op.tx_rollup_commit (I i) contract3 tx_rollup commitment_d >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  let commitment_submit_level =
    (Level.current (Incremental.alpha_ctxt i)).level
  in
  wrap
    (Tx_rollup_commitments.Internal_for_tests.retire_rollup_level
       (Incremental.alpha_ctxt i)
       tx_rollup
       (raw_level 2l)
       commitment_submit_level)
  >>=? fun (ctxt, retired) ->
  assert_retired retired >>=? fun () ->
  wrap
    (Tx_rollup_commitments.Internal_for_tests.retire_rollup_level
       ctxt
       tx_rollup
       (raw_level 3l)
       commitment_submit_level)
  >>=? fun (ctxt, retired) ->
  assert_retired retired >>=? fun () ->
  check_bond ctxt tx_rollup contract1 0 >>=? fun () ->
  check_bond ctxt tx_rollup contract2 0 >>=? fun () ->
  check_bond ctxt tx_rollup contract3 0 >>=? fun () ->
  ignore ctxt ;
  ignore i ;
  return ()

(** [test_bond_finalization] tests that commitment retirement
    in fact finalizes bonds. *)
let test_bond_finalization () =
  context_init 2 >>=? fun (b, contracts) ->
  let contract1 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  let pkh1 = public_key_hash_exn contract1 in
  originate b contract1 >>=? fun (b, tx_rollup) ->
  (* Transactions in block 2, 3, 4 *)
  make_transactions_in tx_rollup contract1 [2; 3; 4] b >>=? fun b ->
  Incremental.begin_construction b >>=? fun i ->
  Op.tx_rollup_return_bond (I i) contract1 tx_rollup >>=? fun op ->
  Incremental.add_operation i op ~expect_failure:(function
      | Environment.Ecoproto_error
          (Tx_rollup_commitments.Bond_does_not_exist a_pkh1 as e)
        :: _
        when a_pkh1 = pkh1 ->
          Assert.test_error_encodings e ;
          return_unit
      | _ -> failwith "Commitment bond should not exist yet")
  >>=? fun i ->
  make_commitment_for_batch i (raw_level 2l) tx_rollup >>=? fun commitment_a ->
  Op.tx_rollup_commit (I i) contract1 tx_rollup commitment_a >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  Op.tx_rollup_return_bond (I i) contract1 tx_rollup >>=? fun op ->
  Incremental.add_operation i op ~expect_failure:(function
      | Environment.Ecoproto_error
          (Tx_rollup_commitments.Bond_in_use a_pkh1 as e)
        :: _
        when a_pkh1 = pkh1 ->
          Assert.test_error_encodings e ;
          return_unit
      | _ -> failwith "Need to check that bond is in-use ")
  >>=? fun i ->
  wrap
    (Tx_rollup_commitments.Internal_for_tests.retire_rollup_level
       (Incremental.alpha_ctxt i)
       tx_rollup
       (raw_level 2l)
       (raw_level 30l))
  >>=? fun (ctxt, retired) ->
  assert_retired retired >>=? fun () ->
  let i = Incremental.set_alpha_ctxt i ctxt in
  Op.tx_rollup_return_bond (I i) contract1 tx_rollup >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  ignore i ;
  return ()

(** [test_bond_finalization] tests that commitment operations
    perform retirement. *)
let test_commitment_finalizes () =
  let constants = {constants with tx_rollup_finality_period = 10} in
  originate_with_constants constants 3 >>=? fun (b, tx_rollup, contracts) ->
  let contract1 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  let contract2 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 1
  in
  let contract3 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 2
  in
  (* Transactions in block 2, 3, 4 *)
  make_transactions_in tx_rollup contract1 [2; 3; 4] b >>=? fun b ->
  Incremental.begin_construction b >>=? fun i ->
  make_commitment_for_batch i (raw_level 2l) tx_rollup >>=? fun commitment ->
  Op.tx_rollup_commit (I i) contract1 tx_rollup commitment >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  (* Now wait for the most of the finality period to pass. *)
  bake_until i 13l >>=? fun i ->
  make_commitment_for_batch i (raw_level 3l) tx_rollup >>=? fun commitment ->
  Op.tx_rollup_commit (I i) contract2 tx_rollup commitment >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  (* We check that the commitment for level 2 was not finalized by
     checking the bond for contract1. *)
  check_bond (Incremental.alpha_ctxt i) tx_rollup contract1 1 >>=? fun () ->
  (* Wait one and try again. *)
  bake_until i 14l >>=? fun i ->
  make_commitment_for_batch i (raw_level 4l) tx_rollup >>=? fun commitment ->
  Op.tx_rollup_commit (I i) contract3 tx_rollup commitment >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  check_bond (Incremental.alpha_ctxt i) tx_rollup contract1 0 >>=? fun () ->
  (* Check that we don't finalize too far. *)
  check_bond (Incremental.alpha_ctxt i) tx_rollup contract2 1 >>=? fun () ->
  ignore i ;
  return ()

(** [test_bond_finalization] tests that commitment operations
       do not finalize more than the limit *)
let test_commitment_finality_limit () =
  let constants =
    {
      constants with
      tx_rollup_finality_period = 15;
      tx_rollup_max_finalize_levels_per_commitment = 3;
      hard_gas_limit_per_block = Gas.Arith.integral_exn (Z.of_int 10000000000);
    }
  in
  originate_with_constants constants 10 >>=? fun (b, tx_rollup, contracts) ->
  let contract1 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  let contract10 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 9
  in
  let check_bond_for_contract i contract_n expected_bond =
    let contract =
      WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts contract_n
    in
    check_bond (Incremental.alpha_ctxt i) tx_rollup contract expected_bond
  in

  (* Transactions in block 2-11 *)
  make_transactions_in tx_rollup contract1 (range 2 12) b >>=? fun b ->
  Incremental.begin_construction b >>=? fun i ->
  let rec make_many_commitments i cur top =
    if cur = top then return i
    else
      make_commitment_for_batch i (raw_level (Int32.of_int cur)) tx_rollup
      >>=? fun commitment ->
      let contract =
        WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts cur
      in
      Op.tx_rollup_commit (I i) contract tx_rollup commitment >>=? fun op ->
      Incremental.add_operation i op >>=? fun i ->
      make_many_commitments i (cur + 1) top
  in
  make_many_commitments i 2 10 >>=? fun i ->
  (* Now wait for the the rest of the finality period to pass. *)
  bake_until i 30l >>=? fun i ->
  make_commitment_for_batch i (raw_level 10l) tx_rollup >>=? fun commitment ->
  Op.tx_rollup_commit (I i) contract10 tx_rollup commitment >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  check_bond_for_contract i 2 0 >>=? fun () ->
  check_bond_for_contract i 3 0 >>=? fun () ->
  check_bond_for_contract i 4 0 >>=? fun () ->
  (* We hit the limit, so the next one is not final. *)
  check_bond_for_contract i 5 1 >>=? fun () ->
  make_commitment_for_batch i (raw_level 11l) tx_rollup >>=? fun commitment ->
  Op.tx_rollup_commit (I i) contract10 tx_rollup commitment >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  check_bond_for_contract i 5 0 >>=? fun () ->
  check_bond_for_contract i 6 0 >>=? fun () ->
  check_bond_for_contract i 7 0 >>=? fun () ->
  check_bond_for_contract i 8 1 >>=? fun () ->
  ignore i ;
  return ()

let test_full_inbox () =
  let constants = {constants with tx_rollup_max_unfinalized_levels = 15} in
  originate_with_constants constants 1 >>=? fun (b, tx_rollup, contracts) ->
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  (* Transactions in blocks [2..17) *)
  make_transactions_in tx_rollup contract (range 2 17) b >>=? fun b ->
  Incremental.begin_construction b >>=? fun i ->
  Op.tx_rollup_submit_batch (B b) contract tx_rollup "contents" >>=? fun op ->
  Incremental.add_operation i op ~expect_failure:(function
      | Environment.Ecoproto_error
          (Tx_rollup_commitments.Too_many_unfinalized_levels as e)
        :: _ ->
          Assert.test_error_encodings e ;
          return_unit
      | _ -> failwith "Need to avoid too many unfinalized inboxes")
  >>=? fun i ->
  ignore i ;
  return ()

let tests =
  [
    Tztest.tztest
      "check feature flag is disabled"
      `Quick
      test_disable_feature_flag;
    Tztest.tztest "check tx rollup origination and burn" `Quick test_origination;
    Tztest.tztest
      "check two originated tx rollup in one operation have different address"
      `Quick
      test_two_originations;
    Tztest.tztest
      "check the function that updates the fees per byte rate of a transaction \
       rollup"
      `Quick
      test_fees_per_byte_update;
    Tztest.tztest "add one batch to a rollup" `Quick test_add_batch;
    Tztest.tztest "add two batches to a rollup" `Quick test_add_two_batches;
    Tztest.tztest
      "Try to add a batch larger than the limit"
      `Quick
      test_batch_too_big;
    Tztest.tztest
      "Try to add several batches to reach the inbox limit"
      `Quick
      test_inbox_too_big;
    Tztest.tztest "Test finalization" `Quick test_finalization;
    Tztest.tztest "Test inbox linked list" `Quick test_inbox_linked_list;
    Tztest.tztest "Smoke test commitment" `Quick test_commitment_duplication;
    Tztest.tztest
      "Test commitment predecessor edge cases"
      `Quick
      test_commitment_predecessor;
    Tztest.tztest
      "Test commitment retirement"
      `Quick
      test_commitment_retire_simple;
    Tztest.tztest
      "Test complex commitment retirement"
      `Quick
      test_commitment_retire_complex;
    Tztest.tztest
      "Test multiple nonrejected commitment"
      `Quick
      test_commitment_acceptance;
    Tztest.tztest "Test bond finalization" `Quick test_bond_finalization;
    Tztest.tztest "Test full inbox" `Quick test_full_inbox;
    Tztest.tztest
      "Test that commitment finalizes"
      `Quick
      test_commitment_finalizes;
    Tztest.tztest
      "Test that commitment finality limit"
      `Quick
      test_commitment_finality_limit;
  ]
