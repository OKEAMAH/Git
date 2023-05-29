(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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

module SMap = Map.Make (String)

type request = {
  proc_id : int;
  procedure : Uri.agent_uri Remote_procedure.packed;
}

let request_encoding =
  Data_encoding.(
    conv
      (fun {proc_id; procedure} -> (proc_id, procedure))
      (fun (proc_id, procedure) -> {proc_id; procedure})
      (obj2
         (req "id" int31)
         (req "procedure" Remote_procedure.agent_packed_encoding)))

type state = {
  home_dir : string;
  mutable continue : bool;
  mutable octez_nodes : Node.t SMap.t;
  mutable rollup_nodes : Sc_rollup_node.t SMap.t;
}

let initial_state ~home_dir () =
  {
    home_dir;
    continue = true;
    octez_nodes = SMap.empty;
    rollup_nodes = SMap.empty;
  }

let setup_octez_node ~network ~sync_threshold
    ?(snapshot : Remote_procedure.file option) ?path ?runner () =
  let l1_node_args =
    Node.
      [
        Expected_pow 26;
        Synchronisation_threshold sync_threshold;
        Network network;
      ]
  in
  (* By default, Tezt set the difficulty to generate the identity file
     of the Octez node to 0 (`--expected-pow 0`). The default value
     used in network like mainnet, Mondaynet etc. is 26 (see
     `lib_node_config/config_file.ml`). *)
  let node = Node.create ?path ?runner l1_node_args in
  let* () = Node.config_init node [] in
  let* () =
    match snapshot with
    | Some snapshot ->
        Log.info "Import snapshot" ;
        let* snapshot =
          match snapshot with
          | Remote {url = snapshot} ->
              Helpers.download ?runner snapshot "snapshot"
          | Local {path} -> return path
        in
        let* () = Node.snapshot_import ~no_check:true node snapshot in
        Log.info "Snapshot imported" ;
        unit
    | None -> unit
  in
  let* () = Node.run node [] in
  let* () = Node.wait_for_ready node in
  let client = Client.create ~endpoint:(Node node) () in
  let* () = Client.bootstrapped client in
  return (client, node)

let parse_endpoint str =
  match str =~*** rex {|^(https?)://(.*):(\d+)|} with
  | Some (scheme, host, port_str) ->
      Client.Foreign_endpoint {host; scheme; port = int_of_string port_str}
  | None -> (
      match str =~** rex {|^(.*):(\d+)|} with
      | Some (host, port_str) ->
          Foreign_endpoint
            {host; scheme = "http"; port = int_of_string port_str}
      | None -> raise (Invalid_argument "parse_endpoint"))

let run_procedure :
    type a. state -> (a, Uri.agent_uri) Remote_procedure.t -> a Lwt.t =
  let open Remote_procedure in
  fun state -> function
    | Quit ->
        state.continue <- false ;
        return ()
    | Start_octez_node {network; snapshot; sync_threshold} ->
        let* _, octez_node =
          setup_octez_node ~network ~sync_threshold ?snapshot ()
        in
        state.octez_nodes <-
          SMap.add (Node.name octez_node) octez_node state.octez_nodes ;
        return
          {rpc_port = Node.rpc_port octez_node; name = Node.name octez_node}
    | Originate_smart_rollup {alias; src; with_endpoint; with_wallet} ->
        let client =
          match with_endpoint with
          | Owned {name = with_node} ->
              let octez_node = SMap.find with_node state.octez_nodes in
              Client.create ~endpoint:(Node octez_node) ?base_dir:with_wallet ()
          | Remote {endpoint} ->
              Client.create
                ~endpoint:(parse_endpoint endpoint)
                ?base_dir:with_wallet
                ()
        in

        let* address =
          Client.Sc_rollup.originate
            client
            ~wait:"0"
            ~alias
            ~src
            ~kind:"wasm_2_0_0"
            ~parameters_ty:"unit"
            ~boot_sector:"00"
            ~burn_cap:(Tez.of_int 2)
        in
        Log.info "Rollup %s originated" address ;
        return {address}
    | Start_rollup_node {with_wallet; with_endpoint; mode; operator; address} ->
        let l1_endpoint =
          match with_endpoint with
          | Owned {name = with_node} ->
              let octez_node = SMap.find with_node state.octez_nodes in
              Client.Node octez_node
          | Remote {endpoint} -> parse_endpoint endpoint
        in
        (* TODO: path to binaries should be a parameter *)
        let rollup_node =
          Sc_rollup_node.(
            create_with_endpoint
              (mode_of_string mode)
              ~default_operator:operator
              l1_endpoint
              ~path:"./octez-smart-rollup-node"
              ~base_dir:with_wallet)
        in
        let* () = Sc_rollup_node.run rollup_node address [] in
        let* _ = Sc_rollup_node.unsafe_wait_sync rollup_node in
        state.rollup_nodes <-
          SMap.add
            (Sc_rollup_node.name rollup_node)
            rollup_node
            state.rollup_nodes ;
        return
          (Start_rollup_node_r
             {
               name = Sc_rollup_node.name rollup_node;
               rpc_port = Sc_rollup_node.rpc_port rollup_node;
             })
    | Echo {payload} -> return {payload}

let rec try_read_line ~input state k =
  let* res =
    Lwt.pick
      [
        (let* line = Lwt_io.read_line input in
         return (`Read line));
        (let* () = Lwt_unix.sleep 1.0 in
         return `Timeout);
      ]
  in
  match res with
  | `Read line -> k line
  | `Timeout -> if state.continue then try_read_line ~input state k else unit

let rec run ~input ~output state =
  try_read_line ~input state @@ fun req_str ->
  let* _ =
    Lwt.both (if state.continue then run ~input ~output state else return ())
    @@
    match Helpers.of_json_string request_encoding req_str with
    | {proc_id; procedure = Packed proc} ->
        Log.debug ">>[%d]" proc_id ;
        let* res = run_procedure state proc in
        Lwt_io.atomic
          (fun output ->
            Lwt_io.write_line
              output
              Format.(
                sprintf
                  "<<[%d]: %s"
                  proc_id
                  (Helpers.to_json_string
                     (Remote_procedure.response_encoding proc)
                     res)))
          output
  in
  unit
