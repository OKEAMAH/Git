type t =
  Tezos_lazy_containers.Chunked_byte_vector.t Tezos_lazy_containers.Lazy_fs.t

exception Durable_empty

let empty : t = Lazy_fs.empty ()
