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

type t = {host : string; scheme : string; port : int}

let rpc_host {host; _} = host

let rpc_port {port; _} = port

let rpc_scheme {scheme; _} = scheme

let as_string {scheme; host; port} =
  Printf.sprintf "%s://%s:%d" scheme host port
  

let of_string s =
  let mk scheme host port =
    try
      let port = int_of_string port in
      {scheme; host; port}
    with _ -> Test.fail "Bad port %s in endpoint %s" port s
  in
  match String.split_on_char ':' s with
  | [scheme; "//"; host; port] -> mk scheme host port
  | [host; port] -> mk "http" host port
  | _ -> Test.fail "Bad endpoint %s" s

let encoding =
  let open Data_encoding in
  conv
    (fun {scheme; host; port} -> (scheme, host, port))
    (fun (scheme, host, port) -> {scheme; host; port})
    (obj3 (dft "scheme" string "http") (req "host" string) (req "port" uint16))
