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

type item = Global_variables.var

type header = {
  name : string;
  with_items : item list option;
  mode : Execution_params.mode;
  vars_updates : Global_variables.update list;
}

type 'uri body =
  | Remote_procedure of {procedure : 'uri Remote_procedure.packed}
  | Copy of {source : string; destination : string}

type 'uri t = {header : header; body : 'uri body}

(** {1 Encodings} *)

let header_encoding =
  Data_encoding.(
    conv
      (fun {name; with_items; mode; vars_updates} ->
        (name, with_items, mode, vars_updates))
      (fun (name, with_items, mode, vars_updates) ->
        {name; with_items; mode; vars_updates})
      (obj4
         (req "name" string)
         (opt "with_items" (list Global_variables.var_encoding))
         (dft "run_items" Execution_params.mode_encoding Sequential)
         (dft "vars_updates" Global_variables.updates_encoding [])))

let encoding =
  let merged_encoding tuple_encoding =
    Data_encoding.(merge_objs header_encoding tuple_encoding)
  in
  let c = Helpers.make_mk_case () in
  Data_encoding.(
    union
      [
        c.mk_case
          "copy"
          (merged_encoding
             (obj1
                (req
                   "copy"
                   (obj2 (req "local_path" string) (req "remote_path" string)))))
          (function
            | {header; body = Copy {source; destination}} ->
                Some (header, (source, destination))
            | _ -> None)
          (fun (header, (source, destination)) ->
            {header; body = Copy {source; destination}});
        c.mk_case
          "echo"
          (merged_encoding Remote_procedure.echo_obj_encoding)
          (function
            | {
                header;
                body = Remote_procedure {procedure = Packed (Echo {payload})};
              } ->
                Some (header, payload)
            | _ -> None)
          (fun (header, payload) ->
            {
              header;
              body = Remote_procedure {procedure = Packed (Echo {payload})};
            });
        c.mk_case
          "quit"
          (merged_encoding Remote_procedure.quit_obj_encoding)
          (function
            | {header; body = Remote_procedure {procedure = Packed Quit}} ->
                Some (header, ())
            | _ -> None)
          (fun (header, ()) ->
            {header; body = Remote_procedure {procedure = Packed Quit}});
        c.mk_case
          "start_octez_node"
          (merged_encoding Remote_procedure.start_octez_node_obj_encoding)
          (function
            | {
                header;
                body =
                  Remote_procedure
                    {
                      procedure =
                        Packed
                          (Start_octez_node {network; snapshot; sync_threshold});
                    };
              } ->
                Some (header, (network, snapshot, sync_threshold))
            | _ -> None)
          (fun (header, (network, snapshot, sync_threshold)) ->
            {
              header;
              body =
                Remote_procedure
                  {
                    procedure =
                      Packed
                        (Start_octez_node {network; snapshot; sync_threshold});
                  };
            });
        c.mk_case
          "originate_smart_rollup"
          (merged_encoding
             (Remote_procedure.originate_smart_rollup_obj_encoding
                Data_encoding.string))
          (function
            | {
                header;
                body =
                  Remote_procedure
                    {
                      procedure =
                        Packed
                          (Originate_smart_rollup
                            {alias; src; with_endpoint; with_wallet});
                    };
              } ->
                Some (header, (alias, src, with_endpoint, with_wallet))
            | _ -> None)
          (fun (header, (alias, src, with_endpoint, with_wallet)) ->
            {
              header;
              body =
                Remote_procedure
                  {
                    procedure =
                      Packed
                        (Originate_smart_rollup
                           {alias; src; with_endpoint; with_wallet});
                  };
            });
        c.mk_case
          "start_rollup_node"
          (merged_encoding
             (Remote_procedure.start_rollup_node_obj_encoding
                Data_encoding.string))
          (function
            | {
                header;
                body =
                  Remote_procedure
                    {
                      procedure =
                        Packed
                          (Start_rollup_node
                            {
                              with_wallet;
                              with_endpoint;
                              operator;
                              mode;
                              address;
                            });
                    };
              } ->
                Some
                  (header, (with_wallet, with_endpoint, operator, mode, address))
            | _ -> None)
          (fun (header, (with_wallet, with_endpoint, operator, mode, address)) ->
            {
              header;
              body =
                Remote_procedure
                  {
                    procedure =
                      Packed
                        (Start_rollup_node
                           {with_wallet; with_endpoint; operator; mode; address});
                  };
            });
      ])
