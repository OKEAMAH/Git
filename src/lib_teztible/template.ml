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

open Jingoo
open Jg_types

let run ?agent ~(vars : Global_variables.t) ~(res : tvalue) ~re ~item template =
  Jg_template.from_string
    ~models:
      [
        ( "var",
          Tfun
            (fun ?kwargs:_ tvalue ->
              match tvalue with
              | Tstr key -> Global_variables.(get vars key |> tvalue_of_var)
              | _ -> raise (Invalid_argument "Template.run: invalid input")) );
        ("vars", Global_variables.tvalue_of_vars vars);
        ("res", res);
        ("re", re);
        ("item", item);
        ( "agent",
          match agent with
          | Some agent ->
              Tobj [("name", Tstr (Remote_agent.name agent :> string))]
          | None -> Tnull );
      ]
    template

let no_re = Tnull

let no_item = Tnull

let no_res = Tnull

let expand_update_var ~vars ~agent ~re ~item ~res u =
  let open Global_variables in
  let run = run ~vars ~agent ~res ~re ~item in
  let key = run u.key in
  let value = Option.map run u.value in
  {u with key; value}

let expand_item ~vars ~agent ~re def =
  match Global_variables.tvalue_of_var def with
  | Tstr def -> (
      let def = run ~vars ~agent ~re ~item:no_item ~res:no_res def in
      match def =~** rex {|(\d+)\.\.(\d+)|} with
      | Some (range_from, range_to) ->
          let range_from = int_of_string range_from in
          let range_to = int_of_string range_to in
          Seq.init (range_to - range_from + 1) (fun x -> Tint (range_from + x))
      | None -> (
          match int_of_string_opt def with
          | Some i -> Seq.return (Tint i)
          | None -> (
              match bool_of_string_opt def with
              | Some b -> Seq.return (Tbool b)
              | None -> Seq.return (Tstr def))))
  | x -> Seq.return x

let expand_remote_procedure ~vars ~agent ~re ~item
    (Remote_procedure.Packed procedure) =
  let open Remote_procedure in
  let run = run ~vars ~agent ~re ~item ~res:Tnull in
  match procedure with
  | Quit -> Packed Quit
  | Echo {payload} ->
      let payload = run payload in
      Packed (Echo {payload})
  | Start_octez_node {network; snapshot; sync_threshold} ->
      let network = run network in
      let snapshot =
        Option.map
          (function
            | Remote {url} -> Remote {url = run url}
            | Local {path} -> Local {path = run path})
          snapshot
      in
      (* TODO: allow to expand [sync_threshold] *)
      Packed (Start_octez_node {network; snapshot; sync_threshold})
  | Originate_smart_rollup {with_wallet; with_endpoint; alias; src} ->
      let with_wallet = Option.map run with_wallet in
      let with_endpoint = run with_endpoint in
      let with_endpoint =
        Uri.global_uri_of_string ~self:(Remote_agent.name agent) with_endpoint
      in
      let alias = run alias in
      let src = run src in
      Packed (Originate_smart_rollup {with_wallet; with_endpoint; alias; src})
  | Start_rollup_node {with_wallet; with_endpoint; operator; mode; address} ->
      let with_wallet = run with_wallet in
      let with_endpoint = run with_endpoint in
      let with_endpoint =
        Uri.global_uri_of_string ~self:(Remote_agent.name agent) with_endpoint
      in
      let operator = run operator in
      let mode = run mode in
      let address = run address in
      Packed
        (Start_rollup_node {with_wallet; with_endpoint; operator; mode; address})

let expand_job_body ~vars ~agent ~re ~item =
  let run = run ~vars ~agent ~re ~item ~res:no_res in
  function
  | Job.Remote_procedure {procedure} ->
      Job.Remote_procedure
        {procedure = expand_remote_procedure ~vars ~agent ~re ~item procedure}
  | Copy {source; destination} ->
      let source = run source in
      let destination = run destination in
      Copy {source; destination}

let expand_agent ~vars = run ~vars ~re:no_re ~res:no_res ~item:no_item
