(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
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

(** View over the context store, restricted to types, access and
    functional manipulation of an existing context. *)

(* Copy/paste of Environment_context_sigs.Context.S *)

(** The tree depth of a fold. See the [fold] function for more information. *)
type depth = [`Eq of int | `Le of int | `Lt of int | `Ge of int | `Gt of int]

module type VIEW = sig
  (** The type for context views. *)
  type t

  (** The type for context keys. *)
  type key

  (** The type for context values. *)
  type value

  (** The type for context trees. *)
  type tree

  (** {2 Getters} *)

  (** [mem t k] is an Lwt promise that resolves to [true] iff [k] is bound
      to a value in [t]. *)
  val mem : t -> key -> bool Lwt.t

  (** [mem_tree t k] is like {!mem} but for trees. *)
  val mem_tree : t -> key -> bool Lwt.t

  (** [find t k] is an Lwt promise that resolves to [Some v] if [k] is
      bound to the value [v] in [t] and [None] otherwise. *)
  val find : t -> key -> value option Lwt.t

  (** [find_tree t k] is like {!find} but for trees. *)
  val find_tree : t -> key -> tree option Lwt.t

  (** [list t key] is the list of files and sub-nodes stored under [k] in [t].
      The result order is not specified but is stable.

      [offset] and [length] are used for pagination. *)
  val list :
    t -> ?offset:int -> ?length:int -> key -> (string * tree) list Lwt.t

  (** [length t key] is an Lwt promise that resolve to the number of
      files and sub-nodes stored under [k] in [t].

      It is equivalent to [list t k >|= List.length] but has a
      constant-time complexity. *)
  val length : t -> key -> int Lwt.t

  (** {2 Setters} *)

  (** [add t k v] is an Lwt promise that resolves to [c] such that:

    - [k] is bound to [v] in [c];
    - and [c] is similar to [t] otherwise.

    If [k] was already bound in [t] to a value that is physically equal
    to [v], the result of the function is a promise that resolves to
    [t]. Otherwise, the previous binding of [k] in [t] disappears. *)
  val add : t -> key -> value -> t Lwt.t

  (** [add_tree] is like {!add} but for trees. *)
  val add_tree : t -> key -> tree -> t Lwt.t

  (** [remove t k v] is an Lwt promise that resolves to [c] such that:

    - [k] is unbound in [c];
    - and [c] is similar to [t] otherwise. *)
  val remove : t -> key -> t Lwt.t

  (** {2 Folding} *)

  (** [fold ?depth t root ~init ~f] recursively folds over the trees
      and values of [t]. The [f] callbacks are called with a key relative
      to [root]. [f] is never called with an empty key for values; i.e.,
      folding over a value is a no-op.

      Elements are traversed in lexical order of keys.

      The depth is 0-indexed. If [depth] is set (by default it is not), then [f]
      is only called when the conditions described by the parameter is true:

      - [Eq d] folds over nodes and values of depth exactly [d].
      - [Lt d] folds over nodes and values of depth strictly less than [d].
      - [Le d] folds over nodes and values of depth less than or equal to [d].
      - [Gt d] folds over nodes and values of depth strictly more than [d].
      - [Ge d] folds over nodes and values of depth more than or equal to [d].

      If [order] is [`Sorted] (the default), the elements are traversed in
      lexicographic order of their keys. For large nodes, these two modes are memory-consuming,
      use [`Undefined] for a more memory efficient [fold]. *)
  val fold :
    ?depth:depth ->
    t ->
    key ->
    order:[`Sorted | `Undefined] ->
    init:'a ->
    f:(key -> tree -> 'a -> 'a Lwt.t) ->
    'a Lwt.t
end

module Proof : sig
  (** Proofs are compact representations of trees which can be shared
      between a node and a client.

      This is expected to be used as follows:

      - The node runs a function [f] over a tree [t]. While performing
        this computation, the node records: the hash of [t] (called [before]
        below), the hash of [f t] (called [after] below) and a subset of [t]
        which is needed to replay [f] without any access to the node's storage.
        Once done, the node packs this into a proof [p] and sends this to the
        client.

      - The client generates an initial tree [t'] from [p] and computes [f t'].
        Once done, it compares [t']'s hash and [f t']'s hash to [before] and
        [after]. If they match, they know that the result state [f t'] is a
        valid context state, without having to have access to the full node's
        storage. *)

  (** The type for file and directory names. *)
  type step = string

  (** The type for values. *)
  type value = bytes

  (** The type of children indexers in inodes. *)
  type side = int

  (** The type for hashes. *)
  type hash = Context_hash.t

  (** The type for (internal) inode proofs.

      These proofs encode large directories into a more efficient tree-like
      structure.

      [length] is the total number of entries in the chidren of the inode.
      It's the size of the "flattened" version of that inode. This is used
      to efficiently implement paginated lists.

      [proofs] have a length of at most 32 entries (or 2 in case of binary
      trees). This list can be sparse so every proof is indexed by their
      position between [0 ... (32 - 1)]. For binary trees, this boolean index is
      a side of the left-right decision proof corresponding to the path in that
      binary tree. *)
  type 'a inode = {length : int; proofs : (side * 'a) list}

  (** The type for inode extenders. *)
  type 'a inode_extender = {length : int; segment : side list; proof : 'a}
  [@@deriving irmin]

  (** The type for inode trees.

      Inodes are optimized representations of trees. Pointers in that trees
      would refer to blinded nodes, nodes or to other inodes.
      Neither blinded values nor values are not expected to appear directly in
      an inode tree. *)
  type inode_tree =
    | Blinded_inode of hash
    | Inode_values of (step * tree) list
    | Inode_tree of inode_tree inode
    | Inode_extender of inode_tree inode_extender

  (** The type for compressed and partial Merkle tree proofs.

      [Blinded_value h] is a shallow pointer to a value with hash [h].
      [Value v] is the value [v].

      Tree proofs do not provide any guarantee with the ordering of
      computations. For instance, if two effects commute, they won't be
      distinguishable by this kind of proofs.

      [Blinded_node h] is a shallow pointer to a node having hash [h].

      [Node ls] is a "flat" node containing the list of files [ls]. The length
      of [ls] is at most 256 (or 2 in the case of binary trees).

      [Inode i] is an optimized representation of a node as a tree. *)
  and tree =
    | Value of value
    | Blinded_value of hash
    | Node of (step * tree) list
    | Blinded_node of hash
    | Inode of inode_tree inode
    | Extender of inode_tree inode_extender

  (** The type for kinded hashes. *)
  type kinded_hash = [`Value of hash | `Node of hash]

  module Stream : sig
    (** The type for elements of stream proofs. *)
    type elt =
      | Value of value
      | Node of (step * kinded_hash) list
      | Inode of hash inode
      | Inode_extender of hash inode_extender

    (** The type for stream proofs. Stream poofs provides stronger ordering
      guarantees as the read effects have to happen in the exact same order and
      they are easier to verify. *)
    type t = elt Seq.t
  end

  type stream = Stream.t

  (** The type for proofs of kind ['a].

       A proof [p] proves that the state advanced from [before p] to
       [after p]. [state p]'s hash is [before p], and [state p] contains
       the minimal information for the computation to reach [after p].
       [version p] is the proof version.*)
  type 'a t = {
    version : int;
    before : kinded_hash;
    after : kinded_hash;
    state : 'a;
  }
end

module Kind : sig
  type t = [`Value | `Tree]
end

module type TREE = sig
  (** [Tree] provides immutable, in-memory partial mirror of the
      context, with lazy reads and delayed writes.

      Trees are immutable and non-persistent (they disappear if the
      host crash), held in memory for efficiency, where reads are done
      lazily and writes are done only when needed on
      [Context.commit]. If a key is modified twice, only the last
      value will be written to disk on commit. *)

  (** The type for context views. *)
  type t

  (** The type for context trees. *)
  type tree

  include VIEW with type t := tree and type tree := tree

  (** [empty _] is the empty tree. *)
  val empty : t -> tree

  (** [is_empty t] is true iff [t] is [empty _]. *)
  val is_empty : tree -> bool

  (** [kind t] is [t]'s kind. It's either a tree node or a leaf
      value. *)
  val kind : tree -> Kind.t

  (** [to_value t] is an Lwt promise that resolves to [Some v] if [t]
      is a leaf tree and [None] otherwise. It is equivalent to [find t
      []]. *)
  val to_value : tree -> value option Lwt.t

  (** [of_value _ v] is an Lwt promise that resolves to the leaf tree
      [v]. Is is equivalent to [add (empty _) [] v]. *)
  val of_value : t -> value -> tree Lwt.t

  (** [hash t] is [t]'s Merkle hash. *)
  val hash : tree -> Context_hash.t

  (** [equal x y] is true iff [x] and [y] have the same Merkle hash. *)
  val equal : tree -> tree -> bool

  (** {2 Caches} *)

  (** [clear ?depth t] clears all caches in the tree [t] for subtrees with a
      depth higher than [depth]. If [depth] is not set, all of the subtrees are
      cleared. *)
  val clear : ?depth:int -> tree -> unit
end

include VIEW with type key = string list and type value = bytes

module Tree :
  TREE
    with type t := t
     and type key := key
     and type value := value
     and type tree := tree

type tree_proof := Proof.tree Proof.t

type stream_proof := Proof.stream Proof.t

(** [verify t f] runs [f] in checking mode, loading data from the proof as
    needed.

    The generated tree is the tree after [f] has completed. More operations can
    be run on that tree, but it won't be able to access the underlying storage.

    Raise [Proof.Bad_proof] when the proof is rejected. *)
type ('proof, 'result) verifier :=
  t ->
  'proof ->
  (tree -> (tree * 'result) Lwt.t) ->
  (tree * 'result, [`Msg of string]) result Lwt.t

(** [verify_tree_proof] is the verifier of tree proofs. *)
val verify_tree_proof : (tree_proof, 'a) verifier

(** [verify_stream] is the verifier of stream proofs. *)
val verify_stream_proof : (stream_proof, 'a) verifier

(** [produce t h f] runs [f] on top of a real store [t], producing a proof
    and a result using the initial root hash [h].

    Note that all bytes read or written during evaluation of [f] may increase
    the size of the resulting proof. Proofs are stored in memory, not on disk,
    so the caller must take care not to exceed available resources.

    It is acceptable to read/write more bytes than fits in memory over multiple
    calls to [produce_tree_proof] or [produce_stream_proof], as long as the
    resulting proofs can be reclaimed by the garbage collector.

    Calling [produce_proof] recursively has an undefined behaviour. *)
type ('proof, 'result) producer :=
  t -> (tree -> (tree * 'result) Lwt.t) -> ('proof * 'result) Lwt.t

(** [produce_tree_proof] is the producer of tree proofs. Calling
    [produce_tree_proof] recursively has an undefined behaviour. *)
val produce_tree_proof : (tree_proof, 'a) producer

(** [produce_stream_proof] is the producer of stream proofs. Calling
    [produce_stream_proof] recursively has an undefined behaviour. *)
val produce_stream_proof : (stream_proof, 'a) producer

val register_resolver :
  'a Base58.encoding -> (t -> string -> 'a list Lwt.t) -> unit

val complete : t -> string -> string list Lwt.t

(** Get the hash version used for the context *)
val get_hash_version : t -> Context_hash.Version.t

(** Set the hash version used for the context.  It may recalculate the hashes
    of the whole context, which can be a long process.
    Returns an Error if the hash version is unsupported. *)
val set_hash_version :
  t -> Context_hash.Version.t -> t Error_monad.shell_tzresult Lwt.t

type cache_key

type cache_value = ..

module type CACHE = sig
  (** Type for context view. A context contains a cache. A cache is
     made of subcaches. Each subcache has its own size limit. The
     limit of its subcache is called a layout and can be initialized
     via the [set_cache_layout] function. *)
  type t

  (** Size for subcaches and values of the cache. Units are not
     specified and left to the economic protocol. *)
  type size

  (** Index type to index caches. *)
  type index

  (** Identifier type for keys. *)
  type identifier

  (** A key uniquely identifies a cached [value] in some subcache. *)
  type key

  (** Cached values inhabit an extensible type. *)
  type value = ..

  (** [key_of_identifier ~cache_index identifier] builds a key from the
      [cache_index] and the [identifier].

      No check are made to ensure the validity of the index.  *)
  val key_of_identifier : cache_index:index -> identifier -> key

  (** [identifier_of_key key] returns the identifier associated to the
      [key]. *)
  val identifier_of_key : key -> identifier

  (** [pp fmt cache] is a pretty printter for a [cache]. *)
  val pp : Format.formatter -> t -> unit

  (** [find ctxt k = Some v] if [v] is the value associated to [k] in
     in the cache where [k] is. Returns [None] if there is no such
     value in the cache of [k].  This function is in the Lwt monad
     because if the value has not been constructed, it is constructed
     on the fly. *)
  val find : t -> key -> value option Lwt.t

  (** [set_cache_layout ctxt layout] sets the caches of [ctxt] to
     comply with given [layout]. If there was already a cache in
     [ctxt], it is erased by the new layout.

     Otherwise, a fresh collection of empty caches is reconstructed
     from the new [layout]. Notice that cache [key]s are invalidated
     in that case, i.e., [get t k] will return [None]. *)
  val set_cache_layout : t -> size list -> t Lwt.t

  (** [update ctxt k (Some (e, size))] returns a cache where the value
      [e] of [size] is associated to key [k]. If [k] is already in the
      cache, the cache entry is updated.

      [update ctxt k None] removes [k] from the cache. *)
  val update : t -> key -> (value * size) option -> t

  (** [sync ctxt ~cache_nonce] updates the context with the domain of
     the cache computed so far. Such function is expected to be called
     at the end of the validation of a block, when there is no more
     accesses to the cache.

     [cache_nonce] identifies the block that introduced new cache
     entries. The nonce should identify uniquely the block which
     modifies this value. It cannot be the block hash for circularity
     reasons: The value of the nonce is stored onto the context and
     consequently influences the context hash of the very same
     block. Such nonce cannot be determined by the shell and its
     computation is delegated to the economic protocol.
  *)
  val sync : t -> cache_nonce:Bytes.t -> t Lwt.t

  (** [clear ctxt] removes all cache entries. *)
  val clear : t -> t

  (** {3 Cache introspection} *)

  (** [list_keys ctxt ~cache_index] returns the list of cached keys in
     cache numbered [cache_index] along with their respective
     [size]. The returned list is sorted in terms of their age in the
     cache, the oldest coming first. If [cache_index] is invalid,
     then this function returns [None]. *)
  val list_keys : t -> cache_index:index -> (key * size) list option

  (** [key_rank index ctxt key] returns the number of cached value older
       than the given [key]; or, [None] if the [key] is not a cache key. *)
  val key_rank : t -> key -> int option

  (** {3 Cache helpers for RPCs} *)

  (** [future_cache_expectation ctxt ~time_in_blocks] returns [ctxt] except
      that the entries of the caches that are presumably too old to
      still be in the caches in [n_blocks] are removed.

      This function is based on a heuristic. The context maintains
      the median of the number of removed entries: this number is
      multipled by `n_blocks` to determine the entries that are
      likely to be removed in `n_blocks`. *)
  val future_cache_expectation : t -> time_in_blocks:int -> t

  (** [cache_size ctxt ~cache_index] returns an overapproximation of
      the size of the cache. Returns [None] if [cache_index] is not a
      valid cache index. *)
  val cache_size : t -> cache_index:index -> size option

  (** [cache_size_limit ctxt ~cache_index] returns the maximal size of
      the cache indexed by [cache_index]. Returns [None] if
      [cache_index] is not a valid cache index. *)
  val cache_size_limit : t -> cache_index:index -> size option
end

module Cache :
  CACHE
    with type t := t
     and type size := int
     and type index := int
     and type identifier := string
     and type key = cache_key
     and type value = cache_value
