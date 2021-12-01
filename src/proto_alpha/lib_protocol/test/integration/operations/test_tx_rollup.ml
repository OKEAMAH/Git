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

let message_hash_testable : Tx_rollup_inbox.message_hash Alcotest.testable =
  Alcotest.testable Tx_rollup_inbox.message_hash_pp ( = )

let check_tx_rollup_exists ctxt tx_rollup =
  Context.Tx_rollup.state ctxt tx_rollup >>=? fun _state -> return_unit

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

(** [check_batch_in_inbox inbox n expected] checks that the [n]th
    element of [inbox] is a batch equal to [expected]. *)
let check_batch_in_inbox :
    Tx_rollup_inbox.t -> int -> string -> unit tzresult Lwt.t =
 fun inbox n expected ->
  match List.nth inbox.contents n with
  | Some content ->
      Alcotest.(
        check
          message_hash_testable
          "Expected batch with a different content"
          content
          (Tx_rollup_inbox.hash_message (Batch expected))) ;
      return_unit
  | _ -> Alcotest.fail "Selected message in the inbox is not a batch"

(** [test_disable_feature_flag] tries to originate a tx rollup with
    the feature flag is deactivated and checks that it fails *)
let test_disable_feature_flag () =
  Context.init 1 >>=? fun (b, contracts) ->
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  Incremental.begin_construction b >>=? fun i ->
  Op.tx_rollup_origination (I i) contract >>=? fun (op, _tx_rollup) ->
  let expect_failure = function
    | Environment.Ecoproto_error (Apply.Tx_rollup_disabled as e) :: _ ->
        Assert.test_error_encodings e ;
        return_unit
    | _ -> failwith "It should not be possible to send a rollup_operation "
  in
  Incremental.add_operation ~expect_failure i op >>= fun _i -> return_unit

(** [test_origination] originates a tx rollup and check that it burns
    the correct amount of the origination source contract. *)
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

(** [test_two_originations] originates two tx rollups in the same
    operation and check that each has a different address. *)
let test_two_originations () =
  (*
    TODO: https://gitlab.com/tezos/tezos/-/issues/2331
    This test can be generalized using a property-based approach.
   *)
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
    "Origination of two tx rollups in one operation have different addresses"
    Tx_rollup.pp
    txo1
    txo2
  >>=? fun () ->
  check_tx_rollup_exists (I i) txo1 >>=? fun () ->
  check_tx_rollup_exists (I i) txo2 >>=? fun () -> return_unit

(** Check that the cost per byte per inbox rate is updated correctly *)
let test_cost_per_byte_update () =
  let cost_per_byte = Tez.of_mutez_exn 250L in
  let test ~tx_rollup_cost_per_byte ~final_size ~hard_limit ~result =
    let result = Tez.of_mutez_exn result in
    let tx_rollup_cost_per_byte = Tez.of_mutez_exn tx_rollup_cost_per_byte in
    let new_cost_per_byte =
      Alpha_context.Tx_rollup_state.Internal_for_tests.update_cost_per_byte
        ~cost_per_byte
        ~tx_rollup_cost_per_byte
        ~final_size
        ~hard_limit
    in
    Assert.equal_tez ~loc:__LOC__ result new_cost_per_byte
  in

  (* Cost per byte should remain constant *)
  test
    ~tx_rollup_cost_per_byte:1_000L
    ~final_size:1_000
    ~hard_limit:1_100
    ~result:1_000L
  >>=? fun () ->
  (* Cost per byte should increase *)
  test
    ~tx_rollup_cost_per_byte:1_000L
    ~final_size:1_000
    ~hard_limit:1_000
    ~result:1_051L
  >>=? fun () ->
  (* Cost per byte should decrease *)
  test
    ~tx_rollup_cost_per_byte:1_000L
    ~final_size:1_000
    ~hard_limit:1_500
    ~result:951L
  >>=? fun () ->
  (* Cost per byte never decreased under the [cost_per_byte] constant *)
  test
    ~tx_rollup_cost_per_byte:(cost_per_byte |> Tez.to_mutez)
    ~final_size:1_000
    ~hard_limit:1_500
    ~result:(cost_per_byte |> Tez.to_mutez)
  >>=? fun () -> return_unit

(** [context_init n] initializes a context with no consensus rewards
    to not interfere with balances prediction. It returns the created
    context and n contracts *)
let context_init n =
  Context.init
    ~consensus_threshold:0
    ~tx_rollup_enable:true
    ~endorsing_reward_per_slot:Tez.zero
    ~baking_reward_bonus_per_slot:Tez.zero
    ~baking_reward_fixed_portion:Tez.zero
    n

(** [originate b contract] originates a tx_rollup from the given contract,
    and returns the new block and the the tx_rollup address *)
let originate b contract =
  Op.tx_rollup_origination (B b) contract >>=? fun (operation, tx_rollup) ->
  Block.bake ~operation b >>=? fun b -> return (b, tx_rollup)

(** [test_add_batch] originates a tx rollup and fills one of its inbox
    with an arbitrary batch of data. *)
let test_add_batch () =
  context_init 1 >>=? fun (b, contracts) ->
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b contract >>=? fun (b, tx_rollup) ->
  Context.Contract.balance (B b) contract >>=? fun balance ->
  Context.Tx_rollup.state (B b) tx_rollup
  >>=? fun {cost_per_byte = tx_rollup_cost_per_byte} ->
  let contents_size = 5 in
  let batch = String.make contents_size 'c' in
  Op.tx_rollup_submit_batch (B b) contract tx_rollup batch >>=? fun operation ->
  Block.bake ~operation b >>=? fun b ->
  Context.Tx_rollup.inbox (B b) tx_rollup >>=? fun {contents; cumulated_size} ->
  let length = List.length contents in
  Alcotest.(check int "Expect an inbox with a single item" 1 length) ;
  Alcotest.(check int "Expect cumulated size" contents_size cumulated_size) ;
  Test_tez.(tx_rollup_cost_per_byte *? Int64.of_int contents_size)
  >>?= fun cost ->
  Assert.balance_was_debited ~loc:__LOC__ (B b) contract balance cost

(** [test_add_two_batches] originates a tx rollup and adds two
    arbitrary batches to one of its inboxes. Ensure that their order
    is correct. *)
let test_add_two_batches () =
  (*
    TODO: https://gitlab.com/tezos/tezos/-/issues/2331
    This test can be generalized using a property-based approach.
   *)
  context_init 1 >>=? fun (b, contracts) ->
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b contract >>=? fun (b, tx_rollup) ->
  Context.Tx_rollup.state (B b) tx_rollup
  >>=? fun {cost_per_byte = tx_rollup_cost_per_byte} ->
  Context.Contract.balance (B b) contract >>=? fun balance ->
  let contents_size1 = 5 in
  let contents1 = String.make contents_size1 'c' in
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
  Test_tez.(
    tx_rollup_cost_per_byte *? (Int64.of_int @@ expected_cumulated_size))
  >>?= fun cost ->
  Assert.balance_was_debited ~loc:__LOC__ (B b) contract balance cost
  >>=? fun () -> return ()

(** Try to add a batch too large in an inbox. *)
let test_batch_too_big () =
  context_init 1 >>=? fun (b, contracts) ->
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b contract >>=? fun (b, tx_rollup) ->
  Context.get_constants (B b) >>=? fun constant ->
  let contents =
    String.make constant.parametric.tx_rollup_hard_size_limit_per_batch 'd'
  in
  Incremental.begin_construction b >>=? fun i ->
  Op.tx_rollup_submit_batch (I i) contract tx_rollup contents >>=? fun op ->
  Incremental.add_operation i op ~expect_failure:(function
      | Environment.Ecoproto_error Protocol.Apply.Tx_rollup_submit_too_big :: _
        ->
          return_unit
      | _ -> failwith "Expected [Tx_rollup_submit_too_big] error")
  >>=? fun i ->
  ignore i ;
  return_unit

(** Try to add enough batch to reach the size limit of an inbox. *)
let test_inbox_too_big () =
  context_init 1 >>=? fun (b, contracts) ->
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b contract >>=? fun (b, tx_rollup) ->
  Context.get_constants (B b) >>=? fun constant ->
  let tx_rollup_inbox_limit =
    constant.parametric.tx_rollup_hard_size_limit_per_inbox
  in
  let tx_rollup_batch_limit =
    constant.parametric.tx_rollup_hard_size_limit_per_batch - 1
  in
  let contents = String.make tx_rollup_batch_limit 'd' in
  Context.Contract.counter (B b) contract >>=? fun counter ->
  Incremental.begin_construction b >>=? fun i ->
  let rec fill_inbox i inbox_size counter =
    (* By default, the [gas_limit] is the maximum gas that can be
       consumed by an operation. We set a lower (arbitrary) limit to
       be able to reach the size limit of an operation. *)
    Op.tx_rollup_submit_batch
      ~gas_limit:(Saturation_repr.safe_int 100_000_000)
      ~counter
      (I i)
      contract
      tx_rollup
      contents
    >>=? fun op ->
    let new_inbox_size = inbox_size + tx_rollup_batch_limit in
    if new_inbox_size < tx_rollup_inbox_limit then
      Incremental.add_operation i op >>=? fun i ->
      fill_inbox i new_inbox_size (Z.succ counter)
    else
      Incremental.add_operation i op ~expect_failure:(function
          | Environment.Ecoproto_error
              (Protocol.Tx_rollup_storage.Tx_rollup_hard_size_limit_reached _)
            :: _ ->
              return_unit
          | err ->
              failwith
                "Expected [Tx_rollup_hard_size_limit_reached] error, got %a"
                Error_monad.pp_print_trace
                err)
  in

  fill_inbox i 0 counter >>=? fun i ->
  ignore i ;
  return_unit

(** Test that block finalization changes gas rates *)
let test_finalization () =
  context_init 1 >>=? fun (b, contracts) ->
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b contract >>=? fun (b, tx_rollup) ->
  Context.get_constants (B b)
  >>=? fun {
             parametric = {cost_per_byte; tx_rollup_hard_size_limit_per_inbox; _};
             _;
           } ->
  Context.Contract.balance (B b) contract >>=? fun balance ->
  Context.Tx_rollup.state (B b) tx_rollup
  >>=? fun {cost_per_byte = tx_rollup_cost_per_byte} ->
  Assert.equal_tez ~loc:__LOC__ cost_per_byte tx_rollup_cost_per_byte
  >>=? fun () ->
  let contents_size = 5 in
  let batch = String.make contents_size 'c' in
  Op.tx_rollup_submit_batch (B b) contract tx_rollup batch >>=? fun operation ->
  Block.bake ~operation b >>=? fun b ->
  Test_tez.(tx_rollup_cost_per_byte *? Int64.of_int contents_size)
  >>?= fun cost ->
  Assert.balance_was_debited ~loc:__LOC__ (B b) contract balance cost
  >>=? fun () ->
  Context.Tx_rollup.inbox (B b) tx_rollup >>=? fun {contents; cumulated_size} ->
  let length = List.length contents in
  (* Check the content of the inbox *)
  Alcotest.(check int "Expect an inbox with a single item" 1 length) ;
  Alcotest.(check int "Expect cumulated_size" contents_size cumulated_size) ;
  (* Check the new cost_per_byte rate *)
  Context.Tx_rollup.state (B b) tx_rollup
  >>=? fun {cost_per_byte = new_tx_rollup_cost_per_byte} ->
  Assert.equal_tez
    ~loc:__LOC__
    (Alpha_context.Tx_rollup_state.Internal_for_tests.update_cost_per_byte
       ~cost_per_byte
       ~tx_rollup_cost_per_byte
       ~final_size:cumulated_size
       ~hard_limit:tx_rollup_hard_size_limit_per_inbox)
    new_tx_rollup_cost_per_byte

let rng_state = Random.State.make_self_init ()

let gen_l2_account () =
  let seed =
    Bytes.init 32 (fun _ -> char_of_int @@ Random.State.int rng_state 255)
  in
  let secret_key = Bls12_381.Signature.generate_sk seed in
  let public_key = Bls12_381.Signature.derive_pk secret_key in
  (secret_key, public_key)

let is_implicit_exn x =
  match Alpha_context.Contract.is_implicit x with
  | Some x -> x
  | None -> raise (Invalid_argument "is_implicit_exn")

let hex_of_tx_rollup_l2_address address =
  Data_encoding.Binary.to_bytes_exn Tx_rollup_l2_address.encoding address
  |> Hex.of_bytes |> Hex.show

(** [expression_from_string] parses a Michelson expression from a string. *)
let expression_from_string str =
  let (ast, errs) = Michelson_v1_parser.parse_expression ~check:true str in
  match errs with
  | [] -> ast.expanded
  | _ -> Stdlib.failwith ("parse expression: " ^ str)

let print_deposit_arg tx_rollup account =
  let open Alpha_context.Script in
  Format.sprintf
    "Pair \"%s\" 0x%s"
    (match tx_rollup with
    | `Typed pk -> Tx_rollup.to_b58check pk
    | `Raw str -> str)
    (match account with
    | `Typed pk -> hex_of_tx_rollup_l2_address pk
    | `Raw str -> str)
  |> expression_from_string |> lazy_expr

(** Test a smart contract can deposit tickets to a transaction rollup *)
let test_valid_deposit () =
  let (_, pk) = gen_l2_account () in

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
  let parameters = print_deposit_arg (`Typed tx_rollup) (`Typed pk) in
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
      let expected =
        Tx_rollup_inbox.hash_message
          (Deposit
             {
               destination = pk;
               amount = 10L;
               key_hash = make_unit_ticket_key ctxt contract tx_rollup;
             })
      in
      Alcotest.(check message_hash_testable "deposit" hash expected) ;
      return_unit
  | _ -> Alcotest.fail "The inbox has not the expected shape"

(** Test a smart contract cannot deposit tickets to a transaction rollup that
    does not exists. *)
let test_valid_deposit_inexistant_rollup () =
  let (_, pk) = gen_l2_account () in
  Context.init
    ~consensus_threshold:0
    ~tx_rollup_enable:
      true (* We don't want reward to interferes with balance computation *)
    ~endorsing_reward_per_slot:Tez.zero
    ~baking_reward_bonus_per_slot:Tez.zero
    ~baking_reward_fixed_portion:Tez.zero
    1
  >>=? fun (b, contracts) ->
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
    print_deposit_arg (`Raw "tru1HdK6HiR31Xo1bSAr4mwwCek8ExgwuUeHm") (`Typed pk)
  in
  let fee = Test_tez.of_int 10 in
  Op.transaction ~fee (I i) account contract Tez.zero ~parameters >>=? fun op ->
  Incremental.add_operation i op ~expect_failure:(function
      | Environment.Ecoproto_error
          (Script_interpreter.Runtime_contract_error _ as e)
        :: _ ->
          Assert.test_error_encodings e ;
          return_unit
      | t -> failwith "Unexpected error: %a" Error_monad.pp_print_trace t)
  >>=? fun _ -> return_unit

(** Test a smart contract cannot deposit something that is not a ticket *)
let test_invalid_deposit_not_ticket () =
  let (_, pk) = gen_l2_account () in

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
  let parameters = print_deposit_arg (`Typed tx_rollup) (`Typed pk) in
  let fee = Test_tez.of_int 10 in
  Op.transaction ~fee (I i) account contract Tez.zero ~parameters >>=? fun op ->
  Incremental.add_operation i op ~expect_failure:(function
      | Environment.Ecoproto_error
          (Script_interpreter.Bad_contract_parameter _ as e)
        :: _ ->
          Assert.test_error_encodings e ;
          return_unit
      | t -> failwith "Unexpected error: %a" Error_monad.pp_print_trace t)
  >>=? fun _ -> return_unit

(** Test a smart contract cannot use an invalid entrypoint *)
let test_invalid_entrypoint () =
  let (_, pk) = gen_l2_account () in

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
  let parameters = print_deposit_arg (`Typed tx_rollup) (`Typed pk) in
  let fee = Test_tez.of_int 10 in
  Op.transaction ~fee (I i) account contract Tez.zero ~parameters >>=? fun op ->
  Incremental.add_operation i op ~expect_failure:(function
      | Environment.Ecoproto_error
          (Script_interpreter.Bad_contract_parameter _ as e)
        :: _ ->
          Assert.test_error_encodings e ;
          return_unit
      | t -> failwith "Unexpected error: %a" Error_monad.pp_print_trace t)
  >>=? fun _ -> return_unit

(** Test a smart contract cannot deposit to an invalid l2 account *)
let test_invalid_l2_account () =
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
    print_deposit_arg
      (`Typed tx_rollup)
      (`Raw ("invalid L2 address" |> Hex.of_string |> Hex.show))
  in
  let fee = Test_tez.of_int 10 in
  Op.transaction ~fee (I i) account contract Tez.zero ~parameters >>=? fun op ->
  Incremental.add_operation i op ~expect_failure:(function
      | Environment.Ecoproto_error
          (Script_interpreter.Bad_contract_parameter _ as e)
        :: _ ->
          Assert.test_error_encodings e ;
          return_unit
      | t -> failwith "Unexpected error: %a" Error_monad.pp_print_trace t)
  >>=? fun _ -> return_unit

(** Test a smart contract cannot transfer tez to a rollup *)
let test_valid_deposit_invalid_amount () =
  let (_, pk) = gen_l2_account () in

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
  let parameters = print_deposit_arg (`Typed tx_rollup) (`Typed pk) in
  let fee = Test_tez.of_int 10 in
  Op.transaction ~fee (I i) account contract Tez.zero ~parameters >>=? fun op ->
  Incremental.add_operation i op ~expect_failure:(function
      | Environment.Ecoproto_error (Apply.Tx_rollup_non_null_transaction as e)
        :: _ ->
          Assert.test_error_encodings e ;
          return_unit
      | t -> failwith "Unexpected error: %a" Error_monad.pp_print_trace t)
  >>=? fun _ -> return_unit

(** Test deposit by non internal operation fails *)
let test_deposit_by_non_internal_operation () =
  let fee = Test_tez.of_int 10 in
  let invalid_transaction ctxt (src : Contract.t) (dst : Tx_rollup.t) =
    let top =
      Transaction
        {
          amount = Tez.zero;
          parameters = Script.unit_parameter;
          destination = Destination.Tx_rollup dst;
          entrypoint = Alpha_context.Entrypoint.default;
        }
    in
    Op.manager_operation ~fee ~source:src ctxt top >>=? fun sop ->
    Context.Contract.manager ctxt src >|=? fun account ->
    Op.sign account.sk ctxt sop
  in

  context_init 1 >>=? fun (b, contracts) ->
  let account =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  originate b account >>=? fun (b, tx_rollup) ->
  invalid_transaction (B b) account tx_rollup >>=? fun operation ->
  Incremental.begin_construction b >>=? fun i ->
  Incremental.add_operation i operation ~expect_failure:(function
      | Environment.Ecoproto_error
          (Apply.Tx_rollup_non_internal_transaction as e)
        :: _ ->
          Assert.test_error_encodings e ;
          return_unit
      | _ -> failwith "It should not be possible to send a rollup_operation ")
  >>=? fun _i -> return_unit

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
      "check the function that updates the cost per byte rate per inbox"
      `Quick
      test_cost_per_byte_update;
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
      test_invalid_l2_account;
    Tztest.tztest
      "Test valid deposit with non-zero amount"
      `Quick
      test_valid_deposit_invalid_amount;
  ]
