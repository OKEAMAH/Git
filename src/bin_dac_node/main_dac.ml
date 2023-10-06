(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 TriliTech, <contact@trili.tech>                        *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                       *)
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

type error += Invalid_positive_int_parameter of string

let () =
  register_error_kind
    `Permanent
    ~id:"dac.node.dac.invalid_positive_int_parameter"
    ~title:"Argument is not a positive integer"
    ~description:"Argument must be a positive integer"
    ~pp:(fun ppf reveal_data_path ->
      Format.fprintf
        ppf
        "Expected a valid positive integer, provided %s instead"
        reveal_data_path)
    Data_encoding.(obj1 (req "arg" string))
    (function Invalid_positive_int_parameter s -> Some s | _ -> None)
    (fun s -> Invalid_positive_int_parameter s)

let group =
  {Tezos_clic.name = "dac-node"; title = "Commands related to the DAC node"}

let data_dir_arg =
  let default = Configuration.default_data_dir in
  Tezos_clic.default_arg
    ~long:"data-dir"
    ~placeholder:"data-dir"
    ~doc:
      (Format.sprintf
         "The path to the DAC node data directory. Default value is %s"
         default)
    ~default
    (Client_config.string_parameter ())

let reveal_data_dir_arg =
  let default = Configuration.default_reveal_data_dir in
  Tezos_clic.default_arg
    ~long:"reveal-data-dir"
    ~placeholder:"reveal-data-dir"
    ~doc:"The directory where reveal preimage pages are saved."
    ~default
    (Client_config.string_parameter ())

let tz4_address_parameter =
  Tezos_clic.parameter (fun _cctxt s ->
      let open Lwt_result_syntax in
      let*? bls_pkh = Signature.Bls.Public_key_hash.of_b58check s in
      let pkh : Tezos_crypto.Aggregate_signature.public_key_hash =
        Tezos_crypto.Aggregate_signature.Bls12_381 bls_pkh
      in
      return pkh)

let tz4_address_param ?(name = "bls-public-key-hash")
    ?(desc = "BLS public key hash.") =
  let desc = String.concat " " [desc; "A tz4 address."] in
  Tezos_clic.param ~name ~desc tz4_address_parameter

let tz4_public_key_parameter =
  Tezos_clic.parameter (fun _cctxt s ->
      let open Lwt_result_syntax in
      let*? pk = Tezos_crypto.Aggregate_signature.Public_key.of_b58check s in
      return pk)

let tz4_public_key_param ?(name = "bls-public-key")
    ?(desc = "BLS public key of committee member.") =
  let desc =
    String.concat
      " "
      [desc; "A BLS12-381 public key which belongs to a tz4 account."]
  in
  Tezos_clic.param ~name ~desc tz4_public_key_parameter

let positive_int_parameter =
  Tezos_clic.parameter (fun _cctxt p ->
      let open Lwt_result_syntax in
      let* i =
        try Lwt.return_ok (int_of_string p)
        with _ -> tzfail @@ Invalid_positive_int_parameter p
      in
      if i < 0 then tzfail @@ Invalid_positive_int_parameter p else return i)

let timeout ~doc =
  Tezos_clic.arg
    ~long:"timeout"
    ~placeholder:"timeout"
    ~doc
    positive_int_parameter

let rpc_address_arg =
  let default = Configuration.default_rpc_address in
  Tezos_clic.default_arg
    ~long:"rpc-addr"
    ~placeholder:"rpc-address|ip"
    ~doc:
      (Format.sprintf
         "The address the DAC node listens to. Default value is %s."
         default)
    ~default
    (Client_config.string_parameter ())

let rpc_port_arg =
  let default = Configuration.default_rpc_port |> string_of_int in
  Tezos_clic.default_arg
    ~long:"rpc-port"
    ~placeholder:"rpc-port"
    ~doc:
      (Format.sprintf
         "The port the DAC node listens to. Default value is %s."
         default)
    ~default
    positive_int_parameter

let allow_v1_api_arg : (bool, Client_context.full) Tezos_clic.arg =
  Tezos_clic.switch
    ~long:"allow-v1-api"
    ~doc:(Format.sprintf "Run dac node with both V0 and V1 (WIP) API.")
    ()

let raw_rpc_parameter =
  let open Lwt_result_syntax in
  let open Dac_clic_helpers in
  Tezos_clic.parameter (fun _cctxt raw_rpc ->
      let parsed_rpc_result = Parsed_rpc.of_string raw_rpc in
      match parsed_rpc_result with
      | Ok parsed_rpc -> return parsed_rpc
      | Error (`Parse_rpc_error msg) -> failwith "%s" msg)

let coordinator_rpc_param ?(name = "coordinator-rpc-address")
    ?(desc =
      "The RPC address of the DAC coordinator in the form of \
       <rpc_address>:<rpc_port>.") =
  Tezos_clic.param ~name ~desc raw_rpc_parameter

let committee_rpc_addresses_param ?(name = "committee-member-rpc-address")
    ?(desc =
      "The RPC address of the DAC committee member in the form of \
       <rpc_address>:<rpc_port>.") =
  Tezos_clic.param ~name ~desc raw_rpc_parameter

let experimental_disclaimer () =
  Format.eprintf
    "@[<v 2>@{<warning>@{<title>Warning@}@}@,\
     @,\
    \                 DAC is in an @{<warning>experimental release@} phase.    \
     @,\
     @,\
    \         We encourage the community to develop rollups using DAC in\n\
    \           Testnets and lower environments. Mainnet is @{<warning>NOT@} \
     recommended.\n\
     @."

module Config_init = struct
  let create_configuration ~data_dir ~reveal_data_dir ~rpc_address ~rpc_port
      ~allow_v1_api mode (cctxt : Client_context.full) =
    let open Lwt_result_syntax in
    let config =
      Configuration.make
        ~data_dir
        ~reveal_data_dir
        ~allow_v1_api
        rpc_address
        rpc_port
        mode
    in
    let* () = Configuration.save config in
    let*! _ =
      cctxt#message
        "DAC node configuration written in %s"
        (Configuration.filename config)
    in
    return_unit

  let coordinator_command =
    let open Tezos_clic in
    command
      ~group
      ~desc:"Configure DAC node in coordinator mode."
      (args5
         data_dir_arg
         rpc_address_arg
         rpc_port_arg
         reveal_data_dir_arg
         allow_v1_api_arg)
      (prefixes
         [
           "configure";
           "as";
           "coordinator";
           "with";
           "data";
           "availability";
           "committee";
           "members";
         ]
      @@ seq_of_param @@ tz4_public_key_param)
      (fun (data_dir, rpc_address, rpc_port, reveal_data_dir, allow_v1_api)
           committee_members
           cctxt ->
        experimental_disclaimer () ;
        create_configuration
          ~data_dir
          ~reveal_data_dir
          ~rpc_address
          ~rpc_port
          ~allow_v1_api
          (Configuration.make_coordinator committee_members)
          cctxt)

  let committee_member_command =
    let open Tezos_clic in
    command
      ~group
      ~desc:"Configure DAC node in committee member mode."
      (args5
         data_dir_arg
         rpc_address_arg
         rpc_port_arg
         reveal_data_dir_arg
         allow_v1_api_arg)
      (prefixes
         ["configure"; "as"; "committee"; "member"; "with"; "coordinator"]
      @@ coordinator_rpc_param
      @@ prefixes ["and"; "signer"]
      @@ tz4_address_param ~desc:"BLS public key hash to use as the signer."
      @@ stop)
      (fun (data_dir, rpc_address, rpc_port, reveal_data_dir, allow_v1_api)
           coordinator_rpc_address
           address
           cctxt ->
        experimental_disclaimer () ;
        let coordinator_rpc_address =
          Uri.make
            ~scheme:coordinator_rpc_address.scheme
            ~host:coordinator_rpc_address.host
            ~port:coordinator_rpc_address.port
            ()
        in
        create_configuration
          ~data_dir
          ~reveal_data_dir
          ~rpc_address
          ~rpc_port
          ~allow_v1_api
          (Configuration.make_committee_member ~coordinator_rpc_address address)
          cctxt)

  let observer_command =
    let open Tezos_clic in
    let open Dac_clic_helpers in
    command
      ~group
      ~desc:"Configure DAC node in observer mode."
      (args6
         data_dir_arg
         rpc_address_arg
         rpc_port_arg
         reveal_data_dir_arg
         (timeout
            ~doc:
              (Format.sprintf
                 "Timeout, in seconds, when requesting a missing page from \
                  Committee Members. Defaults to %i.0 seconds."
                 Configuration.Observer.default_timeout))
         allow_v1_api_arg)
      (prefixes ["configure"; "as"; "observer"; "with"; "coordinator"]
      @@ coordinator_rpc_param
      @@ prefixes ["and"; "committee"; "member"; "rpc"; "addresses"]
      @@ seq_of_param @@ committee_rpc_addresses_param)
      (fun ( data_dir,
             rpc_address,
             rpc_port,
             reveal_data_dir,
             timeout,
             allow_v1_api )
           coordinator_rpc_address
           committee_rpc_addresses
           cctxt ->
        experimental_disclaimer () ;
        let committee_rpc_addresses =
          List.map
            (fun Parsed_rpc.{scheme; host; port} ->
              Uri.make ~scheme ~host ~port ())
            committee_rpc_addresses
        in
        let coordinator_rpc_address =
          Uri.make
            ~scheme:coordinator_rpc_address.scheme
            ~host:coordinator_rpc_address.host
            ~port:coordinator_rpc_address.port
            ()
        in
        create_configuration
          ~data_dir
          ~reveal_data_dir
          ~rpc_address
          ~rpc_port
          ~allow_v1_api
          (Configuration.make_observer
             ~committee_rpc_addresses
             ?timeout
             coordinator_rpc_address)
          cctxt)

  let commands =
    [coordinator_command; committee_member_command; observer_command]
end

let check_network cctxt =
  let open Lwt_syntax in
  let* r = Tezos_shell_services.Version_services.version cctxt in
  match r with
  | Error _ -> Lwt.return_none
  | Ok {network_version; _} ->
      let has_prefix prefix =
        String.has_prefix ~prefix (network_version.chain_name :> string)
      in
      if List.exists has_prefix ["TEZOS_BETANET"; "TEZOS_MAINNET"] then
        Lwt.return_some `Mainnet
      else Lwt.return_some `Testnet

let display_disclaimer cctxt =
  let open Lwt_syntax in
  let+ network_opt = check_network cctxt in
  match network_opt with
  | None -> experimental_disclaimer ()
  | Some `Mainnet -> experimental_disclaimer ()
  | Some `Testnet -> ()

let run_command =
  let open Tezos_clic in
  let open Lwt_result_syntax in
  command
    ~group
    ~desc:
      "Run the DAC node. Use --endpoint to configure the Octez node to connect \
       to (See Global options)."
    (args1 data_dir_arg)
    (prefixes ["run"] @@ stop)
    (fun data_dir cctxt ->
      let*! () = display_disclaimer cctxt in
      Daemon.run ~data_dir cctxt)

let commands () = [run_command] @ Config_init.commands

let select_commands _ _ =
  let open Lwt_result_syntax in
  return (commands ())

let () = Client_main_run.run (module Client_config) ~select_commands
