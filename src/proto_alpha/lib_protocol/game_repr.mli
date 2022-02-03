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
   It is in fact a functor that takes a PVM module and produce a game. 

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
     section and disagree on its final state. If they agree on both then whoever plays loses by InvalidMove.

   Remarks
   =======

   There are several subtle cornercases:

   - If the refuter and the committer both post only invalid states, the
     game may end in a conflict state where both are wrong. By convention,
     we decide that these games have no winner.
   
  - If the refuter and the committer both post only states, the
     game never has any conflicts. By convention,
     we decide that in this case the commiter winds by InvalidMove.

   - If the refuter and the committer both post valid and invalid states,
     all outcomes are possible. This means that if a committer wins a
     game we have no guarantee that she has posted a valid commit.
  

*)

val repeat : int -> (int -> 'a) -> ('a list, 'b list) result

module Make : functor (P : Sc_rollup_repr.TPVM) -> sig
  module PVM :
    Sc_rollup_repr.TPVM
      with type 'a state = 'a P.state
       and type history = P.history

  (** This submodule introduces sections and dissections and the functions that build them
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

    (**a dissection is a split of a section in several smaller sections. it is defined as a map
     based on start_at (which are increasing) rather than a list.*)
    and 'k dissection = 'k section Tick_repr.Map.t

    val section_encoding :
      [`Compressed | `Full | `Verifiable] section Data_encoding.t

    val dissection_encoding :
      [`Compressed | `Full | `Verifiable] dissection option Data_encoding.t

    val find_section : 'a section -> 'a dissection -> 'a section option

    val pp_of_section :
      Format.formatter -> [`Compressed | `Full | `Verifiable] section -> unit

    val pp_of_dissection :
      Format.formatter -> [`Compressed | `Full | `Verifiable] dissection -> unit

    val pp_optional_dissection :
      Format.formatter ->
      [`Compressed | `Full | `Verifiable] dissection option ->
      unit

    (** a section is valid if its star_at tick is smaller than it stop_at tick.*)
    val valid_section : 'a section -> bool

    exception Dissection_error of string

    (**

     A dissection is valid if it is composed of a list of contiguous
     sections that covers a given [section].

     In practice, we also want sections to be balanced in terms of gas
     they consume to avoid strategies that slowdown convergence.

     the function  valid_dissection checks if a dissection is valid and, if so, 
      it verifies that it is a dissection of the given section.

  *)
    val valid_dissection : 'a section -> 'a dissection -> bool

    (** This function takes a section and an integer branching and creates a dissection with branching number of pieces that
        are (roughly) equal and whose states come from the history.
    Assume that length of the initial section is len and len mod branching = r. We have the following invariants:
    - if branching >len then we make branching = len (split the section into one tick sections)
    - valid_disection section (dissection_of_section history branching section)=true
    - The first r pieces are one tick longer than the rest (the alternative would have been for the last piece to be a lot longer)
    *)
    val dissection_of_section :
      PVM.history ->
      int ->
      'a section ->
      [`Compressed | `Full | `Verifiable] dissection option
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

  (** the outcome of a finished game gives the winner as well as the reason for winning*)
  type outcome = {winner : player option; reason : reason}

  val pp_of_winner : Format.formatter -> player option -> unit

  val pp_of_outcome : Format.formatter -> outcome -> unit

  (** a game can be over witha given outcome or Ongoing with  a given game state*)
  type state = Over of outcome | Ongoing of t

  val pp_of_game : Format.formatter -> t -> unit

  val pp_of_move : Format.formatter -> move -> unit

  (** [confict_found game] is [true] iff the [game]'s section is
      one tick long. *)
  val conflict_found : t -> bool

  (** this function extracts the stop state of a conflict_search_step*)
  val stop_state :
    conflict_search_step -> [`Compressed | `Full | `Verifiable] P.state

  (**

     The initial game state from the commit and the refutation.

     The first player to play is the refuter.

  *)
  val initial : commit -> conflict_search_step -> t * move

  (**

     Assuming a [game] where the current section is one tick long,
     [resolve_conflict game] determines the [game] outcome.

  *)
  val resolve_conflict : t -> [> `Verifiable] P.state -> outcome

  (** [apply_choice turn game choice chosen_stop_state] returns [Some
     game'] state where the [choice] of the [turn]'s player is applied
     to [game] and justified by [chosen_stop_state].

     If the [choice] is invalid, this function returns [None]. *)
  val apply_choice :
    game:t ->
    choice:[`Compressed | `Full | `Verifiable] Section_repr.section ->
    [`Compressed | `Full | `Verifiable] P.state ->
    t option

  (** [apply_dissection game next_dissection] returns [Some game']
      where the [current_dissection] is the [next_dissection] if
      it is valid. Otherwise, this function returns [None]. *)
  val apply_dissection :
    game:t ->
    [`Compressed | `Full | `Verifiable] Section_repr.dissection ->
    t option

  val verifiable_representation : 'a P.state -> 'b P.state -> unit option

  (** [playe game move] returns the state of the [game] after that
     [move] has been applied, if [move] is valid. Otherwise, this
     function returns an game over due to InvalidMove. *)
  val play : t -> move -> state

  (** a client is a strategy for a player. It consists of an initial move and a function that 
  picks the next move once the oponent gives ou a dissection.
  In practice 
  - the commuter will be a ((tick * _ state) * commit) client
  - the refuter will be a ((_ state * commit) * refutation) client *)

  type ('from, 'initial) client = {
    initial : 'from -> 'initial;
    next_move :
      [`Compressed | `Full | `Verifiable] Section_repr.dissection -> move;
  }

  (** this is the function that runs a game. 
  It receives a starting tick and a starting state as well as commiter and refuter clients and 
  outputs the outcome of the refutation game.*)

  val run :
    start_at:'a ->
    start_state:[`Compressed | `Full | `Verifiable] P.state ->
    committer:('a * [`Compressed | `Full | `Verifiable] P.state, commit) client ->
    refuter:
      ([`Compressed | `Full | `Verifiable] P.state * commit, refutation) client ->
    outcome
end
