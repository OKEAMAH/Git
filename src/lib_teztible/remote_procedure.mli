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

val file_encoding : file Data_encoding.t

val packed_encoding : string packed Data_encoding.t

val agent_packed_encoding : Uri.agent_uri packed Data_encoding.t

val response_encoding : ('a, 'uri) t -> 'a Data_encoding.t

val echo_obj_encoding : string Data_encoding.t

val start_octez_node_obj_encoding : (string * file option * int) Data_encoding.t

val originate_smart_rollup_obj_encoding :
  'uri Data_encoding.t ->
  (string * string * 'uri * string option) Data_encoding.t

val start_rollup_node_obj_encoding :
  'uri Data_encoding.t ->
  (string * 'uri * string * string * string) Data_encoding.t

val quit_obj_encoding : unit Data_encoding.t

val tvalue_of_response : ('a, 'uri) t -> 'a -> Jingoo.Jg_types.tvalue
