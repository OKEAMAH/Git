(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

(* module adapted from lib_sc_rollup_layer2/l1_operation.ml *)

open Protocol.Alpha_context

(* adapted from Operation_repr.manager_operation *)
type t =
  | Transaction of {
      amount : Tez.t;
      parameters : Script.lazy_expr;
      entrypoint : Entrypoint.t;
      destination : Contract.t;
    }

(* adapted from Operation_repr.Encoding.Manager_operations *)
let encoding : t Data_encoding.t =
  let open Data_encoding in
  let case tag kind encoding proj inj =
    case
      ~title:kind
      (Tag tag)
      (merge_objs (obj1 (req "kind" (constant kind))) encoding)
      (fun o -> Option.map (fun p -> ((), p)) (proj o))
      (fun ((), p) -> inj p)
  in
  def "injector_operation"
  @@ union
       [
         case
           0
           "transaction"
           (obj3
              (req "amount" Tez.encoding)
              (req "destination" Contract.encoding)
              (opt
                 "parameters"
                 (obj2
                    (req "entrypoint" Entrypoint.smart_encoding)
                    (req "value" Script.lazy_expr_encoding))))
           (function
             | Transaction {amount; destination; parameters; entrypoint} ->
                 let parameters =
                   if
                     Script.is_unit_parameter parameters
                     && Entrypoint.is_default entrypoint
                   then None
                   else Some (entrypoint, parameters)
                 in
                 Some (amount, destination, parameters))
           (fun (amount, destination, parameters) ->
             let entrypoint, parameters =
               match parameters with
               | None -> (Entrypoint.default, Script.unit_parameter)
               | Some (entrypoint, value) -> (entrypoint, value)
             in
             Transaction {amount; destination; parameters; entrypoint});
       ]

let pp ppf = function
  | Transaction {amount; destination = _; parameters = _; entrypoint = _} ->
      Format.fprintf ppf "Transaction of %a tez" Tez.pp amount

let to_manager_operation : t -> packed_manager_operation = function
  | Transaction {amount; destination; parameters; entrypoint} ->
      Manager (Transaction {amount; destination; parameters; entrypoint})

let of_manager_operation : type kind. kind manager_operation -> t option =
  function
  | Transaction {amount; destination; parameters; entrypoint} ->
      Some (Transaction {amount; destination; parameters; entrypoint})
  | _ -> None

let unique = function Transaction _ -> true
