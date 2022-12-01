(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.tech>                       *)
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
  | Sc_rollup_disputed
  | Sc_rollup_does_not_exist of Sc_rollup_repr.t
  | Sc_rollup_no_conflict
  | Sc_rollup_no_stakers
  | Sc_rollup_not_staked
  | Sc_rollup_not_staked_on_lcc
  | Sc_rollup_parent_not_lcc
  | Sc_rollup_remove_lcc
  | Sc_rollup_staker_backtracked
  | Sc_rollup_too_far_ahead
  | Sc_rollup_commitment_too_recent of {
      current_level : Raw_level_repr.t;
      min_level : Raw_level_repr.t;
    }
  | Sc_rollup_unknown_commitment of Sc_rollup_commitment_repr.Hash.t
  | Sc_rollup_bad_inbox_level
  | Sc_rollup_game_already_started
  | Sc_rollup_wrong_turn
  | Sc_rollup_no_game
  | Sc_rollup_staker_in_game of
      [ `Both of Signature.public_key_hash * Signature.public_key_hash
      | `Defender of Signature.public_key_hash
      | `Refuter of Signature.public_key_hash ]
  | Sc_rollup_timeout_level_not_reached of int32 * Signature.public_key_hash
  | Sc_rollup_max_number_of_messages_reached_for_commitment_period
  | Sc_rollup_add_zero_messages
  | Sc_rollup_invalid_outbox_message_index
  | Sc_rollup_outbox_level_expired
  | Sc_rollup_outbox_message_already_applied
  | Sc_rollup_staker_funds_too_low of {
      staker : Signature.public_key_hash;
      sc_rollup : Sc_rollup_repr.t;
      staker_balance : Tez_repr.t;
      min_expected_balance : Tez_repr.t;
    }
  | Sc_rollup_bad_commitment_serialization
  | Sc_rollup_address_generation
  | Sc_rollup_zero_tick_commitment
  | Sc_rollup_commitment_past_curfew
  | Sc_rollup_commitment_from_future of {
      current_level : Raw_level_repr.t;
      inbox_level : Raw_level_repr.t;
    }
