(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

module MuSet = Map.Make (String)
module StringSet = Set.Make (String)

(* We need to access the definition of data-encoding's [descr] type. For this
   reason we alias the private/internal module [Data_encoding__Encoding] (rather
   than the public module [Data_encoding.Encoding]. *)
module DataEncoding = Data_encoding__Encoding

(* We need an existential type for encodings because the type of encodings in
   cases is not related to the type of encodings in unions. *)
type anyEncoding = AnyEncoding : _ DataEncoding.t -> anyEncoding [@@unboxed]

type state = {
  enums : Ground.Enum.assoc;
  types : Ground.Type.assoc;
  mus : string list MuSet.t;
  imports : StringSet.t;
  extern : (anyEncoding, string) Hashtbl.t;
}

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

let add_type state typ =
  {state with types = Helpers.add_uniq_assoc state.types typ}

let add_enum state enum =
  {state with enums = Helpers.add_uniq_assoc state.enums enum}

let pathify path id = String.concat "__" (List.rev (id :: path))

let summary ~title ~description =
  match (title, description) with
  | None, None -> None
  | None, (Some _ as s) | (Some _ as s), None -> s
  | Some t, Some d -> Some (t ^ ": " ^ d)

(* when an encoding has id [x],
   then the attr for its size has id [size_id_of_id x].
   Kaitia recomment to use the [len_] prefix in this case. *)
let size_id_of_id id = "len_" ^ id

(* in kaitai-struct, some fields can be added to single attributes but not to a
   group of them. When we want to attach a field to a group of attributes, we
   need to create an indirection to a named type. [redirect] is a function for
   adding a field to an indirection. *)
let redirect state attrs fattr path id =
  let id = pathify path id in
  let ((_, user_type_classpec) as type_) =
    (id, Helpers.class_spec_of_attrs ~id attrs)
  in
  let state = add_type state type_ in
  let attr =
    fattr
      {
        (Helpers.default_attr_spec ~id) with
        dataType = Helpers.usertype user_type_classpec;
      }
  in
  (state, attr)

let redirect_if_any :
    state ->
    AttrSpec.t list ->
    (AttrSpec.t -> AttrSpec.t) ->
    string list ->
    string ->
    state * AttrSpec.t option =
 fun state attrs fattr path id ->
  match attrs with
  | [] -> (state, None)
  | [attr] -> (state, Some {(fattr attr) with id})
  | _ :: _ :: _ as attrs ->
      let state, attr = redirect state attrs fattr path id in
      (state, Some attr)

(* [redirect_if_many] is like [redirect] but it only does the redirection when
   there are multiple attributes, otherwise it adds the field directly. *)
let redirect_if_many :
    ?or_if:(AttrSpec.t -> bool) ->
    state ->
    AttrSpec.t list ->
    (AttrSpec.t -> AttrSpec.t) ->
    string list ->
    string ->
    state * AttrSpec.t =
 fun ?(or_if = fun _ -> false) state attrs fattr path id ->
  let redirected_id = id ^ "_" in
  match attrs with
  | [] -> failwith "Not supported (empty redirect)"
  | [attr] when or_if attr -> redirect state attrs fattr path redirected_id
  | [attr] -> (state, {(fattr attr) with id})
  | _ :: _ :: _ as attrs -> redirect state attrs fattr path redirected_id

let rec seq_field_of_data_encoding :
    type a.
    state ->
    a DataEncoding.t ->
    string list ->
    string ->
    state * AttrSpec.t list =
 fun state ({encoding; _} as whole_encoding) path id ->
  (* We rely on [AnyEncoding] to be unboxed so that we can preserve physical equality *)
  match Hashtbl.find_opt state.extern (AnyEncoding whole_encoding) with
  | Some name ->
      let name = escape_id name in
      let state = {state with imports = StringSet.add name state.imports} in
      ( state,
        [
          {
            (Helpers.default_attr_spec ~id:(escape_id id)) with
            dataType = DataType.(ComplexDataType (UserType name));
          };
        ] )
  | None -> (
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
      | Int31 ->
          let state = add_type state Ground.Type.int31 in
          (state, [Ground.Attr.int31 ~id])
      | RangedInt {minimum; maximum} ->
          let size =
            Data_encoding__Binary_size.range_to_size ~minimum ~maximum
          in
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
            | `Uint16 ->
                (state, [{(Ground.Attr.uint16 ~id) with valid = uvalid}])
            | `Uint30 ->
                (state, [{(Ground.Attr.uint30 ~id) with valid = uvalid}])
            | `Int8 -> (state, [{(Ground.Attr.int8 ~id) with valid}])
            | `Int16 -> (state, [{(Ground.Attr.int16 ~id) with valid}])
            | `Int31 ->
                let state = add_type state Ground.Type.int31 in
                (state, [{(Ground.Attr.int31 ~id) with valid}])
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
                  RangedInt
                    {minimum = minimum - shift; maximum = maximum - shift};
                json_encoding = None;
              }
            in
            let state, represented_interval_attrs =
              seq_field_of_data_encoding state shifted_encoding path shifted_id
            in
            let instance_type : Kaitai.Types.DataType.int_type =
              match size with
              | `Uint8 -> Int1Type {signed = false}
              | `Uint16 ->
                  IntMultiType {signed = false; width = W2; endian = None}
              | `Uint30 ->
                  IntMultiType {signed = false; width = W4; endian = None}
              | `Int8 -> Int1Type {signed = true}
              | `Int16 ->
                  IntMultiType {signed = true; width = W2; endian = None}
              | `Int31 ->
                  IntMultiType {signed = true; width = W4; endian = None}
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
                                "The interval is represented shifted towards 0 \
                                 for compactness, this instance corrects the \
                                 shift.";
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
                                (* FIXME: This is disabled as it break roundtripping.
                                   It seems it's not used in the ksy file *)
                                (if true then None
                                else Some (NumericType (Int_type instance_type)));
                            };
                      } );
                  ]
                represented_interval_attrs
            in
            let state =
              add_type state (shifted_id, represented_interval_class)
            in
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
      | Dynamic_size
          {kind = `Uint8; encoding = {encoding = Bytes (`Variable, _); _}} ->
          let state = add_type state Ground.Type.bytes_dyn_uint8 in
          (state, [Ground.Attr.bytes ~id Dynamic8])
      | Dynamic_size
          {kind = `Uint16; encoding = {encoding = Bytes (`Variable, _); _}} ->
          let state = add_type state Ground.Type.bytes_dyn_uint16 in
          (state, [Ground.Attr.bytes ~id Dynamic16])
      | Dynamic_size
          {kind = `Uint30; encoding = {encoding = Bytes (`Variable, _); _}} ->
          let state = add_type state Ground.Type.uint30 in
          let state = add_type state Ground.Type.bytes_dyn_uint30 in
          (state, [Ground.Attr.bytes ~id Dynamic30])
      | String (`Fixed n, _) -> (state, [Ground.Attr.string ~id (Fixed n)])
      | String (`Variable, _) -> (state, [Ground.Attr.string ~id Variable])
      | Dynamic_size
          {kind = `Uint8; encoding = {encoding = String (`Variable, _); _}} ->
          let state = add_type state Ground.Type.bytes_dyn_uint8 in
          (state, [Ground.Attr.bytes ~id Dynamic8])
      | Dynamic_size
          {kind = `Uint16; encoding = {encoding = String (`Variable, _); _}} ->
          let state = add_type state Ground.Type.bytes_dyn_uint16 in
          (state, [Ground.Attr.bytes ~id Dynamic16])
      | Dynamic_size
          {kind = `Uint30; encoding = {encoding = String (`Variable, _); _}} ->
          let state = add_type state Ground.Type.uint30 in
          let state = add_type state Ground.Type.bytes_dyn_uint30 in
          (state, [Ground.Attr.bytes ~id Dynamic30])
      | Dynamic_size
          {kind; encoding = {encoding = Check_size {limit; encoding}; _}} ->
          let size_id = size_id_of_id (pathify path id ^ "_dyn") in
          let size_attr =
            Helpers.merge_valid
              (Ground.Attr.binary_length_kind ~id:size_id kind)
              (ValidationMax (Ast.IntNum limit))
          in
          let state, attrs =
            seq_field_of_data_encoding state encoding path id
          in
          let state, attr =
            redirect
              state
              attrs
              (fun attr ->
                {attr with size = Some (Ast.Name size_id)})
              path
              (id ^ "_dyn")
          in
          (state, [size_attr; attr])
      | Padded (encoding, pad) ->
          let state, attrs =
            seq_field_of_data_encoding state encoding path id
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
          (state, attrs @ [pad_attr])
      | N ->
          let state = add_type state Ground.Type.n_chunk in
          let state = add_type state Ground.Type.n in
          (state, [Ground.Attr.n ~id])
      | Z ->
          let state = add_type state Ground.Type.n_chunk in
          let state = add_type state Ground.Type.z in
          (state, [Ground.Attr.z ~id])
      | Conv {encoding; _} -> seq_field_of_data_encoding state encoding path id
      | Tup _ ->
          (* single-field tup *)
          let tid_gen =
            let already_called = ref false in
            fun () ->
              if !already_called then
                raise
                  (Invalid_argument "multiple fields inside a single-field tup") ;
              already_called := true ;
              id
          in
          seq_field_of_tups state path tid_gen encoding
      | Tups _ ->
          (* multi-field tup *)
          let tid_gen = Helpers.mk_tid_gen id in
          seq_field_of_tups state path tid_gen encoding
      | List {length_limit; length_encoding; elts} ->
          seq_field_of_collection
            state
            length_limit
            length_encoding
            elts
            path
            id
      | Array {length_limit; length_encoding; elts} ->
          seq_field_of_collection
            state
            length_limit
            length_encoding
            elts
            path
            id
      | Obj f -> seq_field_of_field state path f
      | Objs {kind = _; left; right} ->
          let state, left = seq_field_of_data_encoding state left path id in
          let state, right = seq_field_of_data_encoding state right path id in
          let seq = left @ right in
          (state, seq)
      | Union {kind = _; tag_size; tagged_cases = _; match_case = _; cases} ->
          seq_field_of_union state tag_size cases path id
      | Dynamic_size {kind; encoding} ->
          let dyn_id =
            (* Avoid duplicated id when translating mempool *)
            if List.mem_assoc (id ^ "_dyn") state.types then id ^ "_outer"
            else id
          in
          let size_id = size_id_of_id (pathify path dyn_id ^ "_dyn") in
          let size_attr = Ground.Attr.binary_length_kind ~id:size_id kind in
          let state, attrs =
            seq_field_of_data_encoding state encoding path id
          in
          let state, attr =
            redirect
              state
              attrs
              (fun attr -> {attr with size = Some (Ast.Name size_id)})
              path
              (id ^ "_dyn")
          in
          (state, [size_attr; attr])
      | Splitted {encoding; json_encoding = _; is_obj = _; is_tup = _} ->
          seq_field_of_data_encoding state encoding path id
      | Describe {encoding; id; description; title} ->
          let id = escape_id id in
          let summary = summary ~title ~description in
          let state, attrs =
            seq_field_of_data_encoding state encoding path id
          in
          let state, attr =
            redirect_if_many
              state
              attrs
              (fun attr -> Helpers.merge_summaries attr summary)
              path
              id
          in
          (state, [attr])
      | Check_size {limit = _; encoding} ->
          (* TODO: Add a guard for check size.*)
          seq_field_of_data_encoding state encoding path id
      | Delayed mk ->
          (* TODO: once data-encoding is monorepoed: remove delayed and have "cached" *)
          let e = mk () in
          seq_field_of_data_encoding state e path id
      | Mu {name; title; description; fix; kind = _} -> (
          let summary = summary ~title ~description in
          let name = escape_id name in
          match MuSet.find_opt name state.mus with
          | Some path ->
              (* This node was already visited, we just put a pointer. *)
              ( state,
                [
                  {
                    (Helpers.default_attr_spec ~id) with
                    dataType =
                      (* We don't have the full type, we just put a dummy with the correct
                         [id] which is all that gets printed *)
                      ComplexDataType (UserType (pathify path name));
                  };
                ] )
          | None ->
              let state = {state with mus = MuSet.add name path state.mus} in
              let fixed = fix whole_encoding in
              let state, attrs =
                seq_field_of_data_encoding state fixed path name
              in
              let state, attr =
                redirect
                  state
                  attrs
                  (fun attr -> Helpers.merge_summaries attr summary)
                  path
                  name
              in
              (state, [attr]))
      | String_enum (h, a) ->
          let id = pathify path id in
          let names =
            let t = Hashtbl.create 17 in
            Hashtbl.iter
              (fun _ (name, _i) ->
                let name' = escape_id name in
                if String.equal name' name then Hashtbl.add t name' ())
              h ;
            t
          in
          let map =
            Hashtbl.to_seq_values h
            |> Seq.map (fun (m, i) ->
                   let name = escape_id m in
                   let name =
                     if String.equal name m || not (Hashtbl.mem names name) then (
                       Hashtbl.add names name () ;
                       name)
                     else
                       let rec find name =
                         let name' = name ^ "_" in
                         if Hashtbl.mem names name' then find name' else name'
                       in
                       let name' = find name in
                       Hashtbl.add names name' () ;
                       name'
                   in
                   ( i,
                     EnumValueSpec.
                       {
                         name;
                         doc =
                           DocSpec.
                             {
                               refs = [];
                               summary =
                                 (if String.equal m name then None else Some m);
                             };
                       } ))
            |> List.of_seq
            |> List.sort (fun (t1, _) (t2, _) -> compare t1 t2)
          in
          let enumspec = EnumSpec.{map} in
          let state = add_enum state (id, enumspec) in
          let dataType =
            DataType.NumericType
              (Int_type
                 (match Data_encoding__Binary_size.enum_size a with
                 | `Uint8 -> Int1Type {signed = false}
                 | `Uint16 ->
                     IntMultiType {signed = false; width = W2; endian = None}
                 | `Uint30 ->
                     IntMultiType {signed = false; width = W4; endian = None}))
          in
          let attr =
            {(Helpers.default_attr_spec ~id) with dataType; enum = Some id}
          in
          (state, [attr]))

and seq_field_of_tups :
    type a.
    state ->
    string list ->
    Helpers.tid_gen ->
    a DataEncoding.desc ->
    state * AttrSpec.t list =
 fun state path tid_gen d ->
  (* TODO? add indices in the path? *)
  match d with
  | Tup {encoding = Tup _ as e; json_encoding = _} ->
      seq_field_of_tups state path tid_gen e
  | Tup {encoding = Tups _ as e; json_encoding = _} ->
      seq_field_of_tups state path tid_gen e
  | Tup e ->
      let id = tid_gen () in
      let state, attrs = seq_field_of_data_encoding state e path id in
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
            let state, attr = redirect state attrs Fun.id path id in
            (state, [attr])
      in
      (state, attrs)
  | Tups {kind = _; left; right} ->
      let state, left = seq_field_of_tups state path tid_gen left.encoding in
      let state, right = seq_field_of_tups state path tid_gen right.encoding in
      let seq = left @ right in
      (state, seq)
  | _ -> failwith "Non-tup(s) inside a tups"

and seq_field_of_field :
    type a.
    state -> string list -> a DataEncoding.field -> state * AttrSpec.t list =
 fun state path f ->
  match f with
  | Req {name; encoding; title; description} ->
      let id = escape_id name in
      let state, attrs = seq_field_of_data_encoding state encoding path id in
      let summary = summary ~title ~description in
      let state, attr_o =
        redirect_if_any
          state
          attrs
          (fun attr -> Helpers.merge_summaries attr summary)
          path
          id
      in
      (state, Option.to_list attr_o)
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
                          inType = empty_typeId;
                        };
                  });
        }
      in
      let id = escape_id name in
      let state, attrs = seq_field_of_data_encoding state encoding path id in
      let summary = summary ~title ~description in
      let state, attr =
        redirect_if_many
          state
          attrs
          (fun attr -> {(Helpers.merge_summaries attr summary) with cond})
          path
          id
      in
      (state, [cond_attr; attr])
  | Dft {name; encoding; default = _; title; description} ->
      (* NOTE: in binary format Dft is the same as Req *)
      let id = escape_id name in
      let state, attrs = seq_field_of_data_encoding state encoding path id in
      let summary = summary ~title ~description in
      let state, attr_o =
        redirect_if_any
          state
          attrs
          (fun attr -> Helpers.merge_summaries attr summary)
          path
          id
      in
      (state, Option.to_list attr_o)

and seq_field_of_union :
    type a.
    state ->
    Data_encoding__Binary_size.tag_size ->
    a DataEncoding.case list ->
    string list ->
    string ->
    state * AttrSpec.t list =
 fun state tag_size cases path id ->
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
    |> List.sort (fun (t1, _) (t2, _) -> compare t1 t2)
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
        let path = case_id :: path in
        let state, attrs =
          seq_field_of_data_encoding state encoding path case_id
        in
        match attrs with
        | [] -> (state, payload_attrs)
        | [attr] ->
            ( state,
              {
                attr with
                id = pathify path id;
                cond =
                  {
                    Helpers.cond_no_cond with
                    ifExpr =
                      Some
                        (Compare
                           {
                             left = Name (id ^ "_tag");
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
              }
              :: payload_attrs )
        | _ :: _ as attrs ->
            let state, attr =
              redirect
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
                path
                id
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
    string list ->
    string ->
    state * AttrSpec.t list =
 fun state length_limit length_encoding elts path id ->
  match (length_limit, length_encoding, elts) with
  | At_most max_length, Some le, elts ->
      (* Kaitai recommend to use the [num_] prefix *)
      let length_id = "num_" ^ id in
      let state, length_attrs =
        seq_field_of_data_encoding state le path length_id
      in
      let length_attr =
        match length_attrs with
        | [] -> assert false
        | [attr] ->
            Helpers.merge_valid
              attr
              (ValidationSpec.ValidationMax (Ast.IntNum max_length))
        | _ :: _ :: _ ->
            (* TODO: Big number length size not yet supported. We expect
                     [`Uint30/16/8] to produce only one attribute. *)
            failwith "Not supported (N-like header)"
      in
      let elt_id = id ^ "_elt" in
      let state, attrs = seq_field_of_data_encoding state elts path elt_id in
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
          path
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
      let state, attrs = seq_field_of_data_encoding state elts path elt_id in
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
          path
          (id ^ "_entries")
      in
      (state, [attr])

let add_original_id_to_description ?description id =
  match description with
  | None -> "Encoding id: " ^ id
  | Some description -> "Encoding id: " ^ id ^ "\nDescription: " ^ description

let from_data_encoding :
    type a. id:string -> ?extern:_ -> a DataEncoding.t -> ClassSpec.t =
 fun ~id ?(extern = Hashtbl.create 0) encoding ->
  let encoding_name = escape_id id in
  let state =
    {
      enums = [];
      types = [];
      mus = MuSet.empty;
      imports = StringSet.empty;
      extern;
    }
  in
  match encoding.encoding with
  | Describe {encoding; description; id = descrid; _} ->
      let description = add_original_id_to_description ?description id in
      let state, attrs = seq_field_of_data_encoding state encoding [] descrid in
      Helpers.class_spec_of_attrs
        ~id:encoding_name
        ~description
        ~enums:state.enums
        ~types:state.types
        ~imports:(StringSet.elements state.imports)
        ~instances:[]
        attrs
  | _ ->
      let description = add_original_id_to_description id in
      let state, attrs =
        seq_field_of_data_encoding state encoding [] encoding_name
      in
      Helpers.class_spec_of_attrs
        ~id:encoding_name
        ~description
        ~enums:state.enums
        ~types:state.types
        ~imports:(StringSet.elements state.imports)
        ~instances:[]
        attrs
