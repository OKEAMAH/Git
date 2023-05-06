(** The type of kernel's durable storage. *)
type t

exception Durable_empty

val empty : t

val of_tree : Tezos_lazy_containers.Lazy_tree.CBV_lazy_tree.t -> t

(** @raise Durable_empty *)
val to_tree_exn : t -> Tezos_lazy_containers.Lazy_tree.CBV_lazy_tree.t

val to_tree : t -> Tezos_lazy_containers.Lazy_tree.CBV_lazy_tree.t option
