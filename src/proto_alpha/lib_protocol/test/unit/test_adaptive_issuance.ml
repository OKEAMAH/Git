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
    Component:  Protocol (rewards)
    Invocation: dune exec src/proto_alpha/lib_protocol/test/unit/main.exe \
                 -- --file test_adaptive_issuance.ml
    Subject:    Test reward values under adaptive issuance
*)

open Protocol
open Alpha_context

let test_reward_coefficient () =
  let csts = Default_parameters.constants_test in
  let default =
    Delegate.Rewards.For_RPC.(
      reward_from_constants csts ~reward_kind:Baking_reward_fixed_portion)
  in
  let default_times_4 =
    Delegate.Rewards.For_RPC.(
      reward_from_constants
        ~coeff:(Q.of_int 4)
        csts
        ~reward_kind:Baking_reward_fixed_portion)
  in
  Assert.equal_tez ~loc:__LOC__ (Tez.mul_exn default 4) default_times_4

let test_reward_coeff_ratio () =
  let open Delegate.Rewards.Internal_for_tests in
  let open Lwt_result_wrap_syntax in
  let assert_eq ~loc a b = Assert.equal ~loc Q.equal "" Q.pp_print a b in
  (* Curve tests *)
  let curve stake_ratio =
    compute_reward_coeff_ratio
      ~stake_ratio
      ~bonus:Issuance_bonus_repr.zero
      ~issuance_ratio_max:(Q.of_int 1_000_000)
      ~issuance_ratio_min:(Q.of_int (-1_000_000))
  in
  (* Test the curve on some staking points: 1, 1/10, 1/100, 1/2 *)
  let* () = assert_eq ~loc:__LOC__ (curve Q.one) Q.(1 // 1600) in
  let* () = assert_eq ~loc:__LOC__ (curve Q.(1 // 10)) Q.(1 // 16) in
  let* () = assert_eq ~loc:__LOC__ (curve Q.(1 // 100)) Q.(100 // 16) in
  let* () = assert_eq ~loc:__LOC__ (curve Q.(1 // 2)) Q.(1 // 400) in
  (* Test the curve on extreme values: ε and 1 - ε with ε small *)
  let epsilon = Q.(3 // 50000) in
  let one_m_e = Q.(one - epsilon) in
  let* () =
    assert_eq ~loc:__LOC__ (curve epsilon) Q.(1 // 1600 / (epsilon * epsilon))
  in
  let* () =
    assert_eq ~loc:__LOC__ (curve one_m_e) Q.(1 // 1600 / (one_m_e * one_m_e))
  in
  (* Test bonus *)
  let max_bonus = Issuance_bonus_repr.max_bonus_parameter_of_Q_exn Q.one in
  let*?@ bonus = Issuance_bonus_repr.of_Q ~max_bonus Q.(1 // 5) in
  (* If bounds are not reached, the bonus is an additive component of the curve *)
  let* () =
    assert_eq
      ~loc:__LOC__
      (Q.add Q.(1 // 5) (curve Q.(1 // 10)))
      (compute_reward_coeff_ratio
         ~stake_ratio:Q.(1 // 10)
         ~bonus
         ~issuance_ratio_max:(Q.of_int 100)
         ~issuance_ratio_min:(Q.of_int (-100)))
  in
  (* Test min max *)
  let bound = Q.(1 // 30) in
  (* curve(1/10) = 1/16 > 1/30. Expected result: 1/30 *)
  let* () =
    assert_eq
      ~loc:__LOC__
      (compute_reward_coeff_ratio
         ~stake_ratio:Q.(1 // 10)
         ~bonus:Issuance_bonus_repr.zero
         ~issuance_ratio_max:bound
         ~issuance_ratio_min:(Q.of_int (-100)))
      bound
  in
  (* curve(1) = 1/1600 < 1/30. Expected result: 1/30 *)
  let* () =
    assert_eq
      ~loc:__LOC__
      (compute_reward_coeff_ratio
         ~stake_ratio:Q.one
         ~bonus:Issuance_bonus_repr.zero
         ~issuance_ratio_max:(Q.of_int 100)
         ~issuance_ratio_min:bound)
      bound
  in
  (* curve(1) + 1/5 = 1/5 + 1/1600 > 1/30. Expected result: 1/30 *)
  let* () =
    assert_eq
      ~loc:__LOC__
      (compute_reward_coeff_ratio
         ~stake_ratio:Q.one
         ~bonus
         ~issuance_ratio_max:bound
         ~issuance_ratio_min:(Q.of_int (-100)))
      bound
  in
  return_unit

let test_compute_bonus () =
  let open Delegate.Rewards.Internal_for_tests in
  let open Lwt_result_wrap_syntax in
  let assert_fun ~loc ~f a b = Assert.equal ~loc f "" Q.pp_print a b in
  let assert_eq ~loc a b = Assert.equal ~loc Q.equal "" Q.pp_print a b in
  let reward_params =
    Default_parameters.constants_test.adaptive_issuance.adaptive_rewards_params
  in
  (* For simplicity, one cycle = one day *)
  let seconds_per_cycle = 86_400L in
  let compute_bonus frozen total previous =
    assert (frozen <= total) ;
    Lwt_main.run
      (let total_supply = Tez_repr.of_mutez_exn total in
       let total_frozen_stake = Tez_repr.of_mutez_exn frozen in
       let*?@ previous_bonus =
         Issuance_bonus_repr.of_Q ~max_bonus:reward_params.max_bonus previous
       in
       let*?@ bonus =
         compute_bonus
           ~seconds_per_cycle
           ~total_supply
           ~total_frozen_stake
           ~previous_bonus
           ~reward_params
       in
       return (bonus :> Q.t))
    |> Result.value_f ~default:(fun () -> assert false)
  in
  let small_bonus = Q.(1 // 200) (* 0.5% *) in
  (* Test deadzone *)
  let* () =
    assert_eq ~loc:__LOC__ (compute_bonus 48L 100L small_bonus) small_bonus
  in
  let* () =
    assert_eq ~loc:__LOC__ (compute_bonus 52L 100L small_bonus) small_bonus
  in
  let* () =
    assert_fun
      ~loc:__LOC__
      ~f:Q.gt
      (compute_bonus 47_9999L 100_0000L small_bonus)
      small_bonus
  in
  let* () =
    assert_fun
      ~loc:__LOC__
      ~f:Q.lt
      (compute_bonus 52_0001L 100_0000L small_bonus)
      small_bonus
  in
  (* Test variation amplitude *)
  let variation = Q.(1 // 10_000) (* 0.01% *) in
  let* () =
    assert_eq
      ~loc:__LOC__
      (compute_bonus 47L 100L small_bonus)
      (Q.add small_bonus variation)
  in
  let* () =
    assert_eq
      ~loc:__LOC__
      (compute_bonus 40L 100L small_bonus)
      (Q.add small_bonus (Q.mul variation (Q.of_int 8)))
  in
  let* () =
    assert_eq
      ~loc:__LOC__
      (compute_bonus 53L 100L small_bonus)
      (Q.sub small_bonus variation)
  in
  let* () =
    assert_eq
      ~loc:__LOC__
      (compute_bonus 60L 100L small_bonus)
      (Q.sub small_bonus (Q.mul variation (Q.of_int 8)))
  in
  (* Test bounds *)
  let max_bonus = (reward_params.max_bonus :> Q.t) in
  let* () = assert_eq ~loc:__LOC__ (compute_bonus 60L 100L Q.zero) Q.zero in
  let* () =
    assert_fun
      ~loc:__LOC__
      ~f:Q.leq
      (compute_bonus 40L 100L max_bonus)
      max_bonus
  in
  return_unit

let tests =
  Tztest.
    [
      tztest
        "adaptive issuance - application of coefficient to rewards"
        `Quick
        test_reward_coefficient;
      tztest
        "adaptive issuance - reward coeff ratio computation"
        `Quick
        test_reward_coeff_ratio;
      tztest
        "adaptive issuance - reward bonus computation"
        `Quick
        test_compute_bonus;
    ]

let () =
  Alcotest_lwt.run ~__FILE__ Protocol.name [("adaptive issuance", tests)]
  |> Lwt_main.run
