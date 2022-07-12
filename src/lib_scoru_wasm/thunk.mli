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

(** This module provides a means of transparently manipulating a
    hierarchy of values stored in a tree. These values are lazily
    loaded on demand, modified in-place, and then encoded back in the
    tree once the computation is done.

    In a nutshell, a ['a thunk] is a lazily loaded collection of
    values whose hierarchy is determined by ['a]. A ['a schema] is a
    declarative description of your data model, that is how to encode
    and decode your values. Developers familiar with [Data_encoding]
    will find the API of [schema] familiar.  Then, ['a lens] is a way
    to traverse a [thunk], reading what’s needing from a tree, and
    modifying in-place your datas.

    As a consequence, this module provides a generic way to merklize
    arbitrary complex data-model. *)

(** ['a value] denotes a value in a data-model of type ['a] that can be
    read from and write to a tree. *)
type 'a value

(** [('a, 'b) dict] denotes a dictionary in a data-model that
    associates sub-hierarchies of value determined by type [b] to keys
    of type [a] (said keys need to be serializable to [string]). *)
type ('a, 'b) dict

module Make (T : Tree.S) : sig
  (** Thunks are parameterized by an Irmin tree, that is the preferred
      backend to store the manipulated data in a persistent way. *)
  type tree = T.tree

  (** A thunk is a lazily loaded collection of values whose hierarchy
      is determined by the type parameter ['a].

      The key point to remember is that no values of type ['a] are
      ever constructed.  Instead, developers manipulates ['a t]
      values, by means of lenses and getters and setters.

      The type parameter ['a] is used to describe a tree-like
      structure constructed with OCaml tuples, or dictionary-like
      nodes (see {!dict}). The leaves of this tree-like structure are
      denoted by the {!value} type. That is, a thunk of type ['a value
      thunk] can be fetched from an Irmin tree (using the {!find} or
      {!get} functions), and even updated (using the {!set} function).

      Modifying a thunk does not modify the tree from which the values
      are decoded. Instead, these modifications happen in-place,
      inside the thunk itself. Then, a tree can be constructed back
      from a modified thunk using the {!encode} function (see also the
      {!schema} type).

      Finally, note that thunks are {b not} purely functional. In
      particular, when a sub-part of the data-model is accessed by
      means of a lens, and when a call to {!set} modifies the
      resulting “sub thunk”, the original thunk is modified
      likewise. Similarly, there is no easy way to revert back a thunk
      in a previous state. *)
  type !'a t

  type !'a thunk = 'a t

  (** [find thunk] returns the value behind [thunk], or [None] if
      this value is absent.

      A value can be absent (1) iff it has not been initialized yet,
      or (2) it has been removed from the data model using the {!cut}
      function.

      If necessary, [find] will interact with the Irmin tree used to
      store the data model. *)
  val find : 'a value thunk -> 'a option Lwt.t

  (** [get thunk] returns the value behind [thunk].

      This functions raises an [Invalid_argument] exception if the
      value is absent. *)
  val get : 'a value thunk -> 'a Lwt.t

  (** [set thunk v] updates [thunk] so that the value behind it becomes [v].

      The underlying Irmin tree is {b not} updated, a new tree has to
      be recomputed using {!encode}. *)
  val set : 'a value thunk -> 'a -> unit

  (** [cut thunk] “removes” the collection of data behind [thunk] from
      the original hierarchy.

      After that, these values are absent, and [find] will return
      [None] until {!set} is used again. *)
  val cut : 'a thunk -> unit

  (** A [lens] is a way to traverse a data-model, in order to focus on
      a sub-tree. Thunks resulting to the application of a lens remain
      linked to the orinigal one, that is, modiying the sub-thunk also
      modifies the original thunk. *)
  type ('a, 'b) lens = 'a thunk -> 'b thunk Lwt.t

  (** The composition operator for lenses. *)
  val ( ^. ) : ('a, 'b) lens -> ('b, 'c) lens -> ('a, 'c) lens

  (** [tup2_0] is a lens to traverse a 2-tuple node and select the
      first child. *)
  val tup2_0 : ('a * 'b, 'a) lens

  (** [tup2_1] is a lens to traverse a 2-tuple node and select the
      second child. *)
  val tup2_1 : ('a * 'b, 'b) lens

  (** [tup3_0] is a lens to traverse a 3-tuple node and select the
      first child. *)
  val tup3_0 : ('a * 'b * 'c, 'a) lens

  (** [tup3_1] is a lens to traverse a 3-tuple node and select the
      second child. *)
  val tup3_1 : ('a * 'b * 'c, 'b) lens

  (** [tup3_2] is a lens to traverse a 3-tuple node and select the
      third child. *)
  val tup3_2 : ('a * 'b * 'c, 'c) lens

  (** [tup4_0] is a lens to traverse a 4-tuple node and select the
      first child. *)
  val tup4_0 : ('a * 'b * 'c * 'd, 'a) lens

  (** [tup4_1] is a lens to traverse a 4-tuple node and select the
      second child. *)
  val tup4_1 : ('a * 'b * 'c * 'd, 'b) lens

  (** [tup4_2] is a lens to traverse a 4-tuple node and select the
      third child. *)
  val tup4_2 : ('a * 'b * 'c * 'd, 'c) lens

  (** [tup4_3] is a lens to traverse a 4-tuple node and select the
      fourth child. *)
  val tup4_3 : ('a * 'b * 'c * 'd, 'd) lens

  (** [tup5_0] is a lens to traverse a 5-tuple node and select the
      first child. *)
  val tup5_0 : ('a * 'b * 'c * 'd * 'e, 'a) lens

  (** [tup5_1] is a lens to traverse a 5-tuple node and select the
      second child. *)
  val tup5_1 : ('a * 'b * 'c * 'd * 'e, 'b) lens

  (** [tup5_2] is a lens to traverse a 5-tuple node and select the
      third child. *)
  val tup5_2 : ('a * 'b * 'c * 'd * 'e, 'c) lens

  (** [tup5_3] is a lens to traverse a 5-tuple node and select the
      fourth child. *)
  val tup5_3 : ('a * 'b * 'c * 'd * 'e, 'd) lens

  (** [tup5_4] is a lens to traverse a 5-tuple node and select the
      fifth child. *)
  val tup5_4 : ('a * 'b * 'c * 'd * 'e, 'e) lens

  (** [entry k] is the lens to traverse a {!dict} node to get the
      subtree behind the key [k]. *)
  val entry : 'a -> (('a, 'b) dict, 'b) lens

  module Schema : sig
    (** A schema is a declarative description of the data model used
        to store a collection of data.

        This module provides an API similar to
        [Data_encoding]. Developers familiar with writing their own
        encoding should not find the functions exported by this module
        surprising. The main limitation of [Schema] compared to
        [Data_encoding] is the absence of [mu], [conv] and [union],
        and the absence of [tupN] ([objN] has to be used
        instead). This is because we focus on tree-like structures
        constructed with tuples and dictionaries. *)
    type !'a t

    (** [encoding e] creates a schema from the encoding [e].

        If [e] cannot decode (resp. encode) a value fetch from
        (resp. to write to) a tree, {!decode} (resp. {!encode}) raises
        an exception. *)
    val encoding : 'a Data_encoding.t -> 'a value t

    (** [custom ~encoder ~decoder] is a combinator to encode to and
        decode from a tree a value of type ['a].

        Using these, it is possible to write schema for the lazy
        structures like {!Lazy_map} and {!Lazy_vector}. *)
    val custom :
      encoder:(tree -> string list -> 'a -> tree Lwt.t) ->
      decoder:(tree -> 'a option Lwt.t) ->
      'a value t

    (** [folders keys schema] pushes the substree described by
        [schema] in the subdirectories described listed in [keys]. *)
    val folders : string list -> 'a t -> 'a t

    (* The remaining of this module follows the same logic as the
       [Data_encoding] combinators. *)

    type !'a field

    val req : string -> 'a t -> 'a field

    val obj2 : 'a field -> 'b field -> ('a * 'b) t

    val obj3 : 'a field -> 'b field -> 'c field -> ('a * 'b * 'c) t

    val obj4 :
      'a field -> 'b field -> 'c field -> 'd field -> ('a * 'b * 'c * 'd) t

    val obj5 :
      'a field ->
      'b field ->
      'c field ->
      'd field ->
      'e field ->
      ('a * 'b * 'c * 'd * 'e) t

    val dict : ('a -> string) -> 'b t -> ('a, 'b) dict t
  end

  type 'a schema = 'a Schema.t

  (** [decode schema tree] initialized a thunk that will needs
      [schema] to determine how to fetch data from [tree] when
      needed. *)
  val decode : 'a schema -> tree -> 'a thunk

  (** [encode tree thunk] updates [tree] according to the modification
      cached in [thunk] including cuts of sub-trees and values
      updates. *)
  val encode : tree -> 'a thunk -> tree Lwt.t

  (** Encoding of lists which can be manipulated through this library
      without the need to read or write the entirety of its
      contents. *)
  module Lazy_list : sig
    type !'a t

    val schema : 'a schema -> 'a t schema

    (** [length thunk] returns the list of the lazy list behind
        [thunk].

        This may require an interaction with the underlying Irmin
        tree. *)
    val length : 'a t thunk -> int32 Lwt.t

    (** [nth ~check i] is a lens to access the [i]th element of a lazy
        list.

        If [check] is [true], then a boundaries check is performed to
        ensure the lazy list has a [i]th element (which may require an
        additional interaction with the underlying Irmin tree). *)
    val nth : check:bool -> int32 -> ('a t, 'a) lens

    (** [alloc_cons thunk] updates [thunk] to make room for a new head
        for the lazy list. It returns (1) the new size of the list,
        and (2) a thunk that can be used to initialize the new head.

        That is, [alloc_cons] does {b not} initialize the “allocated”
        data, meaning {!find} is expected to return [None] on the
        resulting thunks.

        This may require an interaction with the underlying Irmin
        tree. *)
    val alloc_cons : 'a t thunk -> (int32 * 'a thunk) Lwt.t

    (** [cons thunk x] allocates a new head for [thunk] and
        initializes it with [x]., then returns the new size of the
        list.

        This may require an interaction with the underlying Irmin
        tree. *)
    val cons : 'a value t thunk -> 'a -> int32 Lwt.t
  end

  module Syntax : sig
    (** [( ^-> )] is the access arrow operator, chosen to mimic the
        access of a field in a structure in many languages.

        This operator is expected to be used in conjunction with
        [( let*^ )] and [( ^:= )] to get an imperative-like style. *)
    val ( ^-> ) : 'a thunk -> ('a, 'b) lens -> 'b thunk Lwt.t

    (** [( let*^? )] allows to bind a name to the (option-wrapped)
        value behind a thunk selected by a lens. *)
    val ( let*^? ) : 'a value thunk Lwt.t -> ('a option -> 'b Lwt.t) -> 'b Lwt.t

    (** [( let*^? )] allows to bind a name to the value behind a
        thunk selected by a lens.

        It raises [Invalid_argument] if the value is absent. *)
    val ( let*^ ) : 'a value thunk Lwt.t -> ('a -> 'b Lwt.t) -> 'b Lwt.t

    (** [( ^:= )] is the assignment operator, which updates the value
        behind a thunk selected by a lens. *)
    val ( ^:= ) : 'a value thunk Lwt.t -> 'a -> unit Lwt.t
  end
end
