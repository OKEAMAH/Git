(** A stateful client to download files. *)
type t

(** [create ()] returns a fresh client. *)
val create : unit -> t

(** [local_path_from_agent_uri client uri] returns the local path of [uri],
    using [client] to download it if necessary. *)
val local_path_from_agent_uri :
  ?keep_name:bool -> ?exec:bool -> t -> Uri.agent_uri -> string Lwt.t
