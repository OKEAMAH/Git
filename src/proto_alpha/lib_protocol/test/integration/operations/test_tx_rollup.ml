(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
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
    Invocation:   cd src/proto_alpha/lib_protocol/test/integration/operations \
                  && dune exec ./main.exe -- test "^tx rollup$"
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
    context -> Tx_rollup_inbox.t -> int -> string -> unit tzresult Lwt.t =
 fun ctxt inbox n expected ->
  Lwt.return
  @@ Environment.wrap_tzresult (Tx_rollup_message.make_batch ctxt expected)
  >>=? fun (expected_batch, _) ->
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

(** [make_unit_ticket_key ctxt ticketer tx_rollup] computes the key hash of
    the unit ticket crafted by [ticketer] and owned by [tx_rollup]. *)
let make_unit_ticket_key ctxt ticketer tx_rollup =
  let open Tezos_micheline.Micheline in
  let open Michelson_v1_primitives in
  let ticketer =
    Bytes (0, Data_encoding.Binary.to_bytes_exn Contract.encoding ticketer)
  in
  let ty = Prim (0, T_unit, [], []) in
  let contents = Prim (0, D_Unit, [], []) in
  match
    Alpha_context.Tx_rollup.hash_ticket ctxt ~ticketer ~ty ~contents tx_rollup
  with
  | Ok (x, _) -> x
  | Error _ -> raise (Invalid_argument "make_unit_ticket_key")

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

(** [expression_from_string] parses a Michelson expression from a string. *)
let expression_from_string str =
  let (ast, errs) = Michelson_v1_parser.parse_expression ~check:true str in
  match errs with
  | [] -> ast.expanded
  | _ -> Stdlib.failwith ("parse expression: " ^ str)

let print_deposit_arg tx_rollup account =
  let open Alpha_context.Script in
  Format.sprintf
    "Pair \"%s\" %s"
    (match tx_rollup with
    | `Typed pk -> Tx_rollup.to_b58check pk
    | `Raw str -> str)
    (match account with
    | `Hash pk -> Format.sprintf "\"%s\"" (Tx_rollup_l2_address.to_b58check pk)
    | `Raw str -> str)
  |> fun x ->
  Format.printf "%s\n@?" x ;
  x |> expression_from_string |> lazy_expr

let assert_ok res = match res with Ok r -> r | Error _ -> assert false

let raw_level level = assert_ok @@ Raw_level.of_int32 level

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
  let test ~fees_per_byte ~final_size ~hard_limit ~result =
    let fees_per_byte = Tez.of_mutez_exn fees_per_byte in
    let result = Tez.of_mutez_exn result in
    let state =
      Alpha_context.Tx_rollup_state.Internal_for_tests
      .initial_state_with_fees_per_byte
        fees_per_byte
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
  test ~fees_per_byte:1_000L ~final_size:1_000 ~hard_limit:1_100 ~result:1_000L
  >>=? fun () ->
  (* Fees per byte should increase *)
  test ~fees_per_byte:1_000L ~final_size:1_000 ~hard_limit:1_000 ~result:1_050L
  >>=? fun () ->
  (* Fees per byte should decrease *)
  test ~fees_per_byte:1_000L ~final_size:1_000 ~hard_limit:1_500 ~result:950L
  >>=? fun () ->
  (* Fees per byte should increase even with [0] as its initial value *)
  test ~fees_per_byte:0L ~final_size:1_000 ~hard_limit:1_000 ~result:1L
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
  Incremental.begin_construction b >>=? fun i ->
  let ctxt = Incremental.alpha_ctxt i in
  check_batch_in_inbox ctxt inbox 0 contents1 >>=? fun () ->
  check_batch_in_inbox ctxt inbox 1 contents2 >>=? fun () ->
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

(** [test_valid_deposit] checks that a smart contract can deposit
    tickets to a transaction rollup. *)
let test_valid_deposit () =
  let (_, _, pkh) = gen_l2_account () in

  context_init 1 >>=? fun (b, contracts) ->
  let account =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b account >>=? fun (b, tx_rollup) ->
  Contract_helpers.originate_contract
    "contracts/tx_rollup_deposit.tz"
    "Unit"
    account
    b
    (is_implicit_exn account)
  >>=? fun (contract, b) ->
  let parameters = print_deposit_arg (`Typed tx_rollup) (`Hash pkh) in
  let fee = Test_tez.of_int 10 in
  Op.transaction
    ~counter:(Z.of_int 2)
    ~fee
    (B b)
    account
    contract
    Tez.zero
    ~parameters
  >>=? fun operation ->
  Block.bake ~operation b >>=? fun b ->
  Incremental.begin_construction b >|=? Incremental.alpha_ctxt >>=? fun ctxt ->
  Context.Tx_rollup.inbox (B b) tx_rollup >>=? function
  | {contents = [hash]; _} ->
      let ticket_hash = make_unit_ticket_key ctxt contract tx_rollup in
      let (message, _size) =
        Tx_rollup_message.make_deposit (Value pkh) ticket_hash 10L
      in
      let expected = Tx_rollup_message.hash message in
      Alcotest.(check message_hash_testable "deposit" hash expected) ;
      return_unit
  | _ -> Alcotest.fail "The inbox has not the expected shape"

(** [test_valid_deposit_inexistant_rollup] checks that the Michelson
    interpreter checks the existence of a transaction rollup prior to
    sending a deposit order. *)
let test_valid_deposit_inexistant_rollup () =
  context_init 1 >>=? fun (b, contracts) ->
  let account =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  Contract_helpers.originate_contract
    "contracts/tx_rollup_deposit.tz"
    "Unit"
    account
    b
    (is_implicit_exn account)
  >>=? fun (contract, b) ->
  Incremental.begin_construction b >>=? fun i ->
  let parameters =
    print_deposit_arg (`Raw "tru1HdK6HiR31Xo1bSAr4mwwCek8ExgwuUeHm") (`Raw "2")
  in
  let fee = Test_tez.of_int 10 in
  Op.transaction ~fee (I i) account contract Tez.zero ~parameters >>=? fun op ->
  Incremental.add_operation
    i
    op
    ~expect_failure:
      (check_proto_error (function
          | Script_interpreter.Runtime_contract_error _ -> true
          | _ -> false))
  >>=? fun _ -> return_unit

(** [test_invalid_deposit_not_contract] checks a smart contract cannot
    deposit something that is not a ticket. *)
let test_invalid_deposit_not_ticket () =
  let (_, _, pkh) = gen_l2_account () in

  context_init 1 >>=? fun (b, contracts) ->
  let account =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b account >>=? fun (b, tx_rollup) ->
  Contract_helpers.originate_contract
    "contracts/tx_rollup_deposit_incorrect_param.tz"
    "Unit"
    account
    b
    (is_implicit_exn account)
  >>=? fun (contract, b) ->
  Incremental.begin_construction b >>=? fun i ->
  let parameters = print_deposit_arg (`Typed tx_rollup) (`Hash pkh) in
  let fee = Test_tez.of_int 10 in
  Op.transaction ~fee (I i) account contract Tez.zero ~parameters >>=? fun op ->
  Incremental.add_operation
    i
    op
    ~expect_failure:
      (check_proto_error (function
          | Script_interpreter.Bad_contract_parameter _ -> true
          | _ -> false))
  >>=? fun _ -> return_unit

(** [test_invalid_entrypoint] checks that a transaction to an invalid entrypoint
    of a transaction rollup fails. *)
let test_invalid_entrypoint () =
  let (_, _, pkh) = gen_l2_account () in

  context_init 1 >>=? fun (b, contracts) ->
  let account =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b account >>=? fun (b, tx_rollup) ->
  Contract_helpers.originate_contract
    "contracts/tx_rollup_deposit_incorrect_param.tz"
    "Unit"
    account
    b
    (is_implicit_exn account)
  >>=? fun (contract, b) ->
  Incremental.begin_construction b >>=? fun i ->
  let parameters = print_deposit_arg (`Typed tx_rollup) (`Hash pkh) in
  let fee = Test_tez.of_int 10 in
  Op.transaction ~fee (I i) account contract Tez.zero ~parameters >>=? fun op ->
  Incremental.add_operation
    i
    op
    ~expect_failure:
      (check_proto_error (function
          | Script_interpreter.Bad_contract_parameter _ -> true
          | _ -> false))
  >>=? fun _ -> return_unit

(** [test_invalid_l2_address] checks that a smart contract cannot make
    a deposit order to something that is not a valid layer-2 address. *)
let test_invalid_l2_address () =
  context_init 1 >>=? fun (b, contracts) ->
  let account =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b account >>=? fun (b, tx_rollup) ->
  Contract_helpers.originate_contract
    "contracts/tx_rollup_deposit.tz"
    "Unit"
    account
    b
    (is_implicit_exn account)
  >>=? fun (contract, b) ->
  Incremental.begin_construction b >>=? fun i ->
  let parameters =
    print_deposit_arg (`Typed tx_rollup) (`Raw "\"invalid L2 address\"")
  in
  let fee = Test_tez.of_int 10 in
  Op.transaction ~fee (I i) account contract Tez.zero ~parameters >>=? fun op ->
  Incremental.add_operation
    i
    op
    ~expect_failure:
      (check_proto_error (function
          | Script_interpreter.Bad_contract_parameter _ -> true
          | _ -> false))
  >>=? fun _ -> return_unit

(** [test_valid_deposit_invalid_amount] checks that a transaction to a
    transaction rollup fails if the [amount] parameter is not null. *)
let test_valid_deposit_invalid_amount () =
  let (_, _, pkh) = gen_l2_account () in

  context_init 1 >>=? fun (b, contracts) ->
  let account =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b account >>=? fun (b, tx_rollup) ->
  Contract_helpers.originate_contract
    "contracts/tx_rollup_deposit_one_mutez.tz"
    "Unit"
    account
    b
    (is_implicit_exn account)
  >>=? fun (contract, b) ->
  Incremental.begin_construction b >>=? fun i ->
  let parameters = print_deposit_arg (`Typed tx_rollup) (`Hash pkh) in
  let fee = Test_tez.of_int 10 in
  Op.transaction ~fee (I i) account contract Tez.zero ~parameters >>=? fun op ->
  Incremental.add_operation
    i
    op
    ~expect_failure:
      (check_proto_error (function
          | Apply.Tx_rollup_invalid_transaction_amount -> true
          | _ -> false))
  >>=? fun _ -> return_unit

(** [test_deposit_by_non_internal_operation] checks that a transaction
    to the deposit entrypoint of a transaction rollup fails if it is
    not internal. *)
let test_deposit_by_non_internal_operation () =
  context_init 1 >>=? fun (b, contracts) ->
  let account =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b account >>=? fun (b, tx_rollup) ->
  Op.unsafe_transaction (B b) account (Tx_rollup tx_rollup) Tez.zero
  >>=? fun operation ->
  Incremental.begin_construction b >>=? fun i ->
  Incremental.add_operation i operation ~expect_failure:(function
      | Environment.Ecoproto_error
          (Apply.Tx_rollup_non_internal_transaction as e)
        :: _ ->
          Assert.test_error_encodings e ;
          return_unit
      | _ -> failwith "It should not be possible to send a rollup_operation ")
  >>=? fun _i -> return_unit

(** Test that block finalization changes gas rates *)
let test_finalization () =
  context_init 2 >>=? fun (b, contracts) ->
  let filler = WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0 in
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b contract >>=? fun (b, tx_rollup) ->
  Context.get_constants (B b)
  >>=? fun {parametric = {tx_rollup_hard_size_limit_per_inbox; _}; _} ->
  Context.Contract.balance (B b) contract >>=? fun balance ->
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
  fill_inbox b tx_rollup filler contents (fun i size _ -> return (size, i))
  >>=? fun (inbox_size, i) ->
  (* Assert we have filled the inbox enough to provoke a change of fees. *)
  assert (tx_rollup_hard_size_limit_per_inbox * 90 / 100 < inbox_size) ;
  (* Finalize the block and check fees per byte has increased. *)
  Incremental.finalize_block i >>=? fun b ->
  (* Check the fees we are getting after finalization are (1) strictly
     positive, and (2) the one we can predict with
     [update_fees_per_byte]. *)
  let expected_state =
    Alpha_context.Tx_rollup_state.Internal_for_tests.update_fees_per_byte
      state
      ~final_size:inbox_size
      ~hard_limit:tx_rollup_hard_size_limit_per_inbox
  in
  fees_per_byte expected_state >>?= fun expected_fees_per_byte ->
  Context.Tx_rollup.state (B b) tx_rollup >>=? fun state ->
  fees_per_byte state >>?= fun fees_per_byte ->
  assert (Tez.(zero < fees_per_byte)) ;
  Assert.equal_tez ~loc:__LOC__ expected_fees_per_byte fees_per_byte
  >>=? fun () ->
  (* Insert a small batch in a new block *)
  let contents_size = 5 in
  let contents = String.make contents_size 'c' in
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
    Tztest.tztest "Test deposit with valid contract" `Quick test_valid_deposit;
    Tztest.tztest
      "Test deposit with invalid parameter"
      `Quick
      test_invalid_deposit_not_ticket;
    Tztest.tztest
      "Test valid deposit to inexistant rollup"
      `Quick
      test_valid_deposit_inexistant_rollup;
    Tztest.tztest "Test invalid entrypoint" `Quick test_invalid_entrypoint;
    Tztest.tztest
      "Test valid deposit to invalid L2 address"
      `Quick
      test_invalid_l2_address;
    Tztest.tztest
      "Test valid deposit with non-zero amount"
      `Quick
      test_valid_deposit_invalid_amount;
    Tztest.tztest "Test finalization" `Quick test_finalization;
    Tztest.tztest "Test inbox linked list" `Quick test_inbox_linked_list;
  ]
