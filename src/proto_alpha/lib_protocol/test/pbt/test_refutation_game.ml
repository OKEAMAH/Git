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

(** Testing
    -------
    Component:    PBT for the SCORU refutation game
    Invocation:   dune exec \
                  src/proto_alpha/lib_protocol/test/pbt/test_refutation_game.exe
    Subject:      SCORU refutation game
*)
open Protocol

open Alpha_context
open Sc_rollup
open Lib_test.Qcheck2_helpers

(** {2 Utils} *)

let cryptobox_parameters =
  Dal_helpers.derive_dal_parameters
    Default_parameters.constants_mainnet.dal.cryptobox_parameters
    ~redundancy_factor:4
    ~constants_divider:64

let dal_parameters =
  {
    Default_parameters.constants_mainnet.dal with
    feature_enable = true;
    availability_threshold = 0;
    (* Slots are automatically confirmed. *)
    cryptobox_parameters;
  }

let network_constants =
  {Default_parameters.constants_mainnet with dal = dal_parameters}

let cryptobox =
  Cryptobox.Internal_for_tests.load_parameters
  @@ Cryptobox.Internal_for_tests.initialisation_parameters_from_slot_size
       ~slot_size:cryptobox_parameters.slot_size ;
  WithExceptions.Result.get_ok ~loc:__LOC__
  @@ Cryptobox.make cryptobox_parameters

(* Dal_pages *)
module M = Map.Make (struct
  type t = Dal.slot_id

  let compare = Dal.Slot.Header.compare_slot_id
end)

module P = Map.Make (Compare.Int)

module Dal_pages = struct
  type t = Bytes.t array M.t

  let find_slot = M.find_opt

  let find_page Dal.Page.{slot_id; page_index} m =
    match find_slot slot_id m with
    | None -> None
    | Some arr -> (
        try Array.get arr page_index with Invalid_argument _ -> None)

  let add = M.add

  let empty = M.empty

  let bindings = M.bindings

  let cardinal = M.cardinal
end

module Dal_headers = struct
  open Dal
  open Page

  type t = Dal.Slot.Header.t M.t

  let find = M.find_opt

  let add = M.add

  let empty = M.empty

  let bindings = M.bindings

  let cardinal = M.cardinal
end

let qcheck_make_lwt = qcheck_make_lwt ~extract:Lwt_main.run

let qcheck_make_lwt_res ?print ?count ~name ~gen f =
  qcheck_make_result
    ~pp_error:Error_monad.pp_print_trace
    ?print
    ?count
    ~name
    ~gen
    (fun a -> Lwt_main.run (f a))

(** Lift a computation using environment errors to use shell errors. *)
let lift k = Lwt.map Environment.wrap_tzresult k

let tick_to_int_exn ?(__LOC__ = __LOC__) t =
  WithExceptions.Option.get ~loc:__LOC__ (Tick.to_int t)

let tick_of_int_exn ?(__LOC__ = __LOC__) n =
  WithExceptions.Option.get ~loc:__LOC__ (Tick.of_int n)

let number_of_ticks_of_int64_exn ?(__LOC__ = __LOC__) n =
  WithExceptions.Option.get ~loc:__LOC__ (Number_of_ticks.of_value n)

let make_external_inbox_message str =
  WithExceptions.Result.get_ok
    ~loc:__LOC__
    Inbox_message.(External str |> serialize)

let game_status_of_refute_op_result = function
  | [
      Apply_results.Operation_metadata
        {
          contents =
            Single_result
              (Manager_operation_result
                {
                  operation_result =
                    Applied (Sc_rollup_refute_result {game_status; _});
                  _;
                });
        };
    ] ->
      game_status
  | _ -> assert false

let list_assoc (key : Tick.t) list = List.assoc ~equal:( = ) key list

let print_dissection_chunk = Format.asprintf "%a" Game.pp_dissection_chunk

let print_dissection = Format.asprintf "%a" Game.pp_dissection

let print_our_states _ = "<our states>"

(** Assert that the computation fails with the given message. *)
let assert_fails_with ~__LOC__ (res : unit Environment.Error_monad.tzresult)
    expected_err =
  match res with
  | Error trace ->
      let expected_trace =
        Environment.Error_monad.trace_of_error expected_err
      in
      if expected_trace = trace then Lwt.return true
      else
        let pp = Environment.Error_monad.pp_trace in
        QCheck2.Test.fail_reportf
          "@[Expected reason: %a@;Actual reason: %a@]"
          pp
          expected_trace
          pp
          trace
  | Ok () -> Lwt.return false

let initial_of_dissection dissection =
  List.hd dissection |> WithExceptions.Option.get ~loc:__LOC__

(** Modify the last section of a dissection. *)
let rec modify_stop f dissection =
  match dissection with
  | [] -> assert false
  | [chunk] -> [f chunk]
  | x :: xs ->
      let xs = modify_stop f xs in
      x :: xs

(** Modify the first section of a dissection. *)
let modify_start f dissection =
  match dissection with
  | chunk :: xs -> f chunk :: xs
  | [] -> (* The dissection can not be empty. *) assert false

(** Checks that the [dissection] is valid regarding the function
    {!Sc_rollup_game_repr.check_dissection}. *)
let valid_dissection ~default_number_of_sections ~start_chunk ~stop_chunk
    dissection =
  Game.Internal_for_tests.check_dissection
    ~default_number_of_sections
    ~start_chunk
    ~stop_chunk
    dissection
  |> Result.is_ok

(** [disputed_sections ~our_states dissection] returns the list of sections
    in the [dissection] on which the player dissecting disagree with.
    It uses [our_states], an assoc list between tick and state hashes to
    compare opponent's claims against our point of view. *)
let disputed_sections ~our_states dissection =
  let open Game in
  let agree_on_state tick their_state =
    let our_state = list_assoc tick our_states in
    Option.equal State_hash.equal our_state their_state
  in
  let rec traverse acc = function
    | ({state_hash = their_start_state; tick = start_tick} as a)
      :: ({state_hash = their_stop_state; tick = stop_tick} as b)
      :: dissection ->
        let rst = b :: dissection in
        if agree_on_state start_tick their_start_state then
          (* It's a disputed section if we agree on the start state but disagree
             on the stop. *)
          if agree_on_state stop_tick their_stop_state then traverse acc rst
          else
            let disputed_section = (a, b) in
            traverse (disputed_section :: acc) rst
        else traverse acc rst
    | _ -> acc
  in
  traverse [] dissection

let pick_disputed_sections disputed_sections =
  QCheck2.Gen.oneofl disputed_sections

let single_tick_disputed_sections disputed_sections =
  List.filter_map
    (fun disputed_section ->
      let Game.({tick = a_tick; _}, {tick = b_tick; _}) = disputed_section in
      let distance = Tick.distance a_tick b_tick in
      if Z.Compare.(distance = Z.one) then Some disputed_section else None)
    disputed_sections

let final_dissection ~our_states dissection =
  let disputed_sections = disputed_sections ~our_states dissection in
  let single_tick_disputed_sections =
    single_tick_disputed_sections disputed_sections
  in
  Compare.List_length_with.(single_tick_disputed_sections > 0)

(** Build a non-random dissection from [start_chunk] to [stop_chunk] using
    [our_states] as the state hashes for each tick. *)
let build_dissection ~number_of_sections ~start_chunk ~stop_chunk ~our_states =
  let open Lwt_result_syntax in
  let state_hash_from_tick tick = return @@ list_assoc tick our_states in
  let our_stop_chunk =
    Game.{stop_chunk with state_hash = list_assoc stop_chunk.tick our_states}
  in
  (* TODO: https://gitlab.com/tezos/tezos/-/issues/3491

     This dissection's building does not check the number of sections. Checks should
     be added to verify that we don't generate invalid dissection and test the
     incorrect cases. *)
  Lwt_main.run
  @@ let*! r =
       Game_helpers.new_dissection
         ~start_chunk
         ~our_stop_chunk
         ~default_number_of_sections:number_of_sections
         ~state_hash_from_tick
     in
     Lwt.return @@ WithExceptions.Result.get_ok ~loc:__LOC__ r

let originate_rollup originator messager ~first_inputs block =
  let open Lwt_result_syntax in
  let* origination_operation, sc_rollup =
    Op.sc_rollup_origination
      (B block)
      originator
      Kind.Example_arith
      ~boot_sector:""
      ~parameters_ty:(Script.lazy_expr @@ Expr.from_string "unit")
  in
  let* add_message_operation =
    Op.sc_rollup_add_messages (B block) messager sc_rollup first_inputs
  in
  let* block =
    Block.bake ~operations:[origination_operation; add_message_operation] block
  in
  let+ genesis_info = Context.Sc_rollup.genesis_info (B block) sc_rollup in
  (block, sc_rollup, genesis_info)

(** [create_ctxt account1 account2] creates a context where
    an arith rollup was originated, and both [account1] and [account2] owns
    enough tez to stake on a commitment. *)
let create_ctxt ~first_inputs =
  WithExceptions.Result.get_ok ~loc:__LOC__
  @@ Lwt_main.run
  @@
  let open Lwt_result_syntax in
  let* block, (account1, account2, account3) =
    Context.init3
      ~sc_rollup_enable:true
      ~dal_parameters
      ~consensus_threshold:0
      ~bootstrap_balances:[100_000_000_000L; 100_000_000_000L; 100_000_000_000L]
      ()
  in
  let* block, sc_rollup, genesis_info =
    originate_rollup account3 account1 ~first_inputs block
  in
  return (block, sc_rollup, genesis_info, (account1, account2, account3))

(** {2 Context free generators} *)

(** Generate a {!State_hash.t}.

    We use a dirty hack {!QCheck2.Gen.make_primitive} to remove the
    automatic shrinking. Shrinking on the states in a dissection can
    be confusing, it can leads to a shrunk list with the same states in
    each cell.
*)
let gen_random_hash =
  let open QCheck2.Gen in
  let gen =
    let* x = bytes_fixed_gen 32 in
    return @@ State_hash.of_bytes_exn x
  in
  (* This is not beautiful, but there is currently no other way to
     remove the shrinker. *)
  make_primitive
    ~gen:(fun rand -> generate1 ~rand gen)
    ~shrink:(fun _ -> Seq.empty)

(** Generate the number of sections in the dissection. *)
let gen_num_sections =
  let open Tezos_protocol_alpha_parameters.Default_parameters in
  let testnet = constants_test.sc_rollup.number_of_sections_in_dissection in
  let mainnet = constants_mainnet.sc_rollup.number_of_sections_in_dissection in
  let sandbox = constants_sandbox.sc_rollup.number_of_sections_in_dissection in
  QCheck2.Gen.(
    frequency
      [(5, pure mainnet); (4, pure testnet); (2, pure sandbox); (1, 4 -- 100)])

(** Generate a tick. *)
let gen_tick ?(lower_bound = 0) ?(upper_bound = 10_000) () =
  let open QCheck2.Gen in
  let+ tick = lower_bound -- upper_bound in
  tick_of_int_exn ~__LOC__ tick

(** [gen_arith_pvm_inputs ~gen_size] is a `correct list` generator.
    It generates a list of strings that are either integers or `+` to be
    consumed by the arithmetic PVM.
    If a `+` is found then the previous two element of the stack are poped
    then added and the result is pushed to the stack. In particular,
    lists like `[1 +]` are incorrect. *)
let gen_arith_pvm_inputs ~gen_size =
  let open QCheck2.Gen in
  (* To preserve the correctness invariant, genlist is a recursive generator
     that produce a pair `(stack_size, state_list)` where  state_list is a
     correct list of integers and `+` and consuming it will produce a `stack`
     of length `stack_size`.
     For example a result can be `(3, [1; 2; +; 3; +; 2; 2; +; 1;]).
     Consuming the list will produce the stack`[6; 4; 1]` which has length 3. *)
  let produce_inputs self fuel =
    match fuel with
    | 0 -> map (fun x -> (1, [string_of_int x])) small_nat
    | n ->
        (* The generator has two branches.
           1. with frequency 1 adds integers to state_list and increases the
              corresponding stack_size.
           2. With frequency 2, at each step, it looks at the inductive result
              [(self (n - 1)) = (stack_size, state_list)].

           If the stack_size is smaller than 2 then it adds an integer to the
           state_list and increases the stack_size. Otherwise, it adds a plus
           to the state_list and decreases the stack_size. *)
        frequency
          [
            ( 2,
              map2
                (fun x (stack_size, state_list) ->
                  if stack_size >= 2 then (stack_size - 1, "+" :: state_list)
                  else (stack_size + 1, string_of_int x :: state_list))
                small_nat
                (self (n / 2)) );
            ( 1,
              map2
                (fun x (i, y) -> (i + 1, string_of_int x :: y))
                small_nat
                (self (n / 2)) );
          ]
  in
  let+ inputs = sized_size gen_size @@ fix produce_inputs in
  snd inputs |> List.rev |> String.concat " "

(** Generate a list of arith pvm inputs for a level *)
let gen_arith_pvm_inputs_for_level ?(level_min = 0) ?(level_max = 1_000) () =
  let open QCheck2.Gen in
  let* level = level_min -- level_max in
  let* input = gen_arith_pvm_inputs ~gen_size:(pure 0) in
  let* inputs = small_list (gen_arith_pvm_inputs ~gen_size:(pure 0)) in
  return (level, input :: inputs)

(** Generate a list of level and associated arith pvm inputs. *)
let gen_arith_pvm_inputs_for_levels ?(nonempty_inputs = false) ?level_min
    ?level_max () =
  let open QCheck2.Gen in
  let rec aux () =
    let* res =
      let+ inputs_per_level =
        small_list (gen_arith_pvm_inputs_for_level ?level_min ?level_max ())
      in
      List.sort_uniq
        (fun (l, _) (l', _) -> Compare.Int.compare l l')
        inputs_per_level
    in
    if nonempty_inputs && Compare.List_length_with.(res = 0) then aux ()
    else return res
  in
  aux ()

(** Dissection helpers and tests *)
module Dissection = struct
  (** Generate an initial *valid* dissection. The validity comes from a
      mirrored implementation of {!Sc_rollup_game_repr.initial}. *)
  let gen_initial_dissection ?ticks () =
    let open QCheck2.Gen in
    let* child_state = gen_random_hash and* parent_state = gen_random_hash in
    let* ticks =
      let+ ticks =
        match ticks with
        | None -> frequency [(1, pure 0); (9, 1 -- 1_000)]
        | Some distance -> pure distance
      in
      Z.of_int ticks
    in
    let* initial_tick = gen_tick () in
    if Z.Compare.(ticks = Z.zero) then
      pure
        [
          Game.{state_hash = Some child_state; tick = initial_tick};
          Game.{state_hash = None; tick = Tick.next initial_tick};
        ]
    else
      let tick = Tick.jump initial_tick ticks in
      pure
        [
          Game.{state_hash = Some parent_state; tick = initial_tick};
          Game.{state_hash = Some child_state; tick};
          Game.{state_hash = None; tick = Tick.next tick};
        ]

  (** Generate a *valid* dissection.
      It returns the dissection alongside the dissected start_chunk and
      stop_chunk, but also the number of sections used to generate the
      dissection. *)
  let gen_dissection ~number_of_sections ~our_states dissection =
    let open QCheck2.Gen in
    let disputed_sections = disputed_sections ~our_states dissection in
    assert (Compare.List_length_with.(disputed_sections > 0)) ;
    let+ start_chunk, stop_chunk = pick_disputed_sections disputed_sections in
    let dissection =
      build_dissection ~number_of_sections ~start_chunk ~stop_chunk ~our_states
    in
    (dissection, start_chunk, stop_chunk)

  let gen_initial_dissection_ticks = QCheck2.Gen.(0 -- 1_000)

  let gen_nonfinal_initial_dissection_ticks = QCheck2.Gen.(3 -- 1_000)

  (** Given an initial tick and state_hash: generates random state hashes for
      every others [ticks].
      Having [our_states] provide the state hashes you believe to
      be true. You can then generate a dissection from another one when
      you disagree with some sections. *)
  let gen_our_states start_chunk ticks =
    let open QCheck2.Gen in
    let Game.{tick = initial_tick; state_hash = initial_state_hash} =
      start_chunk
    in
    let initial_state_hash =
      WithExceptions.Option.get ~loc:__LOC__ initial_state_hash
    in
    let initial_tick_int = tick_to_int_exn initial_tick in
    let rec aux acc i =
      if i < 0 then return acc
      else if i = 0 then return ((initial_tick, initial_state_hash) :: acc)
      else
        let* state_hash = gen_random_hash in
        let tick = tick_of_int_exn (i + initial_tick_int) in
        aux ((tick, state_hash) :: acc) (i - 1)
    in
    aux [] ticks

  (** {3 Dissection tests} *)

  let count = 300

  (** Test the validity of dissection generated by {!gen_dissection} on
      an initial dissection generated by {!gen_initial_dissection}.
      It is a self test that'll help detect issues in subsequent tests;
      in case the generator does not produce valid dissections. *)
  let test_valid_gen_dissection =
    let open QCheck2 in
    let gen =
      let open Gen in
      let* number_of_sections = gen_num_sections in
      let* ticks = gen_initial_dissection_ticks in
      let* dissection = gen_initial_dissection ~ticks () in
      let* our_states =
        gen_our_states (initial_of_dissection dissection) (succ ticks)
      in
      if final_dissection ~our_states dissection then
        (* The initial dissection could not be dissected. *)
        return (dissection, None, number_of_sections, our_states)
      else
        let* new_dissection, start_hash, stop_hash =
          gen_dissection ~number_of_sections ~our_states dissection
        in
        return
          ( dissection,
            Some (new_dissection, start_hash, stop_hash),
            number_of_sections,
            our_states )
    in
    let print =
      Print.(
        quad
          print_dissection
          (option
             (triple
                print_dissection
                print_dissection_chunk
                print_dissection_chunk))
          int
          print_our_states)
    in
    qcheck_make_lwt
      ~count
      ~name:"gen_dissection produces a valid dissection"
      ~print
      ~gen
      (fun (dissection, new_dissection, default_number_of_sections, our_states)
      ->
        let open Lwt_syntax in
        match new_dissection with
        | None -> return (final_dissection ~our_states dissection)
        | Some (new_dissection, start_chunk, stop_chunk) ->
            return
            @@ valid_dissection
                 ~default_number_of_sections
                 ~start_chunk
                 ~stop_chunk
                 new_dissection)

  (** Truncate a [dissection] and expect the
      {!Sc_rollup_game_repr.check_dissection} to fail with an invalid
      number of sections, where [expected_number_of_sections] is expected. *)
  let truncate_and_check_error dissection start_chunk stop_chunk
      default_number_of_sections expected_number_of_sections =
    let truncated_dissection =
      match dissection with
      | x :: _ :: z :: rst -> x :: z :: rst
      | _ ->
          (* If the dissection is valid, this case can not be reached. *)
          assert false
    in
    let expected_len = Z.of_int expected_number_of_sections in
    let expected_reason =
      Game.Dissection_number_of_sections_mismatch
        {expected = expected_len; given = Z.pred expected_len}
    in
    assert_fails_with
      ~__LOC__
      (Game.Internal_for_tests.check_dissection
         ~default_number_of_sections
         ~start_chunk
         ~stop_chunk
         truncated_dissection)
      expected_reason

  (** Test that if a dissection is smaller than the default number of
      sections, the length is equal to (distance + 1) of the dissected
      section. *)
  let test_truncated_small_dissection =
    let open QCheck2 in
    qcheck_make_lwt
      ~count
      ~name:
        "distance < nb_of_sections => (len dissection = succ (dist dissection))"
      ~gen:
        (let open Gen in
        let* number_of_sections = gen_num_sections in
        let* ticks = 3 -- (number_of_sections - 1) in
        let* dissection = gen_initial_dissection ~ticks () in
        let* our_states =
          gen_our_states (initial_of_dissection dissection) (succ ticks)
        in
        let* new_dissection, start_hash, stop_hash =
          gen_dissection ~number_of_sections ~our_states dissection
        in
        return (new_dissection, start_hash, stop_hash, number_of_sections, ticks))
      (fun ( dissection,
             start_chunk,
             stop_chunk,
             default_number_of_sections,
             distance ) ->
        let expected_len = succ distance in
        truncate_and_check_error
          dissection
          start_chunk
          stop_chunk
          default_number_of_sections
          expected_len)

  (** Test that if the distance in the dissected section is larger than
      the default number of sections, the dissection length is exactly the
      default number of sections. *)
  let test_truncated_large_dissection =
    let open QCheck2 in
    qcheck_make_lwt
      ~count
      ~name:"distance >= nb_of_sections => (len dissection = nb_of_sections"
      ~gen:
        (let open Gen in
        let* number_of_sections = gen_num_sections in
        let* ticks = number_of_sections -- 1_000 in
        let* dissection = gen_initial_dissection ~ticks () in
        let* our_states =
          gen_our_states (initial_of_dissection dissection) (succ ticks)
        in
        let* new_dissection, start_chunk, stop_chunk =
          gen_dissection ~number_of_sections ~our_states dissection
        in
        return (new_dissection, start_chunk, stop_chunk, number_of_sections))
      (fun (dissection, start_chunk, stop_chunk, default_number_of_sections) ->
        truncate_and_check_error
          dissection
          start_chunk
          stop_chunk
          default_number_of_sections
          default_number_of_sections)

  (** Test that we can not change the start chunk of a section when we produce
      a dissection. *)
  let test_immutable_start_chunk =
    let open QCheck2 in
    qcheck_make_lwt
      ~count
      ~name:"dissection.start_chunk can not change"
      ~gen:
        (let open Gen in
        let* number_of_sections = gen_num_sections in
        let* ticks = gen_nonfinal_initial_dissection_ticks in
        let* dissection = gen_initial_dissection ~ticks () in
        let* our_states =
          gen_our_states (initial_of_dissection dissection) (succ ticks)
        in
        let* new_dissection, start_chunk, stop_chunk =
          gen_dissection ~number_of_sections ~our_states dissection
        in
        let* new_state_hash = gen_random_hash in
        return
          ( new_dissection,
            start_chunk,
            stop_chunk,
            number_of_sections,
            new_state_hash ))
      (fun ( dissection,
             start_chunk,
             stop_chunk,
             default_number_of_sections,
             new_state_hash ) ->
        (* Check that we can not change the start hash. *)
        let dissection_with_different_start =
          modify_start
            (fun chunk -> Game.{chunk with state_hash = Some new_state_hash})
            dissection
        in
        assert_fails_with
          ~__LOC__
          (Game.Internal_for_tests.check_dissection
             ~default_number_of_sections
             ~start_chunk
             ~stop_chunk
             dissection_with_different_start)
          (Game.Dissection_start_hash_mismatch
             {expected = start_chunk.state_hash; given = Some new_state_hash}))

  (** Test that we can not produce a dissection that agrees with the stop hash.
      Otherwise, there would be nothing to dispute. *)
  let test_stop_hash_must_change =
    let open QCheck2 in
    qcheck_make_lwt
      ~count
      ~name:"dissection.stop_chunk must change"
      ~gen:
        (let open Gen in
        let* number_of_sections = gen_num_sections in
        let* ticks = gen_nonfinal_initial_dissection_ticks in
        let* dissection = gen_initial_dissection ~ticks () in
        let* our_states =
          gen_our_states (initial_of_dissection dissection) (succ ticks)
        in
        let* new_dissection, start_chunk, stop_chunk =
          gen_dissection ~number_of_sections ~our_states dissection
        in
        return (new_dissection, start_chunk, stop_chunk, number_of_sections))
      (fun (dissection, start_chunk, stop_chunk, default_number_of_sections) ->
        let open Lwt_syntax in
        let check_failure_on_same_stop_hash stop_hash =
          let invalid_dissection =
            modify_stop
              (fun chunk -> Game.{chunk with state_hash = stop_hash})
              dissection
          in
          let stop_chunk = Game.{stop_chunk with state_hash = stop_hash} in
          assert_fails_with
            ~__LOC__
            (Game.Internal_for_tests.check_dissection
               ~default_number_of_sections
               ~start_chunk
               ~stop_chunk
               invalid_dissection)
            (Game.Dissection_stop_hash_mismatch stop_hash)
        in
        let* b1 = check_failure_on_same_stop_hash None in
        let* b2 = check_failure_on_same_stop_hash stop_chunk.state_hash in
        return (b1 && b2))

  (** Test that we can not produce a dissection modifying the starting
      end last point of a section. *)
  let test_immutable_start_and_stop_ticks =
    let open QCheck2 in
    qcheck_make_lwt
      ~count
      ~name:
        "start_chunk.tick and stop_chunk.tick can not change in the dissection"
      ~gen:
        (let open Gen in
        let* number_of_sections = gen_num_sections in
        let* ticks = gen_nonfinal_initial_dissection_ticks in
        let* dissection = gen_initial_dissection ~ticks () in
        let* our_states =
          gen_our_states (initial_of_dissection dissection) (succ ticks)
        in
        let* new_dissection, start_chunk, stop_chunk =
          gen_dissection ~number_of_sections ~our_states dissection
        in
        return (new_dissection, start_chunk, stop_chunk, number_of_sections))
      (fun (dissection, start_chunk, stop_chunk, default_number_of_sections) ->
        let open Lwt_syntax in
        let expected_error dissection =
          match (List.hd dissection, List.last_opt dissection) with
          | Some Game.{tick = a_tick; _}, Some {tick = b_tick; _} ->
              Game.Dissection_edge_ticks_mismatch
                {
                  dissection_start_tick = a_tick;
                  dissection_stop_tick = b_tick;
                  chunk_start_tick = start_chunk.tick;
                  chunk_stop_tick = stop_chunk.tick;
                }
          | _ -> assert false
        in
        let modify_tick modify_X dissection =
          let invalid_dissection =
            modify_X
              (fun chunk -> Game.{chunk with tick = Tick.next chunk.tick})
              dissection
          in
          let expected_error = expected_error invalid_dissection in
          assert_fails_with
            ~__LOC__
            (Game.Internal_for_tests.check_dissection
               ~default_number_of_sections
               ~start_chunk
               ~stop_chunk
               invalid_dissection)
            expected_error
        in
        (* We modify the start tick and expect the failure. *)
        let* b1 = modify_tick modify_start dissection in
        (* We modify the stop tick and expect the failure. *)
        let* b2 = modify_tick modify_stop dissection in
        return (b1 && b2))

  (** Test that a valid dissection must have a proper distribution of the
      sections. That is, a section should not be geq than half of the
      dissected section's distance. *)
  let test_badly_distributed_dissection =
    let open QCheck2 in
    qcheck_make_lwt
      ~count
      ~name:"dissection must be well distributed"
      ~gen:
        (let open Gen in
        (* The test is not general enough to support all kind of number of
           sections. *)
        let number_of_sections =
          Tezos_protocol_alpha_parameters.Default_parameters.constants_mainnet
            .sc_rollup
            .number_of_sections_in_dissection
        in
        let* picked_section = 0 -- (number_of_sections - 2) in
        let* ticks = 100 -- 1_000 in
        let* dissection = gen_initial_dissection ~ticks () in
        let* our_states =
          gen_our_states (initial_of_dissection dissection) (succ ticks)
        in
        let* new_dissection, start_chunk, stop_chunk =
          gen_dissection ~number_of_sections ~our_states dissection
        in
        return
          ( new_dissection,
            start_chunk,
            stop_chunk,
            number_of_sections,
            picked_section ))
      (fun ( dissection,
             start_chunk,
             stop_chunk,
             default_number_of_sections,
             picked_section ) ->
        (* We put a distance of [1] in every section. Then, we put the
           distance's left in the [picked_section], it will create
           an invalid section. *)
        let distance =
          Z.succ @@ Tick.distance start_chunk.tick stop_chunk.tick
        in
        let max_section_length =
          Z.(succ @@ (distance - of_int default_number_of_sections))
        in
        let section_length = Z.one in

        (* Replace the distance of the first [k] sections by [section_length].
           In practice, when [k = 0], we're at the last section of the
           dissection. *)
        let rec replace_distances tick k = function
          | a :: b :: xs ->
              let b, tick =
                if k = 0 then
                  let tick = Tick.jump tick max_section_length in
                  (Game.{b with tick}, tick)
                else
                  let tick = Tick.jump tick section_length in
                  (Game.{b with tick}, tick)
              in
              a :: replace_distances tick (k - 1) (b :: xs)
          | xs -> xs
        in
        let invalid_dissection =
          replace_distances start_chunk.tick picked_section dissection
        in
        assert_fails_with
          ~__LOC__
          (Game.Internal_for_tests.check_dissection
             ~default_number_of_sections
             ~start_chunk
             ~stop_chunk
             invalid_dissection)
          Game.Dissection_invalid_distribution)

  let tests =
    ( "Dissection",
      qcheck_wrap
        [
          test_valid_gen_dissection;
          test_truncated_small_dissection;
          test_truncated_large_dissection;
          test_immutable_start_chunk;
          test_stop_hash_must_change;
          test_immutable_start_and_stop_ticks;
          test_badly_distributed_dissection;
        ] )
end

(** {2. ArithPVM utils} *)

module ArithPVM = Sc_rollup_helpers.Arith_pvm

module Tree_inbox = struct
  open Inbox
  module Store = Tezos_context_memory.Context

  module Tree = struct
    include Store.Tree

    type tree = Store.tree

    type t = Store.t

    type key = string list

    type value = bytes
  end

  type t = Store.t

  type tree = Tree.tree

  let commit_tree store key tree =
    let open Lwt_syntax in
    let* store = Store.add_tree store key tree in
    let* (_ : Context_hash.t) = Store.commit ~time:Time.Protocol.epoch store in
    return ()

  let lookup_tree store hash =
    let open Lwt_syntax in
    let index = Store.index store in
    let* _, tree =
      Store.produce_tree_proof
        index
        (`Node (Hash.to_context_hash hash))
        (fun x -> Lwt.return (x, x))
    in
    return (Some tree)

  type proof = Store.Proof.tree Store.Proof.t

  let verify_proof proof f =
    Lwt.map Result.to_option (Store.verify_tree_proof proof f)

  let produce_proof store tree f =
    let open Lwt_syntax in
    let index = Store.index store in
    let* proof = Store.produce_tree_proof index (`Node (Tree.hash tree)) f in
    return (Some proof)

  let kinded_hash_to_inbox_hash = function
    | `Value hash | `Node hash -> Hash.of_context_hash hash

  let proof_before proof = kinded_hash_to_inbox_hash proof.Store.Proof.before

  let proof_encoding =
    Tezos_context_merkle_proof_encoding.Merkle_proof_encoding.V1.Tree32
    .tree_proof_encoding
end

module Store_inbox = struct
  include Inbox.Make_hashing_scheme (Tree_inbox)
end

module Arith_test_pvm = struct
  include ArithPVM

  let init_context () = Tezos_context_memory.make_empty_context ()

  let initial_state ctxt =
    let open Lwt_syntax in
    let* state = initial_state ctxt in
    let* state = install_boot_sector state "" in
    return state

  let initial_hash =
    let open Lwt_syntax in
    let* state = initial_state (init_context ()) in
    state_hash state

  let mk_input level message_counter msg =
    let payload = make_external_inbox_message msg in
    let level = Int32.of_int level in
    Sc_rollup.Inbox_message
      {payload; message_counter; inbox_level = Raw_level.of_int32_exn level}

  let consume_fuel = Option.map pred

  let continue_with_fuel ~our_states ~(tick : int) fuel state f =
    let open Lwt_syntax in
    match fuel with
    | Some 0 -> return (state, fuel, tick, our_states)
    | _ -> f tick our_states (consume_fuel fuel) state

  (* TODO: https://gitlab.com/tezos/tezos/-/issues/3498

     the following is almost the same code as in the rollup node, expect that it
     creates the association list (tick, state_hash). *)
  let eval_until_input ~fuel ~our_states start_tick state dal_pages =
    let open Lwt_syntax in
    let rec go ~our_states fuel (tick : int) state =
      let* input_request = is_input_state state in
      match fuel with
      | Some 0 -> return (state, fuel, tick, our_states)
      | None | Some _ -> (
          match input_request with
          | No_input_required ->
              let* state = eval state in
              let* state_hash = state_hash state in
              let our_states = (tick, state_hash) :: our_states in
              go ~our_states (consume_fuel fuel) (tick + 1) state
          | Needs_reveal (Request_dal_page pid) ->
              let content_opt = Dal_pages.find_page pid dal_pages in
              let input = Sc_rollup.(Reveal (Dal_page content_opt)) in
              let* state = set_input input state in
              let* state_hash = state_hash state in
              let our_states = (tick, state_hash) :: our_states in
              go ~our_states (consume_fuel fuel) (tick + 1) state
          | Initial | First_after (_, _) | Needs_reveal _ ->
              return (state, fuel, tick, our_states))
    in
    go ~our_states fuel start_tick state

  let eval_metadata ~fuel ~our_states tick state ~metadata =
    let open Lwt_syntax in
    continue_with_fuel ~our_states ~tick fuel state
    @@ fun tick our_states fuel state ->
    let input = Sc_rollup.(Reveal (Metadata metadata)) in
    let* state = set_input input state in
    let* state_hash = state_hash state in
    let our_states = (tick, state_hash) :: our_states in
    let tick = succ tick in
    return (state, fuel, tick, our_states)

  let feed_input ~fuel ~our_states ~tick state input dal_pages =
    let open Lwt_syntax in
    let* state, fuel, tick, our_states =
      eval_until_input ~fuel ~our_states tick state dal_pages
    in
    continue_with_fuel ~our_states ~tick fuel state
    @@ fun tick our_states fuel state ->
    let* state = set_input input state in
    let* state_hash = state_hash state in
    let our_states = (tick, state_hash) :: our_states in
    let tick = tick + 1 in
    let* state, fuel, tick, our_states =
      eval_until_input ~fuel ~our_states tick state dal_pages
    in
    return (state, fuel, tick, our_states)

  let eval_inbox ?fuel ~level ~inputs ~tick state dal_pages =
    let open Lwt_result_syntax in
    List.fold_left_i_es
      (fun message_counter (state, fuel, tick, our_states) input ->
        let input = mk_input level (Z.of_int message_counter) input in
        let*! state, fuel, tick, our_states =
          feed_input ~fuel ~our_states ~tick state input dal_pages
        in
        return (state, fuel, tick, our_states))
      (state, fuel, tick, [])
      inputs

  let eval_levels_and_inputs ~metadata ?fuel ctxt levels_and_inputs dal_pages =
    let open Lwt_result_syntax in
    let*! state = initial_state ctxt in
    let*! state_hash = state_hash state in
    let tick = 0 in
    let our_states = [(tick, state_hash)] in
    let tick = succ tick in
    (* 1. We evaluate the boot sector. *)
    let*! state, fuel, tick, our_states =
      eval_until_input ~fuel ~our_states tick state dal_pages
    in
    (* 2. We evaluate the metadata. *)
    let*! state, fuel, tick, our_states =
      eval_metadata ~fuel ~our_states tick state ~metadata
    in
    (* 3. We evaluate the inbox. *)
    let* state, _fuel, tick, our_states =
      List.fold_left_es
        (fun (state, fuel, tick, our_states) (level, inputs) ->
          let* state, fuel, tick, our_states' =
            eval_inbox ?fuel ~level ~inputs ~tick state dal_pages
          in
          return (state, fuel, tick, our_states @ our_states'))
        (state, fuel, tick, our_states)
        levels_and_inputs
    in
    let our_states =
      List.sort (fun (x, _) (y, _) -> Compare.Int.compare x y) our_states
    in
    let our_states =
      List.map
        (fun (tick_int, state) -> (tick_of_int_exn tick_int, state))
        our_states
    in
    let tick = tick_of_int_exn tick in
    return (state, tick, our_states)
end

(** Kind of strategy a player can play

    The cheaters will have their own version of inputs. This way, they
    can produce valid proofs regarding their inboxes, but discarded by
    the protocol.
*)
type strategy =
  | Random  (** A random player will execute its own random vision of inputs. *)
  | Perfect
      (** A perfect player, never lies, always win.
          GSW 73-9 2014-2015 mindset. *)
  | Lazy  (** A lazy player will not execute all messages. *)
  | Eager  (** A eager player will not cheat until a certain point. *)
  | Keen  (** A keen player will execute more messages. *)

let pp_strategy fmt = function
  | Random -> Format.pp_print_string fmt "Random"
  | Perfect -> Format.pp_print_string fmt "Perfect"
  | Lazy -> Format.pp_print_string fmt "Lazy"
  | Eager -> Format.pp_print_string fmt "Eager"
  | Keen -> Format.pp_print_string fmt "Keen"

(** The main data source can be custumised during tests *)
type data_source =
  | Inbox  (** Rollup data are passed through the inbox. *)
  | Dal  (** Rollup data are passed through the Dal. *)

let data_source_to_string = function Inbox -> "Inbox" | Dal -> "Dal"

(** Construct the inbox for the protocol side. *)
let construct_inbox_proto ~data_source block rollup levels_and_inputs dal_pages
    contract =
  let open Lwt_result_syntax in
  match data_source with
  | Inbox ->
      List.fold_left_es
        (fun block (level, payloads) ->
          let*? current_level = Context.get_level (B block) in
          let diff_with_level =
            Raw_level.(diff (of_int32_exn (Int32.of_int level)) current_level)
            |> Int32.to_int
          in
          let* block = Block.bake_n (diff_with_level - 1) block in
          let* operation_add_message =
            Op.sc_rollup_add_messages (B block) contract rollup payloads
          in
          Block.bake ~operation:operation_add_message block)
        block
        levels_and_inputs
  | Dal ->
      List.fold_left_es
        (fun block (slot_id, (_pages_content, slot_header)) ->
          let*? current_level = Context.get_level (B block) in
          let level = slot_id.Dal.published_level in
          let diff_with_level =
            Raw_level.(diff level current_level) |> Int32.to_int
          in
          assert (diff_with_level >= 0) ;
          let* block = Block.bake_n diff_with_level (*- 1*) block in
          let* operation_dal_publish =
            Op.dal_publish_slot_header
              (B block)
              contract
              slot_header
              ~fee:(Tez.of_mutez_exn 1000000L)
              ~gas_limit:Op.High
              ~storage_limit:(Z.of_int 1000)
          in
          let next_level = 1 + (Int32.to_int @@ Raw_level.to_int32 level) in
          let* operation =
            match
              List.find (fun (l, _) -> l = next_level) levels_and_inputs
            with
            | None -> return operation_dal_publish
            | Some (_, payloads) ->
                let* operation_add_message =
                  Op.sc_rollup_add_messages (B block) contract rollup payloads
                in
                Op.batch_operations
                  ~recompute_counters:true
                  ~source:contract
                  (B block)
                  [operation_dal_publish; operation_add_message]
          in
          Block.bake ~operation block)
        block
        (Dal_pages.bindings dal_pages)

module DAL = struct
  (* TMP *)
  let number_of_slots = 8

  let number_of_pages = 8

  (* This function will become useless with EOL. *)
  let mk_dal_directives ~level_min ~level_max =
    (* Using lower values for the number of pages and slots. These directives
       will be removed once EOL is used to request pages. *)
    let gacc = ref [] in
    let acc = ref [] in
    for lvl = level_max downto level_min do
      for slots = number_of_slots - 1 downto 0 do
        for pages = number_of_pages - 1 downto 0 do
          acc := Format.sprintf "dal:%d:%d:%d" lvl slots pages :: !acc
        done
      done ;
      gacc := (lvl + 2, !acc) :: !gacc ;
      acc := []
    done ;
    !gacc

  let add_padding size content =
    let content_size = Bytes.length content in
    if content_size <= size then
      let padding = Bytes.make (size - content_size) ' ' in
      Bytes.concat (Bytes.of_string "") [content; padding]
    else Bytes.sub content 0 size

  let _mk_page_id ~slot_index ~page_index lvl =
    let published_level =
      try Raw_level.of_int32_exn (Int32.of_int lvl) with _ -> assert false
    in
    let slot_index =
      Dal.Slot_index.of_int slot_index
      |> Option.value_f ~default:(fun () -> assert false)
    in
    let slot_id = Dal.Slot.Header.{published_level; index = slot_index} in
    Dal.Page.{slot_id; page_index}

  let mk_slot_id ~slot_index lvl =
    let published_level =
      try Raw_level.of_int32_exn (Int32.of_int lvl) with _ -> assert false
    in
    let slot_index =
      Dal.Slot_index.of_int slot_index
      |> Option.value_f ~default:(fun () -> assert false)
    in
    Dal.Slot.Header.{published_level; index = slot_index}

  let mk_slot_header slot_id page_data =
    let slot_data = add_padding cryptobox_parameters.slot_size page_data in
    let polynomial =
      Cryptobox.polynomial_from_slot cryptobox slot_data
      |> WithExceptions.Result.get_ok ~loc:__LOC__
    in
    let commitment = Cryptobox.commit cryptobox polynomial in
    Dal.Slot.(Header.{id = slot_id; commitment})

  let mk_fresh_data slot_id =
    let open QCheck2.Gen in
    let* j = small_int in
    let page_data = Bytes.of_string @@ string_of_int j in
    let page_data = add_padding cryptobox_parameters.page_size page_data in
    let slot_header = mk_slot_header slot_id page_data in
    return (page_data, slot_header)

  let accumulate_slot_page slot_id page_index page_content acc =
    let old_pages = M.find slot_id acc |> Option.value ~default:P.empty in
    let page_content =
      add_padding cryptobox_parameters.page_size (Bytes.of_string page_content)
    in
    M.add slot_id (P.add page_index page_content old_pages) acc

  let white_page =
    add_padding cryptobox_parameters.page_size (Bytes.of_string " ")

  (*
  let number_of_pages =
    cryptobox_parameters.slot_size / cryptobox_parameters.page_size
*)
  let gen_dal_inputs_for_levels ?level_min ?level_max dal_pages dal_headers =
    let open QCheck2.Gen in
    let* levels_and_inputs =
      gen_arith_pvm_inputs_for_levels ?level_min ?level_max ()
    in
    let rec add_input lvl accu inputs =
      match inputs with
      | [] -> return accu
      | input :: inputs ->
          let* slot_index = 0 -- (number_of_slots - 1) in
          let* page_index = 0 -- (number_of_pages - 1) in
          let slot_id = mk_slot_id ~slot_index lvl in
          let slots_of_level =
            accumulate_slot_page slot_id page_index input accu
          in
          add_input lvl slots_of_level inputs
    in
    let rec add_inputs dal_pages dal_headers levels_and_inputs =
      match levels_and_inputs with
      | [] -> return dal_pages
      | (lvl, inputs) :: levels_and_inputs ->
          let* slots_of_level = add_input lvl M.empty inputs in
          let dal_pages, dal_headers =
            M.fold
              (fun slot_id pages (dal_pages, dal_headers) ->
                let arr = Array.make number_of_pages white_page in
                P.iter (fun i content -> Array.set arr i content) pages ;
                let pages_list = Array.to_list arr in
                let slot_data = Bytes.concat (Bytes.of_string "") pages_list in
                let slot_header = mk_slot_header slot_id slot_data in
                ( M.add slot_id arr dal_pages,
                  M.add slot_id (slot_header, slot_data) dal_headers ))
              slots_of_level
              (dal_pages, dal_headers)
          in
          add_inputs dal_pages dal_headers levels_and_inputs
    in
    add_inputs dal_pages dal_headers levels_and_inputs

  (*

            let pid =
            let slot_id = pid.Dal.Page.slot_id in
            let page_data = Bytes.of_string input in
            let page_data =
              add_padding cryptobox_parameters.page_size page_data
            in
            (* XXX: TODO *)
            let _slot_header = mk_slot_header slot_id page_data in
            if M.mem slot_id dal_pages then
              (* Do not rewrite existing pages *)
              return dal_pages
            else
              Dal_pages.add slot_id (Array.of_list [page_data]) dal_pages
              |> return

*)
  let alter_dal_pages ~strategy ?level_min ?level_max dal_pages =
    let open QCheck2.Gen in
    let rec fold l acc alter_elt =
      match l with
      | [] -> return acc
      | (k, v) :: l ->
          let* acc = alter_elt k v acc in
          fold l acc alter_elt
    in
    let aux dal_pages alter_elt =
      fold (Dal_pages.bindings dal_pages) Dal_pages.empty alter_elt
    in
    match strategy with
    | Perfect ->
        (* The perfect player does not lie, evaluates correctly the inputs. *)
        return dal_pages
    | Random ->
        (* Random player generates its own list of inputs. *)
        gen_dal_inputs_for_levels ?level_min ?level_max Dal_pages.empty
    | Lazy ->
        (* Lazy player removes inputs from [levels_and_inputs]. *)
        aux dal_pages (fun sid data acc ->
            let* i = 0 -- 4 in
            return @@ if i = 0 then acc else Dal_pages.add sid data acc)
    | Eager ->
        (* Eager player executes correctly the inbox until a certain point. *)
        let* eager_counter = 0 -- Dal_pages.cardinal dal_pages in
        let eager_counter = ref eager_counter in
        aux dal_pages (fun _sid _data _acc ->
            (*
               let* _data =
                 if !eager_counter = 0 then mk_fresh_data sid else return data
               in
            *)
            decr eager_counter ;
            assert false
            (*
                 return (Dal_pages.add sid data acc)*))
    | Keen ->
        (* Keen player will add more messages. *)
        gen_dal_inputs_for_levels ?level_min ?level_max dal_pages

  let page_membership_proof page_index slot_data =
    let open Lwt_result_syntax in
    let proof =
      let open Result_syntax in
      let* polynomial = Cryptobox.polynomial_from_slot cryptobox slot_data in
      Cryptobox.prove_page cryptobox polynomial page_index
    in
    match proof with
    | Ok proof -> return proof
    | Error e ->
        failwith
          "%s"
          (match e with
          | `Fail s -> "Fail " ^ s
          | `Segment_index_out_of_range -> "Segment_index_out_of_range"
          | `Slot_wrong_size s -> "Slot_wrong_size: " ^ s)

  let mk_skip_list dal_pages =
    let open Dal.Slots_history in
    List.map
      (fun (_pid, (_page_content, slot_header)) -> slot_header)
      (Dal_pages.bindings dal_pages)
    |> add_confirmed_slot_headers
         genesis
         (History_cache.empty ~capacity:10_000L)
    |> Environment.wrap_tzresult
end

type player = {
  pkh : Signature.Public_key_hash.t;
  contract : Contract.t;
  strategy : strategy;
  game_player : Game.player;
}

let pp_player ppf {pkh; contract = _; strategy; game_player} =
  Format.fprintf
    ppf
    "pkh: %a@,strategy: %a@,game_player: %s"
    Signature.Public_key_hash.pp_short
    pkh
    pp_strategy
    strategy
    (if Game.player_equal game_player Alice then "Alice" else "Bob")

type player_client = {
  player : player;
  states : (Tick.t * State_hash.t) list;
  final_tick : Tick.t;
  inbox :
    Store_inbox.inbox_context
    * Store_inbox.tree option
    * Inbox.History.t
    * Inbox.t;
  levels_and_inputs : (int * string list) list;
  dal_pages : Dal_pages.t;
  metadata : Metadata.t;
}

let pp_levels_and_inputs ppf levels_and_inputs =
  Format.(
    (pp_print_list
       (fun ppf (level, inputs) ->
         fprintf
           ppf
           "level %d, inputs %a"
           level
           (pp_print_list pp_print_string)
           inputs)
       ppf)
      levels_and_inputs)

let pp_player_client ppf
    {
      player;
      states;
      final_tick;
      inbox = _;
      levels_and_inputs;
      metadata;
      dal_pages = _;
    } =
  Format.fprintf
    ppf
    "@[<v 2>player:@,\
     %a@]@,\
     @[<v 2>states:@,\
     %a@]@,\
     final tick: %a@,\
     @[<v 2>levels and inputs:@,\
     %a@]@,\
     metadata: %a@,"
    pp_player
    player
    (Format.pp_print_list (fun ppf (tick, hash) ->
         Format.fprintf
           ppf
           "tick %a, state hash %a"
           Tick.pp
           tick
           State_hash.pp
           hash))
    states
    Tick.pp
    final_tick
    (* inbox *)
    pp_levels_and_inputs
    levels_and_inputs
    Sc_rollup.Metadata.pp
    metadata

(** This function alters inbox message depending on the chosen [strategy]. *)
let alter_inbox_messages strategy ?level_min ?level_max levels_and_inputs =
  let open QCheck2.Gen in
  match strategy with
  | Perfect ->
      (* The perfect player does not lie, evaluates correctly the inputs. *)
      return levels_and_inputs
  | Random ->
      (* Random player generates its own list of inputs. *)
      gen_arith_pvm_inputs_for_levels ?level_min ?level_max ()
  | Lazy ->
      (* Lazy player removes inputs from [levels_and_inputs]. *)
      let n = List.length levels_and_inputs in
      let* remove_k = 1 -- n in
      List.take_n (n - remove_k) levels_and_inputs |> return
  | Eager ->
      (* Eager player executes correctly the inbox until a certain point. *)
      let nb_of_input =
        List.fold_left
          (fun acc (_level, inputs) -> acc + List.length inputs)
          0
          levels_and_inputs
      in
      let* corrupt_at_k = 0 -- (nb_of_input - 1) in
      let new_input = "42 7 +" in
      (* Once an input is corrupted, everything after will be corrupted
         as well. *)
      let idx = ref (-1) in
      List.map
        (fun (level, inputs) ->
          ( level,
            List.map
              (fun input ->
                incr idx ;
                if !idx = corrupt_at_k then new_input else input)
              inputs ))
        levels_and_inputs
      |> return
  | Keen ->
      (* Keen player will add more messages. *)
      let* new_levels_and_inputs =
        gen_arith_pvm_inputs_for_levels ?level_min ?level_max ()
      in
      let new_levels_and_inputs = new_levels_and_inputs @ levels_and_inputs in
      List.sort_uniq
        (fun (l, _) (l', _) -> Compare.Int.compare l l')
        new_levels_and_inputs
      |> return

module Player_client = struct
  (** Transform inputs to payloads. *)
  let levels_and_payloads levels_and_inputs =
    List.map
      (fun (level, inputs) ->
        (level, List.map make_external_inbox_message inputs))
      levels_and_inputs

  let empty_memory_ctxt id =
    let open Lwt_syntax in
    Lwt_main.run
    @@ let+ index = Tezos_context_memory.Context.init id in
       Tezos_context_memory.Context.empty index

  (* TODO: https://gitlab.com/tezos/tezos/-/issues/3529

     Factor code for the unit test.
     this and {!Store_inbox} is highly copy-pasted from
     test/unit/test_sc_rollup_inbox. The main difference is: we use
     [Alpha_context.Sc_rollup.Inbox] instead of [Sc_rollup_repr_inbox] in the
     former. *)
  let construct_inbox ctxt levels_and_payloads ~rollup ~origination_level =
    let open Lwt_syntax in
    let open Store_inbox in
    let* inbox = empty ctxt rollup origination_level in
    let history = Inbox.History.empty ~capacity:10000L in
    let rec aux history inbox level_tree = function
      | [] -> return (ctxt, level_tree, history, inbox)
      | (level, payloads) :: rst ->
          let level = Int32.of_int level |> Raw_level.of_int32_exn in
          let () = assert (Raw_level.(origination_level <= level)) in
          let* res =
            lift @@ add_messages ctxt history inbox level payloads level_tree
          in
          let level_tree, history, inbox =
            WithExceptions.Result.get_ok ~loc:__LOC__ res
          in
          aux history inbox (Some level_tree) rst
    in
    aux history inbox None levels_and_payloads

  (** Construct an inbox based on [levels_and_inputs] in the player context. *)
  let construct_inbox ~origination_level ctxt rollup levels_and_inputs =
    Lwt_main.run
    @@ construct_inbox
         ~origination_level
         ctxt
         ~rollup
         (levels_and_payloads levels_and_inputs)

  (** Generate [our_states] for [levels_and_inputs] based on the strategy.
      It needs [level_min] and [level_max] in case it will need to generate
      new inputs. *)
  let gen_our_states ~data_source ~metadata ctxt strategy ~level_min ~level_max
      levels_and_inputs dal_pages =
    let open QCheck2.Gen in
    let eval_inputs levels_and_inputs dal_pages =
      Lwt_main.run
      @@
      let open Lwt_result_syntax in
      let*! r =
        Arith_test_pvm.eval_levels_and_inputs
          ~metadata
          ctxt
          levels_and_inputs
          dal_pages
      in
      Lwt.return @@ WithExceptions.Result.get_ok ~loc:__LOC__ r
    in
    let* levels_and_inputs, dal_pages =
      match data_source with
      | Inbox ->
          let* levels_and_inputs =
            alter_inbox_messages
              strategy
              ~level_min
              ~level_max
              levels_and_inputs
          in
          return (levels_and_inputs, dal_pages)
      | Dal ->
          let* dal_pages =
            DAL.alter_dal_pages ~strategy ~level_min ~level_max dal_pages
          in
          return (levels_and_inputs, dal_pages)
    in
    let _state, tick, our_states = eval_inputs levels_and_inputs dal_pages in
    return (tick, our_states, levels_and_inputs, dal_pages)

  (** [gen ~rollup ~level_min ~level_max player levels_and_inputs] generates
      a {!player_client} based on {!player.strategy}. *)
  let gen ~data_source ~rollup ~origination_level ~level_min ~level_max
      levels_and_inputs dal_pages player =
    let open QCheck2.Gen in
    let ctxt = empty_memory_ctxt "foo" in
    let metadata = Sc_rollup.Metadata.{address = rollup; origination_level} in
    let* tick, our_states, levels_and_inputs, dal_pages =
      gen_our_states
        ~data_source
        ~metadata
        ctxt
        player.strategy
        ~level_min
        ~level_max
        levels_and_inputs
        dal_pages
    in
    let inbox =
      construct_inbox ~origination_level ctxt rollup levels_and_inputs
    in
    return
      {
        player;
        final_tick = tick;
        states = our_states;
        inbox;
        levels_and_inputs;
        metadata;
        dal_pages;
      }
end

(** [create_commitment ~predecessor ~inbox_level ~our_states] creates
    a commitment using [our_states] as the vision of ticks. *)
let create_commitment ~predecessor ~inbox_level ~our_states =
  let open Lwt_syntax in
  let inbox_level = Int32.of_int inbox_level |> Raw_level.of_int32_exn in
  let+ compressed_state =
    match List.last_opt our_states with
    | None ->
        (* No tick evaluated. *)
        Arith_test_pvm.initial_hash
    | Some (_, state) -> return state
  in

  let number_of_ticks =
    match our_states with
    | [] -> Number_of_ticks.zero
    | _ ->
        List.length our_states - 1
        |> Int64.of_int |> number_of_ticks_of_int64_exn
  in
  Commitment.{compressed_state; inbox_level; predecessor; number_of_ticks}

(** [operation_publish_commitment block rollup lcc inbox_level p1_client]
    creates a commitment and stake on it. *)
let operation_publish_commitment ctxt rollup predecessor inbox_level
    player_client =
  let open Lwt_result_syntax in
  let*! commitment =
    create_commitment ~predecessor ~inbox_level ~our_states:player_client.states
  in
  Op.sc_rollup_publish ctxt player_client.player.contract rollup commitment

(** [build_proof ~player_client start_tick game] builds a valid proof
    regarding the vision [player_client] has. The proof refutes the
    [start_tick]. *)
let build_proof ~player_client start_tick (game : Game.t) =
  let open Lwt_result_syntax in
  (* No messages are added between [game.start_level] and the current level
     so we can take the existing inbox of players. Otherwise, we should find the
     inbox of [start_level]. *)
  let inbox_context, messages_tree, history, inbox = player_client.inbox in
  let* history, history_proof =
    Lwt.map Environment.wrap_tzresult
    @@ Store_inbox.form_history_proof inbox_context history inbox messages_tree
  in
  (* We start a game on a commitment that starts at [Tick.initial], the fuel
     is necessarily [start_tick]. *)
  let fuel = tick_to_int_exn start_tick in
  let metadata = player_client.metadata in
  let*! r =
    Arith_test_pvm.eval_levels_and_inputs
      ~metadata
      ~fuel
      (Arith_test_pvm.init_context ())
      player_client.levels_and_inputs
      player_client.dal_pages
    |> lift
  in
  let* state, _, _ = Assert.get_ok ~__LOC__ r in
  let page_info_from_pvm_state () =
    let*! input_request = Arith_test_pvm.is_input_state state in
    (* We should cut at some level ?? *)
    match input_request with
    | Sc_rollup.(Needs_reveal (Request_dal_page page_id)) -> (
        match Dal_pages.find page_id player_client.dal_pages with
        | Some (content, _headers) ->
            let page_index = 0 in
            let* page_proof =
              DAL.page_membership_proof page_index
              @@ DAL.add_padding cryptobox_parameters.slot_size content
            in
            return_some (content, page_proof)
        | None -> return_none)
    | _ -> return_none
  in
  let* page_info = page_info_from_pvm_state () in

  let*? confirmed_slots_history, history_cache =
    DAL.mk_skip_list player_client.dal_pages
  in

  let module P = struct
    include Arith_test_pvm

    let context = inbox_context

    let state = state

    let reveal _ = assert false

    module Inbox_with_history = struct
      include Store_inbox

      let history = history

      let inbox = history_proof
    end

    module Dal_with_history = struct
      let confirmed_slots_history = confirmed_slots_history

      let history_cache = history_cache

      let page_info = page_info

      let dal_endorsement_lag = dal_parameters.endorsement_lag

      let dal_parameters = cryptobox_parameters
    end
  end in
  let*! proof =
    Sc_rollup.Proof.produce ~metadata (module P) game.inbox_level |> lift
  in
  Assert.get_ok ~__LOC__ proof

(** [next_move ~number_of_sections ~player_client game] produces
    the next move in the refutation game.

    If there is a disputed section where the distance is one tick, it
    produces a proof. Otherwise, provides another dissection.
*)
let next_move ~player_client (game : Game.t) =
  let open Lwt_result_syntax in
  match game.game_state with
  | Dissecting {dissection; default_number_of_sections} -> (
      let disputed_sections =
        disputed_sections ~our_states:player_client.states dissection
      in
      assert (Compare.List_length_with.(disputed_sections > 0)) ;
      let single_tick_disputed_sections =
        single_tick_disputed_sections disputed_sections
      in
      match single_tick_disputed_sections with
      | (start_chunk, _stop_chunk) :: _ ->
          let tick = start_chunk.tick in
          let+ proof = build_proof ~player_client tick game in
          Game.{choice = tick; step = Proof proof}
      | [] ->
          (* If we reach this case, there is necessarily a disputed section. *)
          let start_chunk, stop_chunk = Stdlib.List.hd disputed_sections in
          let dissection =
            build_dissection
              ~number_of_sections:default_number_of_sections
              ~start_chunk
              ~stop_chunk
              ~our_states:player_client.states
          in
          return Game.{choice = start_chunk.tick; step = Dissection dissection})
  | Final_move {agreed_start_chunk; refuted_stop_chunk = _} ->
      let tick = agreed_start_chunk.tick in
      let+ proof = build_proof ~player_client tick game in
      Game.{choice = tick; step = Proof proof}

type game_result_for_tests = Defender_wins | Refuter_wins

(** Play until there is an {!game_result_for_tests}.

    A game result can happen if:
    - A valid refutation was provided to the protocol and it succeeded to
      win the game.
    - A player played an invalid refutation and was rejected by the
      protocol.
*)
let play_until_game_result ~refuter_client ~defender_client ~rollup block =
  let rec play ~player_turn ~opponent block =
    let open Lwt_result_syntax in
    let* game_opt =
      Context.Sc_rollup.ongoing_game_for_staker
        (B block)
        rollup
        player_turn.player.pkh
    in
    let game, _, _ = WithExceptions.Option.get ~loc:__LOC__ game_opt in
    let* refutation = next_move ~player_client:player_turn game in
    let* incr = Incremental.begin_construction block in
    let* operation_refutation =
      Op.sc_rollup_refute
        (I incr)
        player_turn.player.contract
        rollup
        opponent.player.pkh
        (Some refutation)
    in
    let* incr = Incremental.add_operation incr operation_refutation in
    match game_status_of_refute_op_result (Incremental.rev_tickets incr) with
    | Ongoing ->
        let* block = Incremental.finalize_block incr in
        play ~player_turn:opponent ~opponent:player_turn block
    | Ended (Loser {reason = _; loser}) as game_result ->
        let () =
          Format.printf "@,ending result: %a@," Game.pp_status game_result
        in
        if loser = Account.pkh_of_contract_exn refuter_client.player.contract
        then return Defender_wins
        else return Refuter_wins
    | Ended Draw ->
        QCheck2.Test.fail_reportf "Game ended in a draw, which is unexpected"
  in
  play ~player_turn:refuter_client ~opponent:defender_client block

(** Generate two {!player}s with a given strategy. *)
let make_players ~p1_strategy ~contract1 ~p2_strategy ~contract2 =
  let pkh1 = Account.pkh_of_contract_exn contract1 in
  let pkh2 = Account.pkh_of_contract_exn contract2 in
  let ({alice; bob = _} : Game.Index.t) = Game.Index.make pkh1 pkh2 in
  let player1, player2 =
    if Signature.Public_key_hash.equal alice pkh1 then Game.(Alice, Bob)
    else Game.(Bob, Alice)
  in
  ( {
      pkh = pkh1;
      contract = contract1;
      strategy = p1_strategy;
      game_player = player1;
    },
    {
      pkh = pkh2;
      contract = contract2;
      strategy = p2_strategy;
      game_player = player2;
    } )

(** [gen_game ~p1_strategy ~p2_strategy] generates a context where a rollup
    was originated.
    It generates inputs for the rollup, and creates the players' interpretation
    of these inputs in a {!player_client} for [p1_strategy] and [p2_strategy].
*)
let gen_game ~data_source ?nonempty_inputs ~p1_strategy ~p2_strategy () =
  let open QCheck2.Gen in
  (* If there is no good player, we do not care about the result. *)
  assert (p1_strategy = Perfect || p2_strategy = Perfect) ;
  let* first_inputs =
    let* input = gen_arith_pvm_inputs ~gen_size:(pure 0) in
    let* inputs = small_list (gen_arith_pvm_inputs ~gen_size:(pure 0)) in
    return (input :: inputs)
  in
  let block, rollup, genesis_info, (contract1, contract2, contract3) =
    create_ctxt ~first_inputs
  in
  let p1, p2 = make_players ~p1_strategy ~contract1 ~p2_strategy ~contract2 in

  (* Create a context with a rollup originated. *)
  let commitment_period =
    network_constants.sc_rollup.commitment_period_in_blocks
  in
  let origination_level =
    Raw_level.to_int32 genesis_info.level |> Int32.to_int
  in
  let level_min = origination_level + 1 in
  let level_max = origination_level + commitment_period - 1 in
  let* levels_and_inputs, dal_pages =
    match data_source with
    | Inbox ->
        let* levels_and_inputs =
          gen_arith_pvm_inputs_for_levels
            ?nonempty_inputs
            ~level_min
            ~level_max
            ()
        in
        return (levels_and_inputs, Dal_pages.empty)
    | Dal ->
        let* dal_pages =
          DAL.gen_dal_inputs_for_levels ~level_min ~level_max Dal_pages.empty
        in
        (* Will be removed with EOL. *)
        let levels_and_inputs = DAL.mk_dal_directives ~level_min ~level_max in
        return (levels_and_inputs, dal_pages)
  in

  let player_gen =
    Player_client.gen
      ~data_source
      ~origination_level:genesis_info.level
      ~level_min
      ~level_max
      ~rollup
      ((origination_level, first_inputs) :: levels_and_inputs)
      dal_pages
  in
  let* p1_client = player_gen p1 in
  let* p2_client = player_gen p2 in
  let* p1_start = bool in
  let commitment_level = origination_level + commitment_period in
  let* additional_payloads = small_list (string_size (1 -- 15)) in
  return
    ( block,
      rollup,
      commitment_level,
      genesis_info.commitment_hash,
      p1_client,
      p2_client,
      contract3,
      p1_start,
      levels_and_inputs,
      dal_pages,
      additional_payloads )

(** [prepare_game block lcc originated_level p1_client p2_client
    inputs_and_levels] prepares a context where [p1_client] and [p2_client]
    are in conflict for one commitment.
    It creates the protocol inbox using [inputs_and_levels]. *)
let prepare_game ~data_source block rollup lcc commitment_level p1_client
    p2_client contract levels_and_inputs dal_pages =
  let open Lwt_result_syntax in
  let* block =
    construct_inbox_proto
      ~data_source
      block
      rollup
      levels_and_inputs
      dal_pages
      contract
  in
  let* operation_publish_commitment_p1 =
    operation_publish_commitment (B block) rollup lcc commitment_level p1_client
  in
  let* operation_publish_commitment_p2 =
    operation_publish_commitment (B block) rollup lcc commitment_level p2_client
  in
  Block.bake
    ~operations:
      [operation_publish_commitment_p1; operation_publish_commitment_p2]
    block

(** Create a test of [p1_strategy] against [p2_strategy]. One of them
    must be a {!Perfect} player, otherwise, we do not care about which
    cheater wins. *)
let test_game ~data_source ?nonempty_inputs ~p1_strategy ~p2_strategy () =
  let name =
    Format.asprintf
      "%a against %a"
      pp_strategy
      p1_strategy
      pp_strategy
      p2_strategy
  in
  qcheck_make_lwt_res
    ~print:
      (fun ( block,
             rollup,
             commitment_level,
             lcc,
             p1_client,
             p2_client,
             _contract3,
             p1_start,
             levels_and_inputs,
             _dal_pages,
             _additional_payloads ) ->
      let level =
        WithExceptions.Result.get_ok ~loc:__LOC__ @@ Context.get_level (B block)
      in
      Format.asprintf
        "@[<v>@,\
         current level: %a@,\
         rollup: %a@,\
         commitment_level: %d@,\
         last cemented commitment: %a@,\
         @[<v 2>p1:@,\
         %a@]@,\
         @[<v 2>p2:@,\
         %a@]@,\
         who start: %s@,\
         @[<v 2>levels and inputs:@,\
         %a@]@,\
         @]"
        Raw_level.pp
        level
        Sc_rollup.Address.pp_short
        rollup
        commitment_level
        Sc_rollup.Commitment.Hash.pp_short
        lcc
        pp_player_client
        p1_client
        pp_player_client
        p2_client
        (if p1_start then "p1" else "p2")
        pp_levels_and_inputs
        levels_and_inputs)
    ~count:1
    ~name
    ~gen:(gen_game ~data_source ?nonempty_inputs ~p1_strategy ~p2_strategy ())
    (fun ( block,
           rollup,
           commitment_level,
           lcc,
           p1_client,
           p2_client,
           contract3,
           p1_start,
           levels_and_inputs,
           dal_pages,
           additional_payloads ) ->
      let open Lwt_result_syntax in
      (* Otherwise, there is no conflict. *)
      QCheck2.assume
        (not
           (let p1_head = List.last_opt p1_client.states in
            let p2_head = List.last_opt p2_client.states in
            Option.equal
              (fun (t1, state_hash1) (t2, state_hash2) ->
                Tick.equal t1 t2 && State_hash.equal state_hash1 state_hash2)
              p1_head
              p2_head)) ;
      let* block =
        prepare_game
          ~data_source
          block
          rollup
          lcc
          commitment_level
          p1_client
          p2_client
          contract3
          levels_and_inputs
          dal_pages
      in
      let refuter, defender =
        if p1_start then (p1_client, p2_client) else (p2_client, p1_client)
      in
      let* operation_start_game =
        Op.sc_rollup_refute
          (B block)
          refuter.player.contract
          rollup
          defender.player.pkh
          None
      in
      let* block =
        match additional_payloads with
        | [] -> Block.bake ~operation:operation_start_game block
        | payloads ->
            (* Add messages before starting the game. *)
            let* operation_add_messages1 =
              Op.sc_rollup_add_messages
                (B block)
                defender.player.contract
                rollup
                payloads
            in
            (* Start the game in between adding messages so the latest protocol
               inbox is no longer equal to the player's view on inbox. *)
            let* operation_add_messages2 =
              Op.sc_rollup_add_messages (B block) contract3 rollup payloads
            in
            Block.bake
              ~operations:
                [
                  operation_add_messages1;
                  operation_start_game;
                  operation_add_messages2;
                ]
              block
      in
      let* game_result =
        play_until_game_result
          ~rollup
          ~refuter_client:refuter
          ~defender_client:defender
          block
      in
      match game_result with
      | Defender_wins -> return (defender.player.strategy = Perfect)
      | Refuter_wins -> return (refuter.player.strategy = Perfect))

let test_perfect_against_random ~data_source =
  test_game ~p1_strategy:Perfect ~p2_strategy:Random ~data_source ()

let test_random_against_perfect =
  test_game ~p1_strategy:Random ~p2_strategy:Perfect ()

let test_perfect_against_lazy =
  test_game ~nonempty_inputs:true ~p1_strategy:Perfect ~p2_strategy:Lazy ()

let test_lazy_against_perfect =
  test_game ~nonempty_inputs:true ~p1_strategy:Lazy ~p2_strategy:Perfect ()

let test_perfect_against_eager =
  test_game ~nonempty_inputs:true ~p1_strategy:Perfect ~p2_strategy:Eager ()

let test_eager_against_perfect =
  test_game ~nonempty_inputs:true ~p1_strategy:Eager ~p2_strategy:Perfect ()

let test_perfect_against_keen =
  test_game ~p1_strategy:Perfect ~p2_strategy:Keen ()

let test_keen_against_perfect =
  test_game ~p1_strategy:Keen ~p2_strategy:Perfect ()

let mk_tests data_source =
  let title = "Refutation - " ^ data_source_to_string data_source in
  ( title,
    qcheck_wrap
      [
        test_perfect_against_random ~data_source;
        test_random_against_perfect ~data_source;
        test_perfect_against_lazy ~data_source;
        test_lazy_against_perfect ~data_source;
        test_perfect_against_eager ~data_source;
        test_eager_against_perfect ~data_source;
        test_perfect_against_keen ~data_source;
        test_keen_against_perfect ~data_source;
      ] )

(** {2 Entry point} *)

let tests = [mk_tests Dal; Dissection.tests; mk_tests Inbox]
(*
let () = ignore tests

let tests =
  [
    (let title = "Refutation - " ^ data_source_to_string Inbox in
     (title, qcheck_wrap [test_keen_against_perfect ~data_source:Inbox]));
  ]
*)

let () = Alcotest.run "Refutation_game" tests
