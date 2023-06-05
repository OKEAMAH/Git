type t

val create :
  ?name:(* protocol:Protocol.t -> *)
        string ->
  ?color:Log.Color.t ->
  ?event_pipe:string ->
  ?uri:Uri.t ->
  ?runner:Runner.t ->
  Node.t ->
  t

val run : t -> unit Lwt.t

module RPC : sig
  val inject : bytes -> (t, bool) RPC_core.t
end
