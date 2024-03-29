(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020 Nomadic Labs. <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 DaiLambda, Inc. <contact@dailambda.jp>                 *)
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

type solution = {
  (* The data required to perform code generation is a map from variables to
     (floating point) coefficients. *)
  map : float Free_variable.Map.t;
  (* The scores of the models with the estimated coefficients. *)
  scores_list : ((string * Namespace.t) * Inference.scores) list;
}

(** [get_codegen_destinations model_info] will return 
    the generated code destination in which given model is used
  *)
val get_codegen_destination : Registration.model_info -> string option

val solution_encoding : solution Data_encoding.t

val pp_solution : Format.formatter -> solution -> unit

(** Load a solution form a binary or JSON file *)
val load_solution : string -> solution

(** Save the given solution to binary and JSON files *)
val save_solution : solution -> string -> unit

val solution_to_csv : solution -> Csv.csv

(** Generated code for a model *)
type code

type module_

(** Build the cost function codes of the specified model *)
val codegen :
  Model.packed_model -> solution -> Costlang.transform -> Namespace.t -> code

(** [codegen_models models solution transform] generates
    the cost function codes of multiple [models].
*)
val codegen_models :
  (Namespace.t * Registration.model_info) list ->
  solution ->
  Costlang.transform ->
  (string option * code) list

(** Make a comment *)
val comment : string list -> code

(** Make a toplevel module (an .ml file) from the given list of codes *)
val make_toplevel_module : code list -> module_

val pp_code : Format.formatter -> code -> unit

val pp_module : Format.formatter -> module_ -> unit

(** Get the function name of [code] if it has *)
val get_name_of_code : code -> string option

module Parser : sig
  (** [get_cost_functions fn] extracts the cost function names of
      OCaml source file [fn]. *)
  val get_cost_functions : string -> (string list, exn) result
end
