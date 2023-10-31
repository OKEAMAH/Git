(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)
open Sexplib.Std

module Identifier = struct
  type t = string [@@deriving sexp]
end

module Ast = struct
  type boolop = Or | And [@@deriving sexp]

  type typeId = {absolute : bool; names : string list; isArray : bool}
  [@@deriving sexp]

  let typeId_to_string {absolute; names; isArray} =
    if isArray || not absolute then failwith "not implemented (typeId)" ;
    String.concat "." names

  type operator =
    | Add
    | Sub
    | Mult
    | Div
    | Mod
    | LShift
    | RShift
    | BitOr
    | BitXor
    | BitAnd
  [@@deriving sexp]

  let operator_to_string = function
    | BitAnd -> "&"
    | RShift -> ">>"
    | Add -> "+"
    | _ -> failwith "not implemented (operator)"

  type unaryop = Invert | Not | Minus [@@deriving sexp]

  type cmpop = Eq | NotEq | Lt | LtE | Gt | GtE [@@deriving sexp]

  let cmpop_to_string = function
    | NotEq -> "!="
    | Eq -> "=="
    | _ -> failwith "not implemented (cmpop)"

  type t =
    | Raw of string
    | BoolOp of {op : boolop; values : t list}
    | BinOp of {left : t; op : operator; right : t}
    | UnaryOp of {op : unaryop; operand : t}
    | IfExp of {condition : t; ifTrue : t; ifFalse : t}
    | Compare of {left : t; ops : cmpop; right : t}
    | Call of {func : t; args : t list}
    | IntNum of int
    | FloatNum of float
    | Str of string
    | Bool of bool
    | EnumByLabel of {
        enumName : Identifier.t;
        label : Identifier.t;
        inType : typeId;
      }
    | EnumById of {enumName : Identifier.t; id : t; inType : typeId}
    | Attribute of {value : t; attr : Identifier.t}
    | CastToType of {value : t; typeName : typeId}
    | ByteSizeOfType of {typeName : typeId}
    | BitSizeOfType of {typeName : typeId}
    | Subscript of {value : t; idx : t}
    | Name of Identifier.t
    | List of t list
  [@@deriving sexp]

  type expr = t [@@deriving sexp]

  let rec to_string = function
    | IntNum n -> Int.to_string n
    | FloatNum f -> Float.to_string f
    | Name name -> name
    | UnaryOp {op; operand} -> (
        match op with
        | Not -> "not " ^ to_string operand
        | _ -> failwith "unary operator not supported")
    | BinOp {left; op; right} ->
        Format.sprintf
          "(%s %s %s)"
          (to_string left)
          (operator_to_string op)
          (to_string right)
    | Compare {left; ops; right} ->
        Format.sprintf
          "(%s %s %s)"
          (to_string left)
          (cmpop_to_string ops)
          (to_string right)
    | Attribute {value; attr} -> Format.sprintf "(%s.%s)" (to_string value) attr
    | Subscript {value; idx} ->
        Format.sprintf "%s[%s]" (to_string value) (to_string idx)
    | CastToType {value; typeName} ->
        (* TODO: here and other cases: https://gitlab.com/tezos/tezos/-/issues/6487 *)
        Format.sprintf "%s.as<%s>" (to_string value) (typeId_to_string typeName)
    | EnumByLabel {enumName; label; inType} ->
        (* TODO: don't ignore inType *)
        ignore inType ;
        Format.sprintf "%s::%s" enumName label
    | _ -> failwith "not implemented (ast)"
end

type processExpr =
  | ProcessZlib
  | ProcessXor of {key : Ast.expr}
  | ProcessRotate of {left : int; key : Ast.expr}
  | ProcessCustom
[@@deriving sexp]

module BitEndianness = struct
  type t = LittleBitEndian | BigBitEndian [@@deriving sexp]

  let to_string = function LittleBitEndian -> "le" | BigBitEndian -> "be"
end

module Endianness = struct
  type fixed_endian = [`BE | `LE] [@@deriving sexp]

  type cases = (Ast.expr * fixed_endian) list [@@deriving sexp]

  type t = [fixed_endian | `Calc of Ast.expr * cases | `Inherited]
  [@@deriving sexp]

  let to_string = function
    | `BE -> "be"
    | `LE -> "le"
    | `Calc _ | `Inherited -> failwith "not supported (Calc | Inherited)"
end

module DocSpec = struct
  type refspec = TextRef of string | UrlRef of {url : string; text : string}
  [@@deriving sexp]

  type t = {summary : string option; refs : refspec list} [@@deriving sexp]
end

module InstanceIdentifier = struct
  type t = string [@@deriving sexp]
end

module RepeatSpec = struct
  type t =
    | RepeatExpr of Ast.expr
    | RepeatUntil of Ast.expr
    | RepeatEos
    | NoRepeat
  [@@deriving sexp]
end

module ValidationSpec = struct
  type t =
    | ValidationEq of Ast.expr
    | ValidationMin of Ast.expr
    | ValidationMax of Ast.expr
    | ValidationRange of {min : Ast.expr; max : Ast.expr}
    | ValidationAnyOf of Ast.expr list
    | ValidationExpr of Ast.expr
  [@@deriving sexp]
end

module EnumValueSpec = struct
  type t = {name : string; doc : DocSpec.t} [@@deriving sexp]
end

module EnumSpec = struct
  type t = {map : (int * EnumValueSpec.t) list} [@@deriving sexp]
end

module MetaSpec = struct
  type t = {
    isOpaque : bool;
    id : string option;
    endian : Endianness.t option;
    bitEndian : BitEndianness.t option;
    mutable encoding : string option;
    forceDebug : bool;
    opaqueTypes : bool option;
    zeroCopySubstream : bool option;
    imports : string list;
  }
  [@@deriving sexp]
end

module rec DataType : sig
  type data_type =
    | NumericType of numeric_type
    | BooleanType
    | BytesType of bytes_type
    | StrType of str_type
    | ComplexDataType of complex_data_type
    | AnyType
  [@@deriving sexp]

  and int_width = W1 | W2 | W4 | W8 [@@deriving sexp]

  and numeric_type = Int_type of int_type | Float_type of float_type
  [@@deriving sexp]

  and int_type =
    | CalcIntType
    | Int1Type of {signed : bool}
    | IntMultiType of {
        signed : bool;
        width : int_width;
        endian : Endianness.fixed_endian option;
      }
    | BitsType of {width : int; bit_endian : BitEndianness.t}
  [@@deriving sexp]

  and float_type =
    | CalcFloatType
    | FloatMultiType of {
        width : int_width;
        endian : Endianness.fixed_endian option;
      }
  [@@deriving sexp]

  and boolean_type = BitsType1 of BitEndianness.t | CalcBooleanType
  [@@deriving sexp]

  and bytes_type =
    | CalcBytesType
    | BytesEosType of {
        terminator : int option;
        include_ : bool;
        padRight : int option;
        mutable process : processExpr option;
      }
    | BytesLimitType of {
        size : Ast.expr;
        terminator : int option;
        include_ : bool;
        padRight : int option;
        mutable process : processExpr option;
      }
    | BytesTerminatedType of {
        terminator : int;
        include_ : bool;
        consume : bool;
        eosError : bool;
        mutable process : processExpr option;
      }
  [@@deriving sexp]

  and str_type =
    | CalcStrType
    | StrFromBytesType of {bytes : bytes_type; encoding : string}
  [@@deriving sexp]

  and array_type = ArrayTypeInStream | CalcArrayType [@@deriving sexp]

  and complex_data_type =
    | StructType
    | UserType of ClassSpec.t
    | ArrayType of array_type
  [@@deriving sexp]

  and switch_type = {
    on : Ast.expr;
    cases : (Ast.expr * data_type) list;
    isOwning : bool;
    mutable isOwningInExpr : bool;
  }
  [@@deriving sexp]

  type t = data_type [@@deriving sexp]

  val to_string : t -> string
end = struct
  type data_type =
    | NumericType of numeric_type
    | BooleanType
    | BytesType of bytes_type
    | StrType of str_type
    | ComplexDataType of complex_data_type
    | AnyType
  [@@deriving sexp]

  and int_width = W1 | W2 | W4 | W8 [@@deriving sexp]

  and numeric_type = Int_type of int_type | Float_type of float_type
  [@@deriving sexp]

  and int_type =
    | CalcIntType
    | Int1Type of {signed : bool}
    | IntMultiType of {
        signed : bool;
        width : int_width;
        endian : Endianness.fixed_endian option;
      }
    | BitsType of {width : int; bit_endian : BitEndianness.t}
  [@@deriving sexp]

  and float_type =
    | CalcFloatType
    | FloatMultiType of {
        width : int_width;
        endian : Endianness.fixed_endian option;
      }
  [@@deriving sexp]

  and boolean_type = BitsType1 of BitEndianness.t | CalcBooleanType
  [@@deriving sexp]

  and bytes_type =
    | CalcBytesType
    | BytesEosType of {
        terminator : int option;
        include_ : bool;
        padRight : int option;
        mutable process : processExpr option;
      }
    | BytesLimitType of {
        size : Ast.expr;
        terminator : int option;
        include_ : bool;
        padRight : int option;
        mutable process : processExpr option;
      }
    | BytesTerminatedType of {
        terminator : int;
        include_ : bool;
        consume : bool;
        eosError : bool;
        mutable process : processExpr option;
      }
  [@@deriving sexp]

  and str_type =
    | CalcStrType
    | StrFromBytesType of {bytes : bytes_type; encoding : string}
  [@@deriving sexp]

  and array_type = ArrayTypeInStream | CalcArrayType [@@deriving sexp]

  and complex_data_type =
    | StructType
    | UserType of ClassSpec.t
    | ArrayType of array_type
  [@@deriving sexp]

  and switch_type = {
    on : Ast.expr;
    cases : (Ast.expr * data_type) list;
    isOwning : bool;
    mutable isOwningInExpr : bool;
  }
  [@@deriving sexp]

  type t = data_type [@@deriving sexp]

  let width_to_int = function W1 -> 1 | W2 -> 2 | W4 -> 4 | W8 -> 8

  let to_string = function
    | NumericType (Int_type int_type) -> (
        match int_type with
        | Int1Type {signed} -> if signed then "s1" else "u1"
        | IntMultiType {signed; width; endian} ->
            Printf.sprintf
              "%s%d%s"
              (if signed then "s" else "u")
              (width_to_int width)
              (endian
              |> Option.map Endianness.to_string
              |> Option.value ~default:"")
        | BitsType {width; bit_endian} ->
            Printf.sprintf "b%d%s" width (BitEndianness.to_string bit_endian)
        | _ -> failwith "not supported (NumericType)")
    | NumericType (Float_type (FloatMultiType {width = _; endian = _})) -> "f8"
    | ComplexDataType (UserType {meta = {id = Some id; _}; _}) -> id
    | BytesType _ ->
        failwith "Bytes types are ommitted in kaitai struct representation"
    | _ -> failwith "not supported (datatype)"
end

and AttrSpec : sig
  module ConditionalSpec : sig
    type t = {ifExpr : Ast.expr option; repeat : RepeatSpec.t} [@@deriving sexp]
  end

  type t = {
    id : Identifier.t;
    dataType : DataType.t;
    cond : ConditionalSpec.t;
    valid : ValidationSpec.t option;
    enum : string option;
    doc : DocSpec.t;
    size : Ast.expr option;
  }
  [@@deriving sexp]
end = struct
  module ConditionalSpec = struct
    type t = {ifExpr : Ast.expr option; repeat : RepeatSpec.t} [@@deriving sexp]
  end

  type t = {
    id : Identifier.t;
    dataType : DataType.t;
    cond : ConditionalSpec.t;
    valid : ValidationSpec.t option;
    enum : string option;
    doc : DocSpec.t;
    size : Ast.expr option;
  }
  [@@deriving sexp]
end

and InstanceSpec : sig
  type t = {doc : DocSpec.t; descr : descr} [@@deriving sexp]

  and descr =
    | ValueInstanceSpec of {
        id : InstanceIdentifier.t;
        value : Ast.expr;
        ifExpr : Ast.expr option;
        dataTypeOpt : DataType.t option;
      }
    | ParseInstanceSpec
  [@@deriving sexp]
end = struct
  type t = {doc : DocSpec.t; descr : descr} [@@deriving sexp]

  and descr =
    | ValueInstanceSpec of {
        id : InstanceIdentifier.t;
        value : Ast.expr;
        ifExpr : Ast.expr option;
        dataTypeOpt : DataType.t option;
      }
    | ParseInstanceSpec (* TODO *)
  [@@deriving sexp]
end

and ParamDefSpec : sig
  type t = {id : Identifier.t; dataType : DataType.t; doc : DocSpec.t}
  [@@deriving sexp]
end = struct
  type t = {id : Identifier.t; dataType : DataType.t; doc : DocSpec.t}
  [@@deriving sexp]
end

and ClassSpec : sig
  type t = {
    fileName : string option;
    isTopLevel : bool;
    meta : MetaSpec.t;
    doc : DocSpec.t;
    toStringExpr : Ast.expr option;
    params : ParamDefSpec.t list;
    seq : AttrSpec.t list;
    types : (string * t) list;
    instances : (InstanceIdentifier.t * InstanceSpec.t) list;
    enums : (string * EnumSpec.t) list;
  }
  [@@deriving sexp]
end = struct
  type t = {
    fileName : string option;
    isTopLevel : bool;
    meta : MetaSpec.t;
    doc : DocSpec.t;
    toStringExpr : Ast.expr option;
    params : ParamDefSpec.t list;
    seq : AttrSpec.t list;
    types : (string * t) list;
    instances : (InstanceIdentifier.t * InstanceSpec.t) list;
    enums : (string * EnumSpec.t) list;
  }
  [@@deriving sexp]
end
