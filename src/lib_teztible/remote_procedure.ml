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

type (_, 'uri) t =
  | Quit : (unit, 'uri) t
  | Echo : {payload : string} -> (echo_r, 'uri) t
  | Start_octez_node : {
      network : string;
      snapshot : file option;
      sync_threshold : int;
    }
      -> (start_octez_node_r, 'uri) t
  | Originate_smart_rollup : {
      with_wallet : string option;
      with_endpoint : 'uri;
      alias : string;
      src : string;
    }
      -> (originate_smart_rollup_r, 'uri) t
  | Start_rollup_node : {
      with_wallet : string;
      with_endpoint : 'uri;
      operator : string;
      mode : string;
      address : string;
    }
      -> (start_rollup_node_r, 'uri) t

and echo_r = {payload : string}

and start_octez_node_r = {name : string; rpc_port : int}

and originate_smart_rollup_r = {address : string}

and start_rollup_node_r =
  | Start_rollup_node_r of {name : string; rpc_port : int}

type 'uri packed = Packed : ('a, 'uri) t -> 'uri packed

(** {1 Encodings} *)

let file_encoding =
  Data_encoding.(
    conv
      (function Local {path = str} | Remote {url = str} -> str)
      (function
        | url when url =~ rex "https?://" -> Remote {url} | path -> Local {path})
      string)

let echo_r_encoding =
  Data_encoding.(
    conv
      (fun {payload} -> payload)
      (fun payload -> {payload})
      (obj1 (req "payload" string)))

let start_octez_node_r_encoding =
  Data_encoding.(
    conv
      (fun {rpc_port; name} -> (rpc_port, name))
      (fun (rpc_port, name) -> {rpc_port; name})
      (obj2 (req "rpc_port" int31) (req "name" string)))

let start_rollup_node_r_encoding =
  Data_encoding.(
    conv
      (fun (Start_rollup_node_r {rpc_port; name}) -> (rpc_port, name))
      (fun (rpc_port, name) -> Start_rollup_node_r {rpc_port; name})
      (obj2 (req "rpc_port" int31) (req "name" string)))

let originate_smart_rollup_r_encoding =
  Data_encoding.(
    conv
      (fun {address} -> address)
      (fun address -> {address})
      (obj1 (req "address" string)))

let response_encoding : type a. (a, 'uri) t -> a Data_encoding.t = function
  | Echo _ -> echo_r_encoding
  | Start_octez_node _ -> start_octez_node_r_encoding
  | Originate_smart_rollup _ -> originate_smart_rollup_r_encoding
  | Start_rollup_node _ -> start_rollup_node_r_encoding
  | Quit -> Data_encoding.null

let obj_encoding ~title enc = Data_encoding.(obj1 (req title enc))

let echo_obj_encoding = obj_encoding ~title:"echo" Data_encoding.(string)

let start_octez_node_obj_encoding =
  obj_encoding
    ~title:"start_octez_node"
    Data_encoding.(
      obj3
        (dft "network" string "{{ network }}")
        (opt "snapshot" file_encoding)
        (dft "synchronization_threshold" int31 1))

let originate_smart_rollup_obj_encoding uri_encoding =
  obj_encoding
    ~title:"originate_smart_rollup"
    Data_encoding.(
      obj4
        (dft "alias" string "rollup")
        (req "source" string)
        (req "with_endpoint" uri_encoding)
        (opt "with_wallet" string))

let start_rollup_node_obj_encoding uri_encoding =
  obj_encoding
    ~title:"start_rollup_node"
    Data_encoding.(
      obj5
        (req "with_wallet" string)
        (req "with_endpoint" uri_encoding)
        (req "operator" string)
        (req "mode" string)
        (req "address" string))

let quit_obj_encoding = obj_encoding ~title:"quit" Data_encoding.null

let gen_packed_encoding uri_encoding =
  let open Data_encoding in
  let c = Helpers.make_mk_case () in
  union
    [
      c.mk_case
        "echo"
        echo_obj_encoding
        (function Packed (Echo {payload}) -> Some payload | _ -> None)
        (fun payload -> Packed (Echo {payload}));
      c.mk_case
        "start_octez_node"
        start_octez_node_obj_encoding
        (function
          | Packed (Start_octez_node {network; snapshot; sync_threshold}) ->
              Some (network, snapshot, sync_threshold)
          | _ -> None)
        (fun (network, snapshot, sync_threshold) ->
          Packed (Start_octez_node {network; snapshot; sync_threshold}));
      c.mk_case
        "originate_smart_rollup"
        (originate_smart_rollup_obj_encoding uri_encoding)
        (function
          | Packed
              (Originate_smart_rollup {alias; src; with_endpoint; with_wallet})
            ->
              Some (alias, src, with_endpoint, with_wallet)
          | _ -> None)
        (fun (alias, src, with_endpoint, with_wallet) ->
          Packed
            (Originate_smart_rollup {alias; src; with_endpoint; with_wallet}));
      c.mk_case
        "start_rollup_node"
        (start_rollup_node_obj_encoding uri_encoding)
        (function
          | Packed
              (Start_rollup_node
                {with_wallet; with_endpoint; operator; mode; address}) ->
              Some (with_wallet, with_endpoint, operator, mode, address)
          | _ -> None)
        (fun (with_wallet, with_endpoint, operator, mode, address) ->
          Packed
            (Start_rollup_node
               {with_wallet; with_endpoint; operator; mode; address}));
      c.mk_case
        "quit"
        quit_obj_encoding
        (function Packed Quit -> Some () | _ -> None)
        (fun () -> Packed Quit);
    ]

let packed_encoding = gen_packed_encoding Data_encoding.string

let agent_packed_encoding = gen_packed_encoding Uri.agent_uri_encoding

(** {1 [tvalue] converters} *)

open Jingoo.Jg_types

let tvalue_of_echo_r {payload} = Tobj [("payload", Tstr payload)]

let tvalue_of_start_octez_node_r {rpc_port; name} =
  Tobj [("rpc_port", Tint rpc_port); ("name", Tstr name)]

let tvalue_of_originate_smart_rollup_r {address} =
  Tobj [("address", Tstr address)]

let tvalue_of_start_rollup_node_r (Start_rollup_node_r {rpc_port; name}) =
  Tobj [("rpc_port", Tint rpc_port); ("name", Tstr name)]

let tvalue_of_response : type a. (a, 'uri) t -> a -> tvalue = function
  | Echo _ -> tvalue_of_echo_r
  | Start_octez_node _ -> tvalue_of_start_octez_node_r
  | Originate_smart_rollup _ -> tvalue_of_originate_smart_rollup_r
  | Start_rollup_node _ -> tvalue_of_start_rollup_node_r
  | Quit -> fun () -> Tnull
