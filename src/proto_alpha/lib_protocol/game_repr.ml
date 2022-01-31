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

(**

   Preliminary definitions
   =======================

*)
open Compare.Int

open Sc_rollup_repr

let repeat n f = List.init ~when_negative_length:[] n f

module Make (P : TPVM) = struct
  module PVM = P

  module Section_repr = struct
    type 'k section = {
      section_start_state : 'k PVM.state;
      section_start_at : PVM.tick;
      section_stop_state : 'k PVM.state;
      section_stop_at : PVM.tick;
    }

    and 'k dissection = 'k section list

    let section_encoding =
      let open Data_encoding in
      conv
        (fun {
               section_start_state;
               section_start_at;
               section_stop_state;
               section_stop_at;
             } ->
          ( section_start_state,
            section_start_at,
            section_stop_state,
            section_stop_at ))
        (fun ( section_start_state,
               section_start_at,
               section_stop_state,
               section_stop_at ) ->
          {
            section_start_state;
            section_start_at;
            section_stop_state;
            section_stop_at;
          })
        (obj4
           (req "section_start_state" PVM.encoding)
           (req "section_start_at" Tick_repr.encoding)
           (req "section_stop_state" PVM.encoding)
           (req "section_stop_at" Tick_repr.encoding))

    let dissection_encoding = Data_encoding.(option (list section_encoding))

    let find_section section dissection =
      List.find_opt
        (fun {section_start_at; section_stop_at; _} ->
          Tick_repr.(
            section_start_at = section.section_start_at
            && section_stop_at = section.section_stop_at))
        dissection

    let pp_of_section ppf (s : _ section) =
      Format.fprintf
        ppf
        "( %a ) -- [%d] \n ->\n  ( %a ) -- [%d] "
        PVM.pp
        s.section_start_state
        (s.section_start_at :> int)
        PVM.pp
        s.section_stop_state
        (s.section_stop_at :> int)

    let pp_of_dissection d =
      Format.pp_print_list
        ~pp_sep:(fun ppf () -> Format.pp_print_string ppf ";\n\n")
        pp_of_section
        d

    let pp_optional_dissection d =
      Format.pp_print_option
        ~none:(fun ppf () ->
          Format.pp_print_text ppf "no dissection at the moment")
        pp_of_dissection
        d

    let valid_section ({section_start_at; section_stop_at; _} : _ section) =
      (section_stop_at :> int) > (section_start_at :> int)

    (**
      
           A dissection is a partition of a section.
      
        *)
    exception Dissection_error of string

    let section_of_dissection dissection =
      let aux d =
        match d with
        | [] -> raise (Dissection_error "empty dissection")
        | h :: tl ->
            let {section_start_at; section_start_state; _} = h in

            let section =
              List.fold_left
                Tick_repr.(
                  fun acc x ->
                    if
                      acc.section_stop_at = x.section_start_at
                      && valid_section x
                    then x
                    else raise (Dissection_error "invalid dissection"))
                h
                tl
            in
            {section with section_start_at; section_start_state}
      in
      aux dissection

    let valid_dissection (section : _ section) dissection =
      try
        let s = section_of_dissection dissection in
        Tick_repr.(
          s.section_start_at = section.section_start_at
          && s.section_stop_at = section.section_stop_at)
      with _ -> false
  end

  type player = Committer | Refuter

  let pp_of_player ppf player =
    Format.fprintf
      ppf
      (match player with Committer -> "committer" | Refuter -> "refuter")

  let player_encoding =
    let open Data_encoding in
    union
      ~tag_size:`Uint8
      [
        case
          ~title:"Commiter"
          (Tag 0)
          string
          (function Committer -> Some "committer" | _ -> None)
          (fun _ -> Committer);
        case
          ~title:"Refuter"
          (Tag 1)
          string
          (function Refuter -> Some "refuter" | _ -> None)
          (fun _ -> Refuter);
      ]

  let opponent = function Committer -> Refuter | Refuter -> Committer

  type t = {
    turn : player;
    start_state : [`Compressed | `Full | `Verifiable] PVM.state;
    start_at : PVM.tick;
    player_stop_state : [`Compressed | `Full | `Verifiable] PVM.state;
    opponent_stop_state : [`Compressed | `Full | `Verifiable] PVM.state;
    stop_at : PVM.tick;
    current_dissection :
      [`Compressed | `Full | `Verifiable] Section_repr.dissection option;
  }

  (*TODO perhaps this should be a binary tree based on start_at (which ar increasing) rather than a list. It would make find faster. *)

  let encoding =
    let open Data_encoding in
    conv
      (fun {
             turn;
             start_state;
             start_at;
             player_stop_state;
             opponent_stop_state;
             stop_at;
             current_dissection;
           } ->
        ( turn,
          start_state,
          start_at,
          player_stop_state,
          opponent_stop_state,
          stop_at,
          current_dissection ))
      (fun ( turn,
             start_state,
             start_at,
             player_stop_state,
             opponent_stop_state,
             stop_at,
             current_dissection ) ->
        {
          turn;
          start_state;
          start_at;
          player_stop_state;
          opponent_stop_state;
          stop_at;
          current_dissection;
        })
      (obj7
         (req "turn" player_encoding)
         (req "start_state" PVM.encoding)
         (req "start_at" Tick_repr.encoding)
         (req "player_stop_state" PVM.encoding)
         (req "oponent_stop_state" PVM.encoding)
         (req "stop_at" Tick_repr.encoding)
         (req "current_dissection" Section_repr.dissection_encoding))

  type conflict_search_step =
    | Refine of {
        stop_state : [`Compressed | `Full | `Verifiable] PVM.state;
        next_dissection :
          [`Compressed | `Full | `Verifiable] Section_repr.dissection;
      }
    | Conclude : {
        start_state : ([`Compressed | `Full | `Verifiable] as 'a) PVM.state;
        stop_state : [`Compressed | `Full | `Verifiable] PVM.state;
      }
        -> conflict_search_step

  type move =
    | ConflictInside of {
        choice : [`Compressed | `Full | `Verifiable] Section_repr.section;
        conflict_search_step : conflict_search_step;
      }

  type commit =
    | Commit of [`Compressed | `Full | `Verifiable] Section_repr.section

  type refutation = RefuteByConflict of conflict_search_step

  type reason = InvalidMove | ConflictResolved

  let pp_of_reason ppf reason =
    Format.fprintf
      ppf
      "%s"
      (match reason with
      | InvalidMove -> "invalid move"
      | ConflictResolved -> "conflict resolved")

  type outcome = {winner : player option; reason : reason}

  let pp_of_winner winner =
    Format.pp_print_option
      ~none:(fun ppf () -> Format.pp_print_text ppf "no winner")
      pp_of_player
      winner

  let pp_of_outcome ppf {winner; reason} =
    Format.fprintf
      ppf
      "%a because of %a"
      pp_of_winner
      winner
      pp_of_reason
      reason

  type state = Over of outcome | Ongoing of t

  let pp_of_game ppf g =
    Format.fprintf
      ppf
      "%a @ %d -> %a / %a @ %d [%a] %s playing"
      PVM.pp
      g.start_state
      (g.start_at :> int)
      PVM.pp
      g.player_stop_state
      PVM.pp
      g.opponent_stop_state
      (g.stop_at :> int)
      Section_repr.pp_optional_dissection
      g.current_dissection
      (match g.turn with Committer -> "committer" | Refuter -> "refuter")

  let pp_of_move ppf = function
    | ConflictInside
        {choice; conflict_search_step = Refine {next_dissection; stop_state}} ->
        Format.fprintf
          ppf
          "conflict is inside %a, should end with %a, new dissection = %a"
          Section_repr.pp_of_section
          choice
          PVM.pp
          stop_state
          Section_repr.pp_of_dissection
          next_dissection
    | ConflictInside
        {choice; conflict_search_step = Conclude {start_state; stop_state}} ->
        Format.fprintf
          ppf
          "atomic conflict found inside %a, we can verify that it starts with \
           %a and should end with %a"
          Section_repr.pp_of_section
          choice
          PVM.pp
          start_state
          PVM.pp
          stop_state

  (**

     A section is valid if its ticks are consistent.

  *)

  (**

     A dissection is valid if it is composed of a list of contiguous
     sections that covers a given [section].

     In practice, we also want sections to be balanced in terms of gas
     they consume to avoid strategies that slowdown convergence.

     the function section_of_dissection checks if a dissection is valid and, if so, 
      it computes the section it represents.

  *)

  (** [confict_found game] is [true] iff the [game]'s section is
      one tick long. *)
  let conflict_found (game : t) =
    Compare.Int.((game.stop_at :> int) - (game.start_at :> int) = 1)

  let stop_state = function
    | Refine {stop_state; _} -> stop_state
    | Conclude {stop_state; _} -> stop_state

  (**

     The initial game state from the commit and the refutation.

     The first player to play is the refuter.

  *)
  let initial (Commit commit) (refutation : conflict_search_step) =
    let game =
      {
        start_state = commit.section_start_state;
        start_at = commit.section_start_at;
        opponent_stop_state = commit.section_stop_state;
        stop_at = commit.section_stop_at;
        player_stop_state = stop_state refutation;
        current_dissection = None;
        turn = Refuter;
      }
    in
    let choice = commit in
    let move = ConflictInside {choice; conflict_search_step = refutation} in
    (game, move)

  (**

     Assuming a [game] where the current section is one tick long,
     [resolve_conflict game] determines the [game] outcome.

  *)
  let resolve_conflict (game : t) verifiable_start_state =
    let open PVM in
    assert (conflict_found game) ;
    let player = game.turn in
    let over winner = {winner; reason = ConflictResolved} in
    match eval ~failures:[] game.start_at verifiable_start_state with
    | stop_state -> (
        let player_state_valid =
          Internal_for_tests.equal_state stop_state game.player_stop_state
        in
        let opponent_state_valid =
          Internal_for_tests.equal_state stop_state game.opponent_stop_state
        in
        match (player_state_valid, opponent_state_valid) with
        | (true, true) -> over @@ Some Committer
        | (true, false) -> over @@ Some player
        | (false, true) -> over @@ Some (opponent player)
        | (false, false) -> over @@ None)

  (** [apply_choice turn game choice chosen_stop_state] returns [Some
     game'] state where the [choice] of the [turn]'s player is applied
     to [game] and justified by [chosen_stop_state].

     If the [choice] is invalid, this function returns [None]. *)
  let apply_choice ~(game : t) ~(choice : _ Section_repr.section)
      chosen_stop_state =
    Option.bind
      (match game.current_dissection with
      | Some dissection ->
          Section_repr.find_section choice dissection
          (* TODO faster binary search in the list if we have binary tree.*)
      | None ->
          if
            PVM.Internal_for_tests.equal_state
              choice.section_start_state
              game.start_state
          then Some choice
          else None)
    @@ fun ({
              section_start_state;
              section_start_at;
              section_stop_state;
              section_stop_at;
            } :
             _ Section_repr.section) ->
    if PVM.Internal_for_tests.equal_state chosen_stop_state section_stop_state
    then None
    else
      Some
        {
          game with
          start_state = section_start_state;
          start_at = section_start_at;
          opponent_stop_state = section_stop_state;
          player_stop_state = chosen_stop_state;
          stop_at = section_stop_at;
        }

  (** [apply_dissection game next_dissection] returns [Some game']
      where the [current_dissection] is the [next_dissection] if
      it is valid. Otherwise, this function returns [None]. *)
  let apply_dissection ~(game : t) (next_dissection : _ Section_repr.dissection)
      =
    let current_section : _ Section_repr.section =
      {
        section_start_state = game.start_state;
        section_start_at = game.start_at;
        section_stop_state = game.opponent_stop_state;
        section_stop_at = game.stop_at;
      }
    in
    if Section_repr.valid_dissection current_section next_dissection then
      Some {game with current_dissection = Some next_dissection}
    else None

  let verifiable_representation vstate state =
    if PVM.Internal_for_tests.equal_state vstate state then Some () else None

  (** [player game move] returns the status of the [game] after that
     [move] has been applied, if [move] is valid. Otherwise, this
     function returns [None]. *)
  let play game (ConflictInside {choice; conflict_search_step}) =
    let player = game.turn in

    let apply_move () =
      match conflict_search_step with
      | Refine {next_dissection; stop_state} ->
          Option.bind (apply_choice ~game ~choice stop_state) @@ fun game ->
          Option.bind (apply_dissection ~game next_dissection) @@ fun game ->
          Some (Ongoing game)
      | Conclude {start_state; stop_state} ->
          Option.bind (apply_choice ~game ~choice stop_state) @@ fun game ->
          Option.bind (verifiable_representation start_state game.start_state)
          @@ fun () ->
          if conflict_found game then
            Some (Over (resolve_conflict game start_state))
          else None
    in
    match apply_move () with
    | None -> Over {winner = Some (opponent player); reason = InvalidMove}
    | Some state -> state

  type ('from, 'initial) client = {
    initial : 'from -> 'initial;
    next_move :
      [`Compressed | `Full | `Verifiable] Section_repr.dissection -> move;
  }

  let run ~start_at
      ~(start_state : [`Compressed | `Verifiable | `Full] PVM.state) ~committer
      ~refuter =
    let (Commit commit) = committer.initial (start_at, start_state) in
    let (RefuteByConflict refutation) =
      refuter.initial (start_state, Commit commit)
    in
    let outcome =
      let rec loop game move =
        match play game move with
        | Over outcome -> outcome
        | Ongoing game ->
            let game = {game with turn = opponent game.turn} in
            let move =
              match game.turn with
              | Committer ->
                  let nm =
                    committer.next_move
                      (Option.value ~default:[] game.current_dissection)
                  in
                  nm
              | Refuter ->
                  refuter.next_move
                    (Option.value ~default:[] game.current_dissection)
            in
            loop game move
      in
      let (game, move) = initial (Commit commit) refutation in
      loop game move
    in
    outcome
end

(**

   Expected properties
   ===================

   Honest-committer-wins:
   - If a committer has posted a valid commit and has a perfect PVM at hand,
     there is a winning strategy which consists in choosing the first section
     of the current dissection and in producing a regular dissection until the
     conflict is reached.

   Honest-refuter-wins:
   - If a refuter has detected an invalid commit and has a perfect PVM at hand,
     the same strategy is also winning.

   Here "winning strategy" means that the player actually wins (a draw is not
   enough).


   Important invariants
   ====================

   - The committer and the refuter agree on the first state of the current
     section and disagree on its final state.

   Remarks
   =======

   There are several subtle cornercases:

   - If the refuter and the committer both post only invalid states, the
     game may end in a conflict state where both are wrong. By convention,
     we decide that these games have no winner.

   - If the refuter and the committer both post valid and invalid states,
     all outcomes are possible. This means that if a committer wins a
     game we have no guarantee that she has posted a valid commit.

*)
