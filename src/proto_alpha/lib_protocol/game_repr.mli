(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>  and           *)
(*  Trili Tech, <contact@trili.tech>                                         *)
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

(** This module creates a refutation game for Optimistic rollup.
   It is in fact a functor that takes a PVM module and produce a game. *)

val repeat : int -> (int -> 'a) -> ('a list, 'b list) result

module Make : functor (P : Sc_rollup_repr.TPVM) -> sig
  module PVM :
    Sc_rollup_repr.TPVM
      with type 'a state = 'a P.state
       and type history = P.history

  (** This sumbodule introduces sections and dissections and the functions that build them
*)
  module Section_repr : sig
    (** a section has a start and end tick as well as a start and end state. 
    The game will compare such sections and dissagree on them.*)
    type 'k section = {
      section_start_state : 'k P.state;
      section_start_at : Tick_repr.t;
      section_stop_state : 'k P.state;
      section_stop_at : Tick_repr.t;
    }

    (**a dissection is a split of a section in several smaller sections. it is defined as a list.
    TODO perhaps this should be a binary tree based on start_at (which ar increasing) rather than a list. It would make find faster.
*)
    and 'k dissection = 'k section list

    val section_encoding :
      [`Compressed | `Full | `Verifiable] section Data_encoding.t

    val dissection_encoding :
      [`Compressed | `Full | `Verifiable] section list option Data_encoding.t

    val find_section : 'a section -> 'b section list -> 'b section option

    val pp_of_section :
      Format.formatter -> [`Compressed | `Full | `Verifiable] section -> unit

    val pp_of_dissection :
      Format.formatter ->
      [`Compressed | `Full | `Verifiable] section list ->
      unit

    val pp_optional_dissection :
      Format.formatter ->
      [`Compressed | `Full | `Verifiable] section list option ->
      unit

    (** a section is valid if its star_at tick is smaller than it stop_at tick.*)
    val valid_section : 'a section -> bool

    exception Dissection_error of string

    (** this checks that a dissection is continuous and assembles the corresponding 
    section*)
    val section_of_dissection : 'a dissection -> 'a section

    (** this function checks that a given dissection is actually a dissection of a section.*)
    val valid_dissection : 'a section -> 'a dissection -> bool

    (** This splits a section into a dissection with a fixed number of pieces and whose states come from the history.*)
    val dissection_of_section :
      PVM.history ->
      int ->
      'a section ->
      [`Compressed | `Full | `Verifiable] section list option
  end

  type player = Committer | Refuter

  val pp_of_player : Format.formatter -> player -> unit

  val player_encoding : player Data_encoding.t

  val opponent : player -> player

  (** this is the type (state) of a game at a certain moment.It indicates the following:
  - whose turn it is,
  - where does it start and where does it stop
  - the agreed starting state and the disagreed stop state,
  _ the current dissection that teh player should choose from.*)
  type t = {
    turn : player;
    start_state : [`Compressed | `Full | `Verifiable] P.state;
    start_at : Tick_repr.t;
    player_stop_state : [`Compressed | `Full | `Verifiable] P.state;
    opponent_stop_state : [`Compressed | `Full | `Verifiable] P.state;
    stop_at : Tick_repr.t;
    current_dissection :
      [`Compressed | `Full | `Verifiable] Section_repr.dissection option;
  }

  val encoding : t Data_encoding.t

  (** a conflict_search_step can either be a refining of an existing section or a concluded
  step.*)
  type conflict_search_step =
    | Refine of {
        stop_state : [`Compressed | `Full | `Verifiable] P.state;
        next_dissection :
          [`Compressed | `Full | `Verifiable] Section_repr.dissection;
      }
    | Conclude : {
        start_state : [`Compressed | `Full | `Verifiable] P.state;
        stop_state : [`Compressed | `Full | `Verifiable] P.state;
      }
        -> conflict_search_step

  (** a move consists of a choice of a section and a conflict_search step. 
Note that there is some overlap of the info in a move.*)
  type move =
    | ConflictInside of {
        choice : [`Compressed | `Full | `Verifiable] Section_repr.section;
        conflict_search_step : conflict_search_step;
      }

  (** the commiter commits a section *)
  type commit =
    | Commit of [`Compressed | `Full | `Verifiable] Section_repr.section

  (** the refuter refutes a conflict_search_step*)
  type refutation = RefuteByConflict of conflict_search_step

  type reason = InvalidMove | ConflictResolved

  val pp_of_reason : Format.formatter -> reason -> unit

  type outcome = {winner : player option; reason : reason}

  val pp_of_winner : Format.formatter -> player option -> unit

  val pp_of_outcome : Format.formatter -> outcome -> unit

  type state = Over of outcome | Ongoing of t

  val pp_of_game : Format.formatter -> t -> unit

  val pp_of_move : Format.formatter -> move -> unit

  val conflict_found : t -> bool

  val stop_state :
    conflict_search_step -> [`Compressed | `Full | `Verifiable] P.state

  val initial : commit -> conflict_search_step -> t * move

  val resolve_conflict : t -> [> `Verifiable] P.state -> outcome

  val apply_choice :
    game:t ->
    choice:[`Compressed | `Full | `Verifiable] Section_repr.section ->
    [`Compressed | `Full | `Verifiable] P.state ->
    t option

  val apply_dissection :
    game:t ->
    [`Compressed | `Full | `Verifiable] Section_repr.dissection ->
    t option

  val verifiable_representation : 'a P.state -> 'b P.state -> unit option

  val play : t -> move -> state

  type ('from, 'initial) client = {
    initial : 'from -> 'initial;
    next_move :
      [`Compressed | `Full | `Verifiable] Section_repr.dissection -> move;
  }

  val run :
    start_at:'a ->
    start_state:[`Compressed | `Full | `Verifiable] P.state ->
    committer:('a * [`Compressed | `Full | `Verifiable] P.state, commit) client ->
    refuter:
      ([`Compressed | `Full | `Verifiable] P.state * commit, refutation) client ->
    outcome
end
