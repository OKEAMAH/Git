open Store_sigs

module Witness : sig
  type (_, _) t = ..
end

module type Witness = sig
  type repo

  type tree

  type (_, _) Witness.t += Id : (repo, tree) Witness.t
end

type ('repo, 'tree) witness =
  (module Witness with type repo = 'repo and type tree = 'tree)

type ('a, 'repo) raw_index = {path : string; repo : 'repo}

type ('a, 'repo) index = ('a, 'repo) raw_index
  constraint 'a = [< `Read | `Write > `Read]

type ('a, 'repo, 'tree) context = {index : ('a, 'repo) index; tree : 'tree}

val witness : unit -> ('repo, 'tree) witness

module type CONTEXT = sig
  type repo

  type tree

  type nonrec 'a raw_index =
    ('a, repo) raw_index (* {path : string; repo : repo} *)

  type 'a index = 'a raw_index constraint 'a = [< `Read | `Write > `Read]

  (* type 'a t = {index : 'a index; tree : tree} *)

  (** Read/write {!type:index}. *)
  type rw_index = [`Read | `Write] index

  (** Read/write context {!t}. *)
  type rw = ([`Read | `Write], repo, tree) context

  (** Read-only context {!t}. *)
  type ro = ([`Read], repo, tree) context

  type hash = Smart_rollup_context_hash.t

  val witness : (repo, tree) witness

  (** [load cache_size path] initializes from disk a context from [path].
    [cache_size] allows to change the LRU cache size of Irmin
    (100_000 by default at irmin-pack/config.ml *)
  val load : cache_size:int -> 'a mode -> string -> 'a index tzresult Lwt.t

  (** [index context] is the repository of the context [context]. *)
  val index : ('a, repo, tree) context -> 'a index

  (** [close ctxt] closes the context index [ctxt]. *)
  val close : _ index -> unit Lwt.t

  (** [readonly index] returns a read-only version of the index. *)
  val readonly : [> `Read] index -> [`Read] index

  (** [checkout ctxt hash] checkouts the content that corresponds to the commit
    hash [hash] in the repository [ctxt] and returns the corresponding
    context. If there is no commit that corresponds to [hash], it returns
    [None].  *)
  val checkout : 'a index -> hash -> ('a, repo, tree) context option Lwt.t

  (** [empty ctxt] is the context with an empty content for the repository [ctxt]. *)
  val empty : 'a index -> ('a, repo, tree) context

  (** [commit ?message context] commits content of the context [context] on disk,
    and return the commit hash. *)
  val commit : ?message:string -> ([> `Write], repo, tree) context -> hash Lwt.t

  (** [is_gc_finished index] returns true if a GC is finished (or idle) and false
    if a GC is running for [index]. *)
  val is_gc_finished : [> `Write] index -> bool

  (** [gc index ?callback hash] removes all data older than [hash] from disk.
    If passed, [callback] will be executed when garbage collection finishes. *)
  val gc :
    [> `Write] index -> ?callback:(unit -> unit Lwt.t) -> hash -> unit Lwt.t

  (** [wait_gc_completion index] will return a blocking thread if a
    GC run is currently ongoing. *)
  val wait_gc_completion : [> `Write] index -> unit Lwt.t

  (** State of the PVM that this rollup node deals with *)
  module PVMState : sig
    (** The value of a PVM state *)
    type value = tree

    (** [empty ()] is the empty PVM state. *)
    val empty : unit -> value

    (** [find context] returns the PVM state stored in the [context], if any. *)
    val find : ('a, repo, tree) context -> value option Lwt.t

    (** [lookup state path] returns the data stored for the path [path] in the PVM
      state [state].  *)
    val lookup : value -> string list -> bytes option Lwt.t

    (** [set context state] saves the PVM state [state] in the context and returns
      the updated context. Note: [set] does not perform any write on disk, this
      information must be committed using {!val:commit}. *)
    val set :
      ('a, repo, tree) context -> value -> ('a, repo, tree) context Lwt.t
  end

  module Internal_for_tests : sig
    (** [get_a_tree key] provides a value of internal type [tree] which can be
      used as a state to be set in the context directly. *)
    val get_a_tree : string -> tree Lwt.t
  end
end

type ('repo1, 'tree1, 'repo2, 'tree2) eq =
  | Equal : ('repo1, 'tree1, 'repo1, 'tree1) eq

val try_cast :
  ('a, 'b) witness -> ('c, 'd) witness -> ('a, 'b, 'c, 'd) eq option

val cast_context :
  ('repo, 'tree) witness ->
  (module CONTEXT) ->
  (module CONTEXT with type repo = 'repo and type tree = 'tree)

(* include CONTEXT *)

(** Version of thecontext  *)
module Version : sig
  type t

  (** The current and expected version of the context. *)
  val version : t

  (** The encoding for the context version. *)
  val encoding : t Data_encoding.t

  (** [check v] fails if [v] is different from the expected version of the
      context. *)
  val check : t -> unit tzresult
end

(* module PVMState : sig *)
(*   val set : *)
(*     (module Protocol_plugin_sig.PARTIAL) -> *)
(*     (([< `Read | `Write > `Read] as 'a), 'repo, 'tree) context -> *)
(*     'tree -> *)
(*     ('a, 'repo, 'tree) context Lwt.t *)
(* end *)

type ('a, 'repo, 'tree) t = ('a, 'repo, 'tree) context

(** Read/write context {!t}. *)
type ('repo, 'tree) rw = ([`Read | `Write], 'repo, 'tree) t

(** Read-only context {!t}. *)
type ('repo, 'tree) ro = ([`Read], 'repo, 'tree) t
