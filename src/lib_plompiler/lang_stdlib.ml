(*****************************************************************************)
(*                                                                           *)
(* MIT License                                                               *)
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

(** Plompiler standard library. *)

open Lang_core

module type Limb_list = sig
  (** Input for a Plompiler program. *)
  type 'a input

  (** Element of the native scalar field. *)
  type scalar

  (** Representation of values. *)
  type 'a repr

  (** Plompiler program. *)
  type 'a t

  (** Representation of elements. *)
  type tl

  (** [input_bytes ~le b] returns the representation of [b]
      that Plompiler expects as input.
      [le] can be used to set the endianness. *)
  val input_bytes : le:bool -> bytes -> tl input

  (** [constant ~le b] returns the constant [b] as a Plompiler value.
      [le] can be used to set the endianness. *)
  val constant : le:bool -> bytes -> tl repr t

  (** [of_scalar ~total_nb_bits b] converts the scalar [b] of size
      [total_nb_bits] in bits into the [tl] representation. *)
  val of_scalar : total_nb_bits:int -> scalar repr -> tl repr t

  (** [to_scalar b] return the scalar representing the value [b]. *)
  val to_scalar : tl repr -> scalar repr t

  (** [of_bool_list b] converts the list of bits in little-endian
      order into the [tl] representation. *)
  val of_bool_list : bool list repr -> tl repr t

  (** [to_bool_list b] returns the list of bits in little-endian
      order, representing the value [b]. *)
  val to_bool_list : tl repr -> bool list repr t

  (** [xor a b] returns the exclusive disjunction of [a] and [b]. *)
  val xor : tl repr -> tl repr -> tl repr t

  (** [band a b] returns the conjunction of [a] and [b]. *)
  val band : tl repr -> tl repr -> tl repr t

  (** [not b] returns the negation of [b]. *)
  val not : tl repr -> tl repr t

  (** [rotate_right b n] shifts the bits right by n positions,
      so that each bit is less significant.
      The least significant bit becomes the most significant
      i.e. it is "rotated".
      [rotate_right bs (length bl) = bl] *)
  val rotate_right : tl repr -> int -> tl repr t

  (** [shift_right b n] shifts all bits right by n positions,
      so that each bit is less significant.
      The least signigicant bit is lost and the most significant bit is
      set to zero.
      More precisely, if we interpret the [b] as an integer,
      [shift_right b n = b / 2^n] *)
  val shift_right : tl repr -> int -> tl repr t
end

(** The {!LIB} module type extends the core language defined in {!Lang_core.COMMON}
    by adding functions that build upon those primitives.
*)
module type LIB = sig
  include COMMON

  (** [foldiM] is the monadic version of a fold over a natural number. *)
  val foldiM : ('a -> int -> 'a t) -> 'a -> int -> 'a t

  (** [fold2M] is the monadic version of [List.fold_left2]. *)
  val fold2M : ('a -> 'b -> 'c -> 'a t) -> 'a -> 'b list -> 'c list -> 'a t

  (** [mapM] is the monadic version of [List.map]. *)
  val mapM : ('a -> 'b t) -> 'a list -> 'b list t

  (** [map2M] is the monadic version of [List.map2]. *)
  val map2M : ('a -> 'b -> 'c t) -> 'a list -> 'b list -> 'c list t

  (** [iterM] is the monadic version of [List.iter]. *)
  val iterM : ('a -> unit repr t) -> 'a list -> unit repr t

  (** [iter2M] is the monadic version of [List.iter2]. *)
  val iter2M : ('a -> 'b -> unit repr t) -> 'a list -> 'b list -> unit repr t

  module Bool : sig
    include BOOL

    (** Returns the pair (s, c_out), as per
     https://en.wikipedia.org/wiki/Adder_(electronics)#Full_adder *)
    val full_adder : bool repr -> bool repr -> bool repr -> (bool * bool) repr t
  end
  with type scalar = scalar
   and type 'a repr = 'a repr
   and type 'a t = 'a t

  module Num : sig
    include NUM

    (** [square a] returns the value [a^2]. *)
    val square : scalar repr -> scalar repr t

    (** [pow b e_bits] returns the value [b^e] where [e] is the
        number represented by the binary decomposition [e_bits]. *)
    val pow : scalar repr -> bool repr list -> scalar repr t

    (** [add_list ~qc ~coeffs l] returns the sum of the elements of [l]
        weighted by [coeffs].

        Note: if [coeffs] is defined, it should be of the same length
        as [l].
    *)
    val add_list :
      ?qc:S.t -> ?coeffs:S.t list -> scalar list repr -> scalar repr t

    (** [mul_list l] returns the product of the elements of [l]. *)
    val mul_list : scalar list repr -> scalar repr t

    (** [mul_by_constant k a] returns the value [k * a]. *)
    val mul_by_constant : S.t -> scalar repr -> scalar repr t

    (* [scalar_of_bytes bs] returns the scalar represented by the binary
       sequence [bs].
       Specifically, it evaluates P(X) = \sum_i bᵢ Xⁱ at 2. *)
    val scalar_of_bytes : bool list repr -> scalar repr t

    (** [is_eq_const a k] returns whether [a] is equal to [k]. *)
    val is_eq_const : scalar repr -> S.t -> bool repr t

    (** [assert_eq_const a k] asserts that [a] is equal to [k]. *)
    val assert_eq_const : scalar repr -> S.t -> unit repr t

    (** [is_upper_bounded ~bound x] returns whether the scalar [x] is
        strictly lower than [bound] when [x] is interpreted as an integer
        from [0] to [p-1] (being [p] the scalar field order).
        This circuit is total (and more expensive than our version below). *)
    val is_upper_bounded : bound:Z.t -> scalar repr -> bool repr t

    (** Same as [is_upper_bounded] but cheaper and partial.
        [is_upper_bounded_unsafe ~bound l] is unsatisfiable if l cannot be
        represented in binary with [Z.numbits bound] bits. *)
    val is_upper_bounded_unsafe :
      ?nb_bits:int -> bound:Z.t -> scalar repr -> bool repr t

    (** [geq (a, bound_a) (b, bound_b)] returns the boolean wire representing
        a >= b.
        Pre-condition: [a ∈ \[0, bound_a) ∧ b ∈ \[0, bound_b)] *)
    val geq : scalar repr * Z.t -> scalar repr * Z.t -> bool repr t
  end
  with type scalar = scalar
   and type 'a repr = 'a repr
   and type 'a t = 'a t

  (** Enumerations, represented as a list of cases. *)
  module Enum (N : sig
    val n : int
  end) : sig
    (** [switch_case k l] returns the k-th element of the list [l] if
        k ∈ \[0,n) or the first element of [l] otherwise. *)
    val switch_case : scalar repr -> 'a list repr -> 'a repr t
  end

  (** Representation of bytes. *)
  module Bytes : sig
    (** Little-endian representation of bytes.
        First element of the list is the Least Significant Bit. *)
    include
      Limb_list
        with type tl = bool list
         and type scalar = scalar
         and type 'a repr = 'a repr
         and type 'a t = 'a t
         and type 'a input = 'a Input.t

    (** [constant_uint32 ~le n] returns a value holding the bytes correspoding
      to the uint [n].
      [le] can be used to set the endianness. *)
    val constant_uint32 : le:bool -> Stdint.uint32 -> tl repr t

    (** [length b] returns the length of [b] in bits. *)
    val length : tl repr -> int

    (** [concat bs] returns the concatenation of the bitlists in [bs]. *)
    val concat : tl repr array -> tl repr

    (** [add b1 b2] computes the addition of [b1] and [b2]. *)
    val add : ?ignore_carry:bool -> tl repr -> tl repr -> tl repr t

    (** [rotate_left bl n] shifts the bits left by n positions,
      so that each bit is more significant.
      The most significant bit becomes the least significant
      i.e. it is "rotated".
      [rotate_left bl (length bl) = bl] *)
    val rotate_left : tl repr -> int -> tl repr t

    (** [shift_left bl n] shifts all bits left by n positions,
      so that each bit is more significant.
      The most signigicant bit is lost and the least significant bit is
      set to zero.
      More precisely, if we interpret the [bl] as an integer
       [shift_left bl i = bl * 2^i mod 2^{length a}] *)
    val shift_left : tl repr -> int -> tl repr t
  end

  (** This module is a more generic version of Bytes, where each scalar
     stores an [nb_bits]-bit number. *)
  module Limbs (N : sig
    val nb_bits : int
  end) : sig
    include
      Limb_list
        with type tl = scalar list
         and type scalar = scalar
         and type 'a repr = 'a repr
         and type 'a t = 'a t
         and type 'a input = 'a Input.t
  end

  (** [add2 p1 p2] returns the pair [(fst p1 + fst p2, snd p1 + snd p2)]. *)
  val add2 :
    (scalar * scalar) repr -> (scalar * scalar) repr -> (scalar * scalar) repr t

  module Encodings : sig
    (**
    Encoding type for encapsulating encoding/decoding/input functions.
    This type enables us to use more structured types for data
    in circuits.
    For that, encoding is parameterized by 3 types:
    - 'oh is the type of the high-level OCaml representation
    - 'u is the unpacked type, i.e. a collection of atomic reprs.
    - `p is the packed type, i.e the inner type of Plompiler's repr.

    For example, for the representation of a point (pair of scalars),
    one might have:
    {[
    ( {x:int; y:int},
      scalar repr * scalar repr,
      scalar * scalar
    ) encoding
    ]}

    The first type, the record [{x:int; y:int}], represents an OCaml point,
    which becomes the argument taken by the [input] function.

    The second type, [scalar repr * scalar repr], is an unpacking of the
    encoding. This is used for the result of [decode]. We can use any type
    isomorphic to [scalar repr * scalar repr] here.

    The last type must be [scalar * scalar], as an encoding of a point will be
    of the type [(scalar * scalar) repr].
  *)
    type ('oh, 'u, 'p) encoding = {
      encode : 'u -> 'p repr;
      decode : 'p repr -> 'u;
      input : 'oh -> 'p Input.input;
      of_input : 'p Input.input -> 'oh;
    }

    (**
    The function [conv] defines conversions for [encoding]s, by changing
    the higher-level ['u] and and ['oh] types.
  *)

    val conv :
      ('u1 -> 'u0) ->
      ('u0 -> 'u1) ->
      ('o1 -> 'o0) ->
      ('o0 -> 'o1) ->
      ('o0, 'u0, 'p) encoding ->
      ('o1, 'u1, 'p) encoding

    val with_implicit_bool_check :
      ('p repr -> bool repr t) -> ('o, 'u, 'p) encoding -> ('o, 'u, 'p) encoding

    val with_assertion :
      ('p repr -> unit repr t) -> ('o, 'u, 'p) encoding -> ('o, 'u, 'p) encoding

    val scalar_encoding : (Bls12_381.Fr.t, scalar repr, scalar) encoding

    val bool_encoding : (bool, bool repr, bool) encoding

    val list_encoding :
      ('a, 'b, 'c) encoding -> ('a list, 'b list, 'c list) encoding

    val atomic_list_encoding :
      ('a, 'b repr, 'c) encoding -> ('a list, 'b list repr, 'c list) encoding

    val obj2_encoding :
      ('a, 'b, 'c) encoding ->
      ('d, 'e, 'f) encoding ->
      ('a * 'd, 'b * 'e, 'c * 'f) encoding

    val atomic_obj2_encoding :
      ('a, 'b repr, 'c) encoding ->
      ('d, 'e repr, 'f) encoding ->
      ('a * 'd, ('b * 'e) repr, 'c * 'f) encoding

    val obj3_encoding :
      ('a, 'b, 'c) encoding ->
      ('d, 'e, 'f) encoding ->
      ('g, 'h, 'i) encoding ->
      ('a * ('d * 'g), 'b * ('e * 'h), 'c * ('f * 'i)) encoding

    val atomic_obj3_encoding :
      ('a, 'b repr, 'c) encoding ->
      ('d, 'e repr, 'f) encoding ->
      ('g, 'h repr, 'i) encoding ->
      ('a * ('d * 'g), ('b * ('e * 'h)) repr, 'c * ('f * 'i)) encoding

    val obj4_encoding :
      ('a, 'b, 'c) encoding ->
      ('d, 'e, 'f) encoding ->
      ('g, 'h, 'i) encoding ->
      ('j, 'k, 'l) encoding ->
      ( 'a * ('d * ('g * 'j)),
        'b * ('e * ('h * 'k)),
        'c * ('f * ('i * 'l)) )
      encoding

    val atomic_obj4_encoding :
      ('a, 'b repr, 'c) encoding ->
      ('d, 'e repr, 'f) encoding ->
      ('g, 'h repr, 'i) encoding ->
      ('j, 'k repr, 'l) encoding ->
      ( 'a * ('d * ('g * 'j)),
        ('b * ('e * ('h * 'k))) repr,
        'c * ('f * ('i * 'l)) )
      encoding

    val obj5_encoding :
      ('a, 'b, 'c) encoding ->
      ('d, 'e, 'f) encoding ->
      ('g, 'h, 'i) encoding ->
      ('j, 'k, 'l) encoding ->
      ('m, 'n, 'o) encoding ->
      ( 'a * ('d * ('g * ('j * 'm))),
        'b * ('e * ('h * ('k * 'n))),
        'c * ('f * ('i * ('l * 'o))) )
      encoding

    val atomic_obj5_encoding :
      ('a, 'b repr, 'c) encoding ->
      ('d, 'e repr, 'f) encoding ->
      ('g, 'h repr, 'i) encoding ->
      ('j, 'k repr, 'l) encoding ->
      ('m, 'n repr, 'o) encoding ->
      ( 'a * ('d * ('g * ('j * 'm))),
        ('b * ('e * ('h * ('k * 'n)))) repr,
        'c * ('f * ('i * ('l * 'o))) )
      encoding

    val obj6_encoding :
      ('a, 'b, 'c) encoding ->
      ('d, 'e, 'f) encoding ->
      ('g, 'h, 'i) encoding ->
      ('j, 'k, 'l) encoding ->
      ('m, 'n, 'o) encoding ->
      ('p, 'q, 'r) encoding ->
      ( 'a * ('d * ('g * ('j * ('m * 'p)))),
        'b * ('e * ('h * ('k * ('n * 'q)))),
        'c * ('f * ('i * ('l * ('o * 'r)))) )
      encoding

    val atomic_obj6_encoding :
      ('a, 'b repr, 'c) encoding ->
      ('d, 'e repr, 'f) encoding ->
      ('g, 'h repr, 'i) encoding ->
      ('j, 'k repr, 'l) encoding ->
      ('m, 'n repr, 'o) encoding ->
      ('p, 'q repr, 'r) encoding ->
      ( 'a * ('d * ('g * ('j * ('m * 'p)))),
        ('b * ('e * ('h * ('k * ('n * 'q))))) repr,
        'c * ('f * ('i * ('l * ('o * 'r)))) )
      encoding

    val obj7_encoding :
      ('a, 'b, 'c) encoding ->
      ('d, 'e, 'f) encoding ->
      ('g, 'h, 'i) encoding ->
      ('j, 'k, 'l) encoding ->
      ('m, 'n, 'o) encoding ->
      ('p, 'q, 'r) encoding ->
      ('s, 't, 'u) encoding ->
      ( 'a * ('d * ('g * ('j * ('m * ('p * 's))))),
        'b * ('e * ('h * ('k * ('n * ('q * 't))))),
        'c * ('f * ('i * ('l * ('o * ('r * 'u))))) )
      encoding

    val atomic_obj7_encoding :
      ('a, 'b repr, 'c) encoding ->
      ('d, 'e repr, 'f) encoding ->
      ('g, 'h repr, 'i) encoding ->
      ('j, 'k repr, 'l) encoding ->
      ('m, 'n repr, 'o) encoding ->
      ('p, 'q repr, 'r) encoding ->
      ('s, 't repr, 'u) encoding ->
      ( 'a * ('d * ('g * ('j * ('m * ('p * 's))))),
        ('b * ('e * ('h * ('k * ('n * ('q * 't)))))) repr,
        'c * ('f * ('i * ('l * ('o * ('r * 'u))))) )
      encoding

    val obj8_encoding :
      ('a, 'b, 'c) encoding ->
      ('d, 'e, 'f) encoding ->
      ('g, 'h, 'i) encoding ->
      ('j, 'k, 'l) encoding ->
      ('m, 'n, 'o) encoding ->
      ('p, 'q, 'r) encoding ->
      ('s, 't, 'u) encoding ->
      ('v, 'w, 'x) encoding ->
      ( 'a * ('d * ('g * ('j * ('m * ('p * ('s * 'v)))))),
        'b * ('e * ('h * ('k * ('n * ('q * ('t * 'w)))))),
        'c * ('f * ('i * ('l * ('o * ('r * ('u * 'x)))))) )
      encoding

    val atomic_obj8_encoding :
      ('a, 'b repr, 'c) encoding ->
      ('d, 'e repr, 'f) encoding ->
      ('g, 'h repr, 'i) encoding ->
      ('j, 'k repr, 'l) encoding ->
      ('m, 'n repr, 'o) encoding ->
      ('p, 'q repr, 'r) encoding ->
      ('s, 't repr, 'u) encoding ->
      ('v, 'w repr, 'x) encoding ->
      ( 'a * ('d * ('g * ('j * ('m * ('p * ('s * 'v)))))),
        ('b * ('e * ('h * ('k * ('n * ('q * ('t * 'w))))))) repr,
        'c * ('f * ('i * ('l * ('o * ('r * ('u * 'x)))))) )
      encoding

    val obj9_encoding :
      ('a, 'b, 'c) encoding ->
      ('d, 'e, 'f) encoding ->
      ('g, 'h, 'i) encoding ->
      ('j, 'k, 'l) encoding ->
      ('m, 'n, 'o) encoding ->
      ('p, 'q, 'r) encoding ->
      ('s, 't, 'u) encoding ->
      ('v, 'w, 'x) encoding ->
      ('y, 'z, 'a1) encoding ->
      ( 'a * ('d * ('g * ('j * ('m * ('p * ('s * ('v * 'y))))))),
        'b * ('e * ('h * ('k * ('n * ('q * ('t * ('w * 'z))))))),
        'c * ('f * ('i * ('l * ('o * ('r * ('u * ('x * 'a1))))))) )
      encoding

    val atomic_obj9_encoding :
      ('a, 'b repr, 'c) encoding ->
      ('d, 'e repr, 'f) encoding ->
      ('g, 'h repr, 'i) encoding ->
      ('j, 'k repr, 'l) encoding ->
      ('m, 'n repr, 'o) encoding ->
      ('p, 'q repr, 'r) encoding ->
      ('s, 't repr, 'u) encoding ->
      ('v, 'w repr, 'x) encoding ->
      ('y, 'z repr, 'a1) encoding ->
      ( 'a * ('d * ('g * ('j * ('m * ('p * ('s * ('v * 'y))))))),
        ('b * ('e * ('h * ('k * ('n * ('q * ('t * ('w * 'z)))))))) repr,
        'c * ('f * ('i * ('l * ('o * ('r * ('u * ('x * 'a1))))))) )
      encoding

    val obj10_encoding :
      ('a, 'b, 'c) encoding ->
      ('d, 'e, 'f) encoding ->
      ('g, 'h, 'i) encoding ->
      ('j, 'k, 'l) encoding ->
      ('m, 'n, 'o) encoding ->
      ('p, 'q, 'r) encoding ->
      ('s, 't, 'u) encoding ->
      ('v, 'w, 'x) encoding ->
      ('y, 'z, 'a1) encoding ->
      ('b1, 'c1, 'd1) encoding ->
      ( 'a * ('d * ('g * ('j * ('m * ('p * ('s * ('v * ('y * 'b1)))))))),
        'b * ('e * ('h * ('k * ('n * ('q * ('t * ('w * ('z * 'c1)))))))),
        'c * ('f * ('i * ('l * ('o * ('r * ('u * ('x * ('a1 * 'd1)))))))) )
      encoding

    val atomic_obj10_encoding :
      ('a, 'b repr, 'c) encoding ->
      ('d, 'e repr, 'f) encoding ->
      ('g, 'h repr, 'i) encoding ->
      ('j, 'k repr, 'l) encoding ->
      ('m, 'n repr, 'o) encoding ->
      ('p, 'q repr, 'r) encoding ->
      ('s, 't repr, 'u) encoding ->
      ('v, 'w repr, 'x) encoding ->
      ('y, 'z repr, 'a1) encoding ->
      ('b1, 'c1 repr, 'd1) encoding ->
      ( 'a * ('d * ('g * ('j * ('m * ('p * ('s * ('v * ('y * 'b1)))))))),
        ('b * ('e * ('h * ('k * ('n * ('q * ('t * ('w * ('z * 'c1))))))))) repr,
        'c * ('f * ('i * ('l * ('o * ('r * ('u * ('x * ('a1 * 'd1)))))))) )
      encoding
  end
end

module Lib (C : COMMON) = struct
  include C

  let foldiM : ('a -> int -> 'a t) -> 'a -> int -> 'a t =
   fun f e n -> foldM f e (List.init n (fun i -> i))

  let fold2M f acc ls rs =
    foldM (fun acc (l, r) -> f acc l r) acc (List.combine ls rs)

  let mapM f l =
    let* l =
      foldM
        (fun acc e ->
          let* e = f e in
          ret @@ (e :: acc))
        []
        l
    in
    ret @@ List.rev l

  let map2M f ls rs = mapM (fun (l, r) -> f l r) (List.combine ls rs)

  let iterM f l = foldM (fun _ a -> f a) unit l

  let iter2M f l r = iterM (fun (l, r) -> f l r) (List.combine l r)

  module Bool = struct
    include Bool

    let full_adder a b c_in =
      with_label ~label:"Bool.full_adder"
      @@ let* a_xor_b = xor a b in
         let* a_xor_b_xor_c = xor a_xor_b c_in in
         let* a_xor_b_and_c = band a_xor_b c_in in
         let* a_and_b = band a b in
         let* c = bor a_xor_b_and_c a_and_b in
         ret (pair a_xor_b_xor_c c)
  end

  module Num = struct
    include Num

    let square l = mul l l

    let pow x n_list =
      let* init =
        let* left = Num.one in
        ret (left, x)
      in
      let* res, _acc =
        foldM
          (fun (res, acc) bool ->
            let* res_true = mul res acc in
            let* res = Bool.ifthenelse bool res_true res in
            let* acc = mul acc acc in
            ret (res, acc))
          init
          n_list
      in
      ret res

    let add_list ?(qc = S.zero) ?(coeffs = []) l =
      let l = of_list l in
      let q =
        if coeffs != [] then coeffs
        else List.init (List.length l) (fun _ -> S.one)
      in
      assert (List.compare_lengths q l = 0) ;
      match (l, q) with
      | x1 :: x2 :: xs, ql :: qr :: qs ->
          let* res = Num.add ~qc ~ql ~qr x1 x2 in
          fold2M (fun acc x ql -> Num.add ~ql x acc) res xs qs
      | [x], [ql] -> Num.add_constant ~ql qc x
      | [], [] -> Num.constant qc
      | _, _ -> assert false

    let mul_list l =
      match of_list l with [] -> assert false | x :: xs -> foldM Num.mul x xs

    let mul_by_constant s x = Num.add_constant ~ql:s S.zero x

    let scalar_of_bytes b =
      let sb = List.map scalar_of_bool (of_list b) in
      scalar_of_limbs ~nb_bits:1 (to_list sb)

    let assert_eq_const l s = Num.assert_custom ~ql:S.mone ~qc:s l l l

    let is_eq_const l s =
      let* diff = add_constant ~ql:S.mone s l in
      is_zero diff

    (* Function used by [is_upper_bounded(_unsafe)] *)
    let ignore_leading_zeros ~nb_bits ~bound xbits =
      (* We can ignore all leading zeros in the bound's little-endian binary
         decomposition. The assertion cannot be satisfied if they are all zeros. *)
      let rec shave_zeros = function
        | [] ->
            raise
              (Invalid_argument
                 "is_upper_bounded cannot be satisfied on bound = 0")
        | (x, true) :: tl -> (x, tl)
        | (_, false) :: tl -> shave_zeros tl
      in
      List.combine (of_list xbits) (Utils.bool_list_of_z ~nb_bits bound)
      |> shave_zeros

    (* Let [(bn,...,b0)] and [(xn,...,x0)] be binary representations
       of [bound] and [x] respectively where the least significant bit is
       indexed by [0]. Let [op_i = if b_i = 1 then band else bor] for all [i].
       Predicate [x] < [bound] can be expressed as the negation of predicate:
       [ xn op_n (... (x1 op_1 (x0 op_0 true))) ].
       Intuitively we need to carry through a flag that indicates if up to
       step i, x is greater than b. In order for x[0,i] to be greater than
       b[0,i]:
       - if b_i = one then x_i will need to match it and the flag must be true.
       - if b_i = zero then x needs to be one if the flag is false or it can
         have any value if the flag is already true. *)
    let is_upper_bounded_unsafe ?nb_bits ~bound x =
      assert (Z.zero <= bound && bound < S.order) ;
      let nb_bits =
        Option.value
          ~default:(if Z.(equal bound zero) then 1 else Z.numbits bound)
          nb_bits
      in
      let* xbits = bits_of_scalar ~nb_bits x in
      let init, xibi = ignore_leading_zeros ~nb_bits ~bound xbits in
      let* geq =
        foldM
          (fun acc (xi, bi) ->
            let op = if bi then Bool.band else Bool.bor in
            op xi acc)
          init
          xibi
      in
      Bool.bnot geq

    let is_upper_bounded ~bound x =
      assert (Z.zero <= bound && bound < S.order) ;
      let nb_bits = Z.numbits S.order in
      let bound_plus_alpha = Z.(bound + Utils.alpha) in
      let* xbits = bits_of_scalar ~shift:Utils.alpha ~nb_bits x in
      let init, xibi =
        ignore_leading_zeros ~nb_bits ~bound:bound_plus_alpha xbits
      in
      let* geq =
        foldM
          (fun acc (xi, bi) ->
            let op = if bi then Bool.band else Bool.bor in
            op xi acc)
          init
          xibi
      in
      Bool.bnot geq

    let geq (a, bound_a) (b, bound_b) =
      (* (a - b) + bound_b - 1 ∈ [0, bound_a + bound_b - 1) *)
      let* shifted_diff =
        Num.add ~qr:S.mone ~qc:(S.of_z Z.(pred bound_b)) a b
      in
      let nb_bits = Z.(numbits @@ pred (add bound_a bound_b)) in
      let* bits = bits_of_scalar ~nb_bits shifted_diff in
      let init, xibi =
        ignore_leading_zeros ~nb_bits ~bound:Z.(pred bound_b) bits
      in
      foldM
        (fun acc (xi, bi) ->
          let op = if bi then Bool.band else Bool.bor in
          op xi acc)
        init
        xibi
  end

  module Enum (N : sig
    val n : int
  end) =
  struct
    let switch_case k cases =
      let cases = of_list cases in
      assert (List.compare_length_with cases N.n = 0) ;
      let indexed = List.mapi (fun i x -> (i, x)) cases in
      foldM
        (fun c (i, ci) ->
          let* f = Num.is_eq_const k (S.of_z (Z.of_int i)) in
          Bool.ifthenelse f ci c)
        (snd @@ List.hd indexed)
        (List.tl indexed)
  end

  module Bytes = struct
    type 'a input = 'a Input.t

    type nonrec scalar = scalar

    type nonrec 'a repr = 'a repr

    type nonrec 'a t = 'a t

    (* first element of the list is the Least Significant Bit *)
    type tl = bool list

    let input_bitlist l = Input.list (List.map Input.bool l)

    let input_bytes ~le b = input_bitlist @@ Utils.bitlist ~le b

    let of_bool_list x = ret x

    let to_bool_list x = ret x

    let of_scalar ~total_nb_bits x = bits_of_scalar ~nb_bits:total_nb_bits x

    let to_scalar = Num.scalar_of_bytes

    let constant ~le b =
      let bl = Utils.bitlist ~le b in
      let* ws =
        foldM
          (fun ws bit ->
            let* w = Bool.constant bit in
            ret (w :: ws))
          []
          bl
      in
      ret @@ to_list @@ List.rev ws

    let constant_uint32 ~le u32 =
      let b = Stdlib.Bytes.create 4 in
      Stdint.Uint32.to_bytes_big_endian u32 b 0 ;
      constant ~le b

    let length b = List.length (of_list b)

    let concat : tl repr array -> tl repr =
     fun bs ->
      let bs = Array.to_list bs in
      let bs = List.rev bs in
      let bs = List.map of_list bs in
      let bs = List.concat bs in
      to_list bs

    let check_args_length name a b =
      let la = length a in
      let lb = length b in
      if la != lb then
        raise
          (Invalid_argument
             (Format.sprintf
                "%s arguments of different lengths %i %i"
                name
                la
                lb))

    let add ?(ignore_carry = true) a b =
      check_args_length "Bytes.add" a b ;
      with_label ~label:"Bytes.add"
      @@
      let ha, ta = (List.hd (of_list a), List.tl (of_list a)) in
      let hb, tb = (List.hd (of_list b), List.tl (of_list b)) in
      let* a_xor_b = Bool.xor ha hb in
      let* a_and_b = Bool.band ha hb in
      let* res, carry =
        fold2M
          (fun (res, c) a b ->
            let* p = Bool.full_adder a b c in
            let s, c = of_pair p in
            ret (s :: res, c))
          ([a_xor_b], a_and_b)
          ta
          tb
      in
      ret @@ to_list @@ List.rev (if ignore_carry then res else carry :: res)

    let xor a b =
      check_args_length "Bytes.xor" a b ;
      let* l = map2M Bool.xor (of_list a) (of_list b) in
      ret @@ to_list l

    let not a =
      let* l = mapM Bool.bnot (of_list a) in
      ret @@ to_list l

    let band a b =
      check_args_length "Bytes.band" a b ;
      let* l = map2M Bool.band (of_list a) (of_list b) in
      ret @@ to_list l

    let rotate_right a i =
      let split_n n l =
        let rec aux acc k l =
          if k = n then (List.rev acc, l)
          else
            match l with
            | h :: t -> aux (h :: acc) (k + 1) t
            | [] ->
                raise
                  (Invalid_argument
                     (Printf.sprintf "split_n: n=%d >= List.length l=%d" n k))
        in
        aux [] 0 l
      in
      let head, tail = split_n i (of_list a) in
      ret @@ to_list @@ tail @ head

    let rotate_left a i = rotate_right a (length a - i)

    let shift_left a i =
      let* zero = Bool.constant false in
      let l = of_list a in
      let length = List.length l - i in
      assert (length >= 0) ;
      let res =
        List.init i (fun _ -> zero) @ List.filteri (fun j _x -> j < length) l
      in
      ret @@ to_list res

    let shift_right a i =
      let* zero = Bool.constant false in
      let l = of_list a in
      assert (List.compare_length_with l i >= 0) ;
      let res =
        List.filteri (fun j _x -> j >= i) l @ List.init i (fun _ -> zero)
      in
      ret @@ to_list res
  end

  module Limbs (N : sig
    val nb_bits : int
  end) =
  struct
    type 'a input = 'a Input.t

    type nonrec scalar = scalar

    type nonrec 'a repr = 'a repr

    type nonrec 'a t = 'a t

    module LimbN = Limb (N)

    type tl = scalar list

    let nb_bits = N.nb_bits

    let input_bytes ~le b =
      let bl = Utils.bitlist ~le b in
      let limbs = Utils.limbs_of_bool_list ~nb_bits bl in
      let r = List.map S.of_int limbs in
      Input.with_assertion
        (fun x -> iterM (Num.range_check ~nb_bits) (of_list x))
        (Input.list (List.map Input.scalar r))

    let of_bool_list x =
      let bl = Utils.split_exactly (of_list x) nb_bits in
      let* r = mapM (fun x -> Num.scalar_of_bytes (to_list x)) bl in
      ret @@ to_list r

    let to_bool_list l =
      let* lb =
        mapM
          (fun z ->
            let* bz = bits_of_scalar ~nb_bits z in
            ret @@ of_list bz)
          (of_list l)
      in
      ret @@ to_list (List.concat lb)

    let to_scalar b = scalar_of_limbs ~nb_bits b

    let of_scalar ~total_nb_bits b = limbs_of_scalar ~total_nb_bits ~nb_bits b

    let constant ~le b =
      let bl = Utils.bitlist ~le b in
      let limbs = Utils.limbs_of_bool_list ~nb_bits bl in
      let* r = mapM (fun x -> Num.constant @@ S.of_int x) limbs in
      ret @@ to_list r

    let xor a b =
      let* r = map2M LimbN.xor_lookup (of_list a) (of_list b) in
      ret @@ to_list r

    let band a b =
      let* r = map2M LimbN.band_lookup (of_list a) (of_list b) in
      ret @@ to_list r

    let not b =
      let* r = mapM LimbN.bnot_lookup (of_list b) in
      ret @@ to_list r

    let rotate_or_shift_right_rem0 ~is_shift a ind =
      let a = Array.of_list (of_list a) in
      let len = Array.length a in
      let* zero = Num.zero in
      let r =
        List.init (len - ind) (fun i -> a.(i + ind))
        @ List.init ind (fun i -> if is_shift then zero else a.(i))
      in
      ret @@ to_list r

    let rotate_or_shift_right_rem ~is_shift a rem =
      assert (rem < nb_bits) ;
      let a = Array.of_list (of_list a) in
      let len = Array.length a in
      let get_i i : scalar repr t =
        if i < len - 1 then LimbN.rotate_right_lookup a.(i) a.(i + 1) rem
        else
          let* zero = Num.zero in
          let a0 = if is_shift then zero else a.(0) in
          LimbN.rotate_right_lookup a.(i) a0 rem
      in
      let* r = mapM get_i (List.init len (fun i -> i)) in
      ret @@ to_list r

    let rotate_or_shift_right ~is_shift a i =
      let ind = i / nb_bits in
      let rem = i mod nb_bits in
      let* res = rotate_or_shift_right_rem0 ~is_shift a ind in
      if rem > 0 then rotate_or_shift_right_rem ~is_shift res rem else ret res

    let rotate_right a i = rotate_or_shift_right ~is_shift:false a i

    let shift_right a i = rotate_or_shift_right ~is_shift:true a i
  end

  let add2 p1 p2 =
    let x1, y1 = of_pair p1 in
    let x2, y2 = of_pair p2 in
    let* x3 = Num.add x1 x2 in
    let* y3 = Num.add y1 y2 in
    ret (pair x3 y3)

  module Encodings = struct
    type ('oh, 'u, 'p) encoding = {
      encode : 'u -> 'p repr;
      decode : 'p repr -> 'u;
      input : 'oh -> 'p Input.t;
      of_input : 'p Input.t -> 'oh;
    }

    let conv :
        ('u1 -> 'u0) ->
        ('u0 -> 'u1) ->
        ('o1 -> 'o0) ->
        ('o0 -> 'o1) ->
        ('o0, 'u0, 'p) encoding ->
        ('o1, 'u1, 'p) encoding =
     fun f g fi gi e ->
      let encode a = e.encode @@ f a in
      let decode b = g @@ e.decode b in
      let input x = e.input @@ fi x in
      let of_input x = gi @@ e.of_input x in
      {encode; decode; input; of_input}

    let with_implicit_bool_check :
        ('p repr -> bool repr t) ->
        ('o, 'u, 'p) encoding ->
        ('o, 'u, 'p) encoding =
     fun bc e ->
      {e with input = (fun x -> Input.with_implicit_bool_check bc @@ e.input x)}

    let with_assertion :
        ('p repr -> unit repr t) ->
        ('o, 'u, 'p) encoding ->
        ('o, 'u, 'p) encoding =
     fun assertion e ->
      {e with input = (fun x -> Input.with_assertion assertion @@ e.input x)}

    (** Encoding combinators *)
    let scalar_encoding =
      let encode x = x in
      let decode x = x in
      let input = Input.scalar in
      let of_input = Input.to_scalar in
      {encode; decode; input; of_input}

    let bool_encoding =
      let encode x = x in
      let decode x = x in
      let input = Input.bool in
      let of_input = Input.to_bool in
      {encode; decode; input; of_input}

    let list_encoding (e : _ encoding) =
      let encode a = to_list @@ List.map e.encode a in
      let decode x = List.map e.decode (of_list x) in
      let input a = Input.list @@ List.map e.input a in
      let of_input x = List.map e.of_input (Input.to_list x) in
      {encode; decode; input; of_input}

    (* Encoding for lists, where we keep the repr of the list itself, not a list
       of repr *)
    let atomic_list_encoding :
        ('a, 'b repr, 'c) encoding -> ('a list, 'b list repr, 'c list) encoding
        =
     fun e ->
      let encode a = to_list @@ List.map e.encode (of_list a) in
      let decode x = to_list @@ List.map e.decode (of_list x) in
      let input a = Input.list @@ List.map e.input a in
      let of_input x = List.map e.of_input (Input.to_list x) in
      {encode; decode; input; of_input}

    let obj2_encoding (el : _ encoding) (er : _ encoding) =
      let encode (a, b) = pair (el.encode a) (er.encode b) in
      let decode p =
        let a, b = of_pair p in
        (el.decode a, er.decode b)
      in
      let input (a, f) = Input.pair (el.input a) (er.input f) in
      let of_input p =
        let a, b = Input.to_pair p in
        (el.of_input a, er.of_input b)
      in
      {encode; decode; input; of_input}

    let atomic_obj2_encoding :
        ('a, 'b repr, 'c) encoding ->
        ('d, 'e repr, 'f) encoding ->
        ('a * 'd, ('b * 'e) repr, 'c * 'f) encoding =
     fun el er ->
      let encode p =
        let a, b = of_pair p in
        pair (el.encode a) (er.encode b)
      in
      let decode p =
        let a, b = of_pair p in
        pair (el.decode a) (er.decode b)
      in
      let input (a, f) = Input.pair (el.input a) (er.input f) in
      let of_input p =
        let a, b = Input.to_pair p in
        (el.of_input a, er.of_input b)
      in
      {encode; decode; input; of_input}

    let obj3_encoding e0 e1 e2 = obj2_encoding e0 (obj2_encoding e1 e2)

    let atomic_obj3_encoding e0 e1 e2 =
      atomic_obj2_encoding e0 (atomic_obj2_encoding e1 e2)

    let obj4_encoding e0 e1 e2 e3 = obj2_encoding e0 (obj3_encoding e1 e2 e3)

    let atomic_obj4_encoding e0 e1 e2 e3 =
      atomic_obj2_encoding e0 (atomic_obj3_encoding e1 e2 e3)

    let obj5_encoding e0 e1 e2 e3 e4 =
      obj2_encoding e0 (obj4_encoding e1 e2 e3 e4)

    let atomic_obj5_encoding e0 e1 e2 e3 e4 =
      atomic_obj2_encoding e0 (atomic_obj4_encoding e1 e2 e3 e4)

    let obj6_encoding e0 e1 e2 e3 e4 e5 =
      obj2_encoding e0 (obj5_encoding e1 e2 e3 e4 e5)

    let atomic_obj6_encoding e0 e1 e2 e3 e4 e5 =
      atomic_obj2_encoding e0 (atomic_obj5_encoding e1 e2 e3 e4 e5)

    let obj7_encoding e0 e1 e2 e3 e4 e5 e6 =
      obj2_encoding e0 (obj6_encoding e1 e2 e3 e4 e5 e6)

    let atomic_obj7_encoding e0 e1 e2 e3 e4 e5 e6 =
      atomic_obj2_encoding e0 (atomic_obj6_encoding e1 e2 e3 e4 e5 e6)

    let obj8_encoding e0 e1 e2 e3 e4 e5 e6 e7 =
      obj2_encoding e0 (obj7_encoding e1 e2 e3 e4 e5 e6 e7)

    let atomic_obj8_encoding e0 e1 e2 e3 e4 e5 e6 e7 =
      atomic_obj2_encoding e0 (atomic_obj7_encoding e1 e2 e3 e4 e5 e6 e7)

    let obj9_encoding e0 e1 e2 e3 e4 e5 e6 e7 e8 =
      obj2_encoding e0 (obj8_encoding e1 e2 e3 e4 e5 e6 e7 e8)

    let atomic_obj9_encoding e0 e1 e2 e3 e4 e5 e6 e7 e8 =
      atomic_obj2_encoding e0 (atomic_obj8_encoding e1 e2 e3 e4 e5 e6 e7 e8)

    let obj10_encoding e0 e1 e2 e3 e4 e5 e6 e7 e8 e9 =
      obj2_encoding e0 (obj9_encoding e1 e2 e3 e4 e5 e6 e7 e8 e9)

    let atomic_obj10_encoding e0 e1 e2 e3 e4 e5 e6 e7 e8 e9 =
      atomic_obj2_encoding e0 (atomic_obj9_encoding e1 e2 e3 e4 e5 e6 e7 e8 e9)
  end
end
