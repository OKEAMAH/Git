type t

val create :
  ?name:(* protocol:Protocol.t -> *)
        string ->
  ?color:Log.Color.t ->
  ?data_dir:string ->
  ?event_pipe:string ->
  ?uri:Uri.t ->
  ?runner:Runner.t ->
  Node.t ->
  Client.t ->
  t

val run : t -> unit Lwt.t

module RPC : sig
  val inject : bytes -> (t, string) RPC_core.t
end
