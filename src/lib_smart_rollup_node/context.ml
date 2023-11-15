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

type ('a, 'repo) raw_index = {path : string; repo : 'repo}

type ('a, 'repo) index = ('a, 'repo) raw_index
  constraint 'a = [< `Read | `Write > `Read]

type 'repo rw_index = ([`Read | `Write], 'repo) index

type ('a, 'repo, 'tree) context = {
  index : ('a, 'repo) index;
  tree : 'tree;
}
  constraint 'a = [< `Read | `Write > `Read]

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

module Tid = struct
  type 'a t = ..
end

module type Tid = sig
  type t

  type _ Tid.t += Tid : t Tid.t
end

type 'a tid = (module Tid with type t = 'a)

let tid () (type repo tree) =
  let module M = struct
    type t = repo * tree

    type _ Tid.t += Tid : t Tid.t
  end in
  (module M : Tid with type t = repo * tree)

type ('a, 'b) eq = Equal : ('a, 'a) eq

let try_cast : type a b. a tid -> b tid -> (a, b) eq option =
 fun x y ->
  let module X : Tid with type t = a = (val x) in
  let module Y : Tid with type t = b = (val y) in
  match X.Tid with Y.Tid -> Some Equal | _ -> None

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

    (* type 'a index = ('a, Repo.t) raw_index *)
    (*   constraint 'a = [< `Read | `Write > `Read] *)

    (* type 'a context = {index : 'a index; tree : tree} *)

    (* type rw = [`Read | `Write] context *)

    (* type rw_index = [`Read | `Write] index *)

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

module Context_encoding = Tezos_context_encoding.Context_binary

(* We shadow [Tezos_context_encoding] to prevent accidentally using
   [Tezos_context_encoding.Context] instead of
   [Tezos_context_encoding.Context_binary] during a future
   refactoring.*)
module Tezos_context_encoding = struct end

module Maker = Irmin_pack_unix.Maker (Context_encoding.Conf)

module IStore : SMCONTEXT = struct
  let tid = ref None

  module Gc_stats = struct
    type t = Irmin_pack_unix.Stats.Latest_gc.stats

    let total_duration stats =
      Irmin_pack_unix.Stats.Latest_gc.total_duration stats

    let finalise_duration stats =
      Irmin_pack_unix.Stats.Latest_gc.finalise_duration stats
  end

  module Context = struct
    module Store = struct
      include Maker.Make (Context_encoding.Schema)
      module Schema = Context_encoding.Schema
    end

    open Store

    let hash_to_store_hash h =
      Smart_rollup_context_hash.to_string h |> Hash.unsafe_of_raw_string

    let store_hash_to_hash h =
      Hash.to_raw_string h |> Smart_rollup_context_hash.of_string_exn

    let load :
        type a.
        cache_size:int -> a mode -> string -> (a, Repo.t) raw_index Lwt.t =
     fun ~cache_size mode path ->
      let open Lwt_syntax in
      let readonly =
        match mode with Read_only -> true | Read_write -> false
      in
      let+ repo =
        Repo.v
          (Irmin_pack.config
             ~readonly
               (* Note that the use of Gc in the context requires that
                * the [always] indexing strategy not be used. *)
             ~indexing_strategy:Irmin_pack.Indexing_strategy.minimal
             ~lru_size:cache_size
             path)
      in
      {path; repo}

    let close ctxt =
      let _interrupted_gc = Gc.cancel ctxt.repo in
      Repo.close ctxt.repo

    let readonly (index : ([> `Read], Repo.t) index) =
      (index :> ([`Read], Repo.t) index)

    let raw_commit ?(message = "") index tree =
      let info = Info.v ~author:"Tezos" 0L ~message in
      Commit.v index.repo ~info ~parents:[] tree

    let commit ?message ctxt =
      let open Lwt_syntax in
      let+ commit = raw_commit ?message ctxt.index ctxt.tree in
      Commit.hash commit |> store_hash_to_hash

    let checkout index key =
      let open Lwt_syntax in
      let* o = Commit.of_hash index.repo (hash_to_store_hash key) in
      match o with
      | None -> return_none
      | Some commit ->
          let tree = Commit.tree commit in
          return_some {index; tree}

    let empty index = {index; tree = Tree.empty ()}

    let is_empty ctxt = Tree.is_empty ctxt.tree

    let gc index ?(callback : unit -> unit Lwt.t = fun () -> Lwt.return ())
        (hash : Smart_rollup_context_hash.t) =
      let open Lwt_syntax in
      let repo = index.repo in
      let istore_hash = hash_to_store_hash hash in
      let* commit_opt = Commit.of_hash index.repo istore_hash in
      match commit_opt with
      | None ->
          Fmt.failwith
            "%a: unknown context hash"
            Smart_rollup_context_hash.pp
            hash
      | Some commit -> (
          let finished = function
            | Ok (stats : Gc_stats.t) ->
                let total_duration = Gc_stats.total_duration stats in
                let finalise_duration = Gc_stats.finalise_duration stats in
                let* () = callback () in
                Event.ending_context_gc
                  ( Time.System.Span.of_seconds_exn total_duration,
                    Time.System.Span.of_seconds_exn finalise_duration )
            | Error (`Msg err) -> Event.context_gc_failure err
          in
          let commit_key = Commit.key commit in
          let* launch_result = Gc.run ~finished repo commit_key in
          match launch_result with
          | Error (`Msg err) -> Event.context_gc_launch_failure err
          | Ok false -> Event.context_gc_already_launched ()
          | Ok true -> Event.starting_context_gc hash)

    let wait_gc_completion index =
      let open Lwt_syntax in
      let* r = Gc.wait index.repo in
      match r with
      | Ok _stats_opt -> return_unit
      | Error (`Msg _msg) ->
          (* Logs will be printed by the [gc] caller. *)
          return_unit

    let is_gc_finished index = Gc.is_finished index.repo

    let index context = context.index
  end

  module IStoreTree =
    Tezos_context_helpers.Context.Make_tree
      (Context_encoding.Conf)
      (Context.Store)

  module Proof (Hash : sig
    type t

    val of_context_hash : Context_hash.t -> t
  end) (Proof_encoding : sig
    val proof_encoding :
      Tezos_context_sigs.Context.Proof_types.tree
      Tezos_context_sigs.Context.Proof_types.t
      Data_encoding.t
  end) =
  struct
    module IStoreProof =
      Tezos_context_helpers.Context.Make_proof
        (Context.Store)
        (Context_encoding.Conf)

    module Tree = struct
      include IStoreTree

      type t = Context.Store.Repo.t rw_index

      type tree = Context.Store.tree

      type key = path

      type value = bytes
    end

    type tree = Tree.tree

    type proof = IStoreProof.Proof.tree IStoreProof.Proof.t

    let hash_tree tree = Hash.of_context_hash (Tree.hash tree)

    let proof_encoding = Proof_encoding.proof_encoding

    let proof_before proof =
      let (`Value hash | `Node hash) = proof.IStoreProof.Proof.before in
      Hash.of_context_hash hash

    let proof_after proof =
      let (`Value hash | `Node hash) = proof.IStoreProof.Proof.after in
      Hash.of_context_hash hash

    let produce_proof index tree step =
      let open Lwt_syntax in
      (* Committing the context is required by Irmin to produce valid proofs. *)
      let* _commit_key = Context.raw_commit index tree in
      match Tree.kinded_key tree with
      | Some k ->
          let* p = IStoreProof.produce_tree_proof index.repo k step in
          return_some p
      | None -> return_none

    let verify_proof proof step =
      (* The rollup node is not supposed to verify proof. We keep
         this part in case this changes in the future. *)
      let open Lwt_syntax in
      let* result = IStoreProof.verify_tree_proof proof step in
      match result with
      | Ok v -> return_some v
      | Error _ ->
          (* We skip the error analysis here since proof verification is not a
             job for the rollup node. *)
          return_none
  end

  module Version = struct
    type t = V0

    let version = V0

    let encoding =
      let open Data_encoding in
      conv_with_guard
        (fun V0 -> 0)
        (function
          | 0 -> Ok V0
          | v -> Error ("Unsupported context version " ^ string_of_int v))
        int31

    let check = function V0 -> Result.return_unit
  end

  (** State of the PVM that this rollup node deals with. *)
  module PVMState = struct
    open Context

    (* type value = Context.Store.tree *)

    let key = ["pvm_state"]

    let empty () = Context.Store.Tree.empty ()

    let find ctxt = Store.Tree.find_tree ctxt.tree key

    let lookup tree path = Store.Tree.find tree path

    let set ctxt state =
      let open Lwt_syntax in
      let+ tree = Store.Tree.add_tree ctxt.tree key state in
      {ctxt with tree}
  end

  let load :
      type a.
      cache_size:int -> a mode -> string -> (a, 'repo) raw_index tzresult Lwt.t
      =
   fun ~cache_size mode path ->
    let open Lwt_result_syntax in
    let*! index = Context.load ~cache_size mode path in
    return index
end

(* adapted from lib_context/disk/context.ml *)

(** State of the PVM that this rollup node deals with. *)

module Version = struct
  type t = V0

  let version = V0

  let encoding =
    let open Data_encoding in
    conv_with_guard
      (fun V0 -> 0)
      (function
        | 0 -> Ok V0
        | v -> Error ("Unsupported context version " ^ string_of_int v))
      int31

  let check = function V0 -> Result.return_unit
end

let checkout :
    type repo tree.
    (module SMCONTEXT
       with type Context.Store.repo = repo
        and type Context.Store.tree = tree) ->
    ('a, repo) index ->
    Smart_rollup_context_hash.t ->
    ('a, repo, tree) context option Lwt.t =
 fun (module Ctx) index key -> Ctx.Context.checkout index key

let close :
    type repo tree.
    (module SMCONTEXT with type Context.Store.repo = repo) ->
    (_, repo) index ->
    unit Lwt.t =
 fun (module Ctx) -> Ctx.Context.close
