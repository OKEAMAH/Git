(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

open Kaitai.Types

module Enum = struct
  type assoc = (string * Kaitai.Types.EnumSpec.t) list

  let bool_false_name = "false"

  let bool_true_name = "true"

  let bool =
    ( "bool",
      EnumSpec.
        {
          path = [];
          map =
            [
              ( 0,
                EnumValueSpec.
                  {name = bool_false_name; doc = Helpers.default_doc_spec} );
              ( 255,
                EnumValueSpec.
                  {name = bool_true_name; doc = Helpers.default_doc_spec} );
            ];
        } )
end

(* Defining a few types now to break circular dependencies. *)

let n_chunk_type =
  {
    (* TODO/nice to have: Add a docstring, i.e. [?description]
                          to custom defined class spec. *)
    (Helpers.default_class_spec ~encoding_name:"n_chunk" ())
    with
    seq =
      [
        {
          Helpers.default_attr_spec with
          id = "has_more";
          dataType =
            DataType.(
              NumericType
                (Int_type (BitsType {width = 1; bit_endian = BigBitEndidan})));
        };
        {
          Helpers.default_attr_spec with
          id = "payload";
          dataType =
            DataType.(
              NumericType
                (Int_type (BitsType {width = 7; bit_endian = BigBitEndidan})));
        };
      ];
    isTopLevel = false;
  }

let n_seq_attr =
  {
    Helpers.default_attr_spec with
    id = "n";
    dataType = DataType.(ComplexDataType (UserType n_chunk_type));
    cond =
      {
        Helpers.cond_no_cond with
        repeat =
          RepeatUntil
            (UnaryOp
               {
                 op = Not;
                 operand =
                   CastToType
                     {
                       value = Attribute {value = Name "_"; attr = "has_more"};
                       typeName =
                         {absolute = true; names = ["bool"]; isArray = false};
                     };
               });
      };
  }

let n_type =
  {
    (* TODO/nice to have: Add a docstring, i.e. [?description]
                          to custom defined class spec. *)
    (Helpers.default_class_spec ~encoding_name:"n" ())
    with
    seq = [n_seq_attr];
    isTopLevel = false;
  }

let z_type =
  {
    (Helpers.default_class_spec ~encoding_name:"z" ()) with
    seq =
      [
        {
          Helpers.default_attr_spec with
          id = "has_more";
          dataType =
            DataType.(
              NumericType
                (Int_type (BitsType {width = 1; bit_endian = BigBitEndidan})));
        };
        {
          Helpers.default_attr_spec with
          id = "sign";
          dataType =
            DataType.(
              NumericType
                (Int_type (BitsType {width = 1; bit_endian = BigBitEndidan})));
        };
        {
          Helpers.default_attr_spec with
          id = "payload";
          dataType =
            DataType.(
              NumericType
                (Int_type (BitsType {width = 6; bit_endian = BigBitEndidan})));
        };
        {
          Helpers.default_attr_spec with
          AttrSpec.id = "tail";
          dataType = DataType.(ComplexDataType (UserType n_chunk_type));
          cond =
            {
              ifExpr =
                Some
                  (UnaryOp
                     {
                       op = Not;
                       operand =
                         CastToType
                           {
                             value = Name "has_more";
                             typeName =
                               {
                                 absolute = true;
                                 names = ["bool"];
                                 isArray = false;
                               };
                           };
                     });
              repeat =
                RepeatUntil
                  (UnaryOp
                     {
                       op = Not;
                       operand =
                         CastToType
                           {
                             value =
                               Attribute {value = Name "_"; attr = "has_more"};
                             typeName =
                               {
                                 absolute = true;
                                 names = ["bool"];
                                 isArray = false;
                               };
                           };
                     });
            };
        };
      ];
    isTopLevel = false;
  }

module Type = struct
  type assoc = (string * Kaitai.Types.ClassSpec.t) list

  let n_chunk = ("n_chunk", n_chunk_type)

  let n = ("n", n_type)

  let z = ("z", z_type)
end

module Attr = struct
  let bool ~id =
    {
      Helpers.default_attr_spec with
      id;
      dataType = DataType.(NumericType (Int_type (Int1Type {signed = false})));
      enum = Some (fst Enum.bool);
    }

  let int1_type_attr_spec ~id ~signed =
    {
      Helpers.default_attr_spec with
      id;
      dataType = DataType.(NumericType (Int_type (Int1Type {signed})));
    }

  let int_multi_type_atrr_spec ~id ~signed width =
    {
      Helpers.default_attr_spec with
      id;
      dataType =
        DataType.(
          NumericType (Int_type (IntMultiType {signed; width; endian = None})));
    }

  let float_multi_type_attr_spec ~id =
    {
      Helpers.default_attr_spec with
      id;
      dataType =
        DataType.(
          NumericType
            (Float_type
               (FloatMultiType
                  {
                    (* Data-encoding supports only 64-bit floats. *)
                    width = DataType.W8;
                    endian = None;
                  })));
    }

  let uint8 ~id = int1_type_attr_spec ~id ~signed:false

  let int8 ~id = int1_type_attr_spec ~id ~signed:true

  let uint16 ~id = int_multi_type_atrr_spec ~id ~signed:false DataType.W2

  let int16 ~id = int_multi_type_atrr_spec ~id ~signed:true DataType.W2

  let int32 ~id = int_multi_type_atrr_spec ~id ~signed:true DataType.W4

  let int64 ~id = int_multi_type_atrr_spec ~id ~signed:true DataType.W8

  let int31 ~id =
    (* TODO: https://gitlab.com/tezos/tezos/-/issues/6261
             There should be a validation that [Int31] is in the appropriate
             range. *)
    int_multi_type_atrr_spec ~id ~signed:true DataType.W4

  let uint30 ~id =
    (* TODO: https://gitlab.com/tezos/tezos/-/issues/6261
             There should be a validation that [Uint30] is in the appropriate
             range. *)
    int_multi_type_atrr_spec ~id ~signed:true DataType.W4

  let float ~id = float_multi_type_attr_spec ~id

  type byte_size =
    | Fixed of int  (** [size: <int>] *)
    | Dynamic of string  (** [size: <name>] *)
    | Variable  (** [size-eos: true] *)

  let bytes ~id = function
    | Fixed n ->
        {
          Helpers.default_attr_spec with
          id;
          dataType =
            DataType.(
              BytesType
                (BytesLimitType
                   {
                     size = Ast.IntNum n;
                     terminator = None;
                     include_ = false;
                     padRight = None;
                     process = None;
                   }));
          size = Some (Ast.IntNum n);
        }
    | Dynamic size_id ->
        {
          Helpers.default_attr_spec with
          id;
          dataType =
            DataType.(
              BytesType
                (BytesLimitType
                   {
                     size = Ast.Name size_id;
                     terminator = None;
                     include_ = false;
                     padRight = None;
                     process = None;
                   }));
          size = Some (Ast.Name size_id);
        }
    | Variable ->
        {
          Helpers.default_attr_spec with
          id;
          dataType =
            DataType.(
              BytesType
                (BytesEosType
                   {
                     terminator = None;
                     include_ = false;
                     padRight = None;
                     process = None;
                   }));
        }

  let string = bytes

  let n ~id =
    {
      Helpers.default_attr_spec with
      id;
      dataType = DataType.(ComplexDataType (UserType (snd Type.n)));
    }

  let z ~id =
    {
      Helpers.default_attr_spec with
      id;
      dataType = DataType.(ComplexDataType (UserType (snd Type.z)));
    }

  let binary_length_kind ~id kind =
    match kind with
    | `N -> failwith "Not implemented"
    | `Uint30 -> uint30 ~id
    | `Uint16 -> uint16 ~id
    | `Uint8 -> uint8 ~id
end
