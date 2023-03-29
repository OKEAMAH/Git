(** The type of kernel's durable storage. *)
type t

exception Durable_empty

val empty : t

val of_tree :
  Tezos_lazy_containers.Immutable_chunked_byte_vector.t
  Tezos_lazy_containers.Lazy_fs.t ->
  t

(** @raise Durable_empty *)
val to_tree_exn :
  t ->
  Tezos_lazy_containers.Immutable_chunked_byte_vector.t
  Tezos_lazy_containers.Lazy_fs.t

val to_tree :
  t ->
  Tezos_lazy_containers.Immutable_chunked_byte_vector.t
  Tezos_lazy_containers.Lazy_fs.t
  option
