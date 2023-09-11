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

let default_doc_spec = DocSpec.{summary = None; refs = []}

let cond_no_cond =
  AttrSpec.ConditionalSpec.{ifExpr = None; repeat = RepeatSpec.NoRepeat}

let default_attr_spec =
  AttrSpec.
    {
      path = [];
      id = "";
      dataType = DataType.AnyType;
      cond = cond_no_cond;
      valid = None;
      doc = default_doc_spec;
      enum = None;
    }

module Enum = struct
  type map = (string * Kaitai.Types.EnumSpec.t) list

  let add enums ((k, e) as enum) =
    let rec add = function
      | [] -> enum :: enums
      | ee :: _ when enum = ee ->
          (* [enum] is already present in [enums] *)
          enums
      | (kk, ee) :: _ when String.equal kk k && not (ee = e) ->
          (* [enum] key is already present in [enums], but for a different
             [enum]. *)
          raise (Invalid_argument "Enum.add: duplicate keys")
      | _ :: enums -> add enums
    in
    add enums

  let bool =
    ( "bool",
      EnumSpec.
        {
          path = [];
          map =
            [
              (0, EnumValueSpec.{name = "false"; doc = default_doc_spec});
              (255, EnumValueSpec.{name = "true"; doc = default_doc_spec});
            ];
        } )
end

module Attr = struct
  let bool =
    {
      default_attr_spec with
      id = "bool";
      dataType = DataType.(NumericType (Int_type (Int1Type {signed = false})));
      valid = Some (ValidationAnyOf [IntNum 0; IntNum 255]);
      enum = Some (fst Enum.bool);
    }

  let int1_type_attr_spec ~signed =
    {
      default_attr_spec with
      id = (if signed then "int8" else "uint8");
      dataType = DataType.(NumericType (Int_type (Int1Type {signed})));
    }

  let int_multi_type_atrr_spec ~id ~signed width =
    {
      default_attr_spec with
      id;
      dataType =
        DataType.(
          NumericType (Int_type (IntMultiType {signed; width; endian = None})));
    }

  let float_multi_type_attr_spec ~id =
    {
      default_attr_spec with
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

  let bytes_limit_type_attr_spec ~id =
    {
      default_attr_spec with
      id;
      dataType =
        DataType.(
          BytesType
            (BytesLimitType
               {
                 size = Name "size";
                 terminator = None;
                 include_ = false;
                 padRight = None;
                 process = None;
               }));
    }

  let u1 = int1_type_attr_spec ~signed:false

  let s1 = int1_type_attr_spec ~signed:true

  let u2 = int_multi_type_atrr_spec ~id:"uint16" ~signed:false DataType.W2

  let s2 = int_multi_type_atrr_spec ~id:"int16" ~signed:true DataType.W2

  let s4 = int_multi_type_atrr_spec ~id:"int32" ~signed:true DataType.W4

  let s8 = int_multi_type_atrr_spec ~id:"int64" ~signed:true DataType.W8

  let int31 =
    (* TODO: https://gitlab.com/tezos/tezos/-/issues/6261
             There should be a validation that [Int31] is in the appropriate
             range. *)
    int_multi_type_atrr_spec ~id:"int31" ~signed:true DataType.W4

  let f8 = float_multi_type_attr_spec ~id:"float"

  let bytes =
    (* TODO:  https://gitlab.com/tezos/tezos/-/issues/6260
              We fix size header to [`Uint30] for now. This corresponds to
              size header of ground bytes encoding. Later on we want to add
              support for [`Uint16], [`Uint8] and [`N]. *)
    bytes_limit_type_attr_spec ~id:"fixed size (uint30) bytes"

  let string =
    (* TODO:  https://gitlab.com/tezos/tezos/-/issues/6260
              Same as with [Bytes] above, i.e. we need to add support for [`Uint16],
              [`Uint8] and [`N] size header as well. *)
    bytes_limit_type_attr_spec ~id:"fixed size (uint30) bytes"
end
