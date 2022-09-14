(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020-2021 Nomadic Labs <contact@nomadic-labs.com>           *)
(* Copyright (c) 2020 Metastate AG <hello@metastate.dev>                     *)
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

(* Declaration order must respect the version order. *)
type t = Jakarta | Kathmandu | LAlpha | Alpha

type constants = Constants_sandbox | Constants_mainnet | Constants_test

let name = function
  | Alpha -> "Alpha"
  | LAlpha -> "LAlpha"
  | Jakarta -> "Jakarta"
  | Kathmandu -> "Kathmandu"

let number = function
  | Jakarta -> 013
  | Kathmandu -> 014
  | LAlpha -> 015
  | Alpha -> 016

let directory = function
  | Jakarta -> "proto_013_PtJakart"
  | Kathmandu -> "proto_014_PtKathma"
  | LAlpha -> "proto_015_PrnJXeU4"
  | Alpha -> "proto_alpha"

(* Test tags must be lowercase. *)
let tag protocol = String.lowercase_ascii (name protocol)

let hash = function
  | Jakarta -> "PtJakart2xVj7pYXJBXrqHgd82rdkLey5ZeeGwDgPp9rhQUbSqY"
  | Kathmandu -> "PtKathmankSpLLDALzWw7CGD2j2MtyveTwboEYokqUCP4a1LxMg"
  | LAlpha -> "PrnJXeU4v7EpcwXSFDciqWCqh8pMBZCHgaFnHZUXkdFs5nPYDcr"
  | Alpha -> "ProtoALphaALphaALphaALphaALphaALphaALphaALphaDdp3zK"

let genesis_hash = "ProtoGenesisGenesisGenesisGenesisGenesisGenesk612im"

let demo_noops_hash = "ProtoDemoNoopsDemoNoopsDemoNoopsDemoNoopsDemo6XBoYp"

let demo_counter_hash = "ProtoDemoCounterDemoCounterDemoCounterDemoCou4LSpdT"

let default_constants = Constants_sandbox

let parameter_file ?(constants = default_constants) protocol =
  let name =
    match constants with
    | Constants_sandbox -> "sandbox"
    | Constants_mainnet -> "mainnet"
    | Constants_test -> "test"
  in
  sf "src/%s/parameters/%s-parameters.json" (directory protocol) name

let daemon_name = function
  | Jakarta -> "013-PtJakart"
  | Kathmandu -> "014-PtKathma"
  | LAlpha -> "015-PrnJXeU4"
  | Alpha -> "alpha"

let accuser proto = "./tezos-accuser-" ^ daemon_name proto

let baker proto = "./tezos-baker-" ^ daemon_name proto

let sc_rollup_node proto = "./tezos-sc-rollup-node-" ^ daemon_name proto

let encoding_prefix = daemon_name

type parameter_overrides = (string list * string option) list

let write_parameter_file :
    ?additional_bootstrap_accounts:(Account.key * int option) list ->
    base:(string, t * constants option) Either.t ->
    parameter_overrides ->
    string Lwt.t =
 fun ?(additional_bootstrap_accounts = []) ~base parameter_overrides ->
  (* make a copy of the parameters file and update the given constants *)
  let overriden_parameters = Temp.file "parameters.json" in
  let original_parameters =
    let file =
      Either.fold
        ~left:Fun.id
        ~right:(fun (x, constants) -> parameter_file ?constants x)
        base
    in
    JSON.parse_file file |> JSON.unannotate
  in
  let parameters =
    List.fold_left
      (fun acc (path, value) ->
        let parsed_value = Option.map Ezjsonm.value_from_string value in
        Ezjsonm.update acc path parsed_value)
      original_parameters
      parameter_overrides
  in
  let parameters =
    let bootstrap_accounts = ["bootstrap_accounts"] in
    let existing_accounts =
      Ezjsonm.get_list Fun.id (Ezjsonm.find parameters bootstrap_accounts)
    in
    let additional_bootstrap_accounts =
      List.map
        (fun ((account : Account.key), default_balance) ->
          `A
            [
              `String account.public_key_hash;
              `String
                (string_of_int
                   (Option.value ~default:4000000000000 default_balance));
            ])
        additional_bootstrap_accounts
    in
    Ezjsonm.update
      parameters
      bootstrap_accounts
      (Some (`A (existing_accounts @ additional_bootstrap_accounts)))
  in
  JSON.encode_to_file_u overriden_parameters parameters ;
  Lwt.return overriden_parameters

let next_protocol = function
  | Jakarta -> Some Kathmandu
  | Kathmandu -> Some LAlpha
  | LAlpha -> Some Alpha
  | Alpha -> None

let previous_protocol = function
  | Alpha -> Some LAlpha
  | LAlpha -> Some Kathmandu
  | Kathmandu -> Some Jakarta
  | Jakarta -> None

let all = [Alpha; Jakarta; Kathmandu]

type supported_protocols =
  | Any_protocol
  | From_protocol of int
  | Until_protocol of int
  | Between_protocols of int * int

let is_supported supported_protocols protocol =
  match supported_protocols with
  | Any_protocol -> true
  | From_protocol n -> number protocol >= n
  | Until_protocol n -> number protocol <= n
  | Between_protocols (a, b) ->
      let n = number protocol in
      a <= n && n <= b

let show_supported_protocols = function
  | Any_protocol -> "Any_protocol"
  | From_protocol n -> sf "From_protocol %d" n
  | Until_protocol n -> sf "Until_protocol %d" n
  | Between_protocols (a, b) -> sf "Between_protocol (%d, %d)" a b

let iter_on_supported_protocols ~title ~protocols ?(supports = Any_protocol) f =
  match List.filter (is_supported supports) protocols with
  | [] ->
      failwith
        (sf
           "test %s was registered with ~protocols:[%s] %s, which results in \
            an empty list of protocols"
           title
           (String.concat ", " (List.map name protocols))
           (show_supported_protocols supports))
  | supported_protocols -> List.iter f supported_protocols

(* Used to ensure that [register_test] and [register_regression_test]
   share the same conventions. *)
let add_to_test_parameters protocol title tags =
  (name protocol ^ ": " ^ title, tag protocol :: tags)

let register_test ~__FILE__ ~title ~tags ?supports body protocols =
  iter_on_supported_protocols ~title ~protocols ?supports @@ fun protocol ->
  let title, tags = add_to_test_parameters protocol title tags in
  Test.register ~__FILE__ ~title ~tags (fun () -> body protocol)

let register_long_test ~__FILE__ ~title ~tags ?supports ?team ~executors
    ~timeout body protocols =
  iter_on_supported_protocols ~title ~protocols ?supports @@ fun protocol ->
  let title, tags = add_to_test_parameters protocol title tags in
  Long_test.register ~__FILE__ ~title ~tags ?team ~executors ~timeout (fun () ->
      body protocol)

let register_regression_test ~__FILE__ ~title ~tags ?supports body protocols =
  iter_on_supported_protocols ~title ~protocols ?supports @@ fun protocol ->
  let title, tags = add_to_test_parameters protocol title tags in
  Regression.register ~__FILE__ ~title ~tags (fun () -> body protocol)
