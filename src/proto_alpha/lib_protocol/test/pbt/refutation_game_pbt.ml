(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
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
    Component:    Protocol Library
    Invocation:   dune exec \
                  src/proto_alpha/lib_protocol/test/pbt/refutation_game_pbt.exe
    Subject:      SCORU refutation game
*)

open Protocol.Refutation_game

exception TickNotFound of Tick.t

open Lib_test.Qcheck_helpers

let operation state number =
  Digest.bytes @@ Bytes.of_string @@ state ^ string_of_int number

module RandomPVM (P : sig
  val initial_prog : int list
end) : sig
  include PVM with type _ state = string * int list
end = struct
  exception TickNotFound of Tick.t

  type _ state = string * int list

  let compress x = x

  let initial_state = ("hello", P.initial_prog)

  let random_state length (_, program) =
    let remaining_program = List.drop_n length program in
    let stop_state = (operation "" (Random.bits ()), remaining_program) in
    stop_state

  let string_of_state (st, li) =
    st ^ List.fold_left (fun acc x -> acc ^ ";" ^ string_of_int x) "" li

  let equal_state = ( = )

  type history = {states : (string * int list) Tick.Map.t; tick : Tick.t}

  let remember history tick state =
    {history with states = Tick.Map.add tick state history.states}

  let eval ~failures (tick : Tick.t) ((hash, continuation) as state) =
    match continuation with
    | [] -> state
    | h :: tl ->
        if List.mem ~equal:( = ) tick failures then (hash, tl)
        else (operation hash h, tl)

  let execute_until ~failures tick state pred =
    let rec loop state tick =
      if pred tick state || snd state = [] then (tick, state)
      else
        let state = eval ~failures tick state in
        loop state (Tick.next tick)
    in
    loop state tick

  let state_at history tick =
    let (lower, ostate, _) = Tick.Map.split tick history.states in
    match ostate with
    | Some state -> state
    | None ->
        let (tick0, state0) =
          match Tick.Map.max_binding lower with
          | Some (t, s) -> (t, s)
          | None -> raise Not_found
        in
        snd
          (execute_until ~failures:[] tick0 state0 (fun tick' _ -> tick' = tick))

  let verifiable_state_at = state_at

  let empty_history = {states = Tick.Map.empty; tick = Tick.make 0}

  type tick = Tick.t
end

module Strategies (G : Game) = struct
  open G
  open PVM

  let random_tick ?(from = 0) () = Tick.make (from + Random.int 31)

  let random_section (start_at : Tick.t) start_state (stop_at : Tick.t) =
    let x = min 10000 (abs (Tick.distance start_at stop_at)) in
    let length = 1 + try Random.int x with _ -> 0 in
    let stop_at = (start_at :> int) + length in

    ({
       section_start_at = start_at;
       section_start_state = start_state;
       section_stop_at = Tick.make stop_at;
       section_stop_state = compress @@ random_state length start_state;
     }
      : _ G.section)

  let random_dissection (gsection : [`Compressed] G.section) =
    let rec aux dissection start_at start_state =
      if start_at = gsection.section_stop_at then dissection
      else
        let section =
          random_section start_at start_state gsection.section_stop_at
        in
        if
          section.section_start_at = gsection.section_start_at
          && section.section_stop_at = gsection.section_stop_at
        then aux dissection start_at start_state
        else
          aux
            (section :: dissection)
            section.section_stop_at
            section.section_stop_state
    in
    if Tick.distance gsection.section_stop_at gsection.section_start_at > 1 then
      Some
        (aux [] gsection.section_start_at gsection.section_start_state
        |> List.rev)
    else None

  let compress_section section =
    {
      section with
      section_start_state = compress section.section_start_state;
      section_stop_state = compress section.section_stop_state;
    }
  (* let {section_start_state; section_start_at; section_stop_state; section_stop_at} = section in
     {(compress section_start_state); section_start_at; (compress section_stop_state); section_stop_at} *)

  let random_decision d =
    let x = Random.int (List.length d) in
    let section =
      match List.(nth d x) with Some s -> s | None -> raise Not_found
    in
    let section_start_at = section.section_start_at in
    let section_stop_at = section.section_stop_at in
    let section_start_state = random_state 0 section.section_start_state in
    let section_stop_state =
      random_state
        ((section_stop_at :> int) - (section_start_at :> int))
        section.section_start_state
    in
    let next_dissection = random_dissection section in
    let section =
      {
        section_start_state;
        section_start_at;
        section_stop_state;
        section_stop_at;
      }
    in
    let conflict_search_step =
      match next_dissection with
      | None ->
          G.Conclude
            {
              start_state = section.section_start_state;
              stop_state = compress section.section_stop_state;
            }
      | Some next_dissection ->
          G.Refine
            {stop_state = compress section.section_stop_state; next_dissection}
    in
    G.ConflictInside {choice = compress_section section; conflict_search_step}

  type parameters = {branching : int; failing_level : int}

  type checkpoint = Tick.t -> bool

  type strategy = Random | MachineDirected of parameters * checkpoint

  let conflicting_section (history : PVM.history) (section : _ G.section) =
    not
      (equal_state
         section.section_stop_state
         (state_at history section.section_stop_at))

  (** corrected, optimised and inlined version of the split (only one pass of the list rather than 3)*)
  let dissection_from_section history branching (section : _ G.section) =
    if Tick.next section.section_start_at = section.section_stop_at then None
    else
      let start = (section.section_start_at :> int) in
      let stop = (section.section_stop_at :> int) in
      let len = stop - start in
      let bucket = len / branching in
      let dissection =
        init branching (fun x ->
            let start_at = start + (bucket * x) in
            let stop_at =
              if x = branching - 1 then stop
              else min stop (start + (bucket * (x + 1)))
            in
            let section_start_at = Tick.make start_at
            and section_stop_at = Tick.make stop_at in
            ({
               section_start_at;
               section_start_state = PVM.state_at history section_start_at;
               section_stop_at;
               section_stop_state = PVM.state_at history section_stop_at;
             }
              : _ G.section))
      in
      Some dissection

  let compress_section (section : _ G.section) : [`Compressed] G.section =
    {
      section with
      section_start_state = PVM.compress section.section_start_state;
      section_stop_state = PVM.compress section.section_stop_state;
    }

  let remember_section history (section : [`Verifiable | `Full] G.section) =
    let history =
      PVM.remember history section.section_start_at section.section_start_state
    in
    PVM.remember history section.section_stop_at section.section_stop_state

  let next_move history branching dissection =
    let section =
      List.find_opt (conflicting_section history) dissection |> function
      | None -> raise (TickNotFound (Tick.make 0))
      | Some s -> s
    in
    let next_dissection = dissection_from_section history branching section in
    let (conflict_search_step, history) =
      match next_dissection with
      | None ->
          let stop_state =
            state_at history (Tick.next section.section_start_at)
          in
          let stop_state = PVM.(compress stop_state) in
          ( G.Conclude
              {
                start_state =
                  PVM.(verifiable_state_at history section.section_start_at);
                stop_state;
              },
            empty_history )
      | Some next_dissection ->
          let stop_state =
            PVM.(compress (state_at history section.section_stop_at))
          in
          let history =
            List.fold_left remember_section empty_history next_dissection
          in
          let next_dissection = List.map compress_section next_dissection in
          (G.Refine {stop_state; next_dissection}, history)
    in
    (G.ConflictInside {choice = section; conflict_search_step}, history)

  let generate_failures failing_level (section_start_at : Tick.t)
      (section_stop_at : Tick.t) =
    if failing_level > 0 then (
      let d = Tick.distance section_stop_at section_start_at in
      assert (d > 0) ;
      let s =
        init failing_level (fun _ ->
            Tick.make ((section_start_at :> int) + Random.int 5))
      in

      s)
    else []

  let machine_directed_committer {branching; failing_level} pred =
    let history = ref PVM.empty_history in
    let initial ((section_start_at : Tick.t), section_start_state) : G.commit =
      let section_stop_at =
        Tick.make ((section_start_at :> int) + Random.int 100)
      in
      let failures =
        generate_failures failing_level section_start_at section_stop_at
      in
      let (section_stop_at, section_stop_state) =
        PVM.execute_until ~failures section_start_at section_start_state
        @@ fun tick _ -> pred tick
      in
      history := PVM.remember !history section_start_at section_start_state ;
      history := PVM.remember !history section_stop_at section_stop_state ;
      let section_start_state = PVM.compress section_start_state in
      let section_stop_state = PVM.compress section_stop_state in
      Commit
        {
          section_start_state;
          section_start_at;
          section_stop_state;
          section_stop_at;
        }
    in
    let next_move dissection =
      let (move, history') = next_move !history branching dissection in
      history := history' ;
      move
    in
    ({initial; next_move} : _ G.client)

  let machine_directed_refuter {branching; failing_level} =
    let history = ref PVM.empty_history in
    let initial (section_start_state, Commit section) : G.refutation =
      let ({section_start_at; section_stop_at; _} : _ G.section) = section in
      let failures =
        generate_failures failing_level section_start_at section_stop_at
      in
      let (_stop_at, section_stop_state) =
        PVM.execute_until ~failures section_start_at section_start_state
        @@ fun tick _ -> tick >= section_stop_at
      in
      history := PVM.remember !history section_start_at section_start_state ;
      history := PVM.remember !history section_stop_at section_stop_state ;
      let stop_state = compress section_stop_state in
      let next_dissection =
        dissection_from_section !history branching section
      in
      let conflict_search_step =
        match next_dissection with
        | None ->
            G.Conclude
              {
                start_state = verifiable_state_at !history section_start_at;
                stop_state;
              }
        | Some next_dissection ->
            let next_dissection = List.map compress_section next_dissection in
            G.Refine {stop_state; next_dissection}
      in
      RefuteByConflict conflict_search_step
    in
    let next_move dissection =
      let (move, history') = next_move !history branching dissection in
      history := history' ;
      move
    in
    ({initial; next_move} : _ G.client)

  let committer_from_strategy : strategy -> _ G.client = function
    | Random ->
        {
          initial =
            (fun ((section_start_at : Tick.t), start_state) ->
              let section_stop_at =
                random_tick ~from:(section_start_at :> int) ()
              in
              let section =
                random_section
                  section_start_at
                  (compress start_state)
                  section_stop_at
              in

              G.Commit section);
          next_move = random_decision;
        }
    | MachineDirected (parameters, checkpoint) ->
        machine_directed_committer parameters checkpoint

  let refuter_from_strategy : strategy -> _ G.client = function
    | Random ->
        {
          initial =
            (fun ((start_state : [`Verifiable | `Full] state), G.Commit section) ->
              let conflict_search_step =
                let next_dissection = random_dissection section in
                match next_dissection with
                | None ->
                    G.Conclude
                      {
                        start_state;
                        stop_state =
                          compress (random_state 1 (compress start_state));
                      }
                | Some next_dissection ->
                    let section = List.last section next_dissection in
                    G.Refine
                      {
                        stop_state = compress section.section_stop_state;
                        next_dissection;
                      }
              in
              G.RefuteByConflict conflict_search_step);
          next_move = random_decision;
        }
    | MachineDirected (parameters, _) -> machine_directed_refuter parameters

  let test_strategies name count committer_strategy refuter_strategy expectation
      =
    QCheck.Test.make ~name ~count QCheck.small_int (fun _ ->
        let start_state = PVM.initial_state in
        let committer = committer_from_strategy committer_strategy in
        let refuter = refuter_from_strategy refuter_strategy in
        let outcome =
          G.run ~start_at:(Tick.make 0) ~start_state ~committer ~refuter
        in
        expectation outcome)

  let test () =
    let perfect_committer =
      MachineDirected
        ( {failing_level = 0; branching = 2},
          fun tick -> (tick :> int) >= 20 + Random.int 100 )
    in
    let perfect_refuter =
      MachineDirected ({failing_level = 0; branching = 2}, fun _ -> assert false)
    in
    let failing_committer =
      MachineDirected
        ( {failing_level = 1; branching = 2},
          fun tick -> (tick :> int) >= 20 + Random.int 100 )
    in
    let failing_refuter =
      MachineDirected ({failing_level = 1; branching = 2}, fun _ -> assert false)
    in
    Alcotest.run
      "Saturation"
      [
        ( "random-random",
          qcheck_wrap
            [test_strategies "random-random" 30 Random Random (fun _ -> true)]
        );
        ( "pr",
          qcheck_wrap
            [
              (test_strategies "perfect-random" 100 perfect_committer Random
               @@ function
               | x -> (
                   match x with
                   | {G.winner = Some Committer; _} -> true
                   | _ -> false));
            ] );
        ( "rp",
          qcheck_wrap
            [
              (test_strategies "random-perfect" 100 Random perfect_refuter
               @@ function
               | {G.winner = Some Refuter; _} -> true
               | _ -> false);
            ] );
        ( "pp",
          qcheck_wrap
            [
              (test_strategies
                 "perfect-perfect"
                 100
                 perfect_committer
                 perfect_refuter
               @@ function
               | {G.winner = Some Committer; _} -> true
               | _ -> false);
            ] );
        ( "pf",
          qcheck_wrap
            [
              (test_strategies
                 "perfect-flawed"
                 100
                 perfect_committer
                 failing_refuter
               @@ function
               | {G.winner = Some Committer; _} -> true
               | _ -> false);
            ] );
        ( "fp",
          qcheck_wrap
            [
              (test_strategies
                 "flawed-perfect"
                 10
                 failing_committer
                 perfect_refuter
               @@ function
               | {G.winner = Some Refuter; _} -> true
               | _ -> false);
            ] );
      ]
end

let test_machine (module M : PVM) =
  let module PCG = MakeGame (M) in
  let module S = Strategies (PCG) in
  S.test ()

let () =
  test_machine
    (module RandomPVM (struct
      let initial_prog =
        QCheck.Gen.generate1
          (QCheck.Gen.list_size
             QCheck.Gen.small_int
             (QCheck.Gen.int_range 0 100))
    end))
