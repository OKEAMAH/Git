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
    Component:    Protocol Library
    Invocation:   dune exec \
                  src/proto_alpha/lib_protocol/test/pbt/test_sc_rollup_encoding.exe
    Subject:      SC rollup encoding
*)

open Protocol
open QCheck2
open Lib_test.Qcheck2_helpers

let lift k = Lwt.map Environment.wrap_tzresult k

(** {2 Generators} *)

let gen_state_hash =
  let open Gen in
  let* bytes = bytes_fixed_gen Sc_rollup_repr.State_hash.size in
  return (Sc_rollup_repr.State_hash.of_bytes_exn bytes)

let gen_raw_level =
  let open Gen in
  let* level = map Int32.abs int32 in
  return (Raw_level_repr.of_int32_exn level)

let gen_commitment_hash =
  let open Gen in
  let* bytes = bytes_fixed_gen Sc_rollup_commitment_repr.Hash.size in
  return (Sc_rollup_commitment_repr.Hash.of_bytes_exn bytes)

let gen_number_of_ticks =
  let open Gen in
  let open Sc_rollup_repr.Number_of_ticks in
  let* v = int64_range_gen min_value max_value in
  return (WithExceptions.Option.get ~loc:__LOC__ (of_value v))

let gen_commitment =
  let open Gen in
  let* compressed_state = gen_state_hash
  and* inbox_level = gen_raw_level
  and* predecessor = gen_commitment_hash
  and* number_of_ticks = gen_number_of_ticks in
  return
    Sc_rollup_commitment_repr.
      {compressed_state; inbox_level; predecessor; number_of_ticks}

let gen_versioned_commitment =
  let open Gen in
  let* commitment = gen_commitment in
  return (Sc_rollup_commitment_repr.to_versioned commitment)

let gen_player = Gen.oneofl Sc_rollup_game_repr.[Alice; Bob]

let gen_inbox rollup level =
  let open Gen in
  let gen_msg = small_string ~gen:printable in
  let* hd = gen_msg in
  let* tail = small_list gen_msg in
  let payloads = hd :: tail in
  let level_tree_and_inbox =
    let open Lwt_result_syntax in
    let* ctxt = Context.default_raw_context () in
    let inbox_ctxt = Raw_context.recover ctxt in
    let*! empty_inbox = Sc_rollup_inbox_repr.empty inbox_ctxt rollup level in
    lift
    @@ let*? input_messages =
         List.map_e
           (fun msg -> Sc_rollup_inbox_message_repr.(serialize (External msg)))
           payloads
       in
       Sc_rollup_inbox_repr.add_messages_no_history
         inbox_ctxt
         empty_inbox
         level
         input_messages
         None
  in
  return
  @@ (Lwt_main.run level_tree_and_inbox |> function
      | Ok v -> snd v
      | Error e ->
          Stdlib.failwith (Format.asprintf "%a" Error_monad.pp_print_trace e))

let gen_inbox_history_proof rollup level =
  let open Gen in
  let* inbox = gen_inbox rollup level in
  return (Sc_rollup_inbox_repr.take_snapshot inbox)

let gen_raw_level =
  let open Gen in
  let* level = small_nat in
  return @@ Raw_level_repr.of_int32_exn (Int32.of_int level)

let gen_pvm_name = Gen.string_printable

let gen_tick =
  let open Gen in
  let* t = small_nat in
  match Sc_rollup_tick_repr.of_int t with
  | None -> assert false
  | Some r -> return r

let gen_dissection =
  let open Gen in
  small_list (pair (opt gen_state_hash) gen_tick)

let gen_rollup =
  let open Gen in
  let* bytes = bytes_fixed_gen Sc_rollup_repr.Address.size in
  return (Sc_rollup_repr.Address.hash_bytes [bytes])

let gen_game =
  let open Gen in
  let* turn = gen_player in
  let* level = gen_raw_level in
  let* rollup = gen_rollup in
  let* inbox_snapshot = gen_inbox_history_proof rollup level in
  (* FIXME/DAL: https://gitlab.com/tezos/tezos/-/issues/3806
     Generate a non-empty dal Slots_history.t if/when Dal
     is tested here. Otherwise, empty Dal snapshot means that no Dal slot
     is confirmed. *)
  let dal_snapshot = Dal_slot_repr.Slots_history.genesis in
  let* pvm_name = gen_pvm_name in
  let* dissection = gen_dissection in
  let* default_number_of_sections = int_range 4 100 in
  let dissection =
    List.map
      (fun (state_hash, tick) -> Sc_rollup_game_repr.{state_hash; tick})
      dissection
  in
  return
    Sc_rollup_game_repr.
      {
        turn;
        inbox_snapshot;
        dal_snapshot;
        level;
        pvm_name;
        dissection;
        default_number_of_sections (* should be greater than 3 *);
      }

let gen_conflict =
  let open Gen in
  let other = Sc_rollup_repr.Staker.zero in
  let* their_commitment = gen_commitment in
  let* our_commitment = gen_commitment in
  let* parent_commitment = gen_commitment_hash in
  return
    Sc_rollup_refutation_storage.
      {other; their_commitment; our_commitment; parent_commitment}

(** {2 Tests} *)

let test_commitment =
  test_roundtrip
    ~count:1_000
    ~title:"Sc_rollup_commitment.t"
    ~gen:gen_commitment
    ~eq:( = )
    Sc_rollup_commitment_repr.encoding

let test_versioned_commitment =
  test_roundtrip
    ~count:1_000
    ~title:"Sc_rollup_commitment.versioned"
    ~gen:gen_versioned_commitment
    ~eq:( = )
    Sc_rollup_commitment_repr.versioned_encoding

let test_game =
  test_roundtrip
    ~count:1_000
    ~title:"Sc_rollup_game.t"
    ~gen:gen_game
    ~eq:Sc_rollup_game_repr.equal
    Sc_rollup_game_repr.encoding

let test_conflict =
  test_roundtrip
    ~count:1_000
    ~title:"Sc_rollup_refutation_storage.conflict"
    ~gen:gen_conflict
    ~eq:( = )
    Sc_rollup_refutation_storage.conflict_encoding

let tests =
  [test_commitment; test_versioned_commitment; test_game; test_conflict]

let () = Alcotest.run "SC rollup encoding" [("roundtrip", qcheck_wrap tests)]
