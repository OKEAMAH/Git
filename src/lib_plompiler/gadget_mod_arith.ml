(*****************************************************************************)
(*                                                                           *)
(* MIT License                                                               *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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

open Lang_core
open Lang_stdlib

module type PARAMETERS = sig
  val label : string

  val modulus : Z.t

  val base : Z.t

  val nb_limbs : int

  val setM : Z.t list
end

module type MOD_ARITH = functor (L : LIB) -> sig
  open L

  type mod_int

  val label : string

  val modulus : Z.t

  val base : Z.t

  val nb_limbs : int

  val moduli : Z.t list

  val qm_min_add : Z.t

  val qm_bound_add : Z.t

  val ts_bounds_add : (Z.t * Z.t) list

  val input_mod_int : ?kind:input_kind -> S.t list -> mod_int repr t

  val add : mod_int repr -> mod_int repr -> mod_int repr t

  val mul : mod_int repr -> mod_int repr -> mod_int repr t

  val neg : mod_int repr -> mod_int repr t

  (* val of_z : Z.t -> mod_int *)

  (* val to_z : mod_int -> Z.t *)
end

(* Checks that the parameters are sound for implementing modular arithmetic,
   i.e., that there will be no wrap-around when checking equalities modulo the
   moduli and that such equalities imply an equality over the integers.
   This function returns a pair (qm_min, qm_bound):
     - qm_min   : a constant used in all identities related to modular addition
     - qm_bound : an upper-bound on the value of the quotient (modulo m) qm,
                  which needs to be asserted to be in the range [0, qm_bound)
   This function also returns (as a second argument) a list of pairs
   (tj_min, tj_bound), one for each mj in moduli:
     - tj_min   : a constant used in the identity modulo mj
     - tj_bound : an upper-bound on the value of the quotient (modulo mj) tj,
                  which needs to be asserted to be in the range [0, tj_bound) *)
let check_addition_parameters ~modulus:m ~base ~nb_limbs ~moduli =
  (* Assert that we can encode any integer in [nb_limbs] limbs *)
  assert (Z.(pow base nb_limbs >= m)) ;

  (* We enforce z = (x + y) mod m with the equation:
     \sum_i (B^i mod m) * (x_i + y_i - z_i) = qm * m

     In that case, we can establish the following bounds on qm:
       qm_min =   - (B-1) * \sum_i (B^i mod m) / m
       qm_max = 2 * (B-1) * \sum_i (B^i mod m) / m *)
  let sum = List.fold_left Z.add Z.zero in
  let ( %! ) n m = Z.div_rem n m |> snd in
  let bs_mod_m = List.init nb_limbs (fun i -> Z.pow base i %! m) in
  let qm_min = Z.(div (neg (base - one) * sum bs_mod_m) m) in
  let qm_max = Z.(div (of_int 2 * (base - one) * sum bs_mod_m) m) in

  (* We can thus restrict qm to be in [qm_min, qm_max] or any bigger interval
     (for correctness). In order for the interval to start at 0, let us modify
     the above equation as follows:
     \sum_i (B^i mod m) * (x_i + y_i - z_i) = (qm + qm_min) * m

     Now, we can bound qm in the interval [0, qm_max - qm_min].
     For compatibility with our range-check protocol, we will upper-bound
     the interval by a power of 2^15, the one immediately larger than
     qm_max - qm_min.
  *)

  (* Returns the next multiple of k greater than or equal to the given int *)
  let next_multiple_of k n = k * (1 + ((n - 1) / k)) in

  let qm_bound =
    Z.(shift_left one (next_multiple_of 15 @@ numbits (qm_max - qm_min)))
  in

  (* Now, assuming qm is restricted in [0, qm_bound), let us bound the amount
     \sum_i (B^i mod m) * (x_i + y_i - z_i) - (qm + qm_min) * m

     lower_bound:   - (B-1) * \sum_i (B^i mod m) - (qm_bound + qm_min) * m
     upper_bound: 2 * (B-1) * \sum_i (B^i mod m) - qm_min * m

     Then, if we define M := native_modulus :: moduli, lcm(M) must be larger
     than (upper_bound - lower_bound) to guarantee that a solution modulo lcm(M)
     implies a solution over the integers.
  *)
  let lower_bound =
    Z.((neg (base - one) * sum bs_mod_m) - ((qm_bound + qm_min) * m))
  in
  let upper_bound =
    Z.((of_int 2 * (base - one) * sum bs_mod_m) - (qm_min * m))
  in
  let lcm_M_lbound = Z.(upper_bound - lower_bound) in

  assert (
    List.fold_left Z.lcm Z.one (Bls12_381.Fr.order :: moduli) > lcm_M_lbound) ;

  (* For every mj in M, we need to enforce the equation:
     \sum_i ((B^i mod m) mod mj) * (x_i + y_i - z_i)
       - qm * (m mod mj) - ((qm_min * m) mod mj) = tj * mj

     with the exception of the native modulus p = Scalar.order,
     where we can directly check:
      \sum_i ((B^i mod m) mod p) * (x_i + y_i - z_i)
        - (qm + qm_min) * (m mod p) =_{p} 0

     For the moduli != p, we need to bound the corresponding auxiliary
     variable tj. As before, we will first bound tj in the interval
     [tj_min, tj_max] and then apply a small modification to shift it to
     the interval [0, tj_bound) where tj_bound is the power of 2^15
     immediately above (tj_max - tj_min)
  *)
  let ts_bounds =
    List.map
      (fun mj ->
        (* We can establish the following bounds on tj:
           tj_min =
           (- (B-1) * (\sum_i (B^i mod m) mod mj)
            - qm_bound * (m mod mj) - ((qm_min * m) mod mj)) / mj
           tj_max =
           (2 * (B-1) * (\sum_i (B^i mod m) mod mj) - (qm_min * m) mod mj) / mj
        *)
        let qm_min_m_mod_mj = Z.(qm_min * m %! mj) in
        let bs_mod_m_mod_mj = List.map (fun v -> v %! mj) bs_mod_m in
        let sum_bound = Z.((base - one) * sum bs_mod_m_mod_mj) in
        let tj_min =
          Z.(div (neg sum_bound - (qm_bound * (m %! mj)) - qm_min_m_mod_mj) mj)
        in
        let tj_max = Z.(div ((of_int 2 * sum_bound) - qm_min_m_mod_mj) mj) in

        (* We will modify the equation on mj as follows:
           \sum_i ((B^i mod m) mod mj) * (x_i + y_i - z_i)
             - qm * (m mod mj) - ((qm_min * m) mod mj) = (tj + tj_min) * mj

           and bound tj in the interval [0, tj_bound), where tj_bound is the
           smallest power of 2^15 larger than t_max - t_min.
        *)
        let tj_bound =
          Z.(shift_left one (next_multiple_of 15 @@ numbits (tj_max - tj_min)))
        in

        (* Now, assuming tj is restricted to [0, tj_bound), we can bound the
           following amount:
            \sum_i ((B^i mod m) mod mj) * (x_i + y_i - z_i)
              - qm * (m mod mj) - ((qm_min * m) mod mj) - (tj + tj_min) * mj
        *)
        let lower_bound =
          Z.(
            neg sum_bound
            - (qm_bound * (m %! mj))
            - qm_min_m_mod_mj
            - ((tj_bound + tj_min) * mj))
        in
        let upper_bound =
          Z.((of_int 2 * sum_bound) - qm_min_m_mod_mj - (tj_min * mj))
        in

        (* Assert that there will be no wrap-around *)
        assert (Z.(upper_bound - lower_bound < m)) ;
        (tj_min, tj_bound))
      moduli
  in
  ((qm_min, qm_bound), ts_bounds)

module Make (Params : PARAMETERS) : MOD_ARITH =
functor
  (L : LIB)
  ->
  struct
    open L

    type mod_int = scalar list

    let label = Params.label

    let modulus = Params.modulus

    let base = Params.base

    let nb_limbs = Params.nb_limbs

    let moduli = Params.setM

    let (qm_min_add, qm_bound_add), ts_bounds_add =
      check_addition_parameters ~modulus ~base ~nb_limbs ~moduli

    let input_mod_int ?(kind = `Private) n =
      assert (List.length n = Params.nb_limbs) ;
      (* TODO: add range check assertions on the limbs *)
      let* i = Input.(list @@ List.map scalar n) |> input ~kind in
      let nb_bits = Z.log2 Params.base in
      iterM (Num.range_check ~nb_bits) (of_list i) >* ret i

    let add =
      Mod_arith.add
        ~modulus
        ~nb_limbs
        ~base
        ~moduli
        ~qm_min:qm_min_add
        ~qm_bound:qm_bound_add
        ~ts_bounds:ts_bounds_add

    let mul x _ =
      (* failwith "TODO" *)
      ret x

    let neg x =
      (* failwith "TODO" *)
      ret x
  end

module ArithMod25519 = Make (struct
  let label = "2^255-19"

  let modulus = Z.(shift_left one 255 - of_int 19)

  let base = Z.(shift_left one 85)

  let nb_limbs = 3

  let setM = [base]
end)
