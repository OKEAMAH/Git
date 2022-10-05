(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.tech>                       *)
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

(** The DAC node is responsible for indexing pre-reveal images by their hashes,
    store them on disk, and handle request to publish the availability of reveal
    images to the L1.
 *)

(* DAC/TODO: <insert issue here>
   We need to agree on what data is published exactly on the L1.
*)

let group =
  {
    Clic.name = "dac.node";
    title = "Commands related to the Data Availability Committee node.";
  }

let data_dir_arg =
  let default = Configuration.default_data_dir in
  Clic.default_arg
    ~long:"data-dir"
    ~placeholder:"data-dir"
    ~doc:
      (Format.sprintf
         "The path to the smart-contract rollup node data directory. Default \
          value is %s"
         default)
    ~default
    Client_proto_args.string_parameter

let config_init_command =
  let open Clic in
  command
    ~group
    ~desc:"Run the DAC Node."
    (args1 data_dir_arg)
    (prefixes ["config; init"] @@ stop)
    (fun _data_dir _cctxt -> return ())

let run_command =
  let open Clic in
  command
    ~group
    ~desc:"Run the DAC Node."
    (args1 data_dir_arg)
    (prefixes ["run"] @@ stop)
    (fun _data_dir _cctxt -> Daemon.run ())

let select_commands _ _ =
  Lwt_result.return
  @@ List.map
       (Clic.map_command (new Protocol_client_context.wrap_full))
       [config_init_command; run_command]

let () = Client_main_run.run (module Daemon_config) ~select_commands
