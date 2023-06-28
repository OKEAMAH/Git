(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 TriliTech, <contact@trili.tech>                        *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                        *)
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

type host_and_port = {host : string; port : int}

let default_data_dir = Filename.concat (Sys.getenv "HOME") ".tezos-dac-node"

let relative_filename data_dir = Filename.concat data_dir "config.json"

let default_rpc_address = "127.0.0.1"

let default_rpc_port = 10832

let default_reveal_data_dir =
  Filename.concat
    (Filename.concat (Sys.getenv "HOME") ".tezos-smart-rollup-node")
    "wasm_2_0_0"

module Coordinator = struct
  type t = {
    committee_members : Tezos_crypto.Aggregate_signature.public_key list;
  }

  let make committee_members = {committee_members}

  let encoding =
    Data_encoding.(
      conv
        (fun {committee_members} -> committee_members)
        (fun committee_members -> {committee_members})
        (obj1
           (req
              "committee_members"
              (list Tezos_crypto.Aggregate_signature.Public_key.encoding))))

  let committee_members_addresses t =
    List.map
      Tezos_crypto.Aggregate_signature.Public_key.hash
      t.committee_members

  let name = "Coordinator"
end

module Committee_member = struct
  type t = {
    coordinator_rpc_address : string;
    coordinator_rpc_port : int;
    address : Tezos_crypto.Aggregate_signature.public_key_hash;
  }

  let make coordinator_rpc_address coordinator_rpc_port address =
    {coordinator_rpc_address; coordinator_rpc_port; address}

  let encoding =
    Data_encoding.(
      conv
        (fun {coordinator_rpc_address; coordinator_rpc_port; address} ->
          (coordinator_rpc_address, coordinator_rpc_port, address))
        (fun (coordinator_rpc_address, coordinator_rpc_port, address) ->
          {coordinator_rpc_address; coordinator_rpc_port; address})
        (obj3
           (req "coordinator_rpc_address" string)
           (req "coordinator_rpc_port" uint16)
           (req
              "address"
              Tezos_crypto.Aggregate_signature.Public_key_hash.encoding)))

  let name = "Committee_member"
end

module Observer = struct
  type t = {
    coordinator_rpc_address : string;
    coordinator_rpc_port : int;
    committee_rpc_addresses : (string * int) list;
    timeout : int;
  }

  let default_timeout = 6

  let make ~committee_rpc_addresses ?(timeout = default_timeout)
      coordinator_rpc_address coordinator_rpc_port =
    {
      coordinator_rpc_address;
      timeout;
      coordinator_rpc_port;
      committee_rpc_addresses;
    }

  let encoding =
    Data_encoding.(
      conv
        (fun {
               coordinator_rpc_address;
               coordinator_rpc_port;
               committee_rpc_addresses;
               timeout;
             } ->
          ( coordinator_rpc_address,
            coordinator_rpc_port,
            committee_rpc_addresses,
            timeout ))
        (fun ( coordinator_rpc_address,
               coordinator_rpc_port,
               committee_rpc_addresses,
               timeout ) ->
          {
            coordinator_rpc_address;
            coordinator_rpc_port;
            committee_rpc_addresses;
            timeout;
          })
        (obj4
           (req "coordinator_rpc_address" string)
           (req "coordinator_rpc_port" uint16)
           (req
              "committee_rpc_addresses"
              (Data_encoding.list
                 (obj2 (req "rpc_address" string) (req "rpc_port" uint16))))
           (req "timeout" Data_encoding.uint8)))

  let name = "Observer"
end

type mode =
  | Coordinator of Coordinator.t
  | Committee_member of Committee_member.t
  | Observer of Observer.t

let make_coordinator committee_members =
  Coordinator (Coordinator.make committee_members)

let make_committee_member coordinator_rpc_address coordinator_rpc_port
    committee_member_address =
  Committee_member
    (Committee_member.make
       coordinator_rpc_address
       coordinator_rpc_port
       committee_member_address)

let make_observer ~committee_rpc_addresses ?timeout coordinator_rpc_address
    coordinator_rpc_port =
  Observer
    (Observer.make
       ~committee_rpc_addresses
       ?timeout
       coordinator_rpc_address
       coordinator_rpc_port)

type t = {
  data_dir : string;  (** The path to the DAC node data directory. *)
  rpc_address : string;  (** The address the DAC node listens to. *)
  rpc_port : int;  (** The port the DAC node listens to. *)
  reveal_data_dir : string;
      (** The directory where the DAC node saves pages. *)
  mode : mode;
      (** Configuration parameters specific to the operating mode of the
          DAC. *)
  allow_v1_api : bool;
}

let mode_name t =
  match t.mode with
  | Coordinator _ -> Coordinator.name
  | Committee_member _ -> Committee_member.name
  | Observer _ -> Observer.name

let make ~data_dir ~reveal_data_dir ~allow_v1_api rpc_address rpc_port mode =
  {data_dir; reveal_data_dir; rpc_address; rpc_port; mode; allow_v1_api}

let data_dir_path config subpath = Filename.concat config.data_dir subpath

let filename config = relative_filename config.data_dir

let data_dir config = config.data_dir

let reveal_data_dir config = config.reveal_data_dir

let mode config = config.mode

let mode_encoding =
  Data_encoding.With_JSON_discriminant.(
    union
      [
        case
          ~title:Coordinator.name
          (Tag (0, Coordinator.name))
          Coordinator.encoding
          (function Coordinator t -> Some t | _ -> None)
          (fun t -> Coordinator t);
        case
          ~title:Committee_member.name
          (Tag (1, Committee_member.name))
          Committee_member.encoding
          (function Committee_member t -> Some t | _ -> None)
          (fun t -> Committee_member t);
        case
          ~title:Observer.name
          (Tag (2, Observer.name))
          Observer.encoding
          (function Observer t -> Some t | _ -> None)
          (fun t -> Observer t);
      ])

let encoding : t Data_encoding.t =
  let open Data_encoding in
  conv
    (fun {data_dir; rpc_address; rpc_port; reveal_data_dir; mode; allow_v1_api} ->
      (data_dir, rpc_address, rpc_port, reveal_data_dir, mode, allow_v1_api))
    (fun (data_dir, rpc_address, rpc_port, reveal_data_dir, mode, allow_v1_api) ->
      {data_dir; rpc_address; rpc_port; reveal_data_dir; mode; allow_v1_api})
    (obj6
       (dft
          "data-dir"
          ~description:"Location of the data dir"
          string
          default_data_dir)
       (dft "rpc-addr" ~description:"RPC address" string default_rpc_address)
       (dft "rpc-port" ~description:"RPC port" uint16 default_rpc_port)
       (dft
          "reveal_data_dir"
          ~description:"Reveal data directory"
          string
          default_reveal_data_dir)
       (req "mode" ~description:"Running mode" mode_encoding)
       (dft "allow_v1_api" ~description:"Allow V1 API boolean flag" bool false))

type error += DAC_node_unable_to_write_configuration_file of string

let () =
  register_error_kind
    ~id:"dac.node.unable_to_write_configuration_file"
    ~title:"Unable to write configuration file"
    ~description:"Unable to write configuration file"
    ~pp:(fun ppf file ->
      Format.fprintf ppf "Unable to write the configuration file %s" file)
    `Permanent
    Data_encoding.(obj1 (req "file" string))
    (function
      | DAC_node_unable_to_write_configuration_file path -> Some path
      | _ -> None)
    (fun path -> DAC_node_unable_to_write_configuration_file path)

let save config =
  let open Lwt_syntax in
  let file = filename config in
  protect @@ fun () ->
  let* v =
    let* () = Lwt_utils_unix.create_dir @@ data_dir config in
    Lwt_utils_unix.with_atomic_open_out file @@ fun chan ->
    let json = Data_encoding.Json.construct encoding config in
    let content = Data_encoding.Json.to_string json in
    Lwt_utils_unix.write_string chan content
  in
  Lwt.return
    (Result.map_error
       (fun _ -> [DAC_node_unable_to_write_configuration_file file])
       v)

let load ~data_dir =
  let open Lwt_result_syntax in
  let+ json =
    let*! json = Lwt_utils_unix.Json.read_file (relative_filename data_dir) in
    match json with
    | Ok json -> return json
    | Error (Exn _ :: _ as e) ->
        let*! () = Event.(emit data_dir_not_found data_dir) in
        fail e
    | Error e -> fail e
  in
  let config = Data_encoding.Json.destruct encoding json in
  {config with data_dir}
