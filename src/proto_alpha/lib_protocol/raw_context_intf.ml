(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
(* Copyright (c) 2018-2021 Tarides <contact@tarides.com>                     *)
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

(** All context manipulation functions. This signature is included
    as-is for direct context accesses, and used in {!Storage_functors}
    to provide restricted views to the context. *)

module type VIEW = sig
  (* Same as [Environment_context.VIEW] but with extra getters and
     setters functions. *)

  (** The type for context handler. *)
  type t

  (** The type for context trees. *)
  type tree

  (** The type for context keys. *)
  type key = string list

  (** The type for context values. *)
  type value = bytes

  (** {2 Getters} *)

  (** [mem t k] is an Lwt promise that resolves to [true] iff [k] is bound
      to a value in [t]. *)
  val mem : t -> key -> bool Lwt.t

  (** [mem_tree t k] is like {!mem} but for trees. *)
  val mem_tree : t -> key -> bool Lwt.t

  (** [get t k] is an Lwt promise that resolves to [Ok v] if [k] is
      bound to the value [v] in [t] and {!Storage_Error Missing_key}
      otherwise. *)
  val get : t -> key -> value tzresult Lwt.t

  (** [get_tree] is like {!get} but for trees. *)
  val get_tree : t -> key -> tree tzresult Lwt.t

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

  (** {2 Setters} *)

  (** [init t k v] is an Lwt promise that resolves to [Ok c] if:

      - [k] is unbound in [t];
      - [k] is bound to [v] in [c];
      - and [c] is similar to [t] otherwise.

      It is {!Storage_error Existing_key} if [k] is already bound in [t]. *)
  val init : t -> key -> value -> t tzresult Lwt.t

  (** [init_tree] is like {!init} but for trees. *)
  val init_tree : t -> key -> tree -> t tzresult Lwt.t

  (** [update t k v] is an Lwt promise that resolves to [Ok c] if:

      - [k] is bound in [t];
      - [k] is bound to [v] in [c];
      - and [c] is similar to [t] otherwise.

      It is {!Storage_error Missing_key} if [k] is not already bound in [t]. *)
  val update : t -> key -> value -> t tzresult Lwt.t

  (** [update_tree] is like {!update} but for trees. *)
  val update_tree : t -> key -> tree -> t tzresult Lwt.t

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

  (** [remove_existing t k v] is an Lwt promise that resolves to [Ok c] if:

      - [k] is bound in [t] to a value;
      - [k] is unbound in [c];
      - and [c] is similar to [t] otherwise.*)
  val remove_existing : t -> key -> t tzresult Lwt.t

  (** [remove_existing_tree t k v] is an Lwt promise that reolves to [Ok c] if:

      - [k] is bound in [t] to a tree;
      - [k] is unbound in [c];
      - and [c] is similar to [t] otherwise.*)
  val remove_existing_tree : t -> key -> t tzresult Lwt.t

  (** [add_or_remove t k v] is:

      - [add t k x] if [v] is [Some x];
      - [remove t k] otherwise. *)
  val add_or_remove : t -> key -> value option -> t Lwt.t

  (** [add_or_remove_tree t k v] is:

      - [add_tree t k x] if [v] is [Some x];
      - [remove t k] otherwise. *)
  val add_or_remove_tree : t -> key -> tree option -> t Lwt.t

  (** {2 Folds} *)

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
      - [Ge d] folds over nodes and values of depth more than or equal to [d]. *)
  val fold :
    ?depth:[`Eq of int | `Le of int | `Lt of int | `Ge of int | `Gt of int] ->
    t ->
    key ->
    order:[`Sorted | `Undefined] ->
    init:'a ->
    f:(key -> tree -> 'a -> 'a Lwt.t) ->
    'a Lwt.t
end

module type TREE = sig
  (** [Tree] provides immutable, in-memory partial mirror of the
      context, with lazy reads and delayed writes. The trees are Merkle
      trees that carry the same hash as the part of the context they
      mirror.

      Trees are immutable and non-persistent (they disappear if the
      host crash), held in memory for efficiency, where reads are done
      lazily and writes are done only when needed, e.g. on
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
  val kind : tree -> [`Value | `Tree]

  (** [to_value t] is [Some v] is [t] is a leaf tree and [None] otherwise. *)
  val to_value : tree -> value option Lwt.t

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

module type PROOF = sig
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
      to efficiently implements paginated lists.

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
      of [ls]  is at most 256 (or 2 in the case of binary trees).

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

module type T = sig
  (** The type for root contexts. *)
  type root

  include VIEW

  module Tree :
    TREE
      with type t := t
       and type key := key
       and type value := value
       and type tree := tree

  module Proof : PROOF

  type tree_proof := Proof.tree Proof.t

  type stream_proof := Proof.stream Proof.t

  (** [produce r h f] runs [f] on top of a real store [r], producing a proof
      and a result using the initial root hash [h].

      The trees produced during [f]'s computation will carry the full history
      of reads. This history will be reset when [f] is complete so subtrees
      escaping the scope of [f] will not cause memory leaks.

      Calling [produce_proof] recursively has an undefined behaviour. *)
  type ('proof, 'result) producer :=
    t -> (tree -> (tree * 'result) Lwt.t) -> ('proof * 'result) Lwt.t

  val produce_tree_proof : (tree_proof, 'a) producer

  val produce_stream_proof : (stream_proof, 'a) producer

  (** [verify t f] runs [f] in checking mode, loading data from the proof as
      needed.

      The generated tree is the tree after [f] has completed. More operations
      can be run on that tree, but it won't be able to access the underlying
      storage.

      Raise [Proof.Bad_proof] when the proof is rejected. *)
  type ('proof, 'result) verifier :=
    t ->
    'proof ->
    (tree -> (tree * 'result) Lwt.t) ->
    (tree * 'result, [`Msg of string]) result Lwt.t

  (** [verify_tree_proof] is the verifier of tree proofs. *)
  val verify_tree_proof : (tree_proof, 'a) verifier

  (** [verify_stream_proof] is the verifier of tree proofs. *)
  val verify_stream_proof : (stream_proof, 'a) verifier

  (** Internally used in {!Storage_functors} to escape from a view. *)
  val project : t -> root

  (** Internally used in {!Storage_functors} to retrieve a full key
      from partial key relative a view. *)
  val absolute_key : t -> key -> key

  (** Raised if block gas quota is exhausted during gas
     consumption. *)
  type error += Block_quota_exceeded

  (** Raised if operation gas quota is exhausted during gas
     consumption. *)
  type error += Operation_quota_exceeded

  (** Internally used in {!Storage_functors} to consume gas from
     within a view. May raise {!Block_quota_exceeded} or
     {!Operation_quota_exceeded}. *)
  val consume_gas : t -> Gas_limit_repr.cost -> t tzresult

  (** Check if consume_gas will fail *)
  val check_enough_gas : t -> Gas_limit_repr.cost -> unit tzresult

  val description : t Storage_description.t
end
