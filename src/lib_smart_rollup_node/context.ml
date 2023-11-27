open Store_sigs

module Witness = struct
  type (_, _) t = ..
end

module type Witness = sig
  type repo

  type tree

  type (_, _) Witness.t += Id : (repo, tree) Witness.t
end

type ('repo, 'tree) witness =
  (module Witness with type repo = 'repo and type tree = 'tree)

let witness () (type repo tree) =
  let module M = struct
    type nonrec repo = repo

    type nonrec tree = tree

    type (_, _) Witness.t += Id : (repo, tree) Witness.t
  end in
  (module M : Witness with type repo = repo and type tree = tree)

type ('repo1, 'tree1, 'repo2, 'tree2) eq =
  | Equal : ('repo1, 'tree1, 'repo1, 'tree1) eq

let try_cast :
    type a b c d. (a, b) witness -> (c, d) witness -> (a, b, c, d) eq option =
 fun x y ->
  let module X : Witness with type repo = a and type tree = b = (val x) in
  let module Y : Witness with type repo = c and type tree = d = (val y) in
  match X.Id with Y.Id -> Some Equal | _ -> None

type ('a, 'repo) raw_index = {path : string; repo : 'repo}

type ('a, 'repo) index = ('a, 'repo) raw_index
  constraint 'a = [< `Read | `Write > `Read]

type ('a, 'repo, 'tree) context = {index : ('a, 'repo) index; tree : 'tree}

module type CONTEXT = sig
  type repo

  type tree

  type nonrec 'a raw_index = ('a, repo) raw_index

  type 'a index = 'a raw_index constraint 'a = [< `Read | `Write > `Read]

  type 'a t = {index : 'a index; tree : tree}

  (** Read/write {!type:index}. *)
  type rw_index = [`Read | `Write] index

  (** Read/write context {!t}. *)
  type rw = [`Read | `Write] t

  (** Read-only context {!t}. *)
  type ro = [`Read] t

  val witness : (repo, tree) witness

  (* val t_of_context : 'a t -> _ context *)

  (* val context_of_t : _ context -> 'a t *)

  (* val index_of_context : ('a, 'repo) raw_index -> ('a, 'repo) context *)

  (* val context_of_index : ('a, 'repo) context -> ('a, 'repo) raw_index *)

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

(* module Context (C : CONTEXT) = struct *)

(*   type ('a, 'repo) index = ('a, 'repo) C.index *)

(*   type 'a t = 'a C.t *)

(*   type (_,_) context += Index : ('a, 'repo) C.raw_index -> ('repo , 'tree) context *)

(*   let t_of_context (Index *)

(*   val context_of_t : _ context -> 'a t *)

(*   val index_of_context : 'a index -> _ context *)

(*   val context_of_index : _ context -> 'a index *)

(*   (\** Read/write {!type:index}. *\) *)
(*   type rw_index = [`Read | `Write] index *)

(*   (\** Read/write context {!t}. *\) *)
(*   type rw = [`Read | `Write] t *)

(*   (\** Read-only context {!t}. *\) *)
(*   type ro = [`Read] t *)

(*   type hash = Smart_rollup_context_hash.t *)

(*   let load = C.load *)

(*   let index = C.index *)

(*   let close = C.close *)

(*   let checkout = C.checkout *)

(*   let empty = C.empty *)

(*   let commit = C.commit *)

(*   let readonly = C.readonly *)

(*   let is_gc_finished = C.is_gc_finished *)

(*   let gc = C.gc *)

(*   let wait_gc_completion = C.wait_gc_completion *)

(*   (\** State of the PVM that this rollup node deals with. *\) *)
(*   module PVMState = struct *)
(*     type value = tree *)

(*     let empty = C.PVMState.empty *)

(*     let find = C.PVMState.find *)

(*     let lookup = C.PVMState.lookup *)

(*     let set = C.PVMState.set *)
(*   end *)

(*   module Internal_for_tests = struct *)
(*     let get_a_tree = C.Internal_for_tests.get_a_tree *)
(*   end *)
(* end *)

(* include Context (Irmin_context) *)

let cast_context (type repo tree) (t : (repo, tree) witness)
    (module C : CONTEXT) :
    (module CONTEXT with type repo = repo and type tree = tree) =
  match try_cast t C.witness with
  | Some Equal -> (module C)
  | None -> assert false

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

(* module Context : CONTEXT = Irmin_context *)

(* include Context *)

(* module PVMState = struct *)
(*   let set : *)
(*       type repo tree. *)
(*       (module Protocol_plugin_sig.PARTIAL) -> *)
(*       (([< `Read | `Write > `Read] as 'a), repo, tree) context -> *)
(*       tree -> *)
(*       ('a, repo, tree) context Lwt.t = *)
(*    fun (module Plugin) ctxt state -> *)
(*     let ((module Pvm) : (repo, tree) Pvm_plugin_sig.plugin) = *)
(*       Pvm_plugin_sig.into Plugin.Pvm.witness (module Plugin.Pvm) *)
(*     in *)
(*     Pvm.Context.PVMState.set ctxt state *)
(* end *)

type ('a, 'repo, 'tree) t = ('a, 'repo, 'tree) context

(** Read/write context {!t}. *)
type ('repo, 'tree) rw = ([`Read | `Write], 'repo, 'tree) t

(** Read-only context {!t}. *)
type ('repo, 'tree) ro = ([`Read], 'repo, 'tree) t
