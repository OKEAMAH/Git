module Interpreter := Tezos_webassembly_interpreter
module Instance := Interpreter.Instance
module Ast := Interpreter.Ast
module Types := Interpreter.Types
module Source := Interpreter.Source

val module_gen :
  ?module_reg:Instance.module_reg -> unit -> Instance.module_inst QCheck2.Gen.t

val data_label_gen : Ast.data_label QCheck2.Gen.t

val block_label_gen : Ast.block_label QCheck2.Gen.t

val const_gen : Ast.block_label Source.phrase QCheck2.Gen.t

val import_desc_gen : Ast.import_desc' Source.phrase QCheck2.Gen.t

val start_gen : Ast.start' Source.phrase QCheck2.Gen.t

val export_desc_gen : Ast.export_desc' Source.phrase QCheck2.Gen.t

val block_type_gen : Ast.block_type QCheck2.Gen.t

val instr_gen : Ast.instr' Source.phrase QCheck2.Gen.t

val var_gen : int32 Source.phrase QCheck2.Gen.t

val segment_mode_gen : Ast.segment_mode' Source.phrase QCheck2.Gen.t

val value_type_gen : Types.value_type QCheck2.Gen.t

val ref_type_gen : Types.ref_type QCheck2.Gen.t

val table_type_gen : Types.table_type QCheck2.Gen.t

val memory_type_gen : Types.memory_type QCheck2.Gen.t

val global_type_gen : Types.global_type QCheck2.Gen.t
