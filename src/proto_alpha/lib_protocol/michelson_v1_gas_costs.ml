(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
(* Copyright (c) 2019-2022 Nomadic Labs <contact@nomadic-labs.com>           *)
(* Copyright (c) 2020 Metastate AG <hello@metastate.dev>                     *)
(* Copyright (c) 2022 DaiLambda, Inc. <contact@dailambda.jp>                 *)
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

include Michelson_v1_gas_costs_generated
module S = Saturation_repr

(** Hand-edited/written cost functions *)

(* The code is not auto-generated.
   See https://gitlab.com/tezos/tezos/-/issues/3834
   and https://gitlab.com/tezos/tezos/-/issues/4696
*)
(* model N_KList_exit_body *)
let cost_N_KList_exit_body = S.safe_int 10

(* N_ISapling_verify_update
   This function depends on another cost function cost_N_IBlake2b.
   Such code can't be generated by the current Snoop. *)
(* model N_ISapling_verify_update *)
(* Inferred cost (without cost_N_IBlake2b) is:
   fun size1 -> fun size2 -> ((432200.469784 + (5738377.05148 * size1)) + (4634026.28586 * size2)) *)
let cost_N_ISapling_verify_update size1 size2 bound_data =
  let open S.Syntax in
  let v1 = S.safe_int size1 in
  let v2 = S.safe_int size2 in
  cost_N_IBlake2b bound_data + S.safe_int 432_500
  + (S.safe_int 5_740_000 * v1)
  + (S.safe_int 4_635_000 * v2)

(* N_IApply
   The current generated model receives int as a flag,
   but it should receive bool. *)
(* model N_IApply *)
let cost_N_IApply rec_flag = if rec_flag then S.safe_int 220 else S.safe_int 140

(* N_KIter / N_KMap_enter_body
   The empty_branch_model are used as the models.
   However, the defined cost functions receive nothing. *)

(* model N_KIter *)
let cost_N_KIter = S.safe_int 10

(* model N_KMap_enter_body *)
let cost_N_KMap_enter_body = S.safe_int 80

(* N_KList_enter_body
   The generated model receives the length of `xs` as the first argument
   and branches on whether it is 0 or not.
   However, calculating the length makes the performance worse.
   The model should be changed to receive `xs_is_nil` as the first argument. *)
(* model N_KList_enter_body *)
(* Approximating 1.797068 x term *)
let cost_N_KList_enter_body xs size_ys =
  match xs with
  | [] ->
      let open S.Syntax in
      let v0 = S.safe_int size_ys in
      S.safe_int 30 + (v0 + (v0 lsr 1) + (v0 lsr 2) + (v0 lsr 4))
  | _ :: _ -> S.safe_int 30

(* model TY_EQ *)
let cost_TY_EQ size = S.mul size (S.safe_int 60)

(* model PARSE_TYPE
   This is the cost of one iteration of parse_ty, extracted by hand from the
   parameter fit for the PARSE_TYPE benchmark. *)
let cost_PARSE_TYPE = S.safe_int 60

(* model UNPARSE_TYPE
   This is the cost of one iteration of unparse_ty, extracted by hand from the
   parameter fit for the UNPARSE_TYPE benchmark. *)
let cost_UNPARSE_TYPE type_size = S.mul (S.safe_int 20) type_size

(* model TYPECHECKING_CODE
   This is the cost of one iteration of parse_instr, extracted by hand from the
   parameter fit for the TYPECHECKING_CODE benchmark. *)
let cost_TYPECHECKING_CODE = S.safe_int 220

(* model UNPARSING_CODE
   This is the cost of one iteration of unparse_instr, extracted by hand from the
   parameter fit for the UNPARSING_CODE benchmark. *)
let cost_UNPARSING_CODE = S.safe_int 115

(* model TYPECHECKING_DATA
   This is the cost of one iteration of parse_data, extracted by hand from the
   parameter fit for the TYPECHECKING_DATA benchmark. *)
let cost_TYPECHECKING_DATA = S.safe_int 100

(* model UNPARSING_DATA
   This is the cost of one iteration of unparse_data, extracted by hand from the
   parameter fit for the UNPARSING_DATA benchmark. *)
let cost_UNPARSING_DATA = S.safe_int 65

(* TODO: https://gitlab.com/tezos/tezos/-/issues/2264
   Benchmark.
   Currently approximated by 2 comparisons of the longest entrypoint. *)
let cost_FIND_ENTRYPOINT = cost_N_ICompare 31 31

(* ------------------------------------------------------------------------ *)

(* These functions lack the corresponding models. *)

(* model SAPLING_TRANSACTION_ENCODING *)
let cost_SAPLING_TRANSACTION_ENCODING ~inputs ~outputs ~bound_data =
  S.safe_int (1500 + (inputs * 160) + (outputs * 320) + (bound_data lsr 3))

(* model SAPLING_DIFF_ENCODING *)
let cost_SAPLING_DIFF_ENCODING ~nfs ~cms = S.safe_int ((nfs * 22) + (cms * 215))

(* ------------------------------------------------------------------------ *)

(* The allocation costs (0.5 gas unit per byte) are not negligible
   for the following models.
*)

(* model N_IAbs_int *)
(* Allocates [size] bytes. *)
let cost_N_IAbs_int size = S.safe_int (20 + (size lsr 1))

(* model N_IAnd_int_nat *)
(* Allocates [min size1 size2] *)
let cost_N_IAnd_int_nat size1 size2 =
  let open S.Syntax in
  let v0 = S.safe_int (Compare.Int.min size1 size2) in
  S.safe_int 35 + (v0 lsr 1)

(* model N_IAnd_nat *)
(* Allocates [min size1 size2] *)
let cost_N_IAnd_nat size1 size2 =
  let open S.Syntax in
  let v0 = S.safe_int (Compare.Int.min size1 size2) in
  S.safe_int 35 + (v0 lsr 1)

(* model N_IAnd_bytes *)
(* Allocates [min size1 size2] *)
(* fun size1 -> fun size2 -> (34.8914840649 + (0.398826813115 * (min size1 size2))) *)
let cost_N_IAnd_bytes size1 size2 =
  let open S.Syntax in
  let v0 = S.safe_int (Compare.Int.min size1 size2) in
  S.safe_int 35 + (v0 lsr 1)

(* model N_IConcat_bytes_pair *)
(* Allocates [size1 + size2] *)
let cost_N_IConcat_bytes_pair size1 size2 =
  let open S.Syntax in
  let v0 = S.safe_int size1 + S.safe_int size2 in
  S.safe_int 45 + (v0 lsr 1)

(* model N_IConcat_string_pair *)
(* Allocates [size1 + size2] *)
let cost_N_IConcat_string_pair size1 size2 =
  let open S.Syntax in
  let v0 = S.safe_int size1 + S.safe_int size2 in
  S.safe_int 45 + (v0 lsr 1)

(* model N_ILsl_nat *)
(* Allocates at most [size + 256] bytes *)
let cost_N_ILsl_nat size =
  let open S.Syntax in
  let v0 = S.safe_int size in
  S.safe_int 128 + (v0 lsr 1)

(* model N_ILsr_nat *)
(* Allocates at most [size] bytes*)
let cost_N_ILsr_nat size =
  let open S.Syntax in
  let v0 = S.safe_int size in
  S.safe_int 45 + (v0 lsr 1)

(* model N_IOr_bytes *)
(* Allocates [max size1 size2] bytes *)
(* fun size1 -> fun size2 -> (32.5381507316 + (0.232425212131 * (max size1 size2))) *)
let cost_N_IOr_bytes size1 size2 =
  let open S.Syntax in
  let v0 = S.safe_int (Compare.Int.max size1 size2) in
  S.safe_int 35 + (v0 lsr 1)

(* model N_ISlice_bytes *)
(* Allocates [size] bytes *)
let cost_N_ISlice_bytes size =
  let open S.Syntax in
  S.safe_int 25 + (S.safe_int size lsr 1)

(* model N_ISlice_string *)
(* Allocates [size] bytes *)
let cost_N_ISlice_string size =
  let open S.Syntax in
  S.safe_int 25 + (S.safe_int size lsr 1)

(* model N_ISplit_ticket *)
(* Allocates [max size1 size2] *)
let cost_N_ISplit_ticket size1 size2 =
  let open S.Syntax in
  let v1 = S.safe_int (Compare.Int.max size1 size2) in
  S.safe_int 40 + (v1 lsr 1)

(* model N_IXor_bytes *)
(* Allocates [max size1 size2] bytes *)
(* fun size1 -> fun size2 -> (38.5110342369 + (0.397946895815 * (max size1 size2))) *)
let cost_N_IXor_bytes size1 size2 =
  let open S.Syntax in
  let v0 = S.safe_int (Compare.Int.max size1 size2) in
  S.safe_int 40 + (v0 lsr 1)

(* Allocates [max size1 size2] *)
let cost_linear_op_int size1 size2 =
  let open S.Syntax in
  let v0 = S.safe_int (Compare.Int.max size1 size2) in
  S.safe_int 35 + (v0 lsr 1)

(* model N_IAdd_int *)
let cost_N_IAdd_int = cost_linear_op_int

(* model N_IAdd_nat *)
let cost_N_IAdd_nat = cost_linear_op_int

(* model N_IAdd_seconds_to_timestamp *)
let cost_N_IAdd_seconds_to_timestamp = cost_linear_op_int

(* model N_IAdd_timestamp_to_seconds *)
let cost_N_IAdd_timestamp_to_seconds = cost_linear_op_int

(* model N_ISub_int *)
let cost_N_ISub_int = cost_linear_op_int

(* model N_ISub_timestamp_seconds *)
let cost_N_ISub_timestamp_seconds = cost_linear_op_int

(* model N_IXor_nat *)
let cost_N_IXor_nat = cost_linear_op_int

(* model N_IDiff_timestamps *)
let cost_N_IDiff_timestamps = cost_linear_op_int

(* model N_IOr_nat *)
let cost_N_IOr_nat = cost_linear_op_int

(* model for interpreter/N_IEdiv_nat and interpreter/N_IEdiv_int *)
(* Allocates at most [size1] bytes *)
(* fun size1 -> fun size2 -> let q = (sat_sub size1 size2) in
   (((((0.0011458507706 * q) * size2) + (1.28630385018 * size1)) + (12.0204471175 * q)) + 137.990601159) *)
let cost_div_int size1 size2 =
  let open S.Syntax in
  let v1 = S.safe_int size1 in
  let v2 = S.safe_int size2 in
  let q = S.sub v1 v2 in
  (((q lsr 10) + (q lsr 13)) * v2)
  + (v1 + (v1 lsr 2))
  + ((q lsl 3) + (q lsl 2))
  + S.safe_int 150

(* model N_IEdiv_int *)
let cost_N_IEdiv_int = cost_div_int

(* model N_IEdiv_nat *)
let cost_N_IEdiv_nat = cost_div_int

(* model N_ILsl_bytes *)
(* Allocates [size + shift / 8] bytes *)
(* fun size1 -> fun size2 -> ((63.0681507316 + (0.667539714647 * size1)) + (0. * size2)) *)
let cost_N_ILsl_bytes size shift =
  let open S_syntax in
  let v1 = S.safe_int size in
  let v0 = S.safe_int shift in
  S.safe_int 65 + (v1 lsr 1) + (v1 lsr 2) + (v0 lsr 4)

(* model N_ILsr_bytes *)
(* Allocates [max 0 (size - shift / 8)] bytes *)
(* fun size1 -> fun size2 -> let q = (size1 - (size2 * 0.125)) in (53.9248173983 + (0.658785032381 * (if (0 < q) then q else 0))) *)
let cost_N_ILsr_bytes size shift =
  let q = size - (shift lsr 3) in
  let open S.Syntax in
  if Compare.Int.(q < 0) then S.safe_int 55
  else
    let v0 = S.safe_int q in
    S.safe_int 55 + (v0 lsr 1) + (v0 lsr 2)

(* model N_ISapling_empty_state *)
(* Allocates about 600 bytes *)
let cost_N_ISapling_empty_state = S.safe_int 300

(* model N_IEmpty_big_map *)
(* Allocates about 600 bytes *)
let cost_N_IEmpty_big_map = S.safe_int 300

(* ------------------------------------------------------------------------ *)

(* The inferred costs of the following models are 0, but we do not allow them
   cost free.  We charge 10 for them.
*)

(* model N_IExec *)
let cost_N_IExec = S.safe_int 10

(* model N_IIf *)
let cost_N_IIf = S.safe_int 10

(* model N_IIf_cons *)
let cost_N_IIf_cons = S.safe_int 10

(* model N_IIf_left *)
let cost_N_IIf_left = S.safe_int 10

(* model N_IIf_none *)
let cost_N_IIf_none = S.safe_int 10

(* model N_ILoop *)
let cost_N_ILoop = S.safe_int 10

(* model N_ILoop_left *)
let cost_N_ILoop_left = S.safe_int 10

(* model N_KCons *)
let cost_N_KCons = S.safe_int 10

(* model N_IDip *)
let cost_N_IDip = S.safe_int 10

(* ------------------------------------------------------------------------ *)

(* IDropN and IDipN use non affine models with multiple cases. The inferred
   cost functions are more complex than the following affine functions. *)

(* model N_IDropN *)
(* Approximating 2.713108 x term *)
let cost_N_IDropN size =
  let open S.Syntax in
  let v0 = S.safe_int size in
  S.safe_int 30 + (S.safe_int 2 * v0) + (v0 lsr 1) + (v0 lsr 3)

(* model N_IDipN *)
(* Approximating 4.05787663635 x term *)
let cost_N_IDipN size =
  let open S.Syntax in
  let v0 = S.safe_int size in
  S.safe_int 15 + (S.safe_int 4 * v0)

(* ------------------------------------------------------------------------ *)

(* N_IOpt_map has 2 salts, "some" and "none".
   Therefore 2 codes are generated for N_IOpt_map. *)
(* model N_IOpt_mapnone__alpha *)
(* 4.59406074329 *)
let cost_N_IOpt_map = S.safe_int 10

(* ------------------------------------------------------------------------ *)

(* Following functions are partially carbonated: they charge some gas
   by themselves.  Their inferred gas parameters cannot be directly
   used since they should contain the partial carbonation.
*)

(* model N_IContract *)
(* Inferred value: 703.26072741 *)
(* Most computation happens in [parse_contract_for_script], which is
   carbonated. *)
let cost_N_IContract = S.safe_int 30

(* model N_ICreate_contract *)
(* Inferred value: 814.154060743 *)
(* Most computation happens in [create_contract], which is carbonated. *)
let cost_N_ICreate_contract = S.safe_int 60

(* model N_ITransfer_tokens *)
(* Inferred value: 230.707394077 *)
(* Most computation happens in [transfer], which is carbonated. *)
let cost_N_ITransfer_tokens = S.safe_int 60

(* model IEmit *)
(* Inferred value: 244.687394077 *)
(* Most computation happens in [emit_event], which is carbonated. *)
let cost_N_IEmit = S.safe_int 30

(* ------------------------------------------------------------------------ *)

(* The following functions use very different parameters than the inferred
   ones.  Comments to explain the difference are required. *)

(* model CHECK_PRINTABLE *)
(* Inferred: fun size -> (0. + (1.42588022179 * size)) *)
let cost_CHECK_PRINTABLE size =
  let open S_syntax in
  S.safe_int 14 + (S.safe_int 10 * S.safe_int size)

(* model N_IList_iter *)
(* Inferred: 2.26028815324 *)
let cost_N_IList_iter = S.safe_int 20
