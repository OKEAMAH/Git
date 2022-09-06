(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 TriliTech <contact@trili.tech>                         *)
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

  Action is a monad transformer over Lwt.
  The combinators in this module are aimed to mimic Lwt.

  The goal of the Action monad is to count the number of Lwt [bind] and [map]
  combinations. This is far from a perfect measure but in light of the fact that
  the WebAssembly interpreter library composes primarily through a monadic
  Lwt-like interface it can gives us a rough idea of whether a computation is
  running away in a time complexity sense.

  How you compose a program using this Action monad affects the number of steps
  it counts.
  For example: [let* x = return y in f x] is not the same as [let x = y in f x].
  The latter is 0 steps, the former is 1 step. The same is true for mapping:
  [let+ x = return y in f x] is 1 step, but [let x = y in f x] is 0.

*)

(** Raised when the counter exceeds its maximum. *)
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
