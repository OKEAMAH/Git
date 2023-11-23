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

module Context (C : CONTEXT) = struct
  type 'a index = 'a C.index

  type 'a t = 'a C.t

  type tree = C.tree

  (** Read/write {!type:index}. *)
  type rw_index = [`Read | `Write] index

  (** Read/write context {!t}. *)
  type rw = [`Read | `Write] t

  (** Read-only context {!t}. *)
  type ro = [`Read] t

  type hash = Smart_rollup_context_hash.t

  let load = C.load

  let index = C.index

  let close = C.close

  let checkout = C.checkout

  let empty = C.empty

  let commit = C.commit

  let readonly = C.readonly

  let is_gc_finished = C.is_gc_finished

  let gc = C.gc

  let wait_gc_completion = C.wait_gc_completion

  (** State of the PVM that this rollup node deals with. *)
  module PVMState = struct
    type value = tree

    let empty = C.PVMState.empty

    let find = C.PVMState.find

    let lookup = C.PVMState.lookup

    let set = C.PVMState.set
  end

  module Internal_for_tests = struct
    let get_a_tree = C.Internal_for_tests.get_a_tree
  end
end

include Context (Irmin_context)

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
