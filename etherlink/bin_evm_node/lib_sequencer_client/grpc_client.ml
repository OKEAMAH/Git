(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2024 TriliTech    <contact@trili.tech>                      *)
(*                                                                           *)
(*****************************************************************************)

open Ocaml_protoc_plugin

type Error_monad.error +=
  | Cannot_recover_address_info of (string * int)
  | Tcp_connection_failed of (string * int * string)
  | Http2_connection_failed of string
  | Cannot_decode_response of string
  | Grpc_request_failed of int
  | Http2_request_failed of int
  | Timeout of int

let () =
  register_error_kind
    ~id:"grpc.cannot_recover_address_info"
    ~title:"Cannot recover address info for establishing HTTP2/gRPC connection"
    ~description:
      "Cannot recover address info for establishing HTTP2/gRPC connection"
    ~pp:(fun ppf (address, port) ->
      Format.fprintf
        ppf
        "Cannot establish HTTP2/gRPC connection on address %s and port %d"
        address
        port)
    `Permanent
    Data_encoding.(obj2 (req "address" string) (req "port" int31))
    (function
      | Cannot_recover_address_info address_with_port -> Some address_with_port
      | _ -> None)
    (fun address_with_port -> Cannot_recover_address_info address_with_port) ;
  register_error_kind
    ~id:"grpc.tcp_connection_failed"
    ~title:"Cannot establish TCP connection"
    ~description:"Cannot establish TCP connection"
    ~pp:(fun ppf (address, port, reason) ->
      Format.fprintf
        ppf
        "Cannot establish TCP connection on address %s and port %d: %s"
        address
        port
        reason)
    `Permanent
    Data_encoding.(
      obj3 (req "address" string) (req "port" int31) (req "reason" string))
    (function
      | Tcp_connection_failed address_with_port_and_reason ->
          Some address_with_port_and_reason
      | _ -> None)
    (fun address_with_port_and_reason ->
      Tcp_connection_failed address_with_port_and_reason) ;
  register_error_kind
    ~id:"grpc.http2_connection_failed"
    ~title:"Cannot establish HTTP2 connection"
    ~description:"Cannot establish HTTP2 connection"
    ~pp:(fun ppf reason ->
      Format.fprintf ppf "Cannot establish HTTP2 connection: %s" reason)
    `Permanent
    Data_encoding.(obj1 (req "reason" string))
    (function Http2_connection_failed reason -> Some reason | _ -> None)
    (fun reason -> Http2_connection_failed reason) ;
  register_error_kind
    ~id:"grpc.cannot_decode_response"
    ~title:"Cannot decode gRPC response"
    ~description:"Cannot decode gRPC response"
    ~pp:(fun ppf reason ->
      Format.fprintf ppf "Cannot decode gRPC response: %s" reason)
    `Permanent
    Data_encoding.(obj1 (req "reason" string))
    (function Cannot_decode_response reason -> Some reason | _ -> None)
    (fun reason -> Cannot_decode_response reason) ;
  register_error_kind
    ~id:"grpc.grpc_request_failed"
    ~title:"gRPC request failed"
    ~description:"gRPC request failed"
    ~pp:(fun ppf code ->
      Format.fprintf ppf "gRPC request failed with code %d" code)
    `Permanent
    Data_encoding.(obj1 (req "code" int31))
    (function Grpc_request_failed code -> Some code | _ -> None)
    (fun code -> Grpc_request_failed code) ;
  register_error_kind
    ~id:"grpc.http2_request_failed"
    ~title:"HTTP2 request failed"
    ~description:"HTTP2 request failed"
    ~pp:(fun ppf code ->
      Format.fprintf ppf "HTTP2 request failed with code %d" code)
    `Permanent
    Data_encoding.(obj1 (req "code" int31))
    (function Http2_request_failed code -> Some code | _ -> None)
    (fun code -> Http2_request_failed code) ;
  register_error_kind
    ~id:"grpc.grpc_request_timeout"
    ~title:"gRPC request timeout"
    ~description:"gRPC request timeout"
    ~pp:(fun ppf timeout ->
      Format.fprintf
        ppf
        "gRPC request did not receive a response within %d seconds"
        timeout)
    `Permanent
    Data_encoding.(obj1 (req "timeout" int31))
    (function Timeout timeout -> Some timeout | _ -> None)
    (fun timeout -> Timeout timeout)

module Rpc = struct
  type ('request, 'response) t = {
    service : string;
    method_ : string;
    encode : 'request -> string;
    decode : string -> 'response tzresult;
  }

  let make (type request response)
      ( (module Request : Service.Message with type t = request),
        (module Response : Service.Message with type t = response) ) ~service
      ~method_ =
    let encode req = Request.to_proto req |> Writer.contents in
    let decode response =
      let wrapped_response = Reader.create response |> Response.from_proto in
      match wrapped_response with
      | Ok res -> Ok res
      | Error err ->
          Result_syntax.tzfail @@ Cannot_decode_response (Result.show_error err)
    in
    {service; method_; encode; decode}
end

type 'response streamed_call_handler = {
  stream : 'response Lwt_stream.t;
  request_handler : unit tzresult Lwt.t;
}

let create_http2_connection ~error_handler socket =
  let open Lwt_result_syntax in
  Lwt.catch
    (fun () ->
      H2_lwt_unix.Client.create_connection socket ~error_handler
      |> Lwt.map (fun x -> Ok x))
    (fun ex -> tzfail @@ Http2_connection_failed (Printexc.to_string ex))

let make ?(error_handler = ignore) address port =
  let open Lwt_result_syntax in
  let*! addresses =
    Lwt_unix.getaddrinfo address (string_of_int port) [Unix.(AI_FAMILY PF_INET)]
  in
  match List.hd addresses with
  | None -> tzfail @@ Cannot_recover_address_info (address, port)
  | Some address_info ->
      let socket = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
      let* () =
        Lwt.catch
          (fun () ->
            Lwt_unix.connect socket address_info.Unix.ai_addr
            |> Lwt.map (fun x -> Ok x))
          (function
            | ex ->
                tzfail
                @@ Tcp_connection_failed (address, port, Printexc.to_string ex))
      in
      create_http2_connection ~error_handler socket

let call (type request response) ~(rpc : (request, response) Rpc.t)
    ?(error_handler = ignore) http2_connection message =
  let open Lwt_result_syntax in
  let encoded_message = rpc.encode message in
  let*! res =
    Grpc_lwt.Client.call
      ~service:rpc.service
      ~rpc:rpc.method_
      ~do_request:(H2_lwt_unix.Client.request http2_connection ~error_handler)
      ~handler:
        (Grpc_lwt.Client.Rpc.unary encoded_message ~f:(fun response_p ->
             let open Lwt_syntax in
             let* response = response_p in
             let res : response tzresult option =
               match response with
               | None -> None
               | Some res -> Some (rpc.decode res)
             in
             Lwt.return res))
      ()
  in
  match res with
  | Ok (res, grpc_status) -> (
      match res with
      | None ->
          tzfail
          @@ Grpc_request_failed Grpc.Status.(int_of_code @@ code grpc_status)
      | Some res -> Lwt.return res)
  | Error error_status ->
      tzfail @@ Http2_request_failed (H2.Status.to_code error_status)

let call (type request response) ?timeout ~(rpc : (request, response) Rpc.t)
    ?(error_handler = ignore) http2_connection message =
  let open Lwt_result_syntax in
  let grpc_handler = call ~rpc ~error_handler http2_connection message in
  let timeout_handler_opt =
    timeout
    |> Option.map (fun timeout ->
           let*! () = Lwt_unix.sleep @@ Float.of_int timeout in
           tzfail @@ Timeout timeout)
  in
  Lwt.choose @@ (grpc_handler :: Option.to_list timeout_handler_opt)

let streamed_call (type request response) ~(rpc : (request, response) Rpc.t)
    ?(error_handler = ignore) ?(on_grpc_closed_connection = ignore)
    ?(on_http2_closed_connection = ignore) http2_connection message =
  let open Lwt_result_syntax in
  let stream, notify = Lwt.task () in
  let encoded_message = rpc.encode message in
  let request_handler =
    let*! res =
      Grpc_lwt.Client.call
        ~service:rpc.service
        ~rpc:rpc.method_
        ~do_request:(H2_lwt_unix.Client.request http2_connection ~error_handler)
        ~handler:
          (Grpc_lwt.Client.Rpc.server_streaming
             encoded_message
             ~f:(fun response_stream ->
               let decoded_stream =
                 Lwt_stream.map
                   (fun response -> rpc.decode response)
                   response_stream
               in
               let () = Lwt.wakeup notify decoded_stream in
               Lwt.return ()))
        ()
    in
    match res with
    | Ok ((), grpc_status) ->
        on_grpc_closed_connection grpc_status ;
        return ()
    | Error http2_status ->
        on_http2_closed_connection http2_status ;
        return ()
  in
  let*! stream in
  return {request_handler; stream}
