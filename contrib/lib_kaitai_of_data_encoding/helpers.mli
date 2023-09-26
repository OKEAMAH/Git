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

(* This module consists of helpers for building kaitai specifications. *)

open Kaitai.Types

(** [default_doc_spec] is without summary and references.  *)
val default_doc_spec : DocSpec.t

(** [cond_no_cond] is default conditional specification that has no [if]
    expression and no repetition. *)
val cond_no_cond : AttrSpec.ConditionalSpec.t

(** [default_attr_spec] is initialized with default (empty) values. *)
val default_attr_spec : AttrSpec.t

(** [default_meta_spec ~encoding_name] returns default [MetaSpec.t].

    The following meta section properties are set:
    - [endian] is set to [BE] (as per data-encoding default).
    - [id] is set to [~encoding_name].
    - Other fields are [[]] or [None]. *)
val default_meta_spec : encoding_name:string -> MetaSpec.t

(** [default_class_spec ~encoding_name] builds an default (empty) [ClassSpec.t].

    @param ~encoding_name is added to meta section as [id]. *)
val default_class_spec : encoding_name:string -> ClassSpec.t

(** [add_uniq_assoc kvs kv] returns an association list with associations from
    [kvs] as well as [kv].

    If [kvs] already contains [kv], then [kvs] is returned.

    @raises Invalid_argument if [kvs] includes an association with the same key
    as but a different value than [kv]. *)
val add_uniq_assoc : (string * 'a) list -> string * 'a -> (string * 'a) list

(** [class_spec_of_attr ~encoding_name ?enums attr] returns a [ClassSpet.t]
    for [attr].

    In case of [attr] being of [ComplexDataType UserType _] type, then [types]
    section of returned [ClassSpec.t] is automatically populated with
    an appropriate type.

    @param ~encoding_name is added to meta section as [id].
    @param ?enums is added to class specification if present. *)
val class_spec_of_attr :
  encoding_name:string ->
  ?enums:(string * EnumSpec.t) list ->
  AttrSpec.t ->
  ClassSpec.t