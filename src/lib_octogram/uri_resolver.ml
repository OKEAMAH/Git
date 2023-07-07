type t =
  ?suffix:string ->
  Services_cache.node_kind ->
  Services_cache.service_kind ->
  Agent_name.t ->
  string ->
  string * int * string option
