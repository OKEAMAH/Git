(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

(* Identifiers have a strict pattern to follow, this function removes the
   irregularities.

   Without escaping, the kaitai-struct-compiler throws the following error
   message: [error: invalid meta ID, expected /^[a-z][a-z0-9_]*$/] *)
let escape_id id =
  if String.length id < 1 then raise (Invalid_argument "empty id") ;
  let b = Buffer.create (String.length id) in
  if match id.[0] with 'a' .. 'z' | 'A' .. 'Z' -> false | _ -> true then
    Buffer.add_string b "id_" ;
  String.iter
    (function
      | ('a' .. 'z' | '0' .. '9' | '_') as c -> Buffer.add_char b c
      | 'A' .. 'Z' as c -> Buffer.add_char b (Char.lowercase_ascii c)
      | '.' | '-' | ' ' -> Buffer.add_string b "__"
      | c ->
          (* we print [%S] to force escaping of the character *)
          raise
            (Failure
               (Format.asprintf
                  "Unsupported: special character (%C) in id (%S)"
                  c
                  id)))
    id ;
  Buffer.contents b

open Kaitai.Types

(* We need to access the definition of data-encoding's [descr] type. For this
   reason we alias the private/internal module [Data_encoding__Encoding] (rather
   than the public module [Data_encoding.Encoding]. *)
module DataEncoding = Data_encoding__Encoding

let summary ~title ~description =
  match (title, description) with
  | None, None -> None
  | None, (Some _ as s) | (Some _ as s), None -> s
  | Some t, Some d -> Some (t ^ ": " ^ d)

(* when an encoding has id [x],
   then the attr for its size has id [size_id_of_id x] *)
let size_id_of_id id = "size_of_" ^ id

(* in kaitai-struct, some fields can be added to single attributes but not to a
   group of them. When we want to attach a field to a group of attributes, we
   need to create an indirection to a named type. [redirect] is a function for
   adding a field to an indirection. *)
let redirect types attrs fattr id =
  let ((_, user_type) as type_) = (id, Helpers.class_spec_of_attrs ~id attrs) in
  let types = Helpers.add_uniq_assoc types type_ in
  let attr =
    fattr
      {
        (Helpers.default_attr_spec ~id) with
        dataType = DataType.(ComplexDataType (UserType user_type));
      }
  in
  (types, attr)

(* [redirect_if_many] is like [redirect] but it only does the redirection when
   there are multiple attributes, otherwise it adds the field directly. *)
let redirect_if_many :
    Ground.Type.assoc ->
    AttrSpec.t list ->
    (AttrSpec.t -> AttrSpec.t) ->
    string ->
    Ground.Type.assoc * AttrSpec.t =
 fun types attrs fattr id ->
  match attrs with
  | [] -> failwith "Not supported"
  | [attr] -> (types, {(fattr attr) with id})
  | _ :: _ :: _ as attrs -> redirect types attrs fattr id

let rec seq_field_of_data_encoding :
    type a.
    Ground.Enum.assoc ->
    Ground.Type.assoc ->
    a DataEncoding.t ->
    string ->
    Helpers.tid_gen option ->
    Ground.Enum.assoc * Ground.Type.assoc * AttrSpec.t list =
 fun enums types {encoding; _} id tid_gen ->
  let id = escape_id id in
  match encoding with
  | Null -> (enums, types, [])
  | Empty -> (enums, types, [])
  | Ignore -> (enums, types, [])
  | Constant _ -> (enums, types, [])
  | Bool ->
      let enums = Helpers.add_uniq_assoc enums Ground.Enum.bool in
      (enums, types, [Ground.Attr.bool ~id])
  | Uint8 -> (enums, types, [Ground.Attr.uint8 ~id])
  | Int8 -> (enums, types, [Ground.Attr.int8 ~id])
  | Uint16 -> (enums, types, [Ground.Attr.uint16 ~id])
  | Int16 -> (enums, types, [Ground.Attr.int16 ~id])
  | Int32 -> (enums, types, [Ground.Attr.int32 ~id])
  | Int64 -> (enums, types, [Ground.Attr.int64 ~id])
  | Int31 -> (enums, types, [Ground.Attr.int31 ~id])
  | RangedInt {minimum; maximum} -> (
      (* TODO: support shifted RangedInt
         - make the de/serialiser shift the value
         - make the [valid] field check the shifted value *)
      if minimum > 0 then failwith "Not supported (shifted range)" ;
      let size = Data_encoding__Binary_size.range_to_size ~minimum ~maximum in
      let valid =
        Some
          (ValidationSpec.ValidationRange
             {min = Ast.IntNum minimum; max = Ast.IntNum maximum})
      in
      let uvalid =
        if minimum = 0 then
          Some (ValidationSpec.ValidationMax (Ast.IntNum maximum))
        else valid
      in
      match size with
      | `Uint8 -> (enums, types, [{(Ground.Attr.uint8 ~id) with valid = uvalid}])
      | `Uint16 ->
          (enums, types, [{(Ground.Attr.uint16 ~id) with valid = uvalid}])
      | `Uint30 ->
          (enums, types, [{(Ground.Attr.uint30 ~id) with valid = uvalid}])
      | `Int8 -> (enums, types, [{(Ground.Attr.int8 ~id) with valid}])
      | `Int16 -> (enums, types, [{(Ground.Attr.int16 ~id) with valid}])
      | `Int31 -> (enums, types, [{(Ground.Attr.int31 ~id) with valid}]))
  | Float -> (enums, types, [Ground.Attr.float ~id])
  | RangedFloat {minimum; maximum} ->
      let valid =
        Some
          (ValidationSpec.ValidationRange
             {min = Ast.FloatNum minimum; max = Ast.FloatNum maximum})
      in
      (enums, types, [{(Ground.Attr.float ~id) with valid}])
  | Bytes (`Fixed n, _) -> (enums, types, [Ground.Attr.bytes ~id (Fixed n)])
  | Bytes (`Variable, _) -> (enums, types, [Ground.Attr.bytes ~id Variable])
  | Dynamic_size {kind; encoding = {encoding = Bytes (`Variable, _); _}} ->
      let size_id = size_id_of_id id in
      let size_attr = Ground.Attr.binary_length_kind ~id:size_id kind in
      (enums, types, [size_attr; Ground.Attr.bytes ~id (Dynamic size_id)])
  | String (`Fixed n, _) -> (enums, types, [Ground.Attr.string ~id (Fixed n)])
  | String (`Variable, _) -> (enums, types, [Ground.Attr.string ~id Variable])
  | Dynamic_size {kind; encoding = {encoding = String (`Variable, _); _}} ->
      let size_id = size_id_of_id id in
      let size_attr = Ground.Attr.binary_length_kind ~id:size_id kind in
      (enums, types, [size_attr; Ground.Attr.string ~id (Dynamic size_id)])
  | Dynamic_size {kind; encoding = {encoding = Check_size {limit; encoding}; _}}
    ->
      let enums, types, attrs =
        seq_field_of_data_encoding enums types encoding id tid_gen
      in
      let size_id = size_id_of_id id in
      let size_attr = Ground.Attr.binary_length_kind ~id:size_id kind in
      let types, attr =
        redirect_if_many
          types
          attrs
          (fun attr ->
            {
              attr with
              size = Some (Ast.Name size_id);
              valid = Some (ValidationMax (Ast.IntNum limit));
            })
          id
      in
      (enums, types, [size_attr; attr])
  | Padded (encoding, pad) ->
      let enums, types, attrs =
        seq_field_of_data_encoding enums types encoding id tid_gen
      in
      let pad_attr =
        let id = id ^ "_padding" in
        let doc =
          {
            Helpers.default_doc_spec with
            summary = Some "This field is for padding, ignore";
          }
        in
        {(Ground.Attr.bytes ~id (Fixed pad)) with doc}
      in
      (enums, types, attrs @ [pad_attr])
  | N ->
      let types = Helpers.add_uniq_assoc types Ground.Type.n_chunk in
      let types = Helpers.add_uniq_assoc types Ground.Type.n in
      (enums, types, [Ground.Attr.n ~id])
  | Z ->
      let types = Helpers.add_uniq_assoc types Ground.Type.n_chunk in
      let types = Helpers.add_uniq_assoc types Ground.Type.z in
      (enums, types, [Ground.Attr.z ~id])
  | Conv {encoding; _} ->
      seq_field_of_data_encoding enums types encoding id tid_gen
  | Tup e ->
      (* This case corresponds to a [tup1] combinator being called inside a
         [tup*] combinator. It's probably never used, but it's still a valid use
         of data-encoding. Note that we erase the information that there is an
         extraneous [tup1] in the encoding. *)
      let id = match tid_gen with None -> id | Some tid_gen -> tid_gen () in
      seq_field_of_data_encoding enums types e id tid_gen
  | Tups {kind = _; left; right} ->
      let tid_gen =
        match tid_gen with
        | None -> Some (Helpers.mk_tid_gen id)
        | Some _ as tid_gen -> tid_gen
      in
      let enums, types, left =
        seq_field_of_data_encoding enums types left id tid_gen
      in
      let enums, types, right =
        seq_field_of_data_encoding enums types right id tid_gen
      in
      let seq = left @ right in
      (enums, types, seq)
  | List {length_limit = At_most _max_length; length_encoding = Some le; elts}
    ->
      let length_id = "number_of_elements_in_" ^ id in
      let enums, types, length_attrs =
        seq_field_of_data_encoding enums types le length_id tid_gen
      in
      (* TODO: Big number length size not yet supported. We expect
               [`Uint30/16/8] to produce only one attribute. *)
      let () = assert (List.length length_attrs = 1) in
      let elt_id = id ^ "_elt" in
      let enums, types, attrs =
        seq_field_of_data_encoding enums types elts elt_id tid_gen
      in
      (* TODO Add max size guard of size: [(size_of_type elts) * limit].
              Two problems:
                           - Guard should be placed on the actual list and not
                             on the list element.
                           - Support [size_of-type], by calling data-encoding
                             max size combinators/helpers? *)
      let types, attr =
        redirect
          types
          attrs
          (fun attr ->
            {
              attr with
              cond =
                {
                  Helpers.cond_no_cond with
                  (* TODO: Fix size refering to list element instead of whole
                           list. *)
                  repeat = RepeatExpr (Ast.Name length_id);
                };
            })
          (id ^ "_entries")
      in
      (enums, types, length_attrs @ [attr])
  | List
      {length_limit = Exactly _ | No_limit; length_encoding = Some _; elts = _}
    ->
      (* The same [assert false] exists in the de/serialisation functions of
         [data_encoding]. This specific case is rejected by data-encoding
         because the length of the list is both known statically and determined
         dynamically by a header which is a waste of space. *)
      assert false
  | List {length_limit; length_encoding = None; elts} ->
      let elt_id = id ^ "_elt" in
      let enums, types, attrs =
        seq_field_of_data_encoding enums types elts elt_id tid_gen
      in
      let types, attr =
        redirect
          types
          attrs
          (fun attr ->
            match length_limit with
            | No_limit ->
                {
                  attr with
                  cond = {Helpers.cond_no_cond with repeat = RepeatEos};
                }
            | At_most _max_length ->
                {
                  attr with
                  (* TODO: Add guard of size: [(size_of_type elts) * limit]. *)
                  cond = {Helpers.cond_no_cond with repeat = RepeatEos};
                }
            | Exactly exact_length ->
                (* TODO/Question: This is [Dynamic_size(Check_size...)] case
                                  when we have max length for elements of fixed
                                  size?

                                  What about when we have variable size list
                                  with fixed size elements only? We will have to
                                  propagate guard to a parent type? *)
                {
                  attr with
                  cond =
                    {
                      Helpers.cond_no_cond with
                      repeat = RepeatExpr (Ast.IntNum exact_length);
                    };
                })
          (id ^ "_entries")
      in
      (enums, types, [attr])
  | Obj f -> seq_field_of_field enums types f
  | Objs {kind = _; left; right} ->
      let enums, types, left =
        seq_field_of_data_encoding enums types left id None
      in
      let enums, types, right =
        seq_field_of_data_encoding enums types right id None
      in
      let seq = left @ right in
      (enums, types, seq)
  | Dynamic_size {kind; encoding} ->
      let size_id = size_id_of_id id in
      let size_attr = Ground.Attr.binary_length_kind ~id:size_id kind in
      let enums, types, attrs =
        seq_field_of_data_encoding enums types encoding id tid_gen
      in
      let types, attr =
        redirect_if_many
          types
          attrs
          (fun attr -> {attr with size = Some (Ast.Name size_id)})
          id
      in
      (enums, types, [size_attr; attr])
  | Splitted {encoding; json_encoding = _; is_obj = _; is_tup = _} ->
      seq_field_of_data_encoding enums types encoding id tid_gen
  | Describe {encoding; id; description; title} ->
      let id = escape_id id in
      let summary = summary ~title ~description in
      let enums, types, attrs =
        seq_field_of_data_encoding enums types encoding id tid_gen
      in
      let types, attr =
        redirect_if_many
          types
          attrs
          (fun attr -> Helpers.merge_summaries attr summary)
          id
      in
      (enums, types, [attr])
  | Check_size {limit = _; encoding} ->
      (* TODO: Add a guard. *)
      seq_field_of_data_encoding enums types encoding id tid_gen
  | _ -> failwith "Not implemented"

and seq_field_of_field :
    type a.
    Ground.Enum.assoc ->
    Ground.Type.assoc ->
    a DataEncoding.field ->
    Ground.Enum.assoc * Ground.Type.assoc * AttrSpec.t list =
 fun enums types f ->
  match f with
  | Req {name; encoding; title; description} ->
      let id = escape_id name in
      let enums, types, attrs =
        seq_field_of_data_encoding enums types encoding id None
      in
      let summary = summary ~title ~description in
      let types, attr =
        redirect_if_many
          types
          attrs
          (fun attr -> Helpers.merge_summaries attr summary)
          id
      in
      (enums, types, [attr])
  | Opt {name; kind = _; encoding; title; description} ->
      let cond_id = escape_id (name ^ "_tag") in
      let enums = Helpers.add_uniq_assoc enums Ground.Enum.bool in
      let cond_attr = Ground.Attr.bool ~id:cond_id in
      let cond =
        {
          Helpers.cond_no_cond with
          ifExpr =
            Some
              Ast.(
                Compare
                  {
                    left = Name cond_id;
                    ops = Eq;
                    right =
                      EnumByLabel
                        {
                          enumName = fst Ground.Enum.bool;
                          label = Ground.Enum.bool_true_name;
                          inType =
                            {
                              absolute = true;
                              names = [fst Ground.Enum.bool];
                              isArray = false;
                            };
                        };
                  });
        }
      in
      let id = escape_id name in
      let enums, types, attrs =
        seq_field_of_data_encoding enums types encoding id None
      in
      let summary = summary ~title ~description in
      let types, attr =
        redirect_if_many
          types
          attrs
          (fun attr -> {(Helpers.merge_summaries attr summary) with cond})
          id
      in
      (enums, types, [cond_attr; attr])
  | Dft {name; encoding; default = _; title; description} ->
      (* NOTE: in binary format Dft is the same as Req *)
      let id = escape_id name in
      let enums, types, attrs =
        seq_field_of_data_encoding enums types encoding id None
      in
      let summary = summary ~title ~description in
      let types, attr =
        redirect_if_many
          types
          attrs
          (fun attr -> Helpers.merge_summaries attr summary)
          id
      in
      (enums, types, [attr])

let from_data_encoding :
    type a. id:string -> ?description:string -> a DataEncoding.t -> ClassSpec.t
    =
 fun ~id ?description encoding ->
  let encoding_name = escape_id id in
  match encoding.encoding with
  | Describe {encoding; description; id; _} ->
      let enums, types, attrs =
        seq_field_of_data_encoding [] [] encoding id None
      in
      Helpers.class_spec_of_attrs
        ~top_level:true
        ~id:encoding_name
        ?description
        ~enums
        ~types
        ~instances:[]
        attrs
  | _ ->
      let enums, types, attrs =
        seq_field_of_data_encoding [] [] encoding encoding_name None
      in
      Helpers.class_spec_of_attrs
        ~top_level:true
        ~id:encoding_name
        ?description
        ~enums
        ~types
        ~instances:[]
        attrs
