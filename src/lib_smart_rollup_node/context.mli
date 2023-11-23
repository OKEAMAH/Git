open Store_sigs

module type CONTEXT = sig
  type 'a index constraint 'a = [< `Read | `Write > `Read]

  type 'a t constraint 'a = [< `Read | `Write > `Read]

  type tree

  type hash = Smart_rollup_context_hash.t

  (** [load cache_size path] initializes from disk a context from [path].
    [cache_size] allows to change the LRU cache size of Irmin
    (100_000 by default at irmin-pack/config.ml *)
  val load : cache_size:int -> 'a mode -> string -> 'a index tzresult Lwt.t

  (** [index context] is the repository of the context [context]. *)
  val index : 'a t -> 'a index

  (** [close ctxt] closes the context index [ctxt]. *)
  val close : _ index -> unit Lwt.t

  (** [readonly index] returns a read-only version of the index. *)
  val readonly : [> `Read] index -> [`Read] index

  (** [checkout ctxt hash] checkouts the content that corresponds to the commit
    hash [hash] in the repository [ctxt] and returns the corresponding
    context. If there is no commit that corresponds to [hash], it returns
    [None].  *)
  val checkout : 'a index -> hash -> 'a t option Lwt.t

  (** [empty ctxt] is the context with an empty content for the repository [ctxt]. *)
  val empty : 'a index -> 'a t

  (** [commit ?message context] commits content of the context [context] on disk,
    and return the commit hash. *)
  val commit : ?message:string -> [> `Write] t -> hash Lwt.t

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
    val find : _ t -> value option Lwt.t

    (** [lookup state path] returns the data stored for the path [path] in the PVM
      state [state].  *)
    val lookup : value -> string list -> bytes option Lwt.t

    (** [set context state] saves the PVM state [state] in the context and returns
      the updated context. Note: [set] does not perform any write on disk, this
      information must be committed using {!val:commit}. *)
    val set : 'a t -> value -> 'a t Lwt.t
  end

  module Internal_for_tests : sig
    (** [get_a_tree key] provides a value of internal type [tree] which can be
      used as a state to be set in the context directly. *)
    val get_a_tree : string -> tree Lwt.t
  end
end

include
  CONTEXT
    with type 'a index = 'a Irmin_context.index
     and type 'a t = 'a Irmin_context.t
     and type tree = Irmin_context.tree

(** Read/write {!type:index}. *)
type rw_index = [`Read | `Write] index

(** Read/write context {!t}. *)
type rw = [`Read | `Write] t

(** Read-only context {!t}. *)
type ro = [`Read] t

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
