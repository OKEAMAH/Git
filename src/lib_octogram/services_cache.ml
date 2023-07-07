type service_kind = Metrics | Rpc | Http | P2p

type node_kind = Octez_node | Rollup_node | Dac_node | Http_server

let int_of_service_kind = function
  | Octez_node -> 0
  | Rollup_node -> 1
  | Dac_node -> 2
  | Http_server -> 3

module Cache = Map.Make (struct
  type t = node_kind * string

  let compare (k, n) (k', n') =
    let x = Int.compare (int_of_service_kind k) (int_of_service_kind k') in
    if x = 0 then String.compare n n' else x
end)

type t = (service_kind * int) list Cache.t

let empty = Cache.empty

let add cache name node_kind services =
  Cache.update
    (node_kind, name)
    (function
      | Some existing_services -> Some (services @ existing_services)
      | None -> Some services)
    cache

let remove cache name node_kind = Cache.remove (node_kind, name) cache

let get cache name node_kind service_kind =
  Cache.find (node_kind, name) cache |> List.assoc service_kind
