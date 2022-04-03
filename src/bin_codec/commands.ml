(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2019 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

open Clic
open Lwt_result_syntax

let group = {name = "encoding"; title = "Commands to handle encodings"}

let id_parameter =
  parameter (fun (cctxt : #Client_context.printer) id ->
      match Data_encoding.Registration.find id with
      | Some record -> Lwt.return_ok record
      | None -> cctxt#error "Unknown encoding id: %s" id)

let json_parameter =
  let open Lwt_syntax in
  parameter (fun (cctxt : #Client_context.printer) file_or_data ->
      let* data =
        let* file_exists = Lwt_unix.file_exists file_or_data in
        if file_exists then
          Tezos_stdlib_unix.Lwt_utils_unix.read_file file_or_data
        else Lwt.return file_or_data
      in
      match Json.from_string data with
      | Ok json -> return_ok json
      | Error err -> cctxt#error "%s" err)

let bytes_parameter =
  parameter (fun (cctxt : #Client_context.printer) hex ->
      match Hex.to_bytes (`Hex hex) with
      | Some s -> Lwt.return_ok s
      | None -> cctxt#error "Invalid hex string: %s" hex)

class unix_sc_client_context ~rpc_config =
  object
    inherit
      Client_context_unix.unix_io_wallet
        ~base_dir:"/tmp"
        ~password_filename:None

    inherit
      Tezos_rpc_http_client_unix.RPC_client_unix.http_ctxt
        rpc_config
        (Tezos_rpc_http.Media_type.Command_line.of_command_line
           rpc_config.media_type)
  end

let make_unix_client_context endpoint =
  let rpc_config =
    {Tezos_rpc_http_client_unix.RPC_client_unix.default_config with endpoint}
  in
  new unix_sc_client_context ~rpc_config

let default_endpoint = Uri.of_string "http://localhost:8732"

let valid_endpoint _ s =
  let endpoint = Uri.of_string s in
  match (Uri.scheme endpoint, Uri.query endpoint, Uri.fragment endpoint) with
  | (Some ("http" | "https"), [], None) -> return endpoint
  | _ -> failwith "Endpoint should be of the form http[s]://address:port"

let endpoint_arg () =
  arg ~long:"endpoint" ~short:'E' ~placeholder:"uri" ~doc:""
  @@ parameter valid_endpoint

let distributed_db_messages_encoding =
  match Data_encoding.Registration.find "distributed_db_messages" with
  | None ->
      Format.eprintf "Unexpected error@." ;
      assert false (* FIXME *)
  | Some registration -> registration

exception Update

let rec assoc_put_or_replace ~key ~value = function
  | [] -> [(key, value)]
  | (k, _) :: assoc when k = key -> (key, value) :: assoc
  | (k, v) :: assoc -> (k, v) :: assoc_put_or_replace ~key ~value assoc

let as_object_opt json =
  match json with
  | `O l -> Some (List.map (fun (name, node) -> (name, node)) l)
  | _ -> None

let put (key, value) json : Json.t =
  match as_object_opt json with
  | None -> raise Update
  | Some obj -> `O (assoc_put_or_replace ~key ~value obj)

let get (json : Json.t) key =
  match json with
  | `O fields -> (
      match List.assoc_opt ~equal:( = ) key fields with
      | None -> raise Update
      | Some node -> node)
  | _ -> raise Update

let rec get_path json path =
  match path with
  | [] -> Some json
  | key :: path -> ( try get_path (get json key) path with Update -> None)

let update key f (json : Json.t) : Json.t =
  let v = get json key in
  put (key, f v) json

let rec update_path (json : Json.t) path value : Json.t =
  try
    match path with
    | [] -> value
    | key :: path -> update key (fun json -> update_path json path value) json
  with Update -> json

let protocol_data_substitution =
  ("block_header.protocol_data", ["block_header"; "protocol_data"])

let protocol_data_substitution2 =
  ("block_header.protocol_data", ["current_block_header"; "protocol_data"])

(* FIXME: Should be updated *)
let default_proto_level = 012

let proto_prefix_from_level proto_level =
  match proto_level with 012 -> Some "012-Psithaca" | _ -> None

let apply ?(proto_level = default_proto_level) (proto_encoding_name, path) json
    =
  match proto_prefix_from_level proto_level with
  | None ->
      Format.eprintf "Z@." ;
      json
  | Some proto_prefix -> (
      let encoding_name =
        Format.asprintf "%s.%s" proto_prefix proto_encoding_name
      in
      match Data_encoding.Registration.find encoding_name with
      | None ->
          Format.eprintf "A@." ;
          json
      | Some registration -> (
          match get_path json path with
          | None ->
              Format.eprintf "B@." ;
              json
          | Some (`String hex_str) -> (
              match Hex.to_bytes (`Hex hex_str) with
              | None -> json
              | Some data -> (
                  match
                    Data_encoding.Registration.json_of_bytes registration data
                  with
                  | None ->
                      Format.eprintf "C@." ;
                      json
                  | Some value -> update_path json path value))
          | Some _ ->
              Format.eprintf "D@." ;
              json))

let pp_distributed_db_messages fmt data =
  match
    Data_encoding.Registration.json_of_bytes
      distributed_db_messages_encoding
      data
  with
  | None -> Format.fprintf fmt "UNKNOWN ENCODING@."
  | Some json ->
      let json = apply protocol_data_substitution json in
      let json = apply protocol_data_substitution2 json in
      Format.fprintf fmt "%a@." Json.pp json

let commands () =
  [
    command
      ~group
      ~desc:"Sniffer"
      (args1 (endpoint_arg ()))
      (fixed ["sniff"; "local"; "node"])
      (fun local_node (_cctxt : #Client_context.printer) ->
        let endpoint = Option.value local_node ~default:default_endpoint in
        let cctxt = make_unix_client_context endpoint in
        let* points =
          cctxt#call_service
            P2p_services.Points.S.list
            ()
            (object
               method filters = []
            end)
            ()
        in
        let pp_data fmt data = pp_distributed_db_messages fmt data in
        let pp point timestamp data =
          Format.eprintf
            "[%a] point %a sends:@.%a@.@."
            Time.System.pp_hum
            timestamp
            P2p_point.Id.pp
            point
            pp_data
            data
        in
        List.iter_ep
          (fun point ->
            let* (data_stream, stream_stopper) =
              RPC_context.make_streamed_call
                P2p_services.Points.S.sniff
                cctxt
                ((), point)
                ()
                ()
            in
            let rec loop () =
              let*! data = Lwt_stream.get data_stream in
              match data with
              | None -> return (stream_stopper ())
              | Some P2p_services.{timestamp; data} ->
                  pp point timestamp data ;
                  loop ()
            in
            loop ())
          (List.map fst points));
    command
      ~group
      ~desc:"List the registered encoding in Tezos."
      no_options
      (fixed ["list"; "encodings"])
      (fun () (cctxt : #Client_context.printer) ->
        let bindings =
          Data_encoding.Registration.list ()
          |> List.map (fun (id, elem) ->
                 (id, Data_encoding.Registration.description elem))
        in
        let*! () =
          cctxt#message
            "@[<v>%a@]@."
            (Format.pp_print_list
               ~pp_sep:Format.pp_print_cut
               (fun ppf (id, desc) ->
                 let desc =
                   Option.value ~default:"No description available." desc
                 in
                 Format.fprintf
                   ppf
                   "@[<v 2>%s:@ @[%a@]@]"
                   id
                   Format.pp_print_text
                   desc))
            bindings
        in
        Lwt_result_syntax.return_unit);
    command
      ~group
      ~desc:"Dump a json description of all registered encodings."
      (args1
      @@ switch
           ~doc:
             "Output json descriptions without extraneous whitespace characters"
           ~long:"compact"
           ())
      (fixed ["dump"; "encodings"])
      (fun minify (cctxt : #Client_context.printer) ->
        let*! () =
          cctxt#message
            "%s"
            (Json.to_string
               ~minify
               (`A
                 (Registration.list ()
                 |> List.map (fun (id, enc) ->
                        `O
                          [
                            ("id", `String id);
                            ( "json",
                              Json.construct
                                Json.schema_encoding
                                (Registration.json_schema enc) );
                            ( "binary",
                              Json.construct
                                Binary_schema.encoding
                                (Registration.binary_schema enc) );
                          ]))))
        in
        Lwt_result_syntax.return_unit);
    (* JSON -> Binary *)
    command
      ~group
      ~desc:
        "Encode the given JSON data into binary using the provided encoding \
         identifier."
      no_options
      (prefix "encode"
      @@ param ~name:"id" ~desc:"Encoding identifier" id_parameter
      @@ prefix "from"
      @@ param ~name:"json" ~desc:"JSON file or data" json_parameter
      @@ stop)
      (fun () registered_encoding json (cctxt : #Client_context.printer) ->
        match
          Data_encoding.Registration.bytes_of_json registered_encoding json
        with
        | exception exn ->
            cctxt#error "%a" (fun ppf exn -> Json.print_error ppf exn) exn
        | None ->
            cctxt#error
              "Impossible to the JSON convert to binary.@,\
               This error should not happen."
        | Some bytes ->
            let*! () = cctxt#message "%a" Hex.pp (Hex.of_bytes bytes) in
            Lwt_result_syntax.return_unit);
    (* Binary -> JSON *)
    command
      ~group
      ~desc:
        "Decode the binary encoded data into JSON using the provided encoding \
         identifier."
      no_options
      (prefix "decode"
      @@ param ~name:"id" ~desc:"Encoding identifier" id_parameter
      @@ prefix "from"
      @@ param ~name:"hex" ~desc:"Binary encoded data" bytes_parameter
      @@ stop)
      (fun () registered_encoding bytes (cctxt : #Client_context.printer) ->
        match
          Data_encoding.Registration.json_of_bytes registered_encoding bytes
        with
        | None -> cctxt#error "Cannot parse the binary with the given encoding"
        | Some bytes ->
            let*! () = cctxt#message "%a" Json.pp bytes in
            Lwt_result_syntax.return_unit);
    command
      ~group
      ~desc:
        "Display the binary encoded data using the provided encoding \
         identifier."
      no_options
      (prefix "display"
      @@ param ~name:"id" ~desc:"Encoding identifier" id_parameter
      @@ prefixes ["from"; "binary"]
      @@ param ~name:"hex" ~desc:"Binary encoded data" bytes_parameter
      @@ stop)
      (fun () registered_encoding bytes (cctxt : #Client_context.printer) ->
        let pp_bytes fmt bytes =
          Data_encoding.Registration.binary_pretty_printer
            registered_encoding
            fmt
            bytes
        in
        let*! () = cctxt#message "%a" pp_bytes bytes in
        Lwt_result_syntax.return_unit);
    command
      ~group
      ~desc:
        "Display the JSON encoded data using the provided encoding identifier."
      no_options
      (prefix "display"
      @@ param ~name:"id" ~desc:"Encoding identifier" id_parameter
      @@ prefixes ["from"; "json"]
      @@ param ~name:"json" ~desc:"JSON file or data" json_parameter
      @@ stop)
      (fun () registered_encoding json (cctxt : #Client_context.printer) ->
        let pp_json fmt json =
          Data_encoding.Registration.json_pretty_printer
            registered_encoding
            fmt
            json
        in
        let*! () = cctxt#message "%a" pp_json json in
        Lwt_result_syntax.return_unit);
    command
      ~group
      ~desc:
        "Describe the binary schema associated to the provided encoding \
         identifier."
      no_options
      (prefix "describe"
      @@ param ~name:"id" ~desc:"Encoding identifier" id_parameter
      @@ prefixes ["binary"; "schema"]
      @@ stop)
      (fun () registered_encoding (cctxt : #Client_context.printer) ->
        let schema =
          Data_encoding.Registration.binary_schema registered_encoding
        in
        let*! () = cctxt#message "%a" Data_encoding.Binary_schema.pp schema in
        Lwt_result_syntax.return_unit);
    command
      ~group
      ~desc:
        "Describe the JSON schema associated to the provided encoding \
         identifier."
      no_options
      (prefix "describe"
      @@ param ~name:"id" ~desc:"Encoding identifier" id_parameter
      @@ prefixes ["json"; "schema"]
      @@ stop)
      (fun () registered_encoding cctxt ->
        let schema =
          Data_encoding.Registration.json_schema registered_encoding
        in
        let*! () = cctxt#message "%a" Json_schema.pp schema in
        Lwt_result_syntax.return_unit);
  ]
