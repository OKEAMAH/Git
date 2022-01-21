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

(** This module provides specialized encoding that are implemented to
    reduce the size of the serialization result.

    The main trick this module allows to implement more easily is the
    notion of “shared tags”. In [Data_encoding], when you have a
    record [t] with two fields whose encoding are tagged, the encoding
    of [t] will encompass two tags. In practice, only few bits are
    used in each tags, which means the rest is “wasted.”

    As an example, consider this type:

    {[
    type t =
      | T1 of { f1 : int option; f2 : (int, bool) Either.t }
      | T2 of { f3: int }
    ]}

    A value of [t] using the constructor [T1] will be serialized into
    a binary array of this form:

    {v
    ┌────────┬─────────┬─────────────┬─────────┬─────────────┐
    │ tag(t) │ tag(f1) │ payload(f1) │ tag(f2) │ payload(f2) │
    └────────┴─────────┴─────────────┴─────────┴─────────────┘
      1 byte   1 byte    N bytes       1 byte    M bytes
    v}

    Where [tag(f)] is a value used by [Data_encoding] to distinguish
    between several encoding alternatives for [f], and [payload(f)] is
    the resulting binary array.

    For both [option] and [Either.t], the tag of the encoding only
    uses one bit in practice. Which means that for [T1], the encoding
    needs two bits, but the default approach of [Data_encoding] uses
    two {i bytes} instead. Similarly, to distinguish between [T1] and
    [T2], the default approach is to use an additional tag (one byte)
    for that, where only one additional bit is required.

    This module provides an approach to tackle this issue, by
    allocating only one tag ({i i.e.}, one byte) that is used to store
    the useful bits to distinguish between the disjunction cases. We
    call this tag the “shared tag” of the encoding. The bits of the
    shared tag describes precisely the layout of the encoded date.

    For instance, considering a compact encoding for [t], the third
    bit of the tag can be used to distinguish between [T1] and [T2].
    In case the third bit is 0, the first bit of the tag determines
    the case of [option], and the second the case of [Either.t].

    As a consequence, the resulting binary array for the constructor
    [T1] is

    {v
    ┌──────────┬─────────────┬─────────────┐
    │ 000000eo │ payload(f1) │ payload(f2) │
    └──────────┴─────────────┴─────────────┘
      1 byte     N bytes       M bytes
    v}

    while the resulting binary array for the constructor [T2] is

    {v
    ┌──────────┬─────────────┐
    │ 00000100 │ payload(f3) │
    └──────────┴─────────────┘
      1 byte     N bytes
    v} *)

(** The description of a compact encoding. *)
type 'a t

(** Turn a compact encoding into a regular {!Data_encoding.t}. The
    encoding computed for the JSON case can be overwritten using the
    [json] optional argument. *)
val make : ?tag_size:[`Uint8 | `Uint16] -> 'a t -> 'a Data_encoding.t

(** {1 Combinators} *)

(** Similarly to [Data_encoding], we provide various combinators to
    compose compact encoding together. *)

(** {2 Base types} *)

(** A type with no inhabitant. *)
type void

(** A compact encoding to denote an impossible cases in conjunction
    operators such as [case2] or [case4]. For instance, if you have
    only three variants to encode, you can use [case4 a b c void]. *)
val void : void t

(** [refute x] can be used to refute a branch of a [match] which
    exhibits a value of type [void]. *)
val refute : void -> 'a

(** A compact encoding of the singleton value [empty], which has zero
    memory footprint.

    For instance, one can define a compact encoding of [bool] values
    with [case2 unit unit]: this compact encoding uses one bit in the
    shared tag, and zero in the payload. *)
val empty : unit t

(** Efficient encoding of boolean values. It uses one bit in the
    shared tag, and zero bit in the payload. *)
val bool : bool t

(** [singleton encoding] unconditionally uses [encoding] in the
    payload, and uses zero bit in the shared tag. *)
val singleton : 'a Data_encoding.t -> 'a t

val option : 'a t -> 'a option t

(** {2 Conversion} *)

(** [conv ?json f g e] reuses the encoding [e] for type [b] to encode
    an type [a] using the isomorphism [(f, g)]. The optional argument
    allows to overwrite the encoding used for JSON, in place of the
    one computed by default. *)
val conv : ?json:'a Data_encoding.t -> ('a -> 'b) -> ('b -> 'a) -> 'b t -> 'a t

(** {2 Conjunctions} *)

(** [tup2 e1 e2] concatenates the shared tags and payloads of [e1] and
    [e2]. *)
val tup2 : 'a t -> 'b t -> ('a * 'b) t

(** [tup3 e1 e2 e3] concatenates the shared tags and payloads of [e1],
    [e2], and [e3]. *)
val tup3 : 'a t -> 'b t -> 'c t -> ('a * 'b * 'c) t

(** [tup4 e1 e2 e3 e4] concatenates the shared tags and payloads of
    [e1], [e2], [e3] and [e4]. *)
val tup4 : 'a t -> 'b t -> 'c t -> 'd t -> ('a * 'b * 'c * 'd) t

type 'a field

(** [req "f" compact] can be used in conjunction with [optN] to create
    compact encoding with more readable JSON encoding, as an
    alternative of [tupN]. The JSON output is a dictionary which
    contains the field [f] with a value encoded using [compact]. *)
val req : string -> 'a t -> 'a field

(** Same as {!req}, but the field is optional. *)
val opt : string -> 'a t -> 'a option field

(** [obj1] can be used in conjunction with [req] or [opt] to produce
    more readable JSON outputs.  *)
val obj1 : 'a field -> 'a t

(** An alternative to [tup2] which can be used in conjunction with
    {!req} and {!opt} to produce more readable JSON outputs based on
    dictionary. *)
val obj2 : 'a field -> 'b field -> ('a * 'b) t

(** An alternative to [tup3] which can be used in conjunction with
    {!req} and {!opt} to produce more readable JSON outputs based on
    dictionary. *)
val obj3 : 'a field -> 'b field -> 'c field -> ('a * 'b * 'c) t

(** An alternative to [tup4] which can be used in conjunction with
    {!req} and {!opt} to produce more readable JSON outputs based on
    dictionary. *)
val obj4 : 'a field -> 'b field -> 'c field -> 'd field -> ('a * 'b * 'c * 'd) t

(** A compact encoding for [int32] values. It uses 2 bits in the
    shared tag, to determine how many bytes are used in the payload:

    {ul {li [00]: from 0 to 255, one byte.}
        {li [01]: from 256 to 65,535, two bytes.}
        {li [10]: from 65,536 to 2,147,483,647, and for negative
            values, four bytes.}} *)
val int32 : int32 t

(** A compact encoding for [int64] values. It uses 2 bits in the
    shared tag, to determine how many bytes are used in the payload:

    {ul {li [00]: from 0 to 255, one byte.}
        {li [01]: from 256 to 65,535, two bytes.}
        {li [10]: from 65,536 to 4,294,967,295 four bytes.}
        {li [11]: from 65,536 to 4,294,967,295 four bytes.}} *)
val int64 : int64 t

(** [list n encoding] uses [n] bits in the shared tag to encode the
    size of small lists.

    For instance, [list 2 encoding],

    {ul {li [00]: the payload is empty, because it is the empty list}
        {li [01]: the singleton list, whose element is encoded using
            [encoding].}
        {li [10]: a list of two elements encoded with [encoding]}
        {li [11]: a list of more than two elements, prefixed with its
            size (that uses 8 bytes)}} *)
val list : int -> 'a Data_encoding.t -> 'a list t

(** {2 Disjunctions} *)

(** A conjunction of two different cases, which only needs one bit
    to be enumerated. *)
type ('a, 'b) case2 = Case_0 of 'a | Case_1 of 'b

(** A disjunction case, to be constructed with {!case}. *)
type 'a case

(** [case name compact] is the description of a disjunction case; to
    be used with {!case2} and {!case4}. *)
val case : string -> 'a t -> 'a case

(** [case2 a b] creates a new compact encoding for the union of [a]
    and [b]. It uses one extra bit in the shared tag to distinguish
    between the two types. *)
val case2 : 'a case -> 'b case -> ('a, 'b) case2 t

(** [or_int32 c] creates a new compact encoding for the disjunction of
    any type [a] (see {!case}) with [int32]. It uses the same number
    of bits as {!int32}, that is 2, and uses the tag [00] for values
    of type [a]. *)
val or_int32 :
  int32_kind:string ->
  alt_kind:string ->
  'a Data_encoding.t ->
  (int32, 'a) case2 t

(** A conjunction of four different cases, which only needs two bits
    to be enumerated. *)
type ('a, 'b, 'c, 'd) case4 =
  | Case_00 of 'a
  | Case_01 of 'b
  | Case_10 of 'c
  | Case_11 of 'd

(** [case4 a b c d] creates a new compact encoding for the Cartesian
    product of [a], [b], [c] and [d]. It uses two extra bit of
    information in the shared tag. *)
val case4 : 'a case -> 'b case -> 'c case -> 'd case -> ('a, 'b, 'c, 'd) case4 t

(** {1 Space-efficient Encoding} *)

(** We now provide regular [Data_encoding.t] values that can be used
    with the default combinators of the library. Not that they simply
    consists in using {!make} with their compact counterpart. *)

(** A specialized encoding for 32-bits encoding that uses smaller
    buffer if possible, {i e.g.}, integers which fits in one byte are
    stored in a buffer of two bytes (one for the tag, one for the
    value).

    The first two bits of the first byte of the result are used to
    determine the layout of the output, [00] for one byte, [01] for
    two bits, and [10] for four bytes.

    The result will therefore takes two bytes (int8), three bytes
    (int16), or five bytes (int32). This means that if you frequently
    have to encode integers greater than [2^16 - 1], you should not
    use this encoding. *)
val compact_int32 : int32 Data_encoding.t

(** A specialized encoding for 64-bits encoding that uses smaller
    buffer if possible, {i e.g.}, integers which fits in one byte are
    stored in a buffer of two bytes (one for the tag, one for the
    value).

    The first two bits of the first byte of the result are used to
    determine the layout of the output, [00] for one byte, [01] for
    two bits, [10] for four bytes, and [11] for eight bytes.

    The result will therefore takes two bytes (int8), three bytes
    (int16), five bytes (int32), or nine bytes (int64). This means
    that if you frequently have to encode integers greater than
    {!Int32.max_int}, you should not use this encoding. *)
val compact_int64 : int64 Data_encoding.t

(** A specialized encoding for lists that produces a smaller output
    than {!Data_encoding.list} for small lists.

    It uses the first [n] bits of the first byte of the binary
    encoding to encode the size of the small lists, up until [11..1],
    which means a “big list.“ In such a case, the list is prefixed by
    its size.

    As a consequence, seven bytes are spared for small lists, but
    lists of more than [2^n - 2] elements use one more byte. If the
    latter case is more likely, this encoding should not be used. *)
val compact_list : int -> 'a Data_encoding.t -> 'a list Data_encoding.t

(** A specialized encoding for a disjunction between [int32] and any
    type, that produces a compact output for the [int32] case. In the
    JSON encoding, the [int32] kind is identified by [int32_kind], and
    [alt_kind] is used to identified alternative case.

    This encoding is always more efficient space-wise than its default
    [Data_encoding] counterpart. *)
val compact_or_int32 :
  int32_kind:string ->
  alt_kind:string ->
  'a Data_encoding.t ->
  (int32, 'a) case2 Data_encoding.t

(** {1 Internals} *)

(** This module can be used to write compact encoding for complex type
    without using relying on the existing combinators. *)
module Internals : sig
  type tag = int32

  val join_tags : (tag * int) list -> tag

  module type S = sig
    (** The type of [input] this module allows to encode. *)
    type input

    (** The various way to efficiently encode [input]. *)
    type layout

    val layout_equal : layout -> layout -> bool

    (** The list of layouts available to encode [input]. *)
    val layouts : layout list

    (** The number of bits necessary to distinguish between the various
        layouts. *)
    val tag_len : int

    (** [tag layout] computes the tag of {!Data_encoding.union} to be
        used to encode values classified as [layout].

        {b Warning:} It is expected that [tag layout < 2^tag_len -
        1]. *)
    val tag : layout -> tag

    (** [partial_encoding layout] returns the encoding to use for values
        classified as [layout].

        This encoding can be partial in the sense that it may fail for
        values [x] that does not belong to [layout]. See {!belongs}. *)
    val partial_encoding : layout -> input Data_encoding.t

    (** [classify x] returns the layout to be used to encode [x]. *)
    val classify : input -> layout

    (** The encoding to use when targeting a JSON output. *)
    val json_encoding : input Data_encoding.t
  end

  val make : (module S with type input = 'a) -> 'a t
end
