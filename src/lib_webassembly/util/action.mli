exception Exceeded_max_num_steps

type 'a t

(** [run ?max_num_steps a] runs the given action computation [a] and returns the
    resulting lwt promise. If [max_num_steps] is given an exception
    [Exceeded_max_num_steps] is thrown. *)
val run : ?max_num_steps:int -> 'a t -> 'a Lwt.t

(** [return x] an action that always produces [x]. *)
val return : 'a -> 'a t

(** [return_unit] is [return unit]. *)
val return_unit : unit t

(** [return_none] is [return None]. *)
val return_none : 'a option t

(** [return_nil] is [return []]. *)
val return_nil : 'a list t

(** [return_false] is [return false]. *)
val return_false : bool t

(** [of_lwt] creates an action that returns the given lwt value. *)
val of_lwt : 'a Lwt.t -> 'a t

(** [fail e] an action that when run, fails with the the given exception [e]. *)
val fail : exn -> 'a t

(** [catch f r] when run, recovers from any error produced by [f] using [r]. *)
val catch : (unit -> 'a t) -> (exn -> 'a t) -> 'a t

val iter_range : first_index:int -> last_index:int -> (int -> unit t) -> unit t

(**  A module with list combinators. *)
module List : sig
  (** Analogous to {!Lwt.map_s} but for actions. *)
  val map_s : ('a -> 'b t) -> 'a list -> 'b list t

  (** Analogous to {!Lwt.iter_s} but for actions. *)
  val iter_s : ('a -> unit t) -> 'a list -> unit t

  (** Analogous to {!Lwt.fold_left_s} but for actions. *)
  val fold_left_s : ('a -> 'b -> 'a t) -> 'a -> 'b list -> 'a t

  (** Analogous to {!Lwt.mapi_s} but for actions. *)
  val mapi_s : (int -> 'a -> 'b t) -> 'a list -> 'b list t

  (** Analogous to {!Lwt.concat_map_s} but for actions. *)
  val concat_map_s : ('a -> 'b list t) -> 'a list -> 'b list t

  (** Same as {!mapi} but for [int32] indices. *)
  val mapi_int32_s : (int32 -> 'a -> 'b t) -> 'a list -> 'b list t
end

(** Syntax module for {!Action.t} values. *)
module Syntax : sig
  val return : 'a -> 'a t

  val ( let+ ) : 'a t -> ('a -> 'b) -> 'b t

  val ( let* ) : 'a t -> ('a -> 'b t) -> 'b t

  val ( and+ ) : 'a t -> 'b t -> ('a * 'b) t

  val ( and* ) : 'a t -> 'b t -> ('a * 'b) t
end

module Internal_for_tests : sig
  (** Same as [run] but allow running [max_int] steps. Returns the number of steps used. *)
  val run : 'a t -> ('a * int) Lwt.t
end
