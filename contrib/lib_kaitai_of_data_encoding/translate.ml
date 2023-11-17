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
module MuSet = Set.Make (String)

type state = {
  enums : Ground.Enum.assoc;
  types : Ground.Type.assoc;
  mus : MuSet.t;
}

let add_enum state enum =
  {state with enums = Helpers.add_uniq_assoc state.enums enum}

let add_type state typ =
  {state with types = Helpers.add_uniq_assoc state.types typ}

(* We need to access the definition of data-encoding's [descr] type. For this
   reason we alias the private/internal module [Data_encoding__Encoding] (rather
   than the public module [Data_encoding.Encoding]. *)
module DataEncoding = Data_encoding__Encoding

(* We need an existential type for encodings because the type of encodings in
   cases is not related to the type of encodings in unions. *)
type anyEncoding = AnyEncoding : _ DataEncoding.t -> anyEncoding

let summary ~title ~description =
  match (title, description) with
  | None, None -> None
  | None, (Some _ as s) | (Some _ as s), None -> s
  | Some t, Some d -> Some (t ^ ": " ^ d)

(* in kaitai-struct, some fields can be added to single attributes but not to a
   group of them. When we want to attach a field to a group of attributes, we
   need to create an indirection to a named type. [redirect] is a function for
   adding a field to an indirection. *)
let redirect state attrs fattr id =
  let ((_, user_type) as type_) = (id, Helpers.class_spec_of_attrs ~id attrs) in
  let state = add_type state type_ in
  let attr =
    fattr
      {
        (Helpers.default_attr_spec ~id) with
        dataType = Helpers.usertype user_type;
      }
  in
  (state, attr)

(* [redirect_if_many] is like [redirect] but it only does the redirection when
   there are multiple attributes, otherwise it adds the field directly. *)
let redirect_if_many :
    state ->
    AttrSpec.t list ->
    (AttrSpec.t -> AttrSpec.t) ->
    string ->
    state * AttrSpec.t =
 fun state attrs fattr id ->
  match attrs with
  | [] -> failwith "redirect_if_many: empty list not supported"
  | [attr] -> (state, {(fattr attr) with id})
  | _ :: _ :: _ as attrs -> redirect state attrs fattr id

let rec seq_field_of_data_encoding :
    type a. state -> a DataEncoding.t -> string -> state * AttrSpec.t list =
 fun state ({encoding; _} as whole_encoding) id ->
  let id = escape_id id in
  match encoding with
  | Null -> (state, [])
  | Empty -> (state, [])
  | Ignore -> (state, [])
  | Constant _ -> (state, [])
  | Bool ->
      let state = add_enum state Ground.Enum.bool in
      (state, [Ground.Attr.bool ~id])
  | Uint8 -> (state, [Ground.Attr.uint8 ~id])
  | Int8 -> (state, [Ground.Attr.int8 ~id])
  | Uint16 -> (state, [Ground.Attr.uint16 ~id])
  | Int16 -> (state, [Ground.Attr.int16 ~id])
  | Int32 -> (state, [Ground.Attr.int32 ~id])
  | Int64 -> (state, [Ground.Attr.int64 ~id])
  | Int31 -> (state, [Ground.Attr.int31 ~id])
  | RangedInt {minimum; maximum} ->
      let size = Data_encoding__Binary_size.range_to_size ~minimum ~maximum in
      if minimum <= 0 then
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
        | `Uint8 -> (state, [{(Ground.Attr.uint8 ~id) with valid = uvalid}])
        | `Uint16 -> (state, [{(Ground.Attr.uint16 ~id) with valid = uvalid}])
        | `Uint30 -> (state, [{(Ground.Attr.uint30 ~id) with valid = uvalid}])
        | `Int8 -> (state, [{(Ground.Attr.int8 ~id) with valid}])
        | `Int16 -> (state, [{(Ground.Attr.int16 ~id) with valid}])
        | `Int31 -> (state, [{(Ground.Attr.int31 ~id) with valid}])
      else
        (* when [minimum > 0] (as is the case in this branch), data-encoding
           shifts the value of the binary representation so that the minimum is at
           [0]. E.g., the interval [200]–[300] is represented on the wire as the
           interval [0]-[100] and the de/serialisation function is responsible for
           shifting to/from the actual range. *)
        let shift = minimum in
        let shifted_id = id ^ "_shifted_to_zero" in
        let shifted_encoding : a DataEncoding.t =
          {
            encoding =
              RangedInt {minimum = minimum - shift; maximum = maximum - shift};
            json_encoding = None;
          }
        in
        let state, represented_interval_attrs =
          seq_field_of_data_encoding state shifted_encoding shifted_id
        in
        let instance_type : Kaitai.Types.DataType.int_type =
          match size with
          | `Uint8 -> Int1Type {signed = false}
          | `Uint16 -> IntMultiType {signed = false; width = W2; endian = None}
          | `Uint30 -> IntMultiType {signed = false; width = W4; endian = None}
          | `Int8 -> Int1Type {signed = true}
          | `Int16 -> IntMultiType {signed = true; width = W2; endian = None}
          | `Int31 -> IntMultiType {signed = true; width = W4; endian = None}
        in
        let represented_interval_class =
          Helpers.class_spec_of_attrs
            ~id:shifted_id
            ~instances:
              [
                ( "value",
                  {
                    doc =
                      {
                        summary =
                          Some
                            "The interval is represented shifted towards 0 for \
                             compactness, this instance corrects the shift.";
                        refs = [];
                      };
                    descr =
                      ValueInstanceSpec
                        {
                          id = "value";
                          value =
                            BinOp
                              {
                                left = Name shifted_id;
                                op = Add;
                                right = IntNum shift;
                              };
                          ifExpr = None;
                          dataTypeOpt =
                            Some (NumericType (Int_type instance_type));
                        };
                  } );
              ]
            represented_interval_attrs
        in
        let state = add_type state (shifted_id, represented_interval_class) in
        ( state,
          [
            {
              (Helpers.default_attr_spec ~id) with
              dataType = Helpers.usertype represented_interval_class;
            };
          ] )
  | Float -> (state, [Ground.Attr.float ~id])
  | RangedFloat {minimum; maximum} ->
      let valid =
        Some
          (ValidationSpec.ValidationRange
             {min = Ast.FloatNum minimum; max = Ast.FloatNum maximum})
      in
      (state, [{(Ground.Attr.float ~id) with valid}])
  | Bytes (`Fixed n, _) -> (state, [Ground.Attr.bytes ~id (Fixed n)])
  | Bytes (`Variable, _) -> (state, [Ground.Attr.bytes ~id Variable])
  | Dynamic_size {kind; encoding = {encoding = Bytes (`Variable, _); _}} ->
      let size_id = "len_" ^ id in
      let size_attr = Ground.Attr.binary_length_kind ~id:size_id kind in
      (state, [size_attr; Ground.Attr.bytes ~id (Dynamic size_id)])
  | String (`Fixed n, _) -> (state, [Ground.Attr.string ~id (Fixed n)])
  | String (`Variable, _) -> (state, [Ground.Attr.string ~id Variable])
  | Dynamic_size {kind; encoding = {encoding = String (`Variable, _); _}} ->
      let size_id = "len_" ^ id in
      let size_attr = Ground.Attr.binary_length_kind ~id:size_id kind in
      (state, [size_attr; Ground.Attr.string ~id (Dynamic size_id)])
  | N ->
      let state = add_type state Ground.Type.n_chunk in
      let state = add_type state Ground.Type.n in
      (state, [Ground.Attr.n ~id])
  | Z ->
      let state = add_type state Ground.Type.n_chunk in
      let state = add_type state Ground.Type.z in
      (state, [Ground.Attr.z ~id])
  | Conv {encoding; _} -> seq_field_of_data_encoding state encoding id
  | Tup _ ->
      (* single-field tup *)
      let tid_gen =
        let already_called = ref false in
        fun () ->
          if !already_called then
            raise (Invalid_argument "multiple fields inside a single-field tup") ;
          already_called := true ;
          id
      in
      seq_field_of_tups state tid_gen encoding
  | Tups _ ->
      (* multi-field tup *)
      let tid_gen = Helpers.mk_tid_gen id in
      seq_field_of_tups state tid_gen encoding
  | List {length_limit; length_encoding; elts} ->
      seq_field_of_collection state length_limit length_encoding elts id
  | Array {length_limit; length_encoding; elts} ->
      seq_field_of_collection state length_limit length_encoding elts id
  | Obj f -> seq_field_of_field state f
  | Objs {kind = _; left; right} ->
      let state, left = seq_field_of_data_encoding state left id in
      let state, right = seq_field_of_data_encoding state right id in
      let seq = left @ right in
      (state, seq)
  | Union {kind = _; tag_size; tagged_cases = _; match_case = _; cases} ->
      seq_field_of_union state tag_size cases id
  | Dynamic_size {kind; encoding} ->
      let len_id = "len_" ^ id in
      let len_attr =
        match kind with
        | `N -> failwith "Dynamic_size N not implemented"
        | `Uint30 -> Ground.Attr.uint30 ~id:len_id
        | `Uint16 -> Ground.Attr.uint16 ~id:len_id
        | `Uint8 -> Ground.Attr.uint8 ~id:len_id
      in
      let state, attrs = seq_field_of_data_encoding state encoding id in
      let state, attr =
        redirect_if_many
          state
          attrs
          (fun attr -> {attr with size = Some (Ast.Name len_id)})
          id
      in
      (state, [len_attr; attr])
  | Splitted {encoding; json_encoding = _; is_obj = _; is_tup = _} ->
      seq_field_of_data_encoding state encoding id
  | Describe {encoding; id; description; title} -> (
      let id = escape_id id in
      let description = summary ~title ~description in
      let state, attrs = seq_field_of_data_encoding state encoding id in
      match attrs with
      | [] -> failwith "Describe: empty attributes not supported"
      | [attr] -> (state, [Helpers.merge_summaries attr description])
      | _ :: _ :: _ as attrs ->
          let described_class =
            Helpers.class_spec_of_attrs
              ~id
              ?description
              ~enums:[]
              ~types:[]
              ~instances:[]
              attrs
          in
          let state = add_type state (id, described_class) in
          let attr =
            {
              (Helpers.default_attr_spec ~id) with
              dataType = Helpers.usertype described_class;
            }
          in
          (state, [attr]))
  | Check_size {limit = _; encoding} ->
      (* TODO: Add a guard for check size.*)
      seq_field_of_data_encoding state encoding id
  | Delayed mk ->
      (* TODO: once data-encoding is monorepoed: remove delayed and have "cached" *)
      let e = mk () in
      seq_field_of_data_encoding state e id
  | Mu {name; title; description; fix; kind = _} ->
      let summary = summary ~title ~description in
      let name = escape_id name in
      if MuSet.mem name state.mus then
        (* This node was already visited, we just put a pointer. *)
        ( state,
          [
            {
              (Helpers.default_attr_spec ~id) with
              dataType = ComplexDataType (UserType name);
            };
          ] )
      else
        let state = {state with mus = MuSet.add name state.mus} in
        let fixed = fix whole_encoding in
        let state, attrs = seq_field_of_data_encoding state fixed name in
        let state, attr =
          redirect
            state
            attrs
            (fun attr -> Helpers.merge_summaries attr summary)
            name
        in
        (state, [attr])
  | String_enum _ -> failwith "String_enum not implemented"
  | Padded _ -> failwith "Padded not implemented"

and seq_field_of_tups :
    type a.
    state -> Helpers.tid_gen -> a DataEncoding.desc -> state * AttrSpec.t list =
 fun state tid_gen d ->
  match d with
  | Tup {encoding = Tup _ as e; json_encoding = _} ->
      seq_field_of_tups state tid_gen e
  | Tup {encoding = Tups _ as e; json_encoding = _} ->
      seq_field_of_tups state tid_gen e
  | Tup e ->
      let id = tid_gen () in
      let state, attrs = seq_field_of_data_encoding state e id in
      let state, attrs =
        match attrs with
        | [] -> (state, [])
        | [attr] ->
            if attr.id = id then (state, attrs)
            else
              (* [id] was over-ridden by a [Describe] or other construct, we
                 restore it here to guarantee names are unique. *)
              (state, [Helpers.merge_summaries {attr with id} (Some attr.id)])
        | _ :: _ ->
            let state, attr = redirect state attrs Fun.id id in
            (state, [attr])
      in
      (state, attrs)
  | Tups {kind = _; left; right} ->
      let state, left = seq_field_of_tups state tid_gen left.encoding in
      let state, right = seq_field_of_tups state tid_gen right.encoding in
      let seq = left @ right in
      (state, seq)
  | _ -> failwith "Non-tup(s) inside a tups"

and seq_field_of_field :
    type a. state -> a DataEncoding.field -> state * AttrSpec.t list =
 fun state f ->
  match f with
  | Req {name; encoding; title; description} ->
      let id = escape_id name in
      let state, attrs = seq_field_of_data_encoding state encoding id in
      let summary = summary ~title ~description in
      let state, attr =
        redirect_if_many
          state
          attrs
          (fun attr -> Helpers.merge_summaries attr summary)
          id
      in
      (state, [attr])
  | Opt {name; kind = _; encoding; title; description} ->
      let cond_id = escape_id (name ^ "_tag") in
      let state = add_enum state Ground.Enum.bool in
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
                          inType = Ast.empty_typeId;
                        };
                  });
        }
      in
      let id = escape_id name in
      let state, attrs = seq_field_of_data_encoding state encoding id in
      let summary = summary ~title ~description in
      let state, attr =
        redirect_if_many
          state
          attrs
          (fun attr -> {(Helpers.merge_summaries attr summary) with cond})
          id
      in
      (state, [cond_attr; attr])
  | Dft {name; encoding; default = _; title; description} ->
      (* NOTE: in binary format Dft is the same as Req *)
      let id = escape_id name in
      let state, attrs = seq_field_of_data_encoding state encoding id in
      let summary = summary ~title ~description in
      let state, attr =
        redirect_if_many
          state
          attrs
          (fun attr -> Helpers.merge_summaries attr summary)
          id
      in
      (state, [attr])

and seq_field_of_union :
    type a.
    state ->
    Data_encoding__Binary_size.tag_size ->
    a DataEncoding.case list ->
    string ->
    state * AttrSpec.t list =
 fun state tag_size cases id ->
  let tagged_cases : (int * string * string option * anyEncoding) list =
    (* Some cases are JSON-only, we filter those out and we also get rid of
       parts we don't care about like injection and projection functions. *)
    List.filter_map
      (fun (DataEncoding.Case
             {title; tag; description; encoding; proj = _; inj = _}) ->
        Data_encoding__Uint_option.fold
          ~none:None
          ~some:(fun tag ->
            Some (tag, escape_id title, description, AnyEncoding encoding))
          tag)
      cases
  in
  let id = escape_id id in
  let tag_type : Kaitai.Types.DataType.int_type =
    match tag_size with
    | `Uint8 -> Int1Type {signed = false}
    | `Uint16 -> IntMultiType {signed = false; width = W2; endian = None}
  in
  let tag_id = id ^ "_tag" in
  let tag_enum_map =
    List.map
      (fun (tag, id, description, _) ->
        ( tag,
          EnumValueSpec.
            {name = id; doc = DocSpec.{refs = []; summary = description}} ))
      tagged_cases
  in
  let tag_enum = EnumSpec.{map = tag_enum_map} in
  let state = add_enum state (tag_id, tag_enum) in
  let tag_attr =
    {
      (Helpers.default_attr_spec ~id:tag_id) with
      dataType = DataType.(NumericType (Int_type tag_type));
      enum = Some tag_id;
    }
  in
  let state, payload_attrs =
    List.fold_left
      (fun (state, payload_attrs) (_, case_id, _, AnyEncoding encoding) ->
        let state, attrs = seq_field_of_data_encoding state encoding case_id in
        match attrs with
        | [] -> (state, payload_attrs)
        | _ :: _ as attrs ->
            let state, attr =
              redirect_if_many
                state
                attrs
                (fun attr ->
                  {
                    attr with
                    cond =
                      {
                        Helpers.cond_no_cond with
                        ifExpr =
                          Some
                            (Compare
                               {
                                 left = Name tag_id;
                                 ops = Eq;
                                 right =
                                   EnumByLabel
                                     {
                                       enumName = tag_id;
                                       label = case_id;
                                       inType = Ast.empty_typeId;
                                     };
                               });
                      };
                  })
                (id ^ "_" ^ case_id)
            in
            (state, attr :: payload_attrs))
      (state, [])
      tagged_cases
  in
  let payload_attrs = List.rev payload_attrs in
  (state, tag_attr :: payload_attrs)

and seq_field_of_collection :
    type a.
    state ->
    DataEncoding.limit ->
    int DataEncoding.encoding option ->
    a DataEncoding.encoding ->
    string ->
    state * AttrSpec.t list =
 fun state length_limit length_encoding elts id ->
  match (length_limit, length_encoding, elts) with
  | At_most _max_length, Some le, elts ->
      let length_id = "number_of_elements_in_" ^ id in
      let state, length_attrs = seq_field_of_data_encoding state le length_id in
      let length_attr =
        match length_attrs with
        | [] -> assert false
        | [attr] ->
            (* TODO: use [length_limit] to set a [valid:max:] value for length*)
            attr
        | _ :: _ :: _ ->
            (* TODO: Big number length size not yet supported. We expect
                     [`Uint30/16/8] to produce only one attribute. *)
            failwith "Not supported (N-like header)"
      in
      let elt_id = id ^ "_elt" in
      let state, attrs = seq_field_of_data_encoding state elts elt_id in
      let state, attr =
        (* We do uncoditional redirect because there can be issues where the
           [size] of elements and the [size] of the list get mixed up.
           TODO: redirect on (a) multiple attrs and (b) single attr with [size] *)
        redirect
          state
          attrs
          (fun attr ->
            {
              attr with
              cond =
                {
                  Helpers.cond_no_cond with
                  repeat = RepeatExpr (Ast.Name length_id);
                };
            })
          (id ^ "_entries")
      in
      (state, [length_attr; attr])
  | (Exactly _ | No_limit), Some _, _ ->
      (* The same [assert false] exists in the de/serialisation functions of
         [data_encoding]. This specific case is rejected by data-encoding
         because the length of the list is both known statically and determined
         dynamically by a header which is a waste of space. *)
      assert false
  | length_limit, None, elts ->
      let elt_id = id ^ "_elt" in
      let state, attrs = seq_field_of_data_encoding state elts elt_id in
      let state, attr =
        redirect
          state
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
                  (* TODO: Add guard of length *)
                  cond = {Helpers.cond_no_cond with repeat = RepeatEos};
                }
            | Exactly exact_length ->
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
      (state, [attr])

let from_data_encoding :
    type a. id:string -> ?description:string -> a DataEncoding.t -> ClassSpec.t
    =
 fun ~id ?description encoding ->
  let encoding_name = escape_id id in
  let state = {types = []; enums = []; mus = MuSet.empty} in
  match encoding.encoding with
  | Describe {encoding; description; id; _} ->
      let state, attrs = seq_field_of_data_encoding state encoding id in
      Helpers.class_spec_of_attrs
        ~id:encoding_name
        ?description
        ~enums:state.enums
        ~types:state.types
        ~instances:[]
        attrs
  | _ ->
      let state, attrs =
        seq_field_of_data_encoding state encoding encoding_name
      in
      Helpers.class_spec_of_attrs
        ~id:encoding_name
        ?description
        ~enums:state.enums
        ~types:state.types
        ~instances:[]
        attrs
