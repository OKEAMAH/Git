type t =
  Tezos_lazy_containers.Immutable_chunked_byte_vector.t
  Tezos_lazy_containers.Lazy_fs.t

exception Durable_empty

let of_tree t = t

let empty : t = Lazy_fs.create ()
