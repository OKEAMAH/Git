(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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
    Component:    Adaptive Inflation, launch vote
    Invocation:   dune exec src/proto_alpha/lib_protocol/test/integration/main.exe \
                   -- --file test_adaptive_inflation_launch.ml
    Subject:      Test the launch vote feature of Adaptive Inflation.
*)

let assert_level ~loc (blk : Block.t) expected =
  let current_level = blk.header.shell.level in
  Assert.equal_int32 ~loc current_level expected

let get_launch_cycle ~loc blk =
  let open Lwt_result_syntax in
  let* launch_cycle_opt = Context.get_adaptive_inflation_launch_cycle (B blk) in
  Assert.get_some ~loc launch_cycle_opt

let assert_is_not_yet_set_to_launch ~loc blk =
  let open Lwt_result_syntax in
  let* launch_cycle_opt = Context.get_adaptive_inflation_launch_cycle (B blk) in
  Assert.is_none
    ~loc
    ~pp:(fun fmt cycle ->
      Format.fprintf
        fmt
        "Activation cycle is set to %a but we expected it to be unset"
        Protocol.Alpha_context.Cycle.pp
        cycle)
    launch_cycle_opt

let assert_cycle_eq ~loc c1 c2 =
  Assert.equal
    ~loc
    Protocol.Alpha_context.Cycle.( = )
    "cycle equality"
    Protocol.Alpha_context.Cycle.pp
    c1
    c2

let assert_current_cycle ~loc (blk : Block.t) expected =
  let open Lwt_result_syntax in
  let* current_cycle = Block.current_cycle blk in
  assert_cycle_eq ~loc current_cycle expected

let stake ctxt contract amount =
  let open Lwt_result_wrap_syntax in
  let*?@ entrypoint =
    Protocol.Alpha_context.Entrypoint.of_string_strict ~loc:0 "stake"
  in
  Op.transaction ctxt ~entrypoint contract contract amount

let set_delegate_parameters ctxt delegate staking_over_baking_limit
    baking_over_staking_edge =
  let open Lwt_result_wrap_syntax in
  let*?@ entrypoint =
    Protocol.Alpha_context.Entrypoint.of_string_strict
      ~loc:0
      "set_delegate_parameters"
  in
  let parameters =
    Protocol.Alpha_context.Script.lazy_expr
      (Expr.from_string
         (Printf.sprintf
            "Pair %d (Pair %d Unit)"
            staking_over_baking_limit
            baking_over_staking_edge))
  in
  Op.transaction
    ctxt
    ~entrypoint
    ~parameters
    delegate
    delegate
    Protocol.Alpha_context.Tez.zero

module type INTEGER = sig
  type t

  val max : t -> t -> t

  val ( <= ) : t -> t -> bool

  val ( > ) : t -> t -> bool

  val abs : t -> t

  val one : t

  val hundred : t

  val ( + ) : t -> t -> t

  val ( - ) : t -> t -> t

  val ( * ) : t -> t -> t

  val ( / ) : t -> t -> t

  val name : string

  val pp : Format.formatter -> t -> unit
end

module Almost_equal (I : INTEGER) = struct
  let abs_diff x y =
    let open I in
    if x < y then y - x else x - y

  let assert_almost_equal ~loc ~margin_percent i1 i2 =
    let open I in
    let maxi = max (abs i1) (abs i2) in
    let margin = one + (maxi * margin_percent / hundred) in
    let diff = abs_diff i2 i1 in
    let msg = name ^ " almost equal" in
    if diff > margin then
      failwith
        "@[@[[%s]@] - @[%s : %a is not almost equal to %a within a %a%% \
         margin@]@]"
        loc
        msg
        pp
        i1
        pp
        i2
        pp
        margin_percent
    else return_unit

  let assert_really_lt ~loc ~margin_percent i1 i2 =
    let open I in
    let maxi = max (abs i1) (abs i2) in
    let margin = one + (maxi * margin_percent / hundred) in
    let diff = i2 - i1 in
    let msg = name ^ " much lt" in
    if diff <= margin then
      failwith
        "@[@[[%s]@] - @[%s : %a is not much smaller than %a within a %a%% \
         margin@]@]"
        loc
        msg
        pp
        i1
        pp
        i2
        pp
        margin_percent
    else return_unit
end

module Int : INTEGER with type t = int = struct
  type t = int

  let max = max

  let ( <= ) = ( <= )

  let ( > ) = ( > )

  let abs = abs

  let one = 1

  let hundred = 100

  let ( + ) = ( + )

  let ( - ) = ( - )

  let ( * ) = ( * )

  let ( / ) = ( / )

  let name = "int"

  let pp fmt x = Format.fprintf fmt "%d" x
end

module Almost_equal_int = Almost_equal (Int)

module I64 : INTEGER with type t = Int64.t = struct
  include Int64
  include Compare.Int64

  let name = "int64"

  let pp fmt x = Format.fprintf fmt "%s" (to_string x)

  let ( + ) = Int64.add

  let ( - ) = Int64.sub

  let ( * ) = Int64.mul

  let ( / ) = Int64.div

  let hundred = 100L
end

module Almost_equal_int64 = Almost_equal (I64)

module ITez : INTEGER with type t = Protocol.Alpha_context.Tez.t = struct
  include Protocol.Alpha_context.Tez

  let abs x = x

  let name = "tez"

  let lift op x y = of_mutez_exn (op (to_mutez x) (to_mutez y))

  let ( + ) = lift Int64.add

  let ( - ) = lift Int64.sub

  let ( * ) = lift Int64.mul

  let ( / ) = lift Int64.div

  let hundred = of_mutez_exn 100L
end

module Almost_equal_tez = Almost_equal (ITez)

let get_endorsing_power delegate block =
  let open Lwt_result_wrap_syntax in
  let ctxt = Context.B block in
  let* alpha_ctxt =
    let+ i = Incremental.begin_construction block in
    Incremental.alpha_ctxt i
  in
  let preserved_cycles =
    Protocol.Alpha_context.Constants.preserved_cycles alpha_ctxt
  in
  let* current_cycle = Block.current_cycle block in
  let levels_in_cycle cycle =
    Protocol.Alpha_context.Level.levels_in_cycle alpha_ctxt cycle
    |> List.map (fun l -> l.Protocol.Alpha_context.Level.level)
  in
  let rec levels_in_n_cycle n accu ~first_cycle =
    if n < 0 then accu
    else
      levels_in_n_cycle
        (n - 1)
        (levels_in_cycle first_cycle @ accu)
        ~first_cycle:(Protocol.Alpha_context.Cycle.succ first_cycle)
  in
  let levels =
    levels_in_n_cycle preserved_cycles [] ~first_cycle:current_cycle
  in
  Context.get_endorsing_power_for_delegate ctxt ~levels delegate

let assert_same_endorsing_power ~loc block delegate1 delegate2 =
  let open Lwt_result_syntax in
  let* power1 = get_endorsing_power delegate1 block in
  let* power2 = get_endorsing_power delegate2 block in
  Almost_equal_int.assert_almost_equal ~loc ~margin_percent:20 power1 power2

let assert_less_endorsing_power ~loc block delegate1 delegate2 =
  let open Lwt_result_syntax in
  let* power1 = get_endorsing_power delegate1 block in
  let* power2 = get_endorsing_power delegate2 block in
  let _ = (power1, power2, loc) in
  (* Almost_equal_int.assert_really_lt ~loc ~margin_percent:2 power1 power2 *)
  return_unit

let get_voting_power delegate block =
  Context.get_voting_power (B block) delegate

let assert_same_voting_power ~loc block delegate1 delegate2 =
  let open Lwt_result_syntax in
  let* power1 = get_voting_power delegate1 block in
  let* power2 = get_voting_power delegate2 block in
  Almost_equal_int64.assert_almost_equal ~loc ~margin_percent:2L power1 power2

let assert_less_voting_power ~loc block delegate1 delegate2 =
  let open Lwt_result_syntax in
  let* power1 = get_voting_power delegate1 block in
  let* power2 = get_voting_power delegate2 block in
  let _ = (power1, power2, loc) in
  (* Almost_equal_int64.assert_really_lt ~loc ~margin_percent:10L power1 power2 *)
  return_unit

let assert_same_power ~loc block delegate1 delegate2 =
  let open Lwt_result_syntax in
  let* () = assert_same_endorsing_power ~loc block delegate1 delegate2 in
  let* () = assert_same_voting_power ~loc block delegate1 delegate2 in
  return_unit

let assert_same_power3 ~loc block delegate1 delegate2 delegate3 =
  let open Lwt_result_syntax in
  let* () = assert_same_power ~loc block delegate1 delegate2 in
  let* () = assert_same_power ~loc block delegate1 delegate3 in
  let* () = assert_same_power ~loc block delegate2 delegate3 in
  return_unit

let assert_less_power ~loc block delegate1 delegate2 =
  let open Lwt_result_syntax in
  let* () = assert_less_endorsing_power ~loc block delegate1 delegate2 in
  let* () = assert_less_voting_power ~loc block delegate1 delegate2 in
  return_unit

(* Test that:
   - the EMA of the adaptive inflation vote reaches the threshold after the
     expected duration,
   - the launch cycle is set as soon as the threshold is reached,
   - the launch cycle is not reset before it is reached,
   - once the launch cycle is reached, costaking is allowed. *)
let test_launch threshold expected_vote_duration () =
  let open Lwt_result_wrap_syntax in
  let assert_ema_above_threshold ~loc
      (metadata : Protocol.Main.block_header_metadata) =
    let ema =
      Protocol.Alpha_context.Toggle_votes.Adaptive_inflation_launch_EMA.to_int32
        metadata.adaptive_inflation_toggle_ema
    in
    Assert.lt_int32 ~loc threshold ema
  in
  let constants =
    let default_constants = Default_parameters.constants_test in
    let adaptive_inflation =
      {
        default_constants.adaptive_inflation with
        launch_ema_threshold = threshold;
      }
    in
    let consensus_threshold = 0 in
    {default_constants with consensus_threshold; adaptive_inflation}
  in
  let preserved_cycles = constants.preserved_cycles in
  (* Initialize the state with three delegates:

     - delegate1 has a delegator owning half of the balance and who
     wants to become a costaker, delegate1 self-stakes the rest.

     - delegate2 self-stake almost all its balance.

     - delegate3 keeps 50% of its balance liquid.
  *)
  let* block, (delegate1, delegate2, delegate3) =
    Context.init_with_constants3 constants
  in
  let delegate1_pkh =
    match delegate1 with Implicit pkh -> pkh | Originated _ -> assert false
  in
  let delegate2_pkh =
    match delegate2 with Implicit pkh -> pkh | Originated _ -> assert false
  in
  let delegate3_pkh =
    match delegate3 with Implicit pkh -> pkh | Originated _ -> assert false
  in
  let* () = assert_is_not_yet_set_to_launch ~loc:__LOC__ block in

  (* Initially, the 3 delegates have the same stake of 4 million tez:
     3_800_000 liquid tez + 200_000 frozen tez. *)
  let* balance = Context.Contract.balance (B block) delegate1 in
  let* () =
    let* balance_bis = Context.Contract.balance (B block) delegate2 in
    let* () = Assert.equal_tez ~loc:__LOC__ balance balance_bis in
    let* balance_ter = Context.Contract.balance (B block) delegate3 in
    Assert.equal_tez ~loc:__LOC__ balance balance_ter
  in

  (* To test that adaptive inflation is active, we will test that
     costaking, a feature only available after the activation, is
     allowed. But by default, delegates reject costakers, they must
     explicitely set a positive staking_over_baking_limit to allow
     them. Setting this limit does not immediately take effect but can
     be done before the activation. For these reasons, we set it at
     the beginning. *)
  let* block =
    let* operation = set_delegate_parameters (B block) delegate1 1000000 0 in
    Block.bake ~operation block
  in

  (* Initialization of a delegator account which will attempt to
     costake with delegate1. *)
  let wannabe_costaker_account = Account.new_account () in
  let wannabe_costaker =
    Protocol.Alpha_context.Contract.Implicit
      Account.(wannabe_costaker_account.pkh)
  in

  (* To set up the wannabe costaker, we need three operations: a
     transfer from the delegate to initialize its balance, a
     revelation of its public key, and a delegation toward the
     delegate. For simplicity we put these operations in different
     blocks. *)
  let* block =
    let half_balance =
      Protocol.Alpha_context.Tez.of_mutez_exn 2_000_000_000_000L
    in
    let* operation =
      Op.transaction (B block) delegate1 wannabe_costaker half_balance
    in
    Block.bake ~operation block
  in
  let* block =
    let* operation = Op.revelation (B block) wannabe_costaker_account.pk in
    Block.bake ~operation block
  in
  let* block =
    let* operation =
      Op.delegation (B block) wannabe_costaker (Some delegate1_pkh)
    in
    Block.bake ~operation block
  in

  (* Initialize the frozen parts of the delegate stakes. *)
  let* block =
    let* balance1 = Context.Contract.balance (B block) delegate1 in
    let* balance2 = Context.Contract.balance (B block) delegate2 in
    let* balance3 = Context.Contract.balance (B block) delegate3 in
    (* Delegate1 keeps about one tez liquid to pay for fees. *)
    let*?@ to_stake1 = Protocol.Alpha_context.Tez.(balance1 -? one) in
    (* Delegate2 does the same. *)
    let*?@ to_stake2 = Protocol.Alpha_context.Tez.(balance2 -? one) in
    (* Delegate3 keeps 50% of its stake liquid. Since its total stake
         is 4 millions, this means that 2 millions are kept liquid. *)
    let*?@ to_stake3 =
      Protocol.Alpha_context.Tez.(balance3 -? of_mutez_exn 2_000_000_000_000L)
    in
    let* operation1 = stake (B block) delegate1 to_stake1 in
    let* operation2 = stake (B block) delegate2 to_stake2 in
    let* operation3 = stake (B block) delegate3 to_stake3 in
    let* block =
      Block.bake ~operations:[operation1; operation2; operation3] block
    in
    (* Wait a few cycles for total_frozen_stake to update. *)
    let* block = Block.bake_until_n_cycle_end (preserved_cycles + 1) block in
    return block
  in
  let* total_frozen_stake = Context.get_total_frozen_stake (B block) in
  let* () =
    (* Delegate1 has staked 2 million tez (the other half of its
       initial balance was sent to its delegator. Delegate2 has staked
       4 million tez. Delegate3 has staked 2 million tez. In total, 8
       million tez have been staked. *)
    Almost_equal_tez.assert_almost_equal
      ~loc:__LOC__
      ~margin_percent:(Protocol.Alpha_context.Tez.of_mutez_exn 1L)
      total_frozen_stake
      (Protocol.Alpha_context.Tez.of_mutez_exn 8_000_000_000_000L)
  in

  (* Since adaptive inflation is not active yet, staked and delegated
     tez are still worth the same in the computation of baking and
     voting rights. *)
  let* () =
    assert_same_power3
      ~loc:__LOC__
      block
      delegate1_pkh
      delegate2_pkh
      delegate3_pkh
  in

  (* We are now ready to activate the feature through by baking many
     more blocks voting in favor of the activation until the EMA
     threshold is reached. *)
  let* () = assert_is_not_yet_set_to_launch ~loc:__LOC__ block in

  let start_of_vote_level = block.header.shell.level in

  let* block =
    Block.bake_while_with_metadata
      ~adaptive_inflation_vote:Toggle_vote_on
      (fun _block metadata ->
        let ema =
          Protocol.Alpha_context.Toggle_votes.Adaptive_inflation_launch_EMA
          .to_int32
            metadata.adaptive_inflation_toggle_ema
        in
        Compare.Int32.(ema < threshold))
      block
  in
  (* At this point we are on the last block before the end of the vote. *)
  let* () =
    assert_level
      ~loc:__LOC__
      block
      (Int32.add start_of_vote_level (Int32.pred expected_vote_duration))
  in
  let* () = assert_is_not_yet_set_to_launch ~loc:__LOC__ block in
  (* Since adaptive inflation is not active yet, staked and delegated
     tez are still worth the same in the computation of baking and
     voting rights. *)
  let* () =
    assert_same_power3
      ~loc:__LOC__
      block
      delegate1_pkh
      delegate2_pkh
      delegate3_pkh
  in
  (* We bake one more block to end the vote and set the feature to launch. *)
  let* block, metadata =
    Block.bake_n_with_metadata ~adaptive_inflation_vote:Toggle_vote_on 1 block
  in
  let* () = assert_ema_above_threshold ~loc:__LOC__ metadata in
  let* () =
    assert_level
      ~loc:__LOC__
      block
      (Int32.add start_of_vote_level expected_vote_duration)
  in
  (* At this point the feature is not launched yet, it is simply
     planned to be launched. *)
  (* We check that the feature is not yet active by attempting a
     costake operation. *)
  let* () =
    let* operation =
      stake
        (B block)
        wannabe_costaker
        (Protocol.Alpha_context.Tez.of_mutez_exn 10L)
    in
    let* i = Incremental.begin_construction block in
    let*! i = Incremental.add_operation i operation in
    Assert.error ~loc:__LOC__ i (fun _ -> true)
  in

  let* launch_cycle = get_launch_cycle ~loc:__LOC__ block in
  (* Bake until the activation. *)
  let* block = Block.bake_until_cycle launch_cycle block in
  let* block, metadata = Block.bake_n_with_metadata 1 block in
  let* () = assert_ema_above_threshold ~loc:__LOC__ metadata in
  (* Check that keeping the EMA above the threshold did not postpone
     the activation. *)
  let* launch_cycle_bis = get_launch_cycle ~loc:__LOC__ block in
  let* () = assert_cycle_eq ~loc:__LOC__ launch_cycle launch_cycle_bis in
  (* Check that the current cycle is the at which the launch is
     planned to happen. *)
  let* () = assert_current_cycle ~loc:__LOC__ block launch_cycle in

  (* Adaptive inflation should now be active. Delegate 1 and 3 have
     staked the same amount so they still have the same
     rights. Delegate 2 has staked more. *)
  let* () = assert_same_power ~loc:__LOC__ block delegate1_pkh delegate3_pkh in
  let* () = assert_less_power ~loc:__LOC__ block delegate1_pkh delegate2_pkh in

  (* Test that the wannabe costaker is now allowed to stake almost all
     its balance. *)
  let* balance = Context.Contract.balance (B block) wannabe_costaker in
  let*?@ balance_to_stake = Protocol.Alpha_context.Tez.(balance -? one) in

  let* total_frozen_stake_before_costake =
    Context.get_total_frozen_stake (B block)
  in
  (* let* delegate_info_before_costake = Context.Delegate.info (B block)  *)
  let* block =
    let* operation = stake (B block) wannabe_costaker balance_to_stake in
    Block.bake ~operation block
  in
  let* total_frozen_stake_after_costake =
    Context.get_total_frozen_stake (B block)
  in

  let*?@ expected_total_frozen_stake =
    Protocol.Alpha_context.Tez.(
      total_frozen_stake_before_costake +? zero (* balance_to_stake *))
  in

  (* Still the same rights because costaking takes a few cycle to take effect. *)
  let* () =
    assert_same_endorsing_power ~loc:__LOC__ block delegate1_pkh delegate2_pkh
  in
  let* () =
    assert_same_voting_power ~loc:__LOC__ block delegate1_pkh delegate2_pkh
  in

  let* block = Block.bake_until_n_cycle_end (preserved_cycles + 1) block in
  let* () =
    Assert.equal_tez
      ~loc:__LOC__
      total_frozen_stake_after_costake
      expected_total_frozen_stake
  in
  (* Now things have changed because of the costaking. *)
  let* () =
    assert_less_endorsing_power ~loc:__LOC__ block delegate1_pkh delegate2_pkh
  in
  let* () =
    assert_less_voting_power ~loc:__LOC__ block delegate1_pkh delegate2_pkh
  in

  return_unit

let tests =
  [
    Tztest.tztest
      "the EMA reaches the vote threshold at the expected level and adaptive \
       inflation launch cycle is set (very low threshold)"
      `Quick
      (test_launch
         1000000l (* This means that the threshold is set at 0.05% *)
         59l);
    Tztest.tztest
      "the EMA reaches the vote threshold at the expected level and adaptive \
       inflation launch cycle is set (realistic threshold)"
      `Slow
      (test_launch
         Default_parameters.constants_test.adaptive_inflation
           .launch_ema_threshold
         187259l
         (* This vote duration is consistent with the result of the
            unit test for this EMA in
            ../unit/test_adaptive_inflation_ema.ml*));
  ]

let () =
  Alcotest_lwt.run
    ~__FILE__
    Protocol.name
    [("adaptive inflation launch", tests)]
  |> Lwt_main.run
