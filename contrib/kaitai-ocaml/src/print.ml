(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

open Types
open Yaml

let scalar ?anchor ?tag ?(plain_implicit = true) ?(quoted_implicit = false)
    ?(style = `Any) value =
  `Scalar {anchor; tag; value; plain_implicit; quoted_implicit; style}

let sequence l =
  `A {s_anchor = None; s_tag = None; s_implicit = true; s_members = l}

let mapping l =
  `O
    {
      m_anchor = None;
      m_tag = None;
      m_implicit = true;
      m_members = List.map (fun (k, v) -> (scalar k, v)) l;
    }

let mapping_flatten l = mapping (List.flatten l)

let map_list_of_option f = function None -> [] | Some x -> [f x]

let metaSpec (t : MetaSpec.t) =
  mapping_flatten
    [
      map_list_of_option (fun id -> ("id", scalar id)) t.id;
      map_list_of_option
        (fun endian -> ("endian", scalar (Endianness.to_string endian)))
        t.endian;
    ]

let doc_spec DocSpec.{summary; refs = _} =
  map_list_of_option
    (fun summary ->
      let style = if String.length summary > 80 then `Folded else `Any in
      ("doc", scalar ~style summary))
    summary

let instanceSpec InstanceSpec.{doc = _; descr} =
  (* TODO: pp doc spec as well. *)
  match descr with
  | ValueInstanceSpec instance ->
      mapping [("value", scalar (Ast.to_string instance.value))]
  | ParseInstanceSpec -> failwith "not supported (ParseInstanceSpec)"

let instances_spec instances =
  mapping (instances |> List.map (fun (k, v) -> (k, instanceSpec v)))

let enumSpec enumspec =
  mapping
    (List.map
       (fun (v, EnumValueSpec.{name; doc}) ->
         ( string_of_int v,
           match doc_spec doc with
           | [] -> scalar name
           | l -> mapping (("id", scalar name) :: l) ))
       enumspec.EnumSpec.map)

let enums_spec enums =
  mapping (enums |> List.map (fun (k, v) -> (k, enumSpec v)))

(** We only add "type" to Yaml if not [AnyType]. *)
let type_spec attr =
  match attr.AttrSpec.dataType with
  | AnyType | BytesType _ -> []
  | NumericType _ | BooleanType _ | StrType _ | ComplexDataType _ | Raw _ ->
      [("type", scalar (DataType.to_string attr.AttrSpec.dataType))]

let repeat_spec =
  let open RepeatSpec in
  function
  | NoRepeat -> []
  | RepeatUntil expr ->
      [
        ("repeat", scalar "until"); ("repeat-until", scalar (Ast.to_string expr));
      ]
  | RepeatEos -> [("repeat", scalar "eos")]
  | RepeatExpr expr ->
      [("repeat", scalar "expr"); ("repeat-expr", scalar (Ast.to_string expr))]

let if_spec = function
  | None -> []
  | Some ast -> [("if", scalar (Ast.to_string ast))]

let valid_spec : ValidationSpec.t option -> _ = function
  | None -> []
  | Some v ->
      let v =
        match v with
        | ValidationEq e -> [("eq", scalar (Ast.to_string e))]
        | ValidationMin e -> [("min", scalar (Ast.to_string e))]
        | ValidationMax e -> [("max", scalar (Ast.to_string e))]
        | ValidationRange {min; max} ->
            [
              ("min", scalar (Ast.to_string min));
              ("max", scalar (Ast.to_string max));
            ]
        | ValidationAnyOf es ->
            [
              ( "any-of",
                sequence (List.map (fun e -> scalar (Ast.to_string e)) es) );
            ]
        | ValidationExpr e -> [("expr", scalar (Ast.to_string e))]
      in
      [("valid", mapping v)]

let enum_spec attr =
  map_list_of_option (fun enum -> ("enum", scalar enum)) attr.AttrSpec.enum

let size_spec attr =
  map_list_of_option
    (fun e -> ("size", scalar (Ast.to_string e)))
    attr.AttrSpec.size
  @
  match attr.AttrSpec.dataType with
  | BytesType (BytesEosType _) -> [("size-eos", scalar "true")]
  | _ -> []

let attr_spec attr =
  [
    mapping_flatten
      [
        [("id", scalar attr.AttrSpec.id)];
        type_spec attr;
        size_spec attr;
        repeat_spec attr.cond.repeat;
        if_spec attr.cond.ifExpr;
        valid_spec attr.valid;
        enum_spec attr;
        doc_spec attr.doc;
      ];
  ]

let seq_spec seq = sequence (List.concat_map attr_spec seq)

let spec_if_non_empty name args f =
  match args with [] -> [] | _ :: _ -> [(name, f args)]

let rec to_yaml (t : ClassSpec.t) =
  mapping_flatten
    [
      (if t.isTopLevel then [("meta", metaSpec t.meta)] else []);
      doc_spec t.doc;
      spec_if_non_empty "types" t.types types_spec;
      spec_if_non_empty "instances" t.instances instances_spec;
      spec_if_non_empty "enums" t.enums enums_spec;
      spec_if_non_empty "seq" t.seq seq_spec;
    ]

and types_spec types = mapping (types |> List.map (fun (k, v) -> (k, to_yaml v)))

let to_string t =
  let y = to_yaml t in
  match Yaml.yaml_to_string y with Ok x -> x | Error (`Msg m) -> failwith m

let print_diff difftool a b =
  let a_str = Sexplib.Sexp.to_string_hum (Types.ClassSpec.sexp_of_t a) in
  let b_str = Sexplib.Sexp.to_string_hum (Types.ClassSpec.sexp_of_t b) in
  let output_to_file c =
    let f = Filename.temp_file "kaitai" ".ksy" in
    let oc = open_out_bin f in
    output_string oc c ;
    close_out oc ;
    f
  in
  let f1 = output_to_file a_str in
  let f2 = output_to_file b_str in
  ignore (Sys.command (Printf.sprintf "%s %s %s" difftool f1 f2) : int) ;
  Sys.remove f1 ;
  Sys.remove f2

let print t =
  let s = to_string t in
  let t' = Parse.parse s in
  if t <> t' then (
    match Sys.getenv_opt "KAITAIDIFF" with
    | None | Some "" ->
        failwith
          "Printing kaitai value does not roundtrip. Set the KAITAIDIFF \
           environment variable with a difftool to display the diff"
    | Some difftool ->
        print_diff difftool t t' ;
        failwith "Printing kaitai value does not roundtrip")
  else s
