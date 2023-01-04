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

open Tezos_scoru_wasm
open Wasm_utils
module Int32Vector = Tezos_lazy_containers.Lazy_vector.Int32Vector

(* Pattern language for instructions *)
module Patterns = struct
  open Tezos_webassembly_interpreter
  open Ast
  open Types

  type instr' =
    | PUnreachable (* trap unconditionally *)
    | PNop (* do nothing *)
    | PDrop (* forget a value *)
    | PSelect of value_type list option option (* branchless conditional *)
    | PBlock of block_type option * block_label option (* execute in sequence *)
    | PLoop of block_type option * block_label option (* loop header *)
    | PIf of block_type * block_label * block_label (* conditional *)
    | PBr of int32 option (* break to n-th surrounding label *)
    | PBrIf of int32 option (* conditional break *)
    | PBrTable of int32 list option * int32 option (* indexed break *)
    | PReturn (* break from function body *)
    | PCall of int32 option (* call function *)
    | PCallIndirect of
        int32 option * int32 option (* call function through table *)
    | PLocalGet of int32 option (* read local variable *)
    | PLocalSet of int32 option (* write local variable *)
    | PLocalTee of int32 option (* write local variable and keep value *)
    | PGlobalGet of int32 option (* read global variable *)
    | PGlobalSet of int32 option (* write global variable *)
    | PTableGet of int32 option (* read table element *)
    | PTableSet of int32 option (* write table element *)
    | PTableSize of int32 option (* size of table *)
    | PTableGrow of int32 option (* grow table *)
    | PTableFill of int32 option (* fill table range with value *)
    | PTableCopy of int32 option * int32 option (* copy table range *)
    | PTableInit of
        int32 option * int32 option (* initialize table range from segment *)
    | PElemDrop of int32 option (* drop passive element segment *)
    | PLoad of loadop option (* read memory at address *)
    | PStore of storeop option (* write memory at address *)
    | PVecLoad of vec_loadop option (* read memory at address *)
    | PVecStore of vec_storeop option (* write memory at address *)
    | PVecLoadLane of vec_laneop option (* read single lane at address *)
    | PVecStoreLane of vec_laneop option (* write single lane to address *)
    | PMemorySize (* size of memory *)
    | PMemoryGrow (* grow memory *)
    | PMemoryFill (* fill memory range with value *)
    | PMemoryCopy (* copy memory ranges *)
    | PMemoryInit of int32 option (* initialize memory range from segment *)
    | PDataDrop of int32 option (* drop passive data segment *)
    | PRefNull of ref_type option (* null reference *)
    | PRefFunc of int32 option (* function reference *)
    | PRefIsNull (* null test *)
    | PConst of num option (* constant *)
    | PTest of testop option (* numeric test *)
    | PCompare of relop option (* numeric comparison *)
    | PUnary of unop option (* unary numeric operator *)
    | PBinary of binop option (* binary numeric operator *)
    | PConvert of cvtop option (* conversion *)
    | PVecConst of vec (* constant *)
    | PVecTest of vec_testop option (* vector test *)
    | PVecCompare of vec_relop option (* vector comparison *)
    | PVecUnary of vec_unop option (* unary vector operator *)
    | PVecBinary of vec_binop option (* binary vector operator *)
    | PVecConvert of vec_cvtop option (* vector conversion *)
    | PVecShift of vec_shiftop option (* vector shifts *)
    | PVecBitmask of vec_bitmaskop option (* vector masking *)
    | PVecTestBits of vec_vtestop option (* vector bit test *)
    | PVecUnaryBits of vec_vunop option (* unary bit vector operator *)
    | PVecBinaryBits of vec_vbinop option (* binary bit vector operator *)
    | PVecTernaryBits of vec_vternop option (* ternary bit vector operator *)
    | PVecSplat of vec_splatop option (* number to vector conversion *)
    | PVecExtract of vec_extractop option (* extract lane from vector *)
    | PVecReplace of vec_replaceop option (* replace lane in vector *)

  let match_no_loc eq pat value = eq pat value.Source.it

  let check_opt f pat value =
    Option.fold ~none:true ~some:(fun pat -> match_no_loc f pat value) pat

  let check_var = check_opt Int32.equal

  let check_vars_list pat vars =
    let f pat vars =
      List.for_all2
        ~when_different_lengths:()
        (match_no_loc Int32.equal)
        pat
        vars
      |> Result.value ~default:false
    in
    Option.fold ~none:true ~some:(fun pat -> f pat vars) pat

  let match_ pattern value =
    match (pattern, value) with
    | PUnreachable, Unreachable -> true
    | PNop, Nop -> true
    | PDrop, Drop -> true
    | PSelect _, Select _ -> true
    | PBlock _, Block _ -> true
    | PLoop _, Loop _ -> true
    | PIf _, If _ -> true
    | PBr var_pat, Br var -> check_var var_pat var
    | PBrIf var_pat, BrIf var -> check_var var_pat var
    | PBrTable (vars_pat, var_pat), BrTable (vars, var) ->
        check_vars_list vars_pat vars && check_var var_pat var
    | PReturn, Return -> true
    | PCall var_pat, Call var -> check_opt Int32.equal var_pat var
    (* | PCallIndirect of var option * var option (\* call function through table *\) *)
    (* | PLocalGet of var option (\* read local variable *\) *)
    (* | PLocalSet of var option (\* write local variable *\) *)
    (* | PLocalTee of var option (\* write local variable and keep value *\) *)
    (* | PGlobalGet of var option (\* read global variable *\) *)
    (* | PGlobalSet of var option (\* write global variable *\) *)
    (* | PTableGet of var option (\* read table element *\) *)
    (* | PTableSet of var option (\* write table element *\) *)
    (* | PTableSize of var option (\* size of table *\) *)
    (* | PTableGrow of var option (\* grow table *\) *)
    (* | PTableFill of var option (\* fill table range with value *\) *)
    (* | PTableCopy of var option * var option (\* copy table range *\) *)
    (* | PTableInit of *)
    (*     var option * var option (\* initialize table range from segment *\) *)
    (* | PElemDrop of var option (\* drop passive element segment *\) *)
    (* | PLoad of loadop option (\* read memory at address *\) *)
    (* | PStore of storeop option (\* write memory at address *\) *)
    (* | PVecLoad of vec_loadop option (\* read memory at address *\) *)
    (* | PVecStore of vec_storeop option (\* write memory at address *\) *)
    (* | PVecLoadLane of vec_laneop option (\* read single lane at address *\) *)
    (* | PVecStoreLane of vec_laneop option (\* write single lane to address *\) *)
    | PMemorySize, MemorySize -> true
    | PMemoryGrow, MemoryGrow -> true
    | PMemoryFill, MemoryFill -> true
    | PMemoryCopy, MemoryCopy -> true
    | PMemoryInit var_pat, MemoryInit var -> check_var var_pat var
    (* | PDataDrop of var option (\* drop passive data segment *\) *)
    (* | PRefNull of ref_type option (\* null reference *\) *)
    (* | PRefFunc of var option (\* function reference *\) *)
    (* | PRefIsNull (\* null test *\) *)
    (* | PConst of num option (\* constant *\) *)
    (* | PTest of testop option (\* numeric test *\) *)
    (* | PCompare of relop option (\* numeric comparison *\) *)
    (* | PUnary of unop option (\* unary numeric operator *\) *)
    (* | PBinary of binop option (\* binary numeric operator *\) *)
    (* | PConvert of cvtop option (\* conversion *\) *)
    (* | PVecConst of vec (\* constant *\) *)
    (* | PVecTest of vec_testop option (\* vector test *\) *)
    (* | PVecCompare of vec_relop option (\* vector comparison *\) *)
    (* | PVecUnary of vec_unop option (\* unary vector operator *\) *)
    (* | PVecBinary of vec_binop option (\* binary vector operator *\) *)
    (* | PVecConvert of vec_cvtop option (\* vector conversion *\) *)
    (* | PVecShift of vec_shiftop option (\* vector shifts *\) *)
    (* | PVecBitmask of vec_bitmaskop option (\* vector masking *\) *)
    (* | PVecTestBits of vec_vtestop option (\* vector bit test *\) *)
    (* | PVecUnaryBits of vec_vunop option (\* unary bit vector operator *\) *)
    (* | PVecBinaryBits of vec_vbinop option (\* binary bit vector operator *\) *)
    (* | PVecTernaryBits of vec_vternop option (\* ternary bit vector operator *\) *)
    (* | PVecSplat of vec_splatop option (\* number to vector conversion *\) *)
    (* | PVecExtract of vec_extractop option (\* extract lane from vector *\) *)
    (* | PVecReplace of vec_replaceop option (\* replace lane in vector *\) *)
    | _, _ -> false

  let match_admin_instr pattern instr =
    match instr.Source.it with
    | Eval.Plain instr -> match_ pattern instr
    | _ -> false
end

let is_instr = function
  | Wasm_pvm_state.Internal_state.Eval
      {
        config =
          {
            step_kont =
              Tezos_webassembly_interpreter.Eval.(
                SK_Next
                  (_, _, LS_Start (Label_stack ({label_code = _, instrs; _}, _))));
            _;
          };
        _;
      } ->
      Int32Vector.num_elements instrs > 0l
  | _ -> false

let eval_until_instr instr_pattern tree =
  let open Lwt_syntax in
  let should_compute pvm_state =
    let* input_request_val = Wasm_vm.get_info pvm_state in
    match (input_request_val.input_request, pvm_state.tick_state) with
    | Reveal_required _, _ | Input_required, _ -> return false
    | ( No_input_required,
        Eval
          {
            config =
              {
                step_kont =
                  Tezos_webassembly_interpreter.Eval.(
                    SK_Next
                      ( _,
                        _,
                        LS_Start (Label_stack ({label_code = _, instrs; _}, _))
                      ));
                _;
              };
            _;
          } )
      when Int32Vector.num_elements instrs > 0l ->
        let+ head = Int32Vector.get 0l instrs in
        not (Patterns.match_admin_instr instr_pattern head)
    | No_input_required, _ -> return true
  in
  eval_to_cond should_compute tree

(* TODO: Not working yet, Meta instructions are cumbersome *)
let _eval_until_next_instr tree =
  let open Lwt_syntax in
  let* state = Wasm.Internal_for_tests.get_tick_state tree in
  let* tree = if is_instr state then Wasm.compute_step tree else return tree in
  eval_to_cond
    (fun pvm_state ->
      return (is_instr pvm_state.Wasm_pvm_state.Internal_state.tick_state))
    tree

let memory_fill size =
  ( Format.sprintf
      {|
       (memory.fill
        (i32.const 0)
        (i32.const 50)
        (i32.const %d)
        )|}
      size,
    Patterns.PMemoryFill )

let memory_copy size =
  ( Format.sprintf
      {|
       (memory.copy
        (i32.const 0)
        (i32.const 8000)
        (i32.const %d)
        )|}
      size,
    Patterns.PMemoryCopy )

let memory_init size =
  ( Format.sprintf {|(data $0 "%s")|} (String.make size 'a'),
    Format.sprintf
      {|
       (memory.init $0
        (i32.const 0)
        (i32.const 0)
        (i32.const %d)
        )|}
      size,
    Patterns.PMemoryInit (Some 0l) )

let bench_instr init raw_instrs starting_instr =
  let open Lwt_syntax in
  let module_ =
    Format.sprintf
      {|(module
 (memory 10)
 (export "mem" (memory 0))
 %s
 (func (export "kernel_run")
       %s
       (nop)
       )
 )|}
      init
      raw_instrs
  in
  (* Format.printf "module: \n%s\n%!" module_ ; *)
  let* tree = initial_tree ~max_tick:Int64.max_int ~from_binary:false module_ in
  (* Feeding it with one input *)
  let* tree = set_empty_inbox_step 0l tree in
  let* state =
    Test_encodings_util.Tree_encoding_runner.decode
      Wasm_pvm.pvm_state_encoding
      tree
  in
  let* tree =
    Test_encodings_util.Tree_encoding_runner.encode
      Wasm_pvm.pvm_state_encoding
      state
      tree
  in
  let* tree, _ = eval_until_instr starting_instr tree in
  let+ _tree, elapsed_ticks = eval_until_instr Patterns.PNop tree in
  elapsed_ticks

let bench_memory_copy size =
  let open Lwt_syntax in
  let code, instr = memory_copy size in
  let* ticks = bench_instr "" code instr in
  let+ () = Lwt_io.printf "%d, %Ld\n%!" size ticks in
  (size, ticks)

let bench_memory_fill size =
  let open Lwt_syntax in
  let code, instr = memory_fill size in
  let* ticks = bench_instr "" code instr in
  let+ () = Lwt_io.printf "%d, %Ld\n%!" size ticks in
  (size, ticks)

let bench_memory_init size =
  let open Lwt_syntax in
  let init, code, instr = memory_init size in
  let* ticks = bench_instr init code instr in
  let+ () = Lwt_io.printf "%d, %Ld\n%!" size ticks in
  (size, ticks)

let bench_function_with_sizes bench max_exp =
  let open Lwt_syntax in
  let values =
    0
    :: (List.init ~when_negative_length:() (max_exp + 1) (fun i -> 1 lsl i)
       |> Result.value ~default:[])
  in
  let* () = Lwt_io.printf "size (bytes), ticks\n%!" in
  Lwt_list.map_s bench values

(* Consider only polynomial models, for now. *)
type model = Polynomial of int list

let rec pow v exp =
  if exp <= 0 then 1 else if exp = 1 then v else pow (v * exp) (exp - 1)

let compute value model =
  match model with
  | Polynomial coefs ->
      List.fold_left_i
        (fun exp acc coef -> acc + (coef * pow value exp))
        0
        coefs

let check_model values model =
  List.for_all
    (fun (size, ticks) ->
      let expected = Int64.of_int (compute size model) in
      ticks = expected)
    values

(* 6 ticks to read the initial parameters on the stack, 42 ticks per bytes
   copied into memory. *)
let memory_fill_model = Polynomial [6; 42]

(* 6 ticks to read the initial parameters on the stack, 48 ticks per bytes read
   from the memory and copied to the memory. *)
let memory_copy_model = Polynomial [6; 48]

(* 6 ticks to read the initial parameters on the stack, 42 ticks per bytes
   copied into memory. *)
let memory_init_model = Polynomial [6; 42]

let run () =
  let open Lwt_syntax in
  let* () = Lwt_io.printf "MemoryFill:\n\n%!" in
  let* values = bench_function_with_sizes bench_memory_fill 12 in
  let b = check_model values memory_fill_model in
  let* () = Lwt_io.printf "Model is consistent: %b\n%!" b in
  let* () = Lwt_io.printf "\nMemoryCopy:\n\n%!" in
  let* values = bench_function_with_sizes bench_memory_copy 12 in
  let b = check_model values memory_copy_model in
  let* () = Lwt_io.printf "Model is consistent: %b\n%!" b in
  let* () = Lwt_io.printf "\nMemoryInit:\n\n%!" in
  let* values = bench_function_with_sizes bench_memory_init 12 in
  let b = check_model values memory_init_model in
  let* () = Lwt_io.printf "Model is consistent: %b\n%!" b in
  return_unit

let () = Lwt_main.run (run ())
