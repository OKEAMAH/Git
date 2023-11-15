(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Marigold <contact@marigold.dev>                        *)
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

open Store_sigs

type ('a, 'repo) raw_index = {path : string; repo : 'repo (*Repo.t *)}

type ('a, 'repo) index = ('a, 'repo) raw_index
  constraint 'a = [< `Read | `Write > `Read]

type 'repo rw_index = ([`Read | `Write], 'repo) index

type ('a, 'repo, 'tree) context = {index : ('a, 'repo) index; tree : 'tree}

(** Read-only context {!t}. *)
type ('repo, 'tree) ro = ([`Read], 'repo, 'tree) context

type ('repo, 'tree) rw = ([`Read | `Write], 'repo, 'tree) context

(** Version of the context  *)
module type VERSION = sig
  type t

  (** The current and expected version of the context. *)
  val version : t

  (** The encoding for the context version. *)
  val encoding : t Data_encoding.t

  (** [check v] fails if [v] is different from the expected version of the
      context. *)
  val check : t -> unit tzresult
end

module Version : VERSION

module Tid : sig
  type 'a t = ..
end

module type Tid = sig
  type t

  type _ Tid.t += Tid : t Tid.t
end

type 'a tid = (module Tid with type t = 'a)

val tid : unit -> ('repo * 'tree) tid

type ('a, 'b) eq = Equal : ('a, 'a) eq

val try_cast : 'a tid -> 'b tid -> ('a, 'b) eq option

module type SMCONTEXT = sig
  module Gc_stats : sig
    type t

    val total_duration : t -> float

    val finalise_duration : t -> float
  end

  module Context : sig
    module Store : sig
      include Tezos_context_helpers.Context.DB

      module Gc : sig
        type msg = [`Msg of step]

        val is_finished : repo -> bool

        val cancel : repo -> bool

        val wait : repo -> (Gc_stats.t option, msg) result Lwt.t

        val run :
          ?finished:((Gc_stats.t, msg) result -> metadata Lwt.t) ->
          repo ->
          commit_key ->
          (bool, msg) result Lwt.t
      end
    end

    open Store

    (** [load cache_size path] initializes from disk a context from [path].
    [cache_size] allows to change the LRU cache size of Irmin
    (100_000 by default at irmin-pack/config.ml *)
    val load : cache_size:int -> 'a mode -> string -> ('a, Repo.t) index Lwt.t

    (** [index context] is the repository of the context [context]. *)
    val index : ('a, 'repo, _) context -> ('a, 'repo) index

    (** [close ctxt] closes the context index [ctxt]. *)
    val close : (_, Repo.t) index -> unit Lwt.t

    (** [readonly index] returns a read-only version of the index. *)
    val readonly : ([> `Read], Repo.t) index -> ([`Read], Repo.t) index

    (** [raw_commit ?message ctxt tree] commits the [tree] in the context repository
    [ctxt] on disk, and return the commit. *)
    val raw_commit :
      ?message:string -> ([> `Write], Repo.t) index -> tree -> commit Lwt.t

    (** [commit ?message context] commits content of the context [context] on disk,
      and return the commit hash. *)
    val commit :
      ?message:string ->
      ([> `Write], Repo.t, tree) context ->
      Smart_rollup_context_hash.t Lwt.t

    (** [checkout ctxt hash] checkouts the content that corresponds to the commit
    hash [hash] in the repository [ctxt] and returns the corresponding
    context. If there is no commit that corresponds to [hash], it returns
    [None].  *)
    val checkout :
      ('a, Repo.t) index ->
      Smart_rollup_context_hash.t ->
      ('a, Repo.t, tree) context option Lwt.t

    (** [empty ctxt] is the context with an empty content for the repository [ctxt]. *)
    val empty : ('a, Repo.t) index -> ('a, Repo.t, tree) context

    (** [is_empty context] returns [true] iff the context content of [context] is
    empty. *)
    val is_empty : ('a, Repo.t, tree) context -> bool

    (** [gc index ?callback hash] removes all data older than [hash] from disk.
    If passed, [callback] will be executed when garbage collection finishes. *)
    val gc :
      ([> `Write], Repo.t) index ->
      ?callback:(unit -> unit Lwt.t) ->
      Smart_rollup_context_hash.t ->
      unit Lwt.t

    (** [is_gc_finished index] returns true if a GC is finished (or idle) and false
    if a GC is running for [index]. *)
    val is_gc_finished : ([> `Write], Repo.t) index -> bool

    (** [wait_gc_completion index] will return a blocking thread if a
    GC run is currently ongoing. *)
    val wait_gc_completion : ([> `Write], Repo.t) index -> unit Lwt.t
  end

  (** Module for generating and verifying proofs for a context *)
  module Proof (Hash : sig
    type t

    val of_context_hash : Context_hash.t -> t
  end) (Proof_encoding : sig
    val proof_encoding :
      Tezos_context_sigs.Context.Proof_types.tree
      Tezos_context_sigs.Context.Proof_types.t
      Data_encoding.t
  end) : sig
    (** Tree representation for proof generation.

      NOTE: The index needs to be accessed with write permissions because we
      need to commit on disk to generate the proofs (e.g. in
      {!Inbox.produce_proof}, {!PVM.produce_proof}. or
      {!PVM.produce_output_proof}). *)
    module Tree :
      Tezos_context_sigs.Context.TREE
        with type key = string list
         and type value = bytes
         and type t = Context.Store.Repo.t rw_index
         and type tree = Context.Store.tree

    type tree = Tree.tree

    (** See {!Sc_rollup_PVM_sem.proof} *)
    type proof

    val hash_tree : tree -> Hash.t

    (** See {!Sc_rollup_PVM_sem.proof_encoding} *)
    val proof_encoding : proof Data_encoding.t

    (** [proof_before proof] is the hash of the state before the step that
      generated [rpoof].  *)
    val proof_before : proof -> Hash.t

    (** [proof_after proof] is the hash of the state after the step that generated
      [rpoof].  *)
    val proof_after : proof -> Hash.t

    (** [produce_proof ctxt tree f] produces and returns a proof for the execution
      of [f] on the state [tree]. *)
    val produce_proof :
      Context.Store.Repo.t rw_index ->
      tree ->
      (tree -> (tree * 'a) Lwt.t) ->
      (proof * 'a) option Lwt.t

    (** [verify_proof proof f] verifies that [f] produces the proof [proof] and
      returns the resulting [tree], or [None] if the proof cannot be
      verified. *)
    val verify_proof :
      proof -> (tree -> (tree * 'a) Lwt.t) -> (tree * 'a) option Lwt.t
  end

  (** State of the PVM that this rollup node deals with *)
  module PVMState : sig
    (** The value of a PVM state *)
    (* type value (\* = Context.Store.tree *\) *)

    (** [empty ()] is the empty PVM state. *)
    val empty : unit -> (*value*) Context.Store.tree

    (** [find context] returns the PVM state stored in the [context], if any. *)
    val find :
      ('a, Context.Store.repo, Context.Store.tree) context ->
      (*value*) Context.Store.tree option Lwt.t

    (** [lookup state path] returns the data stored for the path [path] in the PVM
      state [state].  *)
    val lookup :
      (*value*) Context.Store.tree -> string list -> bytes option Lwt.t

    (** [set context state] saves the PVM state [state] in the context and returns
      the updated context. Note: [set] does not perform any write on disk, this
      information must be committed using {!val:commit}. *)
    val set :
      ('a, Context.Store.repo, Context.Store.tree) context ->
      (*value*) Context.Store.tree ->
      ('a, Context.Store.repo, Context.Store.tree) context Lwt.t
  end

  val load :
    cache_size:int ->
    'a mode ->
    string ->
    ('a, Context.Store.Repo.t) raw_index tzresult Lwt.t

  val tid : (Context.Store.repo * Context.Store.tree) tid option ref

  module Version : VERSION
end

(** [checkout ctxt hash] checkouts the content that corresponds to the commit
    hash [hash] in the repository [ctxt] and returns the corresponding
    context. If there is no commit that corresponds to [hash], it returns
    [None].  *)
val checkout :
  (module SMCONTEXT
     with type Context.Store.repo = 'repo
      and type Context.Store.tree = 'tree) ->
  ('a, 'repo) index ->
  Smart_rollup_context_hash.t ->
  ('a, 'repo, 'tree) context option Lwt.t

(** [close ctxt] closes the context index [ctxt]. *)
val close :
  (module SMCONTEXT with type Context.Store.repo = 'repo) ->
  (_, 'repo) index ->
  unit Lwt.t

module IStore : SMCONTEXT
