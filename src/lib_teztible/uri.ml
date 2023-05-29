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

type global_uri =
  | Managed of {owner : Agent_name.t; name : string}
  | Remote of {endpoint : string}

type agent_uri = Owned of {name : string} | Remote of {endpoint : string}

let global_uri_of_string ~self str =
  match str =~** rex {|^(.*)://(.*)$|} with
  | Some ("self", name) -> Managed {owner = self; name}
  | Some (p, name) -> (
      match Agent_name.name_of_string_opt p with
      | Some owner -> Managed {owner; name}
      | None -> Remote {endpoint = str})
  | None -> Remote {endpoint = str}

let agent_uri_encoding =
  let c = Helpers.make_mk_case () in
  Data_encoding.(
    union
      [
        c.mk_case
          "owned"
          (obj1 (req "owned" string))
          (function Owned {name} -> Some name | _ -> None)
          (fun name -> Owned {name});
        c.mk_case
          "remote"
          (obj1 (req "remote" string))
          (function Remote {endpoint} -> Some endpoint | _ -> None)
          (fun endpoint -> Remote {endpoint});
      ])

let agent_uri_of_global_uri ~services ~(self : Agent_name.t) = function
  | Managed {owner; name} ->
      if Agent_name.equal owner self then Owned {name}
      else
        let url, port = services owner name in
        Remote {endpoint = Format.sprintf "%s:%d" url port}
  | Remote {endpoint} -> Remote {endpoint}
