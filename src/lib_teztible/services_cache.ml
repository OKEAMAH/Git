type service_kind = Rpc

type node_kind = Octez_node | Rollup_node

let string_of_node = function
  | Octez_node -> ( ^ ) "octez:"
  | Rollup_node -> ( ^ ) "smart-rollup:"

module Cache = Map.Make (struct
  type t = node_kind * string

  let compare (k, n) (k', n') =
    String.compare (string_of_node k n) (string_of_node k' n')
end)

type t = (service_kind * int) list Cache.t

let empty = Cache.empty

let add cache name node_kind services =
  Cache.add (node_kind, name) services cache

let remove cache name node_kind = Cache.remove (node_kind, name) cache

let get cache name node_kind service_kind =
  Cache.find (node_kind, name) cache |> List.assoc service_kind
