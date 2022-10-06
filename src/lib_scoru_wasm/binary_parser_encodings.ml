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

open Tezos_webassembly_interpreter
open Lazy_containers
module V = Instance.Vector
module M = Instance.NameMap
module C = Chunked_byte_vector
open Tree_encoding

(* TODO: https://gitlab.com/tezos/tezos/-/issues/3566

   Locations should either be dropped or not. *)
let no_region_encoding enc =
  conv (fun s -> Source.(s @@ no_region)) (fun {it; _} -> it) enc

let vector_encoding value_enc =
  int32_lazy_vector (value [] Data_encoding.int32) value_enc

module Lazy_vec = struct
  let raw_encoding vector_encoding =
    let offset = value ["offset"] Data_encoding.int32 in
    let vector = scope ["vector"] vector_encoding in
    conv
      (fun (offset, vector) -> Decode.LazyVec {offset; vector})
      (fun (LazyVec {offset; vector}) -> (offset, vector))
      (tup2 ~flatten:true offset vector)

  let encoding value_encoding = raw_encoding (vector_encoding value_encoding)
end

module Lazy_stack = struct
  let encoding value_enc =
    (* TODO: https://gitlab.com/tezos/tezos/-/issues/3569

       The stack can be probably encoded in a unique key in the tree,
       since it is never used concurrently. *)
    let offset = value ["length"] Data_encoding.int32 in
    let vector = scope ["vector"] (vector_encoding value_enc) in
    conv
      (fun (length, vector) -> Decode.LazyStack {length; vector})
      (fun (LazyStack {length; vector}) -> (length, vector))
      (tup2 ~flatten:true offset vector)
end

module Byte_vector = struct
  type t' = Decode.byte_vector_kont

  let value_enc =
    let pos = value ["pos"] Data_encoding.int64 in
    let length = value ["length"] Data_encoding.int64 in
    let data_label =
      value ["data_label"] Interpreter_encodings.Ast.data_label_encoding
    in
    tup3 ~flatten:true data_label pos length

  let vkstop_enc =
    value ["data_label"] Interpreter_encodings.Ast.data_label_encoding

  let tag_encoding = value [] Data_encoding.string

  let unit_encoding = value [] Data_encoding.unit

  let select_encode = function
    | Decode.VKStart ->
        destruction ~tag:"VKStart" ~res:() ~delegate:unit_encoding
    | Decode.VKRead (b, p, l) ->
        destruction ~tag:"VKRead" ~res:(b, p, l) ~delegate:value_enc
    | Decode.VKStop b -> destruction ~tag:"VKStop" ~res:b ~delegate:vkstop_enc

  let select_decode = function
    | "VKStart" ->
        decoding_branch
          ~extract:(fun () -> Lwt.return Decode.VKStart)
          ~delegate:unit_encoding
    | "VKRead" ->
        decoding_branch
          ~extract:(fun (b, p, l) -> Lwt.return @@ Decode.VKRead (b, p, l))
          ~delegate:value_enc
    | "VKStop" ->
        decoding_branch
          ~extract:(fun b -> Lwt.return @@ Decode.VKStop b)
          ~delegate:vkstop_enc
    | _ -> (* FIXME *) assert false

  let encoding = fast_tagged_union tag_encoding ~select_encode ~select_decode
end

module Name = struct
  let buffer_encoding =
    value
      []
      Data_encoding.(
        conv
          (fun b -> (Buffer.contents b, Buffer.length b))
          (fun (content, length) ->
            let b = Buffer.create length in
            Buffer.add_string b content ;
            b)
          (tup2 string int31))

  let value_enc =
    let pos = value ["pos"] Data_encoding.int31 in
    let buffer = scope ["buffer"] buffer_encoding in
    let length = value ["length"] Data_encoding.int31 in
    tup3 ~flatten:true pos buffer length

  let string_encoding = value [] Data_encoding.string

  let unit_encoding = value [] Data_encoding.unit

  let tag_encoding = value [] Data_encoding.string

  let select_encode = function
    | Decode.NKStart ->
        destruction ~tag:"NKStart" ~res:() ~delegate:unit_encoding
    | Decode.NKParse (p, v, l) ->
        destruction ~tag:"NKParse" ~res:(p, v, l) ~delegate:value_enc
    | Decode.NKStop v ->
        destruction ~tag:"NKStop" ~res:v ~delegate:string_encoding

  let select_decode = function
    | "NKStart" ->
        decoding_branch
          ~extract:(fun () -> Lwt.return @@ Decode.NKStart)
          ~delegate:unit_encoding
    | "NKParse" ->
        decoding_branch
          ~extract:(fun (p, v, l) -> Lwt.return @@ Decode.NKParse (p, v, l))
          ~delegate:value_enc
    | "NKStop" ->
        decoding_branch
          ~extract:(fun s -> Lwt.return @@ Decode.NKStop s)
          ~delegate:string_encoding
    | _ -> (* FIXME *) assert false

  let encoding = fast_tagged_union tag_encoding ~select_encode ~select_decode
end

module Func_type = struct
  type tags = FKStart | FKIns | FKOut | FKStop

  let value_type_encoding =
    value [] Interpreter_encodings.Types.value_type_encoding

  let unit_encoding = value [] Data_encoding.unit

  let fkins_enc = scope ["ins_kont"] (Lazy_vec.encoding value_type_encoding)

  let fkout_enc =
    let params = scope ["params"] (vector_encoding value_type_encoding) in
    let lazy_vec =
      scope ["lazy_kont"] (Lazy_vec.encoding value_type_encoding)
    in
    tup2 ~flatten:true params lazy_vec

  let fkstop_enc = Wasm_encoding.func_type_encoding

  let tag_encoding = Data_encoding.string |> value []

  let select_encode = function
    | Decode.FKStart ->
        destruction ~tag:"FKStart" ~res:() ~delegate:unit_encoding
    | Decode.FKIns vec -> destruction ~tag:"FKIns" ~res:vec ~delegate:fkins_enc
    | Decode.FKOut (p, vec) ->
        destruction ~tag:"FKOut" ~res:(p, vec) ~delegate:fkout_enc
    | Decode.FKStop ft -> destruction ~tag:"FKStop" ~res:ft ~delegate:fkstop_enc

  let select_decode = function
    | "FKStart" ->
        decoding_branch
          ~extract:(fun () -> Lwt.return Decode.FKStart)
          ~delegate:unit_encoding
    | "FKIns" ->
        decoding_branch
          ~extract:(fun vec -> Lwt.return @@ Decode.FKIns vec)
          ~delegate:fkins_enc
    | "FKOut" ->
        decoding_branch
          ~extract:(fun (p, vec) -> Lwt.return @@ Decode.FKOut (p, vec))
          ~delegate:fkout_enc
    | "FKStop" ->
        decoding_branch
          ~extract:(fun ft -> Lwt.return @@ Decode.FKStop ft)
          ~delegate:fkstop_enc
    | _ -> (* FIXME *) assert false

  let encoding = fast_tagged_union tag_encoding ~select_encode ~select_decode
end

let name_encoding = value [] Data_encoding.string

module Import = struct
  let impkstart_enc = value [] (Data_encoding.constant "ImpKStart")

  let impkmodulename_enc = scope ["module_name"] Name.encoding

  let impkitemname_enc =
    tup2
      ~flatten:false
      (scope ["module_name"] name_encoding)
      (scope ["item_name"] Name.encoding)

  let import_encoding =
    conv
      (fun (module_name, item_name, idesc) ->
        Ast.{module_name; item_name; idesc})
      (fun {module_name; item_name; idesc} -> (module_name, item_name, idesc))
      (tup3
         ~flatten:true
         (scope ["module_name"] name_encoding)
         (scope ["item_name"] name_encoding)
         (value ["idesc"] Interpreter_encodings.Ast.import_desc_encoding))

  let impkstop_enc = import_encoding

  let tag_encoding = value [] Data_encoding.string

  let select_encode = function
    | Decode.ImpKStart ->
        destruction ~tag:"ImpKStart" ~res:() ~delegate:impkstart_enc
    | Decode.ImpKModuleName n ->
        destruction ~tag:"ImpKModuleName" ~res:n ~delegate:impkmodulename_enc
    | Decode.ImpKItemName (m, i) ->
        destruction ~tag:"ImpKItemName" ~res:(m, i) ~delegate:impkitemname_enc
    | Decode.ImpKStop i ->
        destruction ~tag:"ImpKStop" ~res:i ~delegate:impkstop_enc

  let select_decode = function
    | "ImpKStart" ->
        decoding_branch
          ~extract:(fun () -> Lwt.return Decode.ImpKStart)
          ~delegate:impkstart_enc
    | "ImpKModuleName" ->
        decoding_branch
          ~extract:(fun n -> Lwt.return @@ Decode.ImpKModuleName n)
          ~delegate:impkmodulename_enc
    | "ImpKItemName" ->
        decoding_branch
          ~extract:(fun (m, i) -> Lwt.return @@ Decode.ImpKItemName (m, i))
          ~delegate:impkitemname_enc
    | "ImpKStop" ->
        decoding_branch
          ~extract:(fun i -> Lwt.return @@ Decode.ImpKStop i)
          ~delegate:impkstop_enc
    | _ -> (* FIXME *) assert false

  let encoding = fast_tagged_union tag_encoding ~select_encode ~select_decode
end

module Export = struct
  let expkstart_enc = value [] (Data_encoding.constant "ExpKStart")

  let expkname_enc = Name.encoding

  let export_encoding =
    conv
      (fun (name, edesc) -> Ast.{name; edesc})
      (fun {name; edesc} -> (name, edesc))
      (tup2
         ~flatten:true
         (scope ["name"] name_encoding)
         (value ["edesc"] Interpreter_encodings.Ast.export_desc_encoding))

  let expkstop_enc = export_encoding

  let tags_encoding = value [] Data_encoding.string

  let select_encode = function
    | Decode.ExpKStart ->
        destruction ~tag:"ExpKStart" ~res:() ~delegate:expkstart_enc
    | Decode.ExpKName n ->
        destruction ~tag:"ExpKName" ~res:n ~delegate:expkname_enc
    | Decode.ExpKStop e ->
        destruction ~tag:"ExpKStop" ~res:e ~delegate:expkstop_enc

  let select_decode = function
    | "ExpKStart" ->
        decoding_branch
          ~extract:(fun () -> Lwt.return Decode.ExpKStart)
          ~delegate:expkstart_enc
    | "ExpKName" ->
        decoding_branch
          ~extract:(fun n -> Lwt.return @@ Decode.ExpKName n)
          ~delegate:expkname_enc
    | "ExpKStop" ->
        decoding_branch
          ~extract:(fun e -> Lwt.return @@ Decode.ExpKStop e)
          ~delegate:expkstop_enc
    | _ -> (* FIXME *) assert false

  let encoding = fast_tagged_union tags_encoding ~select_encode ~select_decode
end

module Size = struct
  let encoding =
    conv
      (fun (size, start) -> Decode.{size; start})
      (fun {size; start} -> (size, start))
      (tup2
         ~flatten:true
         (value ["size"] Data_encoding.int31)
         (value ["start"] Data_encoding.int31))
end

module Instr_block = struct
  let stop_enc = value [] Interpreter_encodings.Ast.block_label_encoding

  let next_enc = value [] Interpreter_encodings.Ast.block_label_encoding

  let block_enc =
    tup2
      ~flatten:true
      (value ["type"] Interpreter_encodings.Ast.block_type_encoding)
      (value ["pos"] Data_encoding.int31)

  let loop_enc =
    tup2
      ~flatten:true
      (value ["type"] Interpreter_encodings.Ast.block_type_encoding)
      (value ["pos"] Data_encoding.int31)

  let if1_enc =
    tup2
      ~flatten:true
      (value ["type"] Interpreter_encodings.Ast.block_type_encoding)
      (value ["pos"] Data_encoding.int31)

  let if2_enc =
    tup3
      ~flatten:true
      (value ["type"] Interpreter_encodings.Ast.block_type_encoding)
      (value ["pos"] Data_encoding.int31)
      (value ["else"] Interpreter_encodings.Ast.block_label_encoding)

  let select_encode = function
    | Decode.IKStop lbl -> destruction ~tag:"IKStop" ~res:lbl ~delegate:stop_enc
    | Decode.IKNext lbl -> destruction ~tag:"IKNext" ~res:lbl ~delegate:next_enc
    | Decode.IKBlock (ty, i) ->
        destruction ~tag:"IKBlock" ~res:(ty, i) ~delegate:block_enc
    | Decode.IKLoop (ty, i) ->
        destruction ~tag:"IKLoop" ~res:(ty, i) ~delegate:loop_enc
    | Decode.IKIf1 (ty, i) ->
        destruction ~tag:"IKIf1" ~res:(ty, i) ~delegate:if1_enc
    | Decode.IKIf2 (ty, i, else_lbl) ->
        destruction ~tag:"IKIf2" ~res:(ty, i, else_lbl) ~delegate:if2_enc

  let select_decode = function
    | "IKStop" ->
        decoding_branch
          ~extract:(fun lbl -> Lwt.return @@ Decode.IKStop lbl)
          ~delegate:stop_enc
    | "IKNext" ->
        decoding_branch
          ~extract:(fun lbl -> Lwt.return @@ Decode.IKNext lbl)
          ~delegate:next_enc
    | "IKBlock" ->
        decoding_branch
          ~extract:(fun (ty, i) -> Lwt.return @@ Decode.IKBlock (ty, i))
          ~delegate:block_enc
    | "IKLoop" ->
        decoding_branch
          ~extract:(fun (ty, i) -> Lwt.return @@ Decode.IKLoop (ty, i))
          ~delegate:loop_enc
    | "IKIf1" ->
        decoding_branch
          ~extract:(fun (ty, i) -> Lwt.return @@ Decode.IKIf1 (ty, i))
          ~delegate:if1_enc
    | "IKIf2" ->
        decoding_branch
          ~extract:(fun (ty, i, else_lbl) ->
            Lwt.return @@ Decode.IKIf2 (ty, i, else_lbl))
          ~delegate:if2_enc
    | _ -> (* FIXME *) assert false

  let encoding =
    fast_tagged_union
      (value [] Data_encoding.string)
      ~select_encode
      ~select_decode
end

module Block = struct
  let block_start_enc = value [] (Data_encoding.constant "BlockStart")

  let block_parse_enc = scope [] (Lazy_stack.encoding Instr_block.encoding)

  let block_stop_enc = value [] Interpreter_encodings.Ast.block_label_encoding

  let select_encode = function
    | Decode.BlockStart ->
        destruction ~tag:"BlockStart" ~res:() ~delegate:block_start_enc
    | Decode.BlockParse ik ->
        destruction ~tag:"BlockParse" ~res:ik ~delegate:block_parse_enc
    | Decode.BlockStop lbl ->
        destruction ~tag:"BlockStop" ~res:lbl ~delegate:block_stop_enc

  let select_decode = function
    | "BlockStart" ->
        decoding_branch
          ~extract:(fun () -> Lwt.return Decode.BlockStart)
          ~delegate:block_start_enc
    | "BlockParse" ->
        decoding_branch
          ~extract:(fun ik -> Lwt.return @@ Decode.BlockParse ik)
          ~delegate:block_parse_enc
    | "BlockStop" ->
        decoding_branch
          ~extract:(fun lbl -> Lwt.return @@ Decode.BlockStop lbl)
          ~delegate:block_stop_enc
    | _ -> (* FIXME *) assert false

  let encoding =
    fast_tagged_union
      (value [] Data_encoding.string)
      ~select_encode
      ~select_decode
end

module Code = struct
  let value_type_acc_enc =
    let occurences = value ["occurences"] Data_encoding.int32 in
    let value_type =
      value ["type"] Interpreter_encodings.Types.value_type_encoding
    in
    tup2 ~flatten:true occurences value_type

  let ckstart_enc = value [] (Data_encoding.constant "CKStart")

  let cklocalsparse_enc =
    let left = value ["left"] Data_encoding.int31 in
    let size = scope ["size"] Size.encoding in
    let pos = value ["pos"] Data_encoding.int31 in
    let vec_kont = scope ["vec_kont"] (Lazy_vec.encoding value_type_acc_enc) in
    let locals_size = value ["locals_size"] Data_encoding.int64 in
    tup5 ~flatten:true left size pos vec_kont locals_size

  let cklocalsaccumulate_enc =
    let left = value ["left"] Data_encoding.int31 in
    let size = scope ["size"] Size.encoding in
    let pos = value ["pos"] Data_encoding.int31 in
    let type_vec = scope ["type_vec"] (Lazy_vec.encoding value_type_acc_enc) in
    let curr_type = scope ["curr_type"] (option value_type_acc_enc) in
    let vec_kont =
      scope ["vec_kont"] (Lazy_vec.encoding Func_type.value_type_encoding)
    in
    tup6 ~flatten:true left size pos type_vec curr_type vec_kont

  let ckbody_enc =
    let left = value ["left"] Data_encoding.int31 in
    let size = scope ["size"] Size.encoding in
    let locals =
      scope ["locals"] (vector_encoding Func_type.value_type_encoding)
    in
    let const_kont = scope ["const_kont"] Block.encoding in
    tup4 ~flatten:true left size locals const_kont

  let func_encoding =
    let ftype = value ["ftype"] Interpreter_encodings.Ast.var_encoding in
    let locals =
      scope ["locals"] (vector_encoding Func_type.value_type_encoding)
    in
    let body = value ["body"] Interpreter_encodings.Ast.block_label_encoding in
    conv
      (fun (ftype, locals, body) ->
        Source.(Ast.{ftype; locals; body} @@ no_region))
      (fun {it = {ftype; locals; body}; _} -> (ftype, locals, body))
      (tup3 ~flatten:true ftype locals body)

  let ckstop_enc = func_encoding

  let select_encode = function
    | Decode.CKStart -> destruction ~tag:"CKStart" ~res:() ~delegate:ckstart_enc
    | Decode.CKLocalsParse {left; size; pos; vec_kont; locals_size} ->
        destruction
          ~tag:"CKLocalsParse"
          ~res:(left, size, pos, vec_kont, locals_size)
          ~delegate:cklocalsparse_enc
    | Decode.CKLocalsAccumulate {left; size; pos; type_vec; curr_type; vec_kont}
      ->
        destruction
          ~tag:"CKLocalsAccumulate"
          ~res:(left, size, pos, type_vec, curr_type, vec_kont)
          ~delegate:cklocalsaccumulate_enc
    | Decode.CKBody {left; size; locals; const_kont} ->
        destruction
          ~tag:"CKBody"
          ~res:(left, size, locals, const_kont)
          ~delegate:ckbody_enc
    | Decode.CKStop func ->
        destruction ~tag:"CKStop" ~res:func ~delegate:ckstop_enc

  let select_decode = function
    | "CKStart" ->
        decoding_branch
          ~extract:(fun () -> Lwt.return Decode.CKStart)
          ~delegate:ckstart_enc
    | "CKLocalsParse" ->
        decoding_branch
          ~extract:(fun (left, size, pos, vec_kont, locals_size) ->
            Lwt.return
            @@ Decode.CKLocalsParse {left; size; pos; vec_kont; locals_size})
          ~delegate:cklocalsparse_enc
    | "CKLocalsAccumulate" ->
        decoding_branch
          ~extract:(fun (left, size, pos, type_vec, curr_type, vec_kont) ->
            Lwt.return
            @@ Decode.CKLocalsAccumulate
                 {left; size; pos; type_vec; curr_type; vec_kont})
          ~delegate:cklocalsaccumulate_enc
    | "CKBody" ->
        decoding_branch
          ~extract:(fun (left, size, locals, const_kont) ->
            Lwt.return @@ Decode.CKBody {left; size; locals; const_kont})
          ~delegate:ckbody_enc
    | "CKStop" ->
        decoding_branch
          ~extract:(fun func -> Lwt.return @@ Decode.CKStop func)
          ~delegate:ckstop_enc
    | _ -> (* FIXME *) assert false

  let encoding =
    fast_tagged_union
      (value [] Data_encoding.string)
      ~select_encode
      ~select_decode
end

module Elem = struct
  let region enc =
    Data_encoding.conv
      (fun p -> p.Source.it)
      (fun v -> Source.(v @@ no_region))
      enc

  let index_kind_encoding =
    Data_encoding.string_enum
      [("Indexed", Decode.Indexed); ("Const", Decode.Const)]

  let ekstart_enc = value [] (Data_encoding.constant "EKStart")

  let ekmode_enc =
    let left = value ["left"] Data_encoding.int31 in
    let index =
      value
        ["index"]
        (Interpreter_encodings.Source.phrase_encoding Data_encoding.int32)
    in
    let index_kind = value ["index_kind"] index_kind_encoding in
    let early_ref_type =
      value_option
        ["early_ref_type"]
        Interpreter_encodings.Types.ref_type_encoding
    in
    let offset_kont = value ["offset_kont"] Data_encoding.int31 in
    let offset_kont_code = scope ["offset_kont_code"] Block.encoding in
    tup6
      ~flatten:true
      left
      index
      index_kind
      early_ref_type
      offset_kont
      offset_kont_code

  let ekinitindexed_enc =
    let mode = value ["mode"] Interpreter_encodings.Ast.segment_mode_encoding in
    let ref_type =
      value ["ref_type"] Interpreter_encodings.Types.ref_type_encoding
    in
    let einit_vec =
      scope
        ["einit_vec"]
        (Lazy_vec.encoding
           (value
              []
              (Interpreter_encodings.Source.phrase_encoding
                 Interpreter_encodings.Ast.block_label_encoding)))
    in
    tup3 ~flatten:true mode ref_type einit_vec

  let ekinitconst_enc =
    let mode = value ["mode"] Interpreter_encodings.Ast.segment_mode_encoding in
    let ref_type =
      value ["ref_type"] Interpreter_encodings.Types.ref_type_encoding
    in
    let einit_vec =
      scope
        ["einit_vec"]
        (Lazy_vec.encoding
           (value
              []
              (Interpreter_encodings.Source.phrase_encoding
                 Interpreter_encodings.Ast.block_label_encoding)))
    in
    let einit_kont_pos = value ["einit_kont_pos"] Data_encoding.int31 in
    let einit_kont_block = scope ["einit_kont_block"] Block.encoding in
    tup5 ~flatten:true mode ref_type einit_vec einit_kont_pos einit_kont_block

  let elem_encoding =
    let etype =
      value ["ref_type"] Interpreter_encodings.Types.ref_type_encoding
    in
    let einit =
      scope
        ["einit"]
        (vector_encoding (value [] Interpreter_encodings.Ast.const_encoding))
    in
    let emode =
      value ["mode"] Interpreter_encodings.Ast.segment_mode_encoding
    in
    conv
      (fun (etype, einit, emode) -> Ast.{etype; einit; emode})
      (fun Ast.{etype; einit; emode} -> (etype, einit, emode))
      (tup3 ~flatten:true etype einit emode)

  let ekstop_enc = elem_encoding

  let select_encode = function
    | Decode.EKStart -> destruction ~tag:"EKStart" ~res:() ~delegate:ekstart_enc
    | Decode.EKMode
        {
          left;
          index;
          index_kind;
          early_ref_type;
          offset_kont = offset_kont, offset_kont_code;
        } ->
        destruction
          ~tag:"EKMode"
          ~res:
            ( left,
              index,
              index_kind,
              early_ref_type,
              offset_kont,
              offset_kont_code )
          ~delegate:ekmode_enc
    | Decode.EKInitIndexed {mode; ref_type; einit_vec} ->
        destruction
          ~tag:"EKInitIndexed"
          ~res:(mode, ref_type, einit_vec)
          ~delegate:ekinitindexed_enc
    | Decode.EKInitConst {mode; ref_type; einit_vec; einit_kont = pos, block} ->
        destruction
          ~tag:"EKInitConst"
          ~res:(mode, ref_type, einit_vec, pos, block)
          ~delegate:ekinitconst_enc
    | Decode.EKStop elem ->
        destruction ~tag:"EKStop" ~res:elem ~delegate:ekstop_enc

  let select_decode = function
    | "EKStart" ->
        decoding_branch
          ~extract:(fun () -> Lwt.return @@ Decode.EKStart)
          ~delegate:ekstart_enc
    | "EKMode" ->
        decoding_branch
          ~extract:
            (fun ( left,
                   index,
                   index_kind,
                   early_ref_type,
                   offset_kont,
                   offset_kont_code ) ->
            Lwt.return
            @@ Decode.EKMode
                 {
                   left;
                   index;
                   index_kind;
                   early_ref_type;
                   offset_kont = (offset_kont, offset_kont_code);
                 })
          ~delegate:ekmode_enc
    | "EKInitIndexed" ->
        decoding_branch
          ~extract:(fun (mode, ref_type, einit_vec) ->
            Lwt.return @@ Decode.EKInitIndexed {mode; ref_type; einit_vec})
          ~delegate:ekinitindexed_enc
    | "EKInitConst" ->
        decoding_branch
          ~extract:(fun (mode, ref_type, einit_vec, pos, block) ->
            Lwt.return
            @@ Decode.EKInitConst
                 {mode; ref_type; einit_vec; einit_kont = (pos, block)})
          ~delegate:ekinitconst_enc
    | "EKStop" ->
        decoding_branch
          ~extract:(fun elem -> Lwt.return @@ Decode.EKStop elem)
          ~delegate:ekstop_enc
    | _ -> (* FIXME *) assert false

  let encoding =
    fast_tagged_union
      (value [] Data_encoding.string)
      ~select_encode
      ~select_decode
end

module Data = struct
  let dkstart_enc = value [] (Data_encoding.constant "DKStart")

  let dkmode_enc =
    let left = value ["left"] Data_encoding.int31 in
    let index =
      value
        ["index"]
        (Interpreter_encodings.Source.phrase_encoding Data_encoding.int32)
    in
    let offset_kont = value ["offset_kont"] Data_encoding.int31 in
    let offset_kont_code = scope ["offset_kont_code"] Block.encoding in
    tup4 ~flatten:true left index offset_kont offset_kont_code

  let dkinit_enc =
    let dmode =
      value ["dmode"] Interpreter_encodings.Ast.segment_mode_encoding
    in
    let init_kont = scope ["init_kont"] Byte_vector.encoding in
    tup2 ~flatten:true dmode init_kont

  let data_segment_encoding =
    let dmode =
      value ["dmode"] Interpreter_encodings.Ast.segment_mode_encoding
    in
    let dinit = value ["dinit"] Interpreter_encodings.Ast.data_label_encoding in
    conv
      (fun (dinit, dmode) -> Ast.{dinit; dmode})
      (fun {dinit; dmode} -> (dinit, dmode))
      (tup2 ~flatten:true dinit dmode)

  let dkstop_enc = data_segment_encoding

  let select_encode = function
    | Decode.DKStart -> destruction ~tag:"DKStart" ~res:() ~delegate:dkstart_enc
    | Decode.DKMode {left; index; offset_kont = pos, block} ->
        destruction
          ~tag:"DKMode"
          ~res:(left, index, pos, block)
          ~delegate:dkmode_enc
    | Decode.DKInit {dmode; init_kont} ->
        destruction ~tag:"DKInit" ~res:(dmode, init_kont) ~delegate:dkinit_enc
    | Decode.DKStop data_segment ->
        destruction ~tag:"DKStop" ~res:data_segment ~delegate:dkstop_enc

  let select_decode = function
    | "DKStart" ->
        decoding_branch
          ~extract:(fun () -> Lwt.return Decode.DKStart)
          ~delegate:dkstart_enc
    | "DKMode" ->
        decoding_branch
          ~extract:(fun (left, index, pos, block) ->
            Lwt.return
            @@ Decode.DKMode {left; index; offset_kont = (pos, block)})
          ~delegate:dkmode_enc
    | "DKInit" ->
        decoding_branch
          ~extract:(fun (dmode, init_kont) ->
            Lwt.return @@ Decode.DKInit {dmode; init_kont})
          ~delegate:dkinit_enc
    | "DKStop" ->
        decoding_branch
          ~extract:(fun data_segment ->
            Lwt.return @@ Decode.DKStop data_segment)
          ~delegate:dkstop_enc
    | _ -> (* FIXME *) assert false

  let encoding =
    fast_tagged_union
      (value [] Data_encoding.string)
      ~select_encode
      ~select_decode
end

module Field = struct
  let type_field_encoding =
    scope
      ["module"; "types"]
      (vector_encoding (no_region_encoding Wasm_encoding.func_type_encoding))

  let import_field_encoding =
    scope
      ["module"; "imports"]
      (vector_encoding (no_region_encoding Import.import_encoding))

  let func_field_encoding =
    scope
      ["module"; "funcs"]
      (vector_encoding (value [] Interpreter_encodings.Ast.var_encoding))

  let table_field_encoding =
    scope
      ["module"; "tables"]
      (vector_encoding (value [] Interpreter_encodings.Ast.table_encoding))

  let memory_field_encoding =
    scope
      ["module"; "memories"]
      (vector_encoding (value [] Interpreter_encodings.Ast.memory_encoding))

  let global_field_encoding =
    scope
      ["module"; "globals"]
      (vector_encoding (value [] Interpreter_encodings.Ast.global_encoding))

  let export_field_encoding =
    scope
      ["module"; "exports"]
      (vector_encoding (no_region_encoding Export.export_encoding))

  let start_field_encoding =
    value_option ["module"; "start"] Interpreter_encodings.Ast.start_encoding

  let elem_field_encoding =
    scope
      ["module"; "elem_segments"]
      (vector_encoding (no_region_encoding Elem.elem_encoding))

  let data_count_field_encoding =
    value_option ["module"; "data_count"] Data_encoding.int32

  let code_field_encoding =
    scope ["module"; "code"] (vector_encoding Code.func_encoding)

  let data_field_encoding =
    scope
      ["module"; "data_segments"]
      (vector_encoding (no_region_encoding Data.data_segment_encoding))

  let building_state_encoding =
    conv
      (fun ( types,
             imports,
             vars,
             tables,
             memories,
             globals,
             exports,
             start,
             (elems, data_count, code, datas) ) ->
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
          })
      (fun Decode.
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
             } ->
        ( types,
          imports,
          vars,
          tables,
          memories,
          globals,
          exports,
          start,
          (elems, data_count, code, datas) ))
      (tup9
         ~flatten:true
         type_field_encoding
         import_field_encoding
         func_field_encoding
         table_field_encoding
         memory_field_encoding
         global_field_encoding
         export_field_encoding
         start_field_encoding
         (tup4
            ~flatten:true
            elem_field_encoding
            data_count_field_encoding
            code_field_encoding
            data_field_encoding))

  (* Only used to encode field_type. *)
  type packed_field_type =
    | FieldType : ('a, 'repr) Decode.field_type -> packed_field_type

  let packed_field_type_encoding =
    let type_field_enc = value [] (Data_encoding.constant "TypeField") in
    let import_field_enc = value [] (Data_encoding.constant "ImportField") in
    let func_field_enc = value [] (Data_encoding.constant "FuncField") in
    let table_field_enc = value [] (Data_encoding.constant "TableField") in
    let memory_field_enc = value [] (Data_encoding.constant "MemoryField") in
    let global_field_enc = value [] (Data_encoding.constant "GlobalField") in
    let export_field_enc = value [] (Data_encoding.constant "ExportField") in
    let start_field_enc = value [] (Data_encoding.constant "StartField") in
    let elem_field_enc = value [] (Data_encoding.constant "ElemField") in
    let data_count_field_enc =
      value [] (Data_encoding.constant "DataCountField")
    in
    let code_field_enc = value [] (Data_encoding.constant "CodeField") in
    let data_field_enc = value [] (Data_encoding.constant "DataField") in
    let enum_destruction tag delegate = destruction ~tag ~res:() ~delegate in
    let select_encode = function
      | FieldType Decode.TypeField ->
          enum_destruction "TypeField" type_field_enc
      | FieldType Decode.ImportField ->
          enum_destruction "ImportField" import_field_enc
      | FieldType Decode.FuncField ->
          enum_destruction "FuncField" func_field_enc
      | FieldType Decode.TableField ->
          enum_destruction "TableField" table_field_enc
      | FieldType Decode.MemoryField ->
          enum_destruction "MemoryField" memory_field_enc
      | FieldType Decode.GlobalField ->
          enum_destruction "GlobalField" global_field_enc
      | FieldType Decode.ExportField ->
          enum_destruction "ExportField" export_field_enc
      | FieldType Decode.StartField ->
          enum_destruction "StartField" start_field_enc
      | FieldType Decode.ElemField ->
          enum_destruction "ElemField" elem_field_enc
      | FieldType Decode.DataCountField ->
          enum_destruction "DataCountField" data_count_field_enc
      | FieldType Decode.CodeField ->
          enum_destruction "CodeField" code_field_enc
      | FieldType Decode.DataField ->
          enum_destruction "DataField" data_field_enc
    in
    let enum_decoding_branch k delegate =
      decoding_branch ~extract:(fun () -> Lwt.return @@ FieldType k) ~delegate
    in
    let select_decode = function
      | "TypeField" -> enum_decoding_branch Decode.TypeField type_field_enc
      | "ImportField" ->
          enum_decoding_branch Decode.ImportField import_field_enc
      | "FuncField" -> enum_decoding_branch Decode.FuncField func_field_enc
      | "TableField" -> enum_decoding_branch Decode.TableField table_field_enc
      | "MemoryField" ->
          enum_decoding_branch Decode.MemoryField memory_field_enc
      | "GlobalField" ->
          enum_decoding_branch Decode.GlobalField global_field_enc
      | "ExportField" ->
          enum_decoding_branch Decode.ExportField export_field_enc
      | "StartField" -> enum_decoding_branch Decode.StartField start_field_enc
      | "ElemField" -> enum_decoding_branch Decode.ElemField elem_field_enc
      | "DataCountField" ->
          enum_decoding_branch Decode.DataCountField data_count_field_enc
      | "CodeField" -> enum_decoding_branch Decode.CodeField code_field_enc
      | "DataField" -> enum_decoding_branch Decode.DataField data_field_enc
      | _ -> (* FIXME *) assert false
    in
    fast_tagged_union
      (value [] Data_encoding.string)
      ~select_encode
      ~select_decode

  (* Only used to encode lazy vector parameterized by the field type in the
     continuation. *)
  type packed_typed_lazy_vec =
    | TypedLazyVec :
        ('a, Decode.vec_repr) Decode.field_type * 'a Decode.lazy_vec_kont
        -> packed_typed_lazy_vec

  let packed_typed_lazy_vec_encoding =
    let type_field_enc = Lazy_vec.raw_encoding type_field_encoding in
    let import_field_enc = Lazy_vec.raw_encoding import_field_encoding in
    let func_field_enc = Lazy_vec.raw_encoding func_field_encoding in
    let table_field_enc = Lazy_vec.raw_encoding table_field_encoding in
    let memory_field_enc = Lazy_vec.raw_encoding memory_field_encoding in
    let global_field_enc = Lazy_vec.raw_encoding global_field_encoding in
    let export_field_enc = Lazy_vec.raw_encoding export_field_encoding in
    let elem_field_enc = Lazy_vec.raw_encoding elem_field_encoding in
    let code_field_enc = Lazy_vec.raw_encoding code_field_encoding in
    let data_field_enc = Lazy_vec.raw_encoding data_field_encoding in
    let select_encode = function
      | TypedLazyVec (Decode.TypeField, vec) ->
          destruction ~tag:"TypeField" ~res:vec ~delegate:type_field_enc
      | TypedLazyVec (Decode.ImportField, vec) ->
          destruction ~tag:"ImportField" ~res:vec ~delegate:import_field_enc
      | TypedLazyVec (Decode.FuncField, vec) ->
          destruction ~tag:"FuncField" ~res:vec ~delegate:func_field_enc
      | TypedLazyVec (Decode.TableField, vec) ->
          destruction ~tag:"TableField" ~res:vec ~delegate:table_field_enc
      | TypedLazyVec (Decode.MemoryField, vec) ->
          destruction ~tag:"MemoryField" ~res:vec ~delegate:memory_field_enc
      | TypedLazyVec (Decode.GlobalField, vec) ->
          destruction ~tag:"GlobalField" ~res:vec ~delegate:global_field_enc
      | TypedLazyVec (Decode.ExportField, vec) ->
          destruction ~tag:"ExportField" ~res:vec ~delegate:export_field_enc
      | TypedLazyVec (Decode.ElemField, vec) ->
          destruction ~tag:"ElemField" ~res:vec ~delegate:elem_field_enc
      | TypedLazyVec (Decode.CodeField, vec) ->
          destruction ~tag:"CodeField" ~res:vec ~delegate:code_field_enc
      | TypedLazyVec (Decode.DataField, vec) ->
          destruction ~tag:"DataField" ~res:vec ~delegate:data_field_enc
    and select_decode = function
      | "TypeField" ->
          decoding_branch
            ~extract:(fun vec ->
              Lwt.return @@ TypedLazyVec (Decode.TypeField, vec))
            ~delegate:type_field_enc
      | "ImportField" ->
          decoding_branch
            ~extract:(fun vec ->
              Lwt.return @@ TypedLazyVec (Decode.ImportField, vec))
            ~delegate:import_field_enc
      | "FuncField" ->
          decoding_branch
            ~extract:(fun vec ->
              Lwt.return @@ TypedLazyVec (Decode.FuncField, vec))
            ~delegate:func_field_enc
      | "TableField" ->
          decoding_branch
            ~extract:(fun vec ->
              Lwt.return @@ TypedLazyVec (Decode.TableField, vec))
            ~delegate:table_field_enc
      | "MemoryField" ->
          decoding_branch
            ~extract:(fun vec ->
              Lwt.return @@ TypedLazyVec (Decode.MemoryField, vec))
            ~delegate:memory_field_enc
      | "GlobalField" ->
          decoding_branch
            ~extract:(fun vec ->
              Lwt.return @@ TypedLazyVec (Decode.GlobalField, vec))
            ~delegate:global_field_enc
      | "ExportField" ->
          decoding_branch
            ~extract:(fun vec ->
              Lwt.return @@ TypedLazyVec (Decode.ExportField, vec))
            ~delegate:export_field_enc
      | "ElemField" ->
          decoding_branch
            ~extract:(fun vec ->
              Lwt.return @@ TypedLazyVec (Decode.ElemField, vec))
            ~delegate:elem_field_enc
      | "CodeField" ->
          decoding_branch
            ~extract:(fun vec ->
              Lwt.return @@ TypedLazyVec (Decode.CodeField, vec))
            ~delegate:code_field_enc
      | "DataField" ->
          decoding_branch
            ~extract:(fun vec ->
              Lwt.return @@ TypedLazyVec (Decode.DataField, vec))
            ~delegate:data_field_enc
      | _ -> (* FIXME *) assert false
    in
    fast_tagged_union
      (value [] Data_encoding.string)
      ~select_encode
      ~select_decode
end

module Module = struct
  let mkstart_enc = value [] (Data_encoding.constant "MKStart")

  let mkskipcustom_enc = option Field.packed_field_type_encoding

  let mkfieldstart_enc = Field.packed_field_type_encoding

  let mkfield_enc =
    tup2 ~flatten:true Field.packed_typed_lazy_vec_encoding Size.encoding

  let mkelaboratefunc_enc =
    let func_types = Field.func_field_encoding in
    let func_bodies = Field.code_field_encoding in
    let func_kont =
      scope ["func_kont"] (Lazy_vec.encoding Code.func_encoding)
    in
    let instr_kont =
      scope
        ["instr_kont"]
        (option
           (Lazy_vec.encoding
              (Lazy_vec.encoding Wasm_encoding.instruction_encoding)))
    in
    let no_datas_in_func = value ["no-datas-in-funcs"] Data_encoding.bool in
    tup5
      ~flatten:true
      func_types
      func_bodies
      func_kont
      instr_kont
      no_datas_in_func

  let module_funcs_encoding =
    scope ["module"; "funcs"] (vector_encoding Code.func_encoding)

  let mkbuild_enc =
    let no_datas_in_func = value ["no-datas-in-funcs"] Data_encoding.bool in
    tup2 ~flatten:true (option module_funcs_encoding) no_datas_in_func

  let mktypes_enc =
    let func_type_kont = scope ["func_type_kont"] Func_type.encoding in
    let pos = value ["pos"] Data_encoding.int31 in
    let size = scope ["size"] Size.encoding in
    let type_accumulator = Lazy_vec.raw_encoding Field.type_field_encoding in
    tup4 ~flatten:true func_type_kont pos size type_accumulator

  let mkimport_enc =
    let import_kont = scope ["import_kont"] Import.encoding in
    let pos = value ["pos"] Data_encoding.int31 in
    let size = scope ["size"] Size.encoding in
    let import_accumulator =
      Lazy_vec.raw_encoding Field.import_field_encoding
    in
    tup4 ~flatten:true import_kont pos size import_accumulator

  let mkexport_enc =
    let export_kont = scope ["export_kont"] Export.encoding in
    let pos = value ["pos"] Data_encoding.int31 in
    let size = scope ["size"] Size.encoding in
    let export_accumulator =
      Lazy_vec.raw_encoding Field.export_field_encoding
    in
    tup4 ~flatten:true export_kont pos size export_accumulator

  let mkglobal_enc =
    let global_type =
      value ["global_type"] Interpreter_encodings.Types.global_type_encoding
    in
    let block_kont = scope ["block_kont"] Block.encoding in
    let pos = value ["pos"] Data_encoding.int31 in
    let size = scope ["size"] Size.encoding in
    let global_accumulator =
      Lazy_vec.raw_encoding Field.global_field_encoding
    in
    tup5 ~flatten:true global_type pos block_kont size global_accumulator

  let mkdata_enc =
    let data_kont = scope ["data_kont"] Data.encoding in
    let pos = value ["pos"] Data_encoding.int31 in
    let size = scope ["size"] Size.encoding in
    let data_accumulator = Lazy_vec.raw_encoding Field.data_field_encoding in
    tup4 ~flatten:true data_kont pos size data_accumulator

  let mkelem_enc =
    let elem_kont = scope ["elem_kont"] Elem.encoding in
    let pos = value ["pos"] Data_encoding.int31 in
    let size = scope ["size"] Size.encoding in
    let elem_accumulator = Lazy_vec.raw_encoding Field.elem_field_encoding in
    tup4 ~flatten:true elem_kont pos size elem_accumulator

  let mkcode_enc =
    let code_kont = scope ["code_kont"] Code.encoding in
    let pos = value ["pos"] Data_encoding.int31 in
    let size = scope ["size"] Size.encoding in
    let code_accumulator = Lazy_vec.raw_encoding Field.code_field_encoding in
    tup4 ~flatten:true code_kont pos size code_accumulator

  let module_encoding =
    let open Field in
    conv
      (fun ( types,
             globals,
             tables,
             memories,
             funcs,
             start,
             elems,
             datas,
             (imports, exports, allocations) ) ->
        Ast.
          {
            types;
            tables;
            memories;
            globals;
            funcs;
            imports;
            exports;
            elems;
            datas;
            start;
            allocations;
          })
      (fun {
             types;
             tables;
             memories;
             globals;
             funcs;
             imports;
             exports;
             elems;
             datas;
             start;
             allocations;
           } ->
        ( types,
          globals,
          tables,
          memories,
          funcs,
          start,
          elems,
          datas,
          (imports, exports, allocations) ))
      (tup9
         ~flatten:true
         type_field_encoding
         global_field_encoding
         table_field_encoding
         memory_field_encoding
         module_funcs_encoding
         start_field_encoding
         elem_field_encoding
         data_field_encoding
         (tup3
            ~flatten:true
            import_field_encoding
            export_field_encoding
            Wasm_encoding.allocations_encoding))

  let mkstop_enc = no_region_encoding module_encoding

  let select_encode = function
    | Decode.MKStart -> destruction ~tag:"MKStart" ~res:() ~delegate:mkstart_enc
    | Decode.MKSkipCustom (Some field_type) ->
        destruction
          ~tag:"MKSkipCustom"
          ~res:(Some (Field.FieldType field_type))
          ~delegate:mkskipcustom_enc
    | Decode.MKSkipCustom None ->
        destruction ~tag:"MKSkipCustom" ~res:None ~delegate:mkskipcustom_enc
    | Decode.MKFieldStart field_type ->
        destruction
          ~tag:"MKFieldStart"
          ~res:(Field.FieldType field_type)
          ~delegate:mkfieldstart_enc
    | Decode.MKField (field_type, size, vec) ->
        destruction
          ~tag:"MKField"
          ~res:(Field.TypedLazyVec (field_type, vec), size)
          ~delegate:mkfield_enc
    | Decode.MKElaborateFunc
        (func_types, func_bodies, func_kont, instr_kont, no_datas_in_func) ->
        destruction
          ~tag:"MKElaborateFunc"
          ~res:(func_types, func_bodies, func_kont, instr_kont, no_datas_in_func)
          ~delegate:mkelaboratefunc_enc
    | Decode.MKBuild (funcs, no_datas_in_func) ->
        destruction
          ~tag:"MKBuild"
          ~res:(funcs, no_datas_in_func)
          ~delegate:mkbuild_enc
    | Decode.MKTypes (func_type_kont, pos, size, types_acc) ->
        destruction
          ~tag:"MKTypes"
          ~res:(func_type_kont, pos, size, types_acc)
          ~delegate:mktypes_enc
    | Decode.MKImport (import_kont, pos, size, import_acc) ->
        destruction
          ~tag:"MKImport"
          ~res:(import_kont, pos, size, import_acc)
          ~delegate:mkimport_enc
    | Decode.MKExport (export_kont, pos, size, export_acc) ->
        destruction
          ~tag:"MKExport"
          ~res:(export_kont, pos, size, export_acc)
          ~delegate:mkexport_enc
    | Decode.MKGlobal (global_type, pos, block_kont, size, global_acc) ->
        destruction
          ~tag:"MKGlobal"
          ~res:(global_type, pos, block_kont, size, global_acc)
          ~delegate:mkglobal_enc
    | Decode.MKData (data_kont, pos, size, data_acc) ->
        destruction
          ~tag:"MKData"
          ~res:(data_kont, pos, size, data_acc)
          ~delegate:mkdata_enc
    | Decode.MKElem (elem_kont, pos, size, elem_acc) ->
        destruction
          ~tag:"MKElem"
          ~res:(elem_kont, pos, size, elem_acc)
          ~delegate:mkelem_enc
    | Decode.MKCode (code_kont, pos, size, code_acc) ->
        destruction
          ~tag:"MKCode"
          ~res:(code_kont, pos, size, code_acc)
          ~delegate:mkcode_enc
    | Decode.MKStop m -> destruction ~tag:"MKStop" ~res:m ~delegate:mkstop_enc

  let select_decode = function
    | "MKStart" ->
        decoding_branch
          ~extract:(fun () -> Lwt.return Decode.MKStart)
          ~delegate:mkstart_enc
    | "MKSkipCustom" ->
        decoding_branch
          ~extract:(function
            | None -> Lwt.return @@ Decode.MKSkipCustom None
            | Some (Field.FieldType ft) ->
                Lwt.return @@ Decode.MKSkipCustom (Some ft))
          ~delegate:mkskipcustom_enc
    | "MKFieldStart" ->
        decoding_branch
          ~extract:(fun (Field.FieldType ft) ->
            Lwt.return @@ Decode.MKFieldStart ft)
          ~delegate:mkfieldstart_enc
    | "MKField" ->
        decoding_branch
          ~extract:(fun (Field.TypedLazyVec (ft, vec), size) ->
            Lwt.return @@ Decode.MKField (ft, size, vec))
          ~delegate:mkfield_enc
    | "MKElaborateFunc" ->
        decoding_branch
          ~extract:
            (fun ( func_types,
                   func_bodies,
                   func_kont,
                   instr_kont,
                   no_datas_in_func ) ->
            Lwt.return
            @@ Decode.MKElaborateFunc
                 ( func_types,
                   func_bodies,
                   func_kont,
                   instr_kont,
                   no_datas_in_func ))
          ~delegate:mkelaboratefunc_enc
    | "MKBuild" ->
        decoding_branch
          ~extract:(fun (funcs, no_datas_in_func) ->
            Lwt.return @@ Decode.MKBuild (funcs, no_datas_in_func))
          ~delegate:mkbuild_enc
    | "MKTypes" ->
        decoding_branch
          ~extract:(fun (func_type_kont, pos, size, types_acc) ->
            Lwt.return @@ Decode.MKTypes (func_type_kont, pos, size, types_acc))
          ~delegate:mktypes_enc
    | "MKImport" ->
        decoding_branch
          ~extract:(fun (import_kont, pos, size, import_acc) ->
            Lwt.return @@ Decode.MKImport (import_kont, pos, size, import_acc))
          ~delegate:mkimport_enc
    | "MKExport" ->
        decoding_branch
          ~extract:(fun (export_kont, pos, size, export_acc) ->
            Lwt.return @@ Decode.MKExport (export_kont, pos, size, export_acc))
          ~delegate:mkexport_enc
    | "MKGlobal" ->
        decoding_branch
          ~extract:(fun (global_type, pos, block_kont, size, global_acc) ->
            Lwt.return
            @@ Decode.MKGlobal (global_type, pos, block_kont, size, global_acc))
          ~delegate:mkglobal_enc
    | "MKData" ->
        decoding_branch
          ~extract:(fun (data_kont, pos, size, data_acc) ->
            Lwt.return @@ Decode.MKData (data_kont, pos, size, data_acc))
          ~delegate:mkdata_enc
    | "MKElem" ->
        decoding_branch
          ~extract:(fun (elem_kont, pos, size, elem_acc) ->
            Lwt.return @@ Decode.MKElem (elem_kont, pos, size, elem_acc))
          ~delegate:mkelem_enc
    | "MKCode" ->
        decoding_branch
          ~extract:(fun (code_kont, pos, size, code_acc) ->
            Lwt.return @@ Decode.MKCode (code_kont, pos, size, code_acc))
          ~delegate:mkcode_enc
    | "MKStop" ->
        decoding_branch
          ~extract:(fun m -> Lwt.return @@ Decode.MKStop m)
          ~delegate:mkstop_enc
    | _ -> (* FIXME *) assert false

  let encoding =
    fast_tagged_union
      (value [] Data_encoding.string)
      ~select_encode
      ~select_decode
end

module Building_state = struct
  let types_encoding =
    vector_encoding (no_region_encoding Wasm_encoding.func_type_encoding)

  let imports_encoding =
    vector_encoding (no_region_encoding Import.import_encoding)

  let vars_encoding =
    vector_encoding (value [] Interpreter_encodings.Ast.var_encoding)

  let tables_encoding =
    vector_encoding (value [] Interpreter_encodings.Ast.table_encoding)

  let memories_encoding =
    vector_encoding (value [] Interpreter_encodings.Ast.memory_encoding)

  let globals_encoding =
    vector_encoding (value [] Interpreter_encodings.Ast.global_encoding)

  let exports_encoding =
    vector_encoding (no_region_encoding Export.export_encoding)

  let start_encoding = value_option [] Interpreter_encodings.Ast.start_encoding

  let elems_encoding = vector_encoding (no_region_encoding Elem.elem_encoding)

  let code_encoding =
    vector_encoding (no_region_encoding Wasm_encoding.func'_encoding)

  let datas_encoding =
    vector_encoding (no_region_encoding Data.data_segment_encoding)

  let encoding =
    conv
      (fun ( types,
             imports,
             vars,
             tables,
             memories,
             globals,
             exports,
             start,
             (elems, data_count, code, datas) ) ->
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
          })
      (fun {
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
           } ->
        ( types,
          imports,
          vars,
          tables,
          memories,
          globals,
          exports,
          start,
          (elems, data_count, code, datas) ))
      (tup9
         ~flatten:true
         (scope ["types"] types_encoding)
         (scope ["imports"] imports_encoding)
         (scope ["vars"] vars_encoding)
         (scope ["tables"] tables_encoding)
         (scope ["memories"] memories_encoding)
         (scope ["globals"] globals_encoding)
         (scope ["exports"] exports_encoding)
         (scope ["start"] start_encoding)
         (tup4
            ~flatten:true
            (scope ["elems"] elems_encoding)
            (scope ["data_count"] (value_option [] Data_encoding.int32))
            (scope ["code"] code_encoding)
            (scope ["datas"] datas_encoding)))
end

module Decode = struct
  let encoding =
    conv
      (fun ( building_state,
             module_kont,
             allocation_state,
             stream_pos,
             stream_name ) ->
        Decode.
          {
            building_state;
            module_kont;
            allocation_state;
            stream_pos;
            stream_name;
          })
      (fun {
             building_state;
             module_kont;
             allocation_state;
             stream_pos;
             stream_name;
           } ->
        (building_state, module_kont, allocation_state, stream_pos, stream_name))
    @@ tup5
         ~flatten:true
         (scope ["building_state"] Building_state.encoding)
         (scope ["module_kont"] Module.encoding)
         (scope ["allocation_state"] Wasm_encoding.allocations_encoding)
         (value ["stream_pos"] Data_encoding.int31)
         (value ["stream_name"] Data_encoding.string)
end
