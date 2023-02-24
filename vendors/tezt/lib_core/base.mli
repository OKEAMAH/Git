(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020-2022 Nomadic Labs <contact@nomadic-labs.com>           *)
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

(** Base functions. *)

(** {2 Strings} *)

(** Same as [Filename.concat]. *)
val ( // ) : string -> string -> string

(** Same as [Printf.sprintf]. *)
val sf : ('a, unit, string) format -> 'a

(** {2 Concurrency Monad} *)

(** Same as [Lwt.bind]. *)
val ( let* ) : 'a Lwt.t -> ('a -> 'b Lwt.t) -> 'b Lwt.t

(** Same as [Lwt.both]. *)
val ( and* ) : 'a Lwt.t -> 'b Lwt.t -> ('a * 'b) Lwt.t

(** Same as [Lwt.both], but immediately propagate exceptions.

    More precisely, if one of the two promises is rejected
    or canceled, cancel the other promise and reject the resulting
    promise immediately with the original exception. *)
val lwt_both_fail_early : 'a Lwt.t -> 'b Lwt.t -> ('a * 'b) Lwt.t

(** Same as [Lwt.return]. *)
val return : 'a -> 'a Lwt.t

(** Same as [Lwt.return_unit]. *)
val unit : unit Lwt.t

(** Same as [Lwt.return_none]. *)
val none : 'a option Lwt.t

(** Same as [Lwt.return_some]. *)
val some : 'a -> 'a option Lwt.t

(** Get the value of an option that must not be [None].

    Usage: [mandatory name option]

    [name] is used in the error message if [option] is [None]. *)
val mandatory : string -> 'a option -> 'a

(** {2 Lists} *)

(** Make a list of all integers between two integers.

    If the first argument [a] is greater than the second argument [b],
    return the empty list. Otherwise, returns the list [a; ...; b].  *)
val range : int -> int -> int list

(** Backport of [List.find_map] from OCaml 4.10. *)
val list_find_map : ('a -> 'b option) -> 'a list -> 'b option

(** [take n l] returns the first [n] elements of [l] if longer than [n],
    else [l] itself. *)
val take : int -> 'a list -> 'a list

(** [drop n l] removes the first [n] elements of [l] if longer than [n],
    else the empty list. Raise [invalid_arg] if [n] is negative. *)
val drop : int -> 'a list -> 'a list

(** Split a list based on a predicate.

    [span f l] returns a pair of lists [(l1, l2)], where [l1] is the
    longest prefix of [l] that satisfies the predicate [f], and [l2] is
    the rest of the list. The order of the elements in the input list
    is preserved such that [l = l1 @ l2]. *)
val span : ('a -> bool) -> 'a list -> 'a list * 'a list

(** {2 Regular Expressions} *)

(** Compiled regular expressions. *)
type rex

(** Compile a regular expression using Perl syntax. *)
val rex : ?opts:Re.Perl.opt list -> string -> rex

(** Same as [rex @@ sf ...]. *)
val rexf : ?opts:Re.Perl.opt list -> ('a, unit, string, rex) format4 -> 'a

(** Convert a regular expression to a string using Perl syntax. *)
val show_rex : rex -> string

(** Test whether a string matches a regular expression.

    Example: ["number 1234 matches" =~ rex "\\d+"] *)
val ( =~ ) : string -> rex -> bool

(** Negation of [=~]. *)
val ( =~! ) : string -> rex -> bool

(** Match a regular expression with one capture group. *)
val ( =~* ) : string -> rex -> string option

(** Match a regular expression with two capture groups. *)
val ( =~** ) : string -> rex -> (string * string) option

(** Match a regular expression with three capture groups. *)
val ( =~*** ) : string -> rex -> (string * string * string) option

(** Match a regular expression with four capture groups. *)
val ( =~**** ) : string -> rex -> (string * string * string * string) option

(** Match a regular expression with one capture group and return all results. *)
val matches : string -> rex -> string list

(** [replace_string ~all rex ~by s] iterates on [s], and replaces every
    occurrence of [rex] with [by]. If [all = false], then only the first
    occurrence of [rex] is replaced. *)
val replace_string :
  ?pos:int ->
  (* Default: 0 *)
  ?len:int ->
  ?all:bool ->
  (* Default: true. Otherwise only replace first occurrence *)
  rex ->
  (* matched groups *)
  by:string ->
  (* replacement string *)
  string ->
  (* string to replace in *)
  string

(** {2 Promises} *)

(** Repeat something a given amount of times. *)
val repeat : int -> (unit -> unit Lwt.t) -> unit Lwt.t

(** Fold n times a given function. *)
val fold : int -> 'a -> (int -> 'a -> 'a Lwt.t) -> 'a Lwt.t

(** {2 Input/Output} *)

(** Open file, use function to write output then close the output. In case of
   error while writing, the channel is closed before raising the exception *)
val with_open_out : string -> (out_channel -> unit) -> unit

(** Open file, use function to read input then close the input. In case of
   error while reading, the channel is closed before raising the exception **)
val with_open_in : string -> (in_channel -> 'a) -> 'a

(** Write a string into a file, overwriting the file if it already exists.

    Usage: [write_file filename ~contents] *)
val write_file : string -> contents:string -> unit

(** Read the whole contents of a file. *)
val read_file : string -> string

(** {2 Common structures} *)

module String_map : Map.S with type key = string

module String_set : sig
  include Set.S with type elt = string

  (** Pretty-print a set of strings.

      Items are quoted, separated by commas and breakable spaces,
      and the result is surrounded by braces. *)
  val pp : Format.formatter -> t -> unit
end

(** {2 Environment} *)

(** Path to the root of the project.

    This is [DUNE_SOURCEROOT] is defined, [PWD] otherwise. *)
val project_root : string
