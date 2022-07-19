(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 TriliTech <contact@trili.tech>                         *)
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

open Tezos_webassembly_interpreter

exception Uninitialized_current_module

module Make
    (M : Tree_encoding_decoding.S
           with type vector_key = int32
            and type 'a vector = 'a Instance.Vector.t
            and type 'a map = 'a Instance.NameMap.t
            and type chunked_byte_vector = Chunked_byte_vector.Lwt.t) : sig
  type tree = M.tree

  type 'a t = 'a M.t

  val var_list_encoding : Ast.var list t

  val instruction_list_encoding : Ast.instr list t

  val function_encoding :
    current_module:Instance.module_inst ref -> Instance.func_inst t

  val value_ref_encoding :
    current_module:Instance.module_inst ref -> Values.ref_ t

  val value_encoding : current_module:Instance.module_inst ref -> Values.value t

  val memory_encoding : Partial_memory.memory t

  val table_encoding :
    current_module:Instance.module_inst ref -> Partial_table.table t

  val global_encoding :
    current_module:Instance.module_inst ref -> Global.global t

  val memory_instance_encoding : Partial_memory.memory Instance.Vector.t t

  val table_vector_encoding :
    current_module:Instance.module_inst ref ->
    Partial_table.table Instance.Vector.t t

  val global_vector_encoding :
    current_module:Instance.module_inst ref -> Global.global Instance.Vector.t t

  val chunked_byte_vector_ref_encoding : Chunked_byte_vector.Lwt.t ref t

  val function_vector_encoding :
    current_module:Instance.module_inst ref ->
    Instance.func_inst Instance.Vector.t t

  val function_type_vector_encoding : Types.func_type Instance.Vector.t t

  val value_ref_vector_encoding :
    current_module:Instance.module_inst ref -> Values.ref_ Instance.Vector.t t

  val extern_map_encoding :
    current_module:Instance.module_inst ref ->
    Instance.extern Instance.NameMap.t t

  val value_ref_vector_vector_encoding :
    current_module:Instance.module_inst ref ->
    Values.ref_ Instance.Vector.t ref Instance.Vector.t t

  val block_table_encoding : Ast.block_table t

  val module_instance_encoding : Instance.module_inst t
end
