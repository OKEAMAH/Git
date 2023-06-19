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
  val add_pending_operation :
    int64 -> string -> string -> (t, string) RPC_core.t

  val operation_status : string -> (t, string option) RPC_core.t

  val inject : unit -> (t, unit) RPC_core.t
end
