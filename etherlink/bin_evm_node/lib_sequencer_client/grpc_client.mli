(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2024 TriliTech    <contact@trili.tech>                      *)
(*                                                                           *)
(*****************************************************************************)

(** Errors that can be returned by creating gRPC connections and invoking gRPC
    methods. *)
type Error_monad.error +=
  | Cannot_recover_address_info of (string * int)
  | Tcp_connection_failed of (string * int * string)
  | Http2_connection_failed of string
  | Cannot_decode_response of string
  | Grpc_request_failed of int
  | Http2_request_failed of int
  | Timeout of int

(** Module for handling gRPC methods. *)
module Rpc : sig
  (** The type of a gRPC method. *)
  type ('request, 'response) t

  (** [make (Req,Rep) ~service ~method_] builds a rpc value that can be used to
    calling [method_] of [service]. The modules [REQ] and [REP] are precomipled
    via the `ocaml-protoc-compiler`, and supply the information to encode and
    decode requests and responses, respectively, in and from protobuf. *)
  val make :
    (module Ocaml_protoc_plugin.Service.Message with type t = 'request)
    * (module Ocaml_protoc_plugin.Service.Message with type t = 'response) ->
    service:string ->
    method_:string ->
    ('request, 'response) t
end

(** The return type of [streamed_call] requests. *)
type 'response streamed_call_handler = private {
  stream : 'response Lwt_stream.t;
      (** The stream where responses from the server are pushed to. *)
  request_handler : unit tzresult Lwt.t;
      (** The handler responsbile for receiving responses from the server. *)
}

(** [make ~error_handler address port] establishes a gRPC over HTTP/2 at the
    host [address]:[port]. The connection does not use TLS. If the connection
    fails, [error_handler] is invoked.
    Can fail with:
    {ul
      {li [Cannot_recover_address_info (address, port)] if the underlying call
        to `Lwt_unix.client_info` does not return any `addrinfo` value, }
      {li [Tcp_connection_failed (address, port)] if it is not possible to
        establish a TCP connection to [address]:[port], }
      {li [Http2_connection_failed reason], if it is not possible to esablish a
        HTTP/2 connection of top of the underlying TCP connection. This error
        reports the [reason] why the connection failed, in string format. }
    } *)
val make :
  ?error_handler:H2.Client_connection.error_handler ->
  string ->
  int ->
  (H2_lwt_unix.Client.t, error trace) result Lwt.t

(** [call ~timeout ~rpc ~error_handler client message] sends [message] to the
      method and service specified by [rpc], using [client] to send the
      request. An [error_handler] can be supplied to handle unsuccessful
      requests. An optional [timeout] field can be specified in seconds to
      terminate the request if no response is received. This function can fail
      with the following errors:
      {ul
        {li [Http2_request_failed status] if the HTTP2 request fails
          with a non `2xx` [status] code, }
        {li [Grpc_request_failed status] if the HTTP2 request is successful, but
          the underlying grpc response contains a non-successful status ( i.e.
          not 0) [status] code }
        {li [Cannot_decode_response raw_response] if a non-valid [raw_response] is
          received from the server, }
        {li [Timeout n] if the specified timeout of [n] seconds has passed and the
          request has not been completed. }
      }*)
val call :
  ?timeout:int ->
  rpc:('request, 'response) Rpc.t ->
  ?error_handler:(H2.Client_connection.error -> unit) ->
  H2_lwt_unix.Client.t ->
  'request ->
  'response tzresult Lwt.t

(** [streamed_call ~rpc ~error_handler ~on_grpc_closed_connection ~on_http2_closed_connection] client message]
    sends a streamed [message] request via [client] using [rpc].
    It returns a ['response streamed_call_handler] that can be used to extract
    the values of type ['response] streamed by the server. *)

val streamed_call :
  rpc:('request, 'response) Rpc.t ->
  ?error_handler:H2.Client_connection.error_handler ->
  ?on_grpc_closed_connection:(Grpc.Status.t -> unit) ->
  ?on_http2_closed_connection:(H2.Status.t -> unit) ->
  H2_lwt_unix.Client.t ->
  'request ->
  ('response tzresult streamed_call_handler, 'a) result Lwt.t
