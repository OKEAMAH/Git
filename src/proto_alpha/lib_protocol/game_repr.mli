val repeat : int -> (int -> 'a) -> ('a list, 'b list) result

module Make : functor (P : Sc_rollup_repr.TPVM) -> sig
  module PVM : sig
    type 'a state = 'a P.state

    module Internal_for_tests : sig
      val initial_state : [`Compressed | `Full | `Verifiable] state

      val random_state :
        int ->
        [`Compressed | `Verifiable | `Full] state ->
        [`Compressed | `Verifiable | `Full] state

      val equal_state : 'a state -> 'b state -> bool
    end

    type history = P.history

    val empty_history : history

    type tick = Tick_repr.t

    val encoding : [`Compressed | `Full | `Verifiable] state Data_encoding.t

    val remember :
      history -> tick -> [`Compressed | `Full | `Verifiable] state -> history

    val compress : 'a state -> [`Compressed] state

    val verifiable_state_at :
      history -> tick -> [`Compressed | `Full | `Verifiable] state

    val state_at : history -> tick -> [`Compressed | `Full | `Verifiable] state

    val pp :
      Format.formatter -> [`Compressed | `Full | `Verifiable] state -> unit

    val eval :
      failures:tick list -> tick -> ([> `Verifiable] as 'a) state -> 'a state

    val execute_until :
      failures:tick list ->
      tick ->
      ([> `Verifiable] as 'a) state ->
      (tick -> 'a state -> bool) ->
      tick * 'a state
  end

  type t

  val pp_of_game : Format.formatter -> t -> unit

  type 'k section = {
    section_start_state : 'k P.state;
    section_start_at : Tick_repr.t;
    section_stop_state : 'k P.state;
    section_stop_at : Tick_repr.t;
  }

  val pp_of_section :
    Format.formatter -> [`Compressed | `Full | `Verifiable] section -> unit

  type player = Committer | Refuter

  val pp_of_player : Format.formatter -> player -> unit

  val encoding : t Data_encoding.t

  type reason = InvalidMove | ConflictResolved

  type outcome = {winner : player option; reason : reason}

  val pp_of_outcome : Format.formatter -> outcome -> unit

  type state = Over of outcome | Ongoing of t

  type 'k dissection = 'k section list

  val pp_of_dissection :
    Format.formatter -> [`Compressed | `Full | `Verifiable] dissection -> unit

  val valid_dissection : 'a section -> 'b dissection -> bool

  type move =
    | ConflictInside of {
        choice : [`Compressed | `Full | `Verifiable] section;
        conflict_search_step : conflict_search_step;
      }

  and conflict_search_step =
    | Refine of {
        stop_state : [`Compressed | `Full | `Verifiable] P.state;
        next_dissection : [`Compressed | `Full | `Verifiable] dissection;
      }
    | Conclude : {
        start_state : [`Compressed | `Full | `Verifiable] P.state;
        stop_state : [`Compressed | `Full | `Verifiable] P.state;
      }
        -> conflict_search_step

  val pp_of_move : Format.formatter -> move -> unit

  type commit = Commit of [`Compressed | `Full | `Verifiable] section

  type refutation = RefuteByConflict of conflict_search_step

  type ('from, 'initial) client = {
    initial : 'from -> 'initial;
    next_move : [`Compressed | `Full | `Verifiable] dissection -> move;
  }

  val run :
    start_at:Tick_repr.t ->
    start_state:[`Compressed | `Full | `Verifiable] P.state ->
    committer:
      (Tick_repr.t * [`Compressed | `Full | `Verifiable] P.state, commit) client ->
    refuter:
      ([`Compressed | `Full | `Verifiable] P.state * commit, refutation) client ->
    outcome
end
