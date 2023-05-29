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

type file = Local of {path : string} | Remote of {url : string}

let file_encoding =
  Data_encoding.(
    conv
      (function Local {path = str} | Remote {url = str} -> str)
      (function
        | url when url =~ rex "https?://" -> Remote {url} | path -> Local {path})
      string)

let protocol_encoding =
  Protocol.all
  |> List.map (fun p -> (Protocol.tag p, p))
  |> Data_encoding.string_enum

type t = {
  network : string;
  snapshot : file option;
  protocol : Protocol.t;
  data_dir : string option;
}

let encoding =
  Data_encoding.(
    conv
      (fun {network; snapshot; protocol; data_dir} ->
        (network, snapshot, protocol, data_dir))
      (fun (network, snapshot, protocol, data_dir) ->
        {network; snapshot; protocol; data_dir})
      (obj4
         (req "network" string)
         (opt "snapshot" file_encoding)
         (req "protocol" protocol_encoding)
         (opt "data_dir" string)))

let file_of_string str =
  if str =~ rex "https?://" then Remote {url = str} else Local {path = str}

let get_testnet_config path =
  let conf = JSON.parse_file path in
  let snapshot =
    Option.map file_of_string JSON.(conf |-> "snapshot" |> as_string_opt)
  in
  let network = JSON.(conf |-> "network" |> as_string) in
  let data_dir = JSON.(conf |-> "data-dir" |> as_string_opt) in
  let protocol =
    let tags =
      List.map (fun proto -> (proto, Protocol.tag proto)) Protocol.all
    in
    let protocol_tag = JSON.(conf |-> "protocol" |> as_string) in
    match List.find_opt (fun (_proto, tag) -> tag = protocol_tag) tags with
    | Some (proto, _tag) -> proto
    | None -> failwith (protocol_tag ^ " is not a valid protocol name")
  in
  {snapshot; network; protocol; data_dir}

let from_cli () =
  let path = Command_line.get_config_path () in
  get_testnet_config path
