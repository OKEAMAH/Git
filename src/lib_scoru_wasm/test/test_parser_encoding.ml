(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

(** Testing
    -------
    Component:    Tree_encoding_decoding
    Invocation:   dune exec  src/lib_scoru_wasm/test/test_scoru_wasm.exe \
                    -- test "^Parser encodings$"
    Subject:      Parser encoding tests for the tezos-scoru-wasm library
*)

open Tztest
open Lazy_containers
open Tezos_webassembly_interpreter
open Tezos_scoru_wasm

(* Use context-binary for testing. *)
module Context = Tezos_context_memory.Context_binary

module Tree :
  Tezos_context_sigs.Context.TREE
    with type t = Context.t
     and type tree = Context.tree
     and type key = string list
     and type value = bytes = struct
  type t = Context.t

  type tree = Context.tree

  type key = Context.key

  type value = Context.value

  include Context.Tree
end

module UtilsMake (Tree_encoding : Tree_encoding.S with type tree = Tree.tree) =
struct
  include Tree_encoding
  module V = Lazy_vector.LwtInt32Vector
  module C = Chunked_byte_vector.Lwt

  let empty_tree () =
    let open Lwt_syntax in
    let* index = Context.init "/tmp" in
    let empty_store = Context.empty index in
    return @@ Context.Tree.empty empty_store

  let test_encode_decode enc value f =
    let open Lwt_result_syntax in
    let*! empty_tree = empty_tree () in
    let*! tree = Tree_encoding.encode enc value empty_tree in
    let*! value' = Tree_encoding.decode enc tree in
    f value'

  let encode_decode enc value = test_encode_decode enc value Lwt.return

  let make_test encoding gen check () =
    Test_wasm_encoding.qcheck gen (fun value ->
        let open Lwt_result_syntax in
        let*! value' = encode_decode encoding value in
        let* res = check value value' in
        (* TODO: a better error reporting could be useful. *)
        if res then return_unit else fail ())
end

type Lazy_containers.Lazy_map.tree += Tree of Tree.tree

module Tree_encoding = struct
  include Tree_encoding.Make (struct
    include Tree

    let select = function
      | Tree t -> t
      | _ -> raise Tree_encoding.Incorrect_tree_type

    let wrap t = Tree t
  end)

  include Lazy_map_encoding.Make (Instance.NameMap)
end

module Parser = Binary_parser_encodings.Make (Tree_encoding)
module Utils = UtilsMake (Tree_encoding)

module Byte_vector = struct
  open Utils

  let gen_chunked_byte_vector =
    let open QCheck2.Gen in
    let+ values = string in
    C.of_string values

  let gen_buffer =
    let open QCheck2.Gen in
    let* buffer = Ast_generators.data_label_gen in
    let* length = int64 in
    let+ offset = int64 in
    (buffer, offset, length)

  let gen =
    let open QCheck2.Gen in
    let start = return Decode.VKStart in
    let read =
      let+ buffer, offset, length = gen_buffer in
      Decode.VKRead (buffer, offset, length)
    in
    let stop =
      let+ vec = Ast_generators.data_label_gen in
      Decode.VKStop vec
    in
    oneof [start; read; stop]

  let check_vector vector vector' =
    let open Lwt_result_syntax in
    assert (C.length vector = C.length vector') ;
    let*! str = C.to_string vector in
    let*! str' = C.to_string vector' in
    return (String.equal str str')

  let check_buffer (buffer, offset, length) (buffer', offset', length') =
    let open Lwt_result_syntax in
    return
      (buffer = buffer' && Int64.equal offset offset'
     && Int64.equal length length')

  let check bv bv' =
    match (bv, bv') with
    | Decode.VKStart, Decode.VKStart -> Lwt.return_ok true
    | VKRead (buffer, offset, length), VKRead (buffer', offset', length') ->
        check_buffer (buffer, offset, length) (buffer', offset', length')
    | VKStop label, VKStop label' -> Lwt.return_ok (label = label')
    | _, _ -> Lwt.return_ok false

  let tests =
    [
      tztest
        "Byte_vector"
        `Quick
        (make_test Parser.Byte_vector.encoding gen check);
    ]
end

(* Lazy_vector generators *)
module Vec = struct
  open Utils

  let gen gen_values =
    let open QCheck2.Gen in
    let* length = int_range 1 100 in
    let* values = list_repeat length gen_values in
    let vec =
      List.fold_left_i
        (fun index vec value -> V.set (Int32.of_int index) value vec)
        (V.create (Int32.of_int length))
        values
    in
    return vec

  (* Vectors will always be of same type, but some GADTs usage can
     make them virtually of different type. See
     {!Module.check_field_type_value} and it's usage when checking
     equality of two [MKField] states. *)
  let check_possibly_different (eq_value : 'a -> 'b -> (bool, _) result Lwt.t)
      (vector : 'a V.t) (vector' : 'b V.t) =
    let open Lwt_result_syntax in
    assert (V.num_elements vector = V.num_elements vector') ;
    let*! eq_s =
      List.init_es
        ~when_negative_length:()
        (Int32.to_int (V.num_elements vector) - 1)
        (fun index ->
          let*! v = V.get (Int32.of_int index) vector in
          let*! v' = V.get (Int32.of_int index) vector' in
          let* eq = eq_value v v' in
          return eq)
    in
    match eq_s with
    | Ok b -> return (List.for_all Stdlib.(( = ) true) b)
    | Error () -> return false

  (* Checks two vectors are equivalent. *)
  let check (eq_value : 'a -> 'a -> (bool, _) result Lwt.t) (vector : 'a V.t)
      (vector' : 'a V.t) =
    check_possibly_different eq_value vector vector'

  let tests =
    let eq x y = Lwt.return_ok (Int32.equal x y) in
    tztest
      "Vec"
      `Quick
      (make_test
         Parser.(vector_encoding (value [] Data_encoding.int32))
         (gen QCheck2.Gen.int32)
         (check eq))
end

(* Generators for Lazy_vec, similar to {!Vec}. *)
module LazyVec = struct
  open Utils

  let gen_with_vec gen_vec =
    let open QCheck2.Gen in
    let* vector = gen_vec in
    let* offset =
      Lib_test.Qcheck2_helpers.int32_range_gen 0l (V.num_elements vector)
    in
    return (Decode.LazyVec {vector; offset})

  let gen gen_values = gen_with_vec (Vec.gen gen_values)

  let check eq_value (Decode.LazyVec {vector; offset})
      (Decode.LazyVec {vector = vector'; offset = offset'}) =
    let open Lwt_result_syntax in
    let* eq_lzvecs = Vec.check eq_value vector vector' in
    return (eq_lzvecs && offset = offset')

  let check_possibly_different eq_value (Decode.LazyVec {vector; offset})
      (Decode.LazyVec {vector = vector'; offset = offset'}) =
    let open Lwt_result_syntax in
    let* eq_lzvecs = Vec.check_possibly_different eq_value vector vector' in
    return (eq_lzvecs && offset = offset')

  let tests =
    let eq x y = Lwt.return_ok (Int32.equal x y) in
    [
      tztest
        "LazyVec"
        `Quick
        (make_test
           Parser.Lazy_vec.(encoding (value [] Data_encoding.int32))
           (gen QCheck2.Gen.int32)
           (check eq));
    ]
end

module Names = struct
  open Utils

  let gen_utf8 = QCheck2.Gen.small_nat

  let gen =
    let open QCheck2.Gen in
    let start = return Decode.NKStart in
    let parse =
      let* (Decode.LazyVec {vector; _} as buffer) = LazyVec.gen gen_utf8 in
      let vector_length = Int32.to_int (V.num_elements vector) in
      let* offset = int_range 0 vector_length in
      let+ length = int_range vector_length (vector_length * 2) in
      Decode.NKParse (offset, buffer, length)
    in
    let stop =
      let+ buffer = Vec.gen small_nat in
      Decode.NKStop buffer
    in
    oneof [start; parse; stop]

  let check ns ns' =
    let open Lwt_result_syntax in
    let eq_value x y = return (x = y) in
    match (ns, ns') with
    | Decode.NKStart, Decode.NKStart -> return true
    | NKParse (offset, buffer, length), NKParse (offset', buffer', length') ->
        let+ eq_bs = LazyVec.check eq_value buffer buffer' in
        eq_bs && offset = offset' && length = length'
    | NKStop vec, NKStop vec' -> Vec.check eq_value vec vec'
    | _, _ -> return false

  let tests = [tztest "Names" `Quick (make_test Parser.Name.encoding gen check)]
end

module Func_type = struct
  open Utils

  let func_type_gen =
    let open QCheck2.Gen in
    let* ins = Vec.gen Ast_generators.value_type_gen in
    let+ out = Vec.gen Ast_generators.value_type_gen in
    Types.FuncType (ins, out)

  let gen =
    let open QCheck2.Gen in
    let start = return Decode.FKStart in
    let ins =
      let+ ins = LazyVec.gen Ast_generators.value_type_gen in
      Decode.FKIns ins
    in
    let out =
      let* ins = Vec.gen Ast_generators.value_type_gen in
      let+ out = LazyVec.gen Ast_generators.value_type_gen in
      Decode.FKOut (ins, out)
    in
    let stop =
      let+ ft = func_type_gen in
      Decode.FKStop ft
    in
    oneof [start; ins; out; stop]

  let func_type_check (Types.FuncType (ins, out)) (Types.FuncType (ins', out'))
      =
    let open Lwt_result_syntax in
    let eq_value_types t t' = return Stdlib.(t = t') in
    let* eq_ins = Vec.check eq_value_types ins ins' in
    let+ eq_out = Vec.check eq_value_types out out' in
    eq_ins && eq_out

  let check fk fk' =
    let open Lwt_result_syntax in
    let eq_value_types t t' = return Stdlib.(t = t') in
    match (fk, fk') with
    | Decode.FKStart, Decode.FKStart -> return true
    | FKIns ins, FKIns ins' -> LazyVec.check eq_value_types ins ins'
    | FKOut (ins, out), FKOut (ins', out') ->
        let* eq_ins = Vec.check eq_value_types ins ins' in
        let+ eq_out = LazyVec.check eq_value_types out out' in
        eq_ins && eq_out
    | FKStop ft, FKStop ft' -> func_type_check ft ft'
    | _, _ -> return false

  let tests =
    [tztest "Func_type" `Quick (make_test Parser.Func_type.encoding gen check)]
end

module Imports = struct
  open Utils

  let import_gen =
    let open QCheck2.Gen in
    let* modl = Vec.gen Names.gen_utf8 in
    let* item = Vec.gen Names.gen_utf8 in
    let+ idesc = Ast_generators.import_desc_gen in
    Ast.{module_name = modl; item_name = item; idesc}

  let gen =
    let open QCheck2.Gen in
    let start = return Decode.ImpKStart in
    let module_name =
      let+ modl = Names.gen in
      Decode.ImpKModuleName modl
    in
    let item_name =
      let* modl = Vec.gen Names.gen_utf8 in
      let+ item = Names.gen in
      Decode.ImpKItemName (modl, item)
    in
    let stop =
      let+ import = import_gen in
      Decode.ImpKStop import
    in
    oneof [start; module_name; item_name; stop]

  let import_check import import' =
    let open Lwt_result_syntax in
    let eq_value x y = return (x = y) in
    let* eq_m =
      Vec.check eq_value import.Ast.module_name import'.Ast.module_name
    in
    let+ eq_i = Vec.check eq_value import.item_name import'.item_name in
    eq_m && eq_i && import.idesc = import'.idesc

  let check import import' =
    let open Lwt_result_syntax in
    match (import, import') with
    | Decode.ImpKStart, Decode.ImpKStart -> return true
    | ImpKModuleName m, ImpKModuleName m' -> Names.check m m'
    | ImpKItemName (m, i), ImpKItemName (m', i') ->
        let eq_value x y = return (x = y) in
        let* eq_m = Vec.check eq_value m m' in
        let+ eq_i = Names.check i i' in
        eq_m && eq_i
    | ImpKStop imp, ImpKStop imp' -> import_check imp imp'
    | _, _ -> return false

  let tests =
    [tztest "Imports" `Quick (make_test Parser.Import.encoding gen check)]
end

module LazyStack = struct
  open Utils

  let gen gen_values =
    let open QCheck2.Gen in
    let* vector = Vec.gen gen_values in
    let* length =
      Lib_test.Qcheck2_helpers.int32_range_gen 0l (V.num_elements vector)
    in
    return (Decode.LazyStack {vector; length})

  let check eq_value (Decode.LazyStack {vector; length})
      (Decode.LazyStack {vector = vector'; length = length'}) =
    let open Lwt_result_syntax in
    let* eq_lzs = Vec.check eq_value vector vector' in
    return (eq_lzs && length = length')

  let tests =
    let eq x y = Lwt.return_ok (Int32.equal x y) in
    [
      tztest
        "LazyStack"
        `Quick
        (make_test
           Parser.Lazy_stack.(encoding (value [] Data_encoding.int32))
           (gen QCheck2.Gen.int32)
           (check eq));
    ]
end

module Exports = struct
  open Utils

  let export_gen =
    let open QCheck2.Gen in
    let* name = Vec.gen Names.gen_utf8 in
    let+ edesc = Ast_generators.export_desc_gen in
    Ast.{name; edesc}

  let gen =
    let open QCheck2.Gen in
    let start = return Decode.ExpKStart in
    let name =
      let+ name = Names.gen in
      Decode.ExpKName name
    in
    let stop =
      let+ export = export_gen in
      Decode.ExpKStop export
    in
    oneof [start; name; stop]

  let export_check exp exp' =
    let open Lwt_result_syntax in
    let eq_value x y = return (x = y) in
    let+ eq_n = Vec.check eq_value exp.Ast.name exp'.Ast.name in
    eq_n && exp.edesc = exp'.edesc

  let check export export' =
    let open Lwt_result_syntax in
    match (export, export') with
    | Decode.ExpKStart, Decode.ExpKStart -> return true
    | ExpKName n, ExpKName n' -> Names.check n n'
    | ExpKStop exp, ExpKStop exp' -> export_check exp exp'
    | _, _ -> return false

  let tests =
    [tztest "Exports" `Quick (make_test Parser.Export.encoding gen check)]
end

module Size = struct
  open Utils

  let gen =
    let open QCheck2.Gen in
    let* size = small_nat in
    let+ start = small_nat in
    Decode.{size; start}

  let check s s' =
    let open Lwt_result_syntax in
    return (s.Decode.size = s'.Decode.size && s.start = s'.start)

  let tests = tztest "Size" `Quick (make_test Parser.Size.encoding gen check)
end

module Instr_block = struct
  open Utils

  let gen =
    let open QCheck2.Gen in
    let stop =
      let+ lbl = Ast_generators.block_label_gen in
      Decode.IKStop lbl
    in
    let next =
      let+ lbl = Ast_generators.block_label_gen in
      Decode.IKNext lbl
    in
    let block =
      let* ty = Ast_generators.block_type_gen in
      let+ pos = small_nat in
      Decode.IKBlock (ty, pos)
    in
    let loop =
      let* ty = Ast_generators.block_type_gen in
      let+ pos = small_nat in
      Decode.IKLoop (ty, pos)
    in
    let if1 =
      let* ty = Ast_generators.block_type_gen in
      let+ pos = small_nat in
      Decode.IKIf1 (ty, pos)
    in
    let if2 =
      let* ty = Ast_generators.block_type_gen in
      let* pos = small_nat in
      let+ lbl = Ast_generators.block_label_gen in
      Decode.IKIf2 (ty, pos, lbl)
    in
    oneof [stop; next; block; loop; if1; if2]

  let check ik ik' =
    let open Lwt_result_syntax in
    match (ik, ik') with
    | Decode.IKStop l, Decode.IKStop l' | IKNext l, IKNext l' -> return (l = l')
    | IKBlock (ty, pos), IKBlock (ty', pos')
    | IKLoop (ty, pos), IKLoop (ty', pos')
    | IKIf1 (ty, pos), IKIf1 (ty', pos') ->
        return (ty = ty' && pos = pos')
    | IKIf2 (ty, pos, l), IKIf2 (ty', pos', l') ->
        return (ty = ty' && pos = pos' && l = l')
    | _, _ -> return_false

  let tests =
    tztest
      "Instr_block"
      `Quick
      (make_test Parser.Instr_block.encoding gen check)
end

module Block = struct
  open Utils

  let gen =
    let open QCheck2.Gen in
    let start = return Decode.BlockStart in
    let parse =
      let+ instr_stack = LazyStack.gen Instr_block.gen in
      Decode.BlockParse instr_stack
    in
    let stop =
      let+ lbl = Ast_generators.block_label_gen in
      Decode.BlockStop lbl
    in
    oneof [start; parse; stop]

  let check bl bl' =
    let open Lwt_result_syntax in
    match (bl, bl') with
    | Decode.BlockStart, Decode.BlockStart -> return_true
    | BlockParse is, BlockParse is' -> LazyStack.check Instr_block.check is is'
    | BlockStop l, BlockStop l' -> return (l = l')
    | _, _ -> return_false

  let tests =
    [tztest "Block" `Quick (make_test Parser.Block.encoding gen check)]
end

module Code = struct
  open Utils

  let func_gen =
    let open QCheck2.Gen in
    let* ftype = Ast_generators.var_gen in
    let* locals = Vec.gen Ast_generators.value_type_gen in
    let+ body = Ast_generators.block_label_gen in
    Source.(Ast.{ftype; locals; body} @@ no_region)

  let gen =
    let open QCheck2.Gen in
    let start = return Decode.CKStart in
    let locals_parse =
      let* left = small_nat in
      let* size = Size.gen in
      let* pos = small_nat in
      let* vec_kont = LazyVec.gen (pair int32 Ast_generators.value_type_gen) in
      let+ locals_size = int64 in
      Decode.CKLocalsParse {left; size; pos; vec_kont; locals_size}
    in
    let locals_accumulate =
      let* left = small_nat in
      let* size = Size.gen in
      let* pos = small_nat in
      let* type_vec = LazyVec.gen (pair int32 Ast_generators.value_type_gen) in
      let* curr_type = opt (pair int32 Ast_generators.value_type_gen) in
      let+ vec_kont = LazyVec.gen Ast_generators.value_type_gen in
      Decode.CKLocalsAccumulate {left; size; pos; type_vec; curr_type; vec_kont}
    in
    let body =
      let* left = small_nat in
      let* size = Size.gen in
      let* locals = Vec.gen Ast_generators.value_type_gen in
      let+ const_kont = Block.gen in
      Decode.CKBody {left; size; locals; const_kont}
    in
    let stop =
      let+ func = func_gen in
      Decode.CKStop func
    in
    oneof [start; locals_parse; locals_accumulate; body; stop]

  let check_func Ast.{ftype; locals; body}
      Ast.{ftype = ftype'; locals = locals'; body = body'} =
    let open Lwt_result_syntax in
    let eq_value_type t t' = return (t = t') in
    let+ eq_locals = Vec.check eq_value_type locals locals' in
    ftype = ftype' && body = body' && eq_locals

  let check code code' =
    let open Lwt_result_syntax in
    let eq_value_type t t' = return (t = t') in
    match (code, code') with
    | Decode.CKStart, Decode.CKStart -> return_true
    | ( Decode.CKLocalsParse {left; size; pos; vec_kont; locals_size},
        Decode.CKLocalsParse
          {
            left = left';
            size = size';
            pos = pos';
            vec_kont = vec_kont';
            locals_size = locals_size';
          } ) ->
        let+ eq_vec_kont = LazyVec.check eq_value_type vec_kont vec_kont' in
        eq_vec_kont && left = left' && size = size' && pos = pos'
        && locals_size = locals_size'
    | ( Decode.CKLocalsAccumulate
          {left; size; pos; type_vec; curr_type; vec_kont},
        Decode.CKLocalsAccumulate
          {
            left = left';
            size = size';
            pos = pos';
            type_vec = type_vec';
            curr_type = curr_type';
            vec_kont = vec_kont';
          } ) ->
        let* eq_type_vec = LazyVec.check eq_value_type type_vec type_vec' in
        let+ eq_vec_kont = LazyVec.check eq_value_type vec_kont vec_kont' in
        eq_type_vec && eq_vec_kont && left = left' && size = size' && pos = pos'
        && curr_type = curr_type'
    | ( Decode.CKBody {left; size; locals; const_kont},
        Decode.CKBody
          {
            left = left';
            size = size';
            locals = locals';
            const_kont = const_kont';
          } ) ->
        let* eq_locals = Vec.check eq_value_type locals locals' in
        let+ eq_const_kont = Block.check const_kont const_kont' in
        eq_locals && eq_const_kont && left = left' && size = size'
    | Decode.CKStop Source.{it = func; _}, Decode.CKStop Source.{it = func'; _}
      ->
        check_func func func'
    | _, _ -> return false

  let tests = [tztest "Code" `Quick (make_test Parser.Code.encoding gen check)]
end

module Elem = struct
  open Utils

  let elem_gen =
    let open QCheck2.Gen in
    let open Ast_generators in
    let* etype = ref_type_gen in
    let* emode = segment_mode_gen in
    let+ einit = Vec.gen const_gen in
    Ast.{etype; emode; einit}

  let gen =
    let open QCheck2.Gen in
    let open Ast_generators in
    let start = return Decode.EKStart in
    let mode =
      let* left = small_nat in
      let* index = int32 in
      let* index_kind = oneofl [Decode.Indexed; Decode.Const] in
      let* early_ref_type = opt ref_type_gen in
      let* offset_kont = small_nat in
      let+ offset_kont_code = Block.gen in
      Decode.EKMode
        {
          left;
          index = Source.(index @@ no_region);
          index_kind;
          early_ref_type;
          offset_kont = (offset_kont, offset_kont_code);
        }
    in
    let initindexed =
      let* mode = segment_mode_gen in
      let* ref_type = ref_type_gen in
      let+ einit_vec = LazyVec.gen const_gen in
      Decode.EKInitIndexed {mode; ref_type; einit_vec}
    in
    let initconst =
      let* mode = segment_mode_gen in
      let* ref_type = ref_type_gen in
      let* einit_vec = LazyVec.gen const_gen in
      let* pos = small_int in
      let+ block = Block.gen in
      Decode.EKInitConst {mode; ref_type; einit_vec; einit_kont = (pos, block)}
    in
    let stop =
      let+ elem = elem_gen in
      Decode.EKStop elem
    in
    oneof [start; mode; initindexed; initconst; stop]

  let elem_check Ast.{emode; einit; etype}
      Ast.{emode = emode'; einit = einit'; etype = etype'} =
    let open Lwt_result_syntax in
    let eq_const c c' = return (c = c') in
    let* eq_init = Vec.check eq_const einit einit' in
    return (emode = emode' && eq_init && etype = etype')

  let check ek ek' =
    let open Lwt_result_syntax in
    match (ek, ek') with
    | Decode.EKStart, Decode.EKStart -> return_true
    | ( EKMode
          {
            left;
            index;
            index_kind;
            early_ref_type;
            offset_kont = offset_kont_pos, offset_kont_code;
          },
        EKMode
          {
            left = left';
            index = index';
            index_kind = index_kind';
            early_ref_type = early_ref_type';
            offset_kont = offset_kont_pos', offset_kont_code';
          } ) ->
        let+ eq_code = Block.check offset_kont_code offset_kont_code' in
        left = left' && index = index' && index_kind = index_kind'
        && early_ref_type = early_ref_type'
        && offset_kont_pos = offset_kont_pos'
        && eq_code
    | ( EKInitIndexed {mode; ref_type; einit_vec},
        EKInitIndexed
          {mode = mode'; ref_type = ref_type'; einit_vec = einit_vec'} ) ->
        let eq_const c c' = return (c = c') in
        let+ eq_init = LazyVec.check eq_const einit_vec einit_vec' in
        mode = mode' && ref_type = ref_type' && eq_init
    | ( EKInitConst {mode; ref_type; einit_vec; einit_kont = pos, block},
        EKInitConst
          {
            mode = mode';
            ref_type = ref_type';
            einit_vec = einit_vec';
            einit_kont = pos', block';
          } ) ->
        let eq_const c c' = return (c = c') in
        let* eq_init = LazyVec.check eq_const einit_vec einit_vec' in
        let+ eq_block = Block.check block block' in
        mode = mode' && ref_type = ref_type' && pos = pos' && eq_init
        && eq_block
    | EKStop elem, EKStop elem' -> elem_check elem elem'
    | _, _ -> return_false

  let tests = [tztest "Elem" `Quick (make_test Parser.Elem.encoding gen check)]
end

module Data = struct
  open Utils

  let data_gen =
    let open QCheck2.Gen in
    let* dmode = Ast_generators.segment_mode_gen in
    let+ dinit = Ast_generators.data_label_gen in
    Ast.{dmode; dinit}

  let gen =
    let open QCheck2.Gen in
    let start = return Decode.DKStart in
    let mode =
      let* left = small_nat in
      let* index = int32 in
      let* offset_kont = small_nat in
      let+ offset_kont_code = Block.gen in
      Decode.DKMode
        {
          left;
          index = Source.(index @@ no_region);
          offset_kont = (offset_kont, offset_kont_code);
        }
    in
    let init =
      let* dmode = Ast_generators.segment_mode_gen in
      let+ init_kont = Byte_vector.gen in
      Decode.DKInit {dmode; init_kont}
    in
    let stop =
      let+ data = data_gen in
      Decode.DKStop data
    in
    oneof [start; mode; init; stop]

  let data_check Ast.{dmode; dinit} Ast.{dmode = dmode'; dinit = dinit'} =
    let open Lwt_result_syntax in
    return (dmode = dmode' && dinit = dinit')

  let check dk dk' =
    let open Lwt_result_syntax in
    match (dk, dk') with
    | Decode.DKStart, Decode.DKStart -> return_true
    | ( DKMode {left; index; offset_kont = offset_kont_pos, offset_kont_code},
        DKMode
          {
            left = left';
            index = index';
            offset_kont = offset_kont_pos', offset_kont_code';
          } ) ->
        let+ eq_code = Block.check offset_kont_code offset_kont_code' in
        left = left' && index = index'
        && offset_kont_pos = offset_kont_pos'
        && eq_code
    | DKInit {dmode; init_kont}, DKInit {dmode = dmode'; init_kont = init_kont'}
      ->
        let+ eq_init = Byte_vector.check init_kont init_kont' in
        dmode = dmode' && eq_init
    | DKStop data, DKStop data' -> data_check data data'
    | _, _ -> return false

  let tests = [tztest "Data" `Quick (make_test Parser.Data.encoding gen check)]
end

module Field = struct
  open Utils

  let no_region gen = QCheck2.Gen.map (fun v -> Source.(v @@ no_region)) gen

  let type_field_gen = Vec.gen (no_region Func_type.func_type_gen)

  let import_field_gen = Vec.gen (no_region Imports.import_gen)

  let func_field_gen = Vec.gen Ast_generators.var_gen

  let table_field_gen =
    let open QCheck2.Gen in
    let table_gen =
      let+ ttype = Ast_generators.table_type_gen in
      Ast.{ttype}
    in
    Vec.gen (no_region table_gen)

  let memory_field_gen =
    let open QCheck2.Gen in
    let memory_gen =
      let+ mtype = Ast_generators.memory_type_gen in
      Ast.{mtype}
    in
    Vec.gen (no_region memory_gen)

  let global_field_gen =
    let open QCheck2.Gen in
    let global_gen =
      let* ginit = no_region Ast_generators.block_label_gen in
      let+ gtype = Ast_generators.global_type_gen in
      Ast.{gtype; ginit}
    in
    Vec.gen (no_region global_gen)

  let export_field_gen = Vec.gen (no_region Exports.export_gen)

  let start_field_gen = QCheck2.Gen.opt Ast_generators.start_gen

  let elem_field_gen = Vec.gen (no_region Elem.elem_gen)

  let data_count_field_gen = QCheck2.Gen.(opt int32)

  let code_field_gen = Vec.gen Code.func_gen

  let data_field_gen = Vec.gen (no_region Data.data_gen)

  let field_type_gen =
    let open QCheck2.Gen in
    let pack f = Parser.Field.FieldType f in
    oneofl
      [
        pack Decode.TypeField;
        pack ImportField;
        pack FuncField;
        pack TableField;
        pack MemoryField;
        pack GlobalField;
        pack ExportField;
        pack StartField;
        pack ElemField;
        pack DataCountField;
        pack CodeField;
        pack DataField;
      ]

  let typed_lazy_vec_gen =
    let open QCheck2.Gen in
    let pack f gen_vec =
      let+ vec = LazyVec.gen_with_vec gen_vec in
      Parser.Field.TypedLazyVec (f, vec)
    in
    oneof
      [
        pack Decode.TypeField type_field_gen;
        pack ImportField import_field_gen;
        pack FuncField func_field_gen;
        pack TableField table_field_gen;
        pack MemoryField memory_field_gen;
        pack GlobalField global_field_gen;
        pack ExportField export_field_gen;
        pack ElemField elem_field_gen;
        pack CodeField code_field_gen;
        pack DataField data_field_gen;
      ]

  let check_field_type :
      type a a' repr repr'.
      (a, repr) Decode.field_type -> (a', repr') Decode.field_type -> bool =
   fun ft ft' ->
    match (ft, ft') with
    | Decode.DataCountField, Decode.DataCountField -> true
    | StartField, StartField -> true
    | TypeField, TypeField -> true
    | ImportField, ImportField -> true
    | FuncField, FuncField -> true
    | TableField, TableField -> true
    | MemoryField, MemoryField -> true
    | GlobalField, GlobalField -> true
    | ExportField, ExportField -> true
    | ElemField, ElemField -> true
    | CodeField, CodeField -> true
    | DataField, DataField -> true
    | _, _ -> false

  let check_packed_field_type (Parser.Field.FieldType ft)
      (Parser.Field.FieldType ft') =
    Lwt.return_ok (check_field_type ft ft')

  let check_field_type_value :
      type a a' repr repr'.
      (a, repr) Decode.field_type ->
      (a', repr') Decode.field_type ->
      a ->
      a' ->
      (bool, _) result Lwt.t =
   fun ft ft' x y ->
    let open Lwt_result_syntax in
    match (ft, ft') with
    | Decode.DataCountField, Decode.DataCountField -> return (x = y)
    | StartField, StartField -> return (x = y)
    | TypeField, TypeField -> Func_type.func_type_check x.Source.it y.Source.it
    | ImportField, ImportField -> Imports.import_check x.Source.it y.Source.it
    | FuncField, FuncField -> return (x = y)
    | TableField, TableField -> return (x = y)
    | MemoryField, MemoryField -> return (x = y)
    | GlobalField, GlobalField -> return (x = y)
    | ExportField, ExportField -> Exports.export_check x.Source.it y.Source.it
    | ElemField, ElemField -> Elem.elem_check x.Source.it y.Source.it
    | CodeField, CodeField -> Code.check_func x.Source.it y.Source.it
    | DataField, DataField -> Data.data_check x.Source.it y.Source.it
    | _, _ -> return_false

  let building_state_gen =
    let open QCheck2.Gen in
    let* types = type_field_gen in
    let* imports = import_field_gen in
    let* vars = func_field_gen in
    let* tables = table_field_gen in
    let* memories = memory_field_gen in
    let* globals = global_field_gen in
    let* exports = export_field_gen in
    let* start = start_field_gen in
    let* elems = elem_field_gen in
    let* data_count = data_count_field_gen in
    let* code = code_field_gen in
    let+ datas = data_field_gen in
    Decode.
      {
        types;
        imports;
        vars;
        tables;
        memories;
        globals;
        exports;
        start;
        elems;
        data_count;
        code;
        datas;
      }

  let building_state_check
      Decode.
        {
          types;
          imports;
          vars;
          tables;
          memories;
          globals;
          exports;
          start;
          elems;
          data_count;
          code;
          datas;
        }
      Decode.
        {
          types = types';
          imports = imports';
          vars = vars';
          tables = tables';
          memories = memories';
          globals = globals';
          exports = exports';
          start = start';
          elems = elems';
          data_count = data_count';
          code = code';
          datas = datas';
        } =
    let open Lwt_result_syntax in
    let check_no_region check v v' = check v.Source.it v'.Source.it in
    let eq v v' = return (v = v') in
    let* eq_types =
      Vec.check (check_no_region Func_type.func_type_check) types types'
    in
    let* eq_imports =
      Vec.check (check_no_region Imports.import_check) imports imports'
    in
    let* eq_vars = Vec.check (check_no_region eq) vars vars' in
    let* eq_tables = Vec.check (check_no_region eq) tables tables' in
    let* eq_memories = Vec.check (check_no_region eq) memories memories' in
    let* eq_globals = Vec.check (check_no_region eq) globals globals' in
    let* eq_exports =
      Vec.check (check_no_region Exports.export_check) exports exports'
    in
    let* eq_start = return (start = start') in
    let* eq_elems = Vec.check (check_no_region Elem.elem_check) elems elems' in
    let* eq_data_count = return (data_count = data_count') in
    let* eq_code = Vec.check (check_no_region Code.check_func) code code' in
    let+ eq_datas = Vec.check (check_no_region Data.data_check) datas datas' in
    eq_types && eq_imports && eq_vars && eq_tables && eq_memories && eq_globals
    && eq_exports && eq_start && eq_elems && eq_data_count && eq_code
    && eq_datas

  let tests =
    tztest
      "Field"
      `Quick
      (make_test
         Parser.Field.building_state_encoding
         building_state_gen
         building_state_check)

  let tests_packed =
    [
      tztest
        "Field.Packed"
        `Quick
        (make_test
           Parser.Field.packed_field_type_encoding
           field_type_gen
           check_packed_field_type);
    ]
end

let tests =
  Byte_vector.tests @ LazyVec.tests @ Names.tests @ Func_type.tests
  @ Imports.tests @ LazyStack.tests @ Exports.tests @ Block.tests @ Code.tests
  @ Elem.tests @ Data.tests @ Field.tests_packed
