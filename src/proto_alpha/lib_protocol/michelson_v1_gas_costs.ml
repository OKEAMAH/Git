(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
(* Copyright (c) 2019-2022 Nomadic Labs <contact@nomadic-labs.com>           *)
(* Copyright (c) 2020 Metastate AG <hello@metastate.dev>                     *)
(* Copyright (c) 2022-2023 DaiLambda, Inc. <contact@dailambda.jp>            *)
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

let cost_N_IAbs_int = cost_N_IAbs_int_synthesized

let cost_N_IAdd_bls12_381_fr = cost_N_IAdd_bls12_381_fr_synthesized

let cost_N_IAdd_bls12_381_g1 = cost_N_IAdd_bls12_381_g1_synthesized

let cost_N_IAdd_bls12_381_g2 = cost_N_IAdd_bls12_381_g2_synthesized

let cost_N_IAdd_int = cost_N_IAdd_int_synthesized

let cost_N_IAdd_nat = cost_N_IAdd_nat_synthesized

let cost_N_IAdd_seconds_to_timestamp = cost_N_IAdd_seconds_to_timestamp_synthesized

let cost_N_IAdd_tez = cost_N_IAdd_tez_synthesized

let cost_N_IAdd_timestamp_to_seconds = cost_N_IAdd_timestamp_to_seconds_synthesized

let cost_N_IAddress = cost_N_IAddress_synthesized

let cost_N_IAmount = cost_N_IAmount_synthesized

let cost_N_IAnd_bytes = cost_N_IAnd_bytes_synthesized

let cost_N_IAnd_int_nat = cost_N_IAnd_int_nat_synthesized

let cost_N_IAnd_nat = cost_N_IAnd_nat_synthesized

let cost_N_IAnd = cost_N_IAnd_synthesized

let cost_N_IBalance = cost_N_IBalance_synthesized

let cost_N_IBig_map_get_and_update = cost_N_IBig_map_get_and_update_synthesized

let cost_N_IBig_map_get = cost_N_IBig_map_get_synthesized

let cost_N_IBig_map_mem = cost_N_IBig_map_mem_synthesized

let cost_N_IBig_map_update = cost_N_IBig_map_update_synthesized

let cost_N_IBlake2b = cost_N_IBlake2b_synthesized

let cost_N_IBytes_int = cost_N_IBytes_int_synthesized

let cost_N_IBytes_nat = cost_N_IBytes_nat_synthesized

let cost_N_IBytes_size = cost_N_IBytes_size_synthesized

let cost_N_ICar = cost_N_ICar_synthesized

let cost_N_ICdr = cost_N_ICdr_synthesized

let cost_N_IChainId = cost_N_IChainId_synthesized

let cost_N_ICheck_signature_bls = cost_N_ICheck_signature_bls_synthesized

let cost_N_ICheck_signature_ed25519 = cost_N_ICheck_signature_ed25519_synthesized

let cost_N_ICheck_signature_p256 = cost_N_ICheck_signature_p256_synthesized

let cost_N_ICheck_signature_secp256k1 = cost_N_ICheck_signature_secp256k1_synthesized

let cost_N_IComb_get = cost_N_IComb_get_synthesized

let cost_N_IComb_set = cost_N_IComb_set_synthesized

let cost_N_IComb = cost_N_IComb_synthesized

let cost_N_ICompare = cost_N_ICompare_synthesized

let cost_N_IConcat_bytes_pair = cost_N_IConcat_bytes_pair_synthesized

let cost_N_IConcat_string_pair = cost_N_IConcat_string_pair_synthesized

let cost_N_ICons_list = cost_N_ICons_list_synthesized

let cost_N_ICons_none = cost_N_ICons_none_synthesized

let cost_N_ICons_pair = cost_N_ICons_pair_synthesized

let cost_N_ICons_some = cost_N_ICons_some_synthesized

let cost_N_IDiff_timestamps = cost_N_IDiff_timestamps_synthesized

let cost_N_IDig = cost_N_IDig_synthesized

let cost_N_IDipN = cost_N_IDipN_synthesized

let cost_N_IDip = cost_N_IDip_synthesized

let cost_N_IDrop = cost_N_IDrop_synthesized

let cost_N_IDug = cost_N_IDug_synthesized

let cost_N_IDup = cost_N_IDup_synthesized

let cost_N_IEdiv_int = cost_N_IEdiv_int_synthesized

let cost_N_IEdiv_nat = cost_N_IEdiv_nat_synthesized

let cost_N_IEdiv_tez = cost_N_IEdiv_tez_synthesized

let cost_N_IEdiv_teznat = cost_N_IEdiv_teznat_synthesized

let cost_N_IEmpty_big_map = cost_N_IEmpty_big_map_synthesized

let cost_N_IEmpty_map = cost_N_IEmpty_map_synthesized

let cost_N_IEmpty_set = cost_N_IEmpty_set_synthesized

let cost_N_IEq = cost_N_IEq_synthesized

let cost_N_IExec = cost_N_IExec_synthesized

let cost_N_IFailwith = cost_N_IFailwith_synthesized

let cost_N_IGe = cost_N_IGe_synthesized

let cost_N_IGt = cost_N_IGt_synthesized

let cost_N_IHalt = cost_N_IHalt_synthesized

let cost_N_IHash_key = cost_N_IHash_key_synthesized

let cost_N_IIf_cons = cost_N_IIf_cons_synthesized

let cost_N_IIf_left = cost_N_IIf_left_synthesized

let cost_N_IIf_none = cost_N_IIf_none_synthesized

let cost_N_IIf = cost_N_IIf_synthesized

let cost_N_IImplicit_account = cost_N_IImplicit_account_synthesized

let cost_N_IInt_bls12_381_z_fr = cost_N_IInt_bls12_381_z_fr_synthesized

let cost_N_IInt_bytes = cost_N_IInt_bytes_synthesized

let cost_N_IInt_nat = cost_N_IInt_nat_synthesized

let cost_N_IIs_nat = cost_N_IIs_nat_synthesized

let cost_N_IJoin_tickets = cost_N_IJoin_tickets_synthesized

let cost_N_IKeccak = cost_N_IKeccak_synthesized

let cost_N_ILambda_lam = cost_N_ILambda_lam_synthesized

let cost_N_ILambda_lamrec = cost_N_ILambda_lamrec_synthesized

let cost_N_ILe = cost_N_ILe_synthesized

let cost_N_ILeft = cost_N_ILeft_synthesized

let cost_N_ILevel = cost_N_ILevel_synthesized

let cost_N_IList_iter = cost_N_IList_iter_synthesized

let cost_N_IList_map = cost_N_IList_map_synthesized

let cost_N_IList_size = cost_N_IList_size_synthesized

let cost_N_ILoop_in = cost_N_ILoop_in_synthesized

let cost_N_ILoop_left_in = cost_N_ILoop_left_in_synthesized

let cost_N_ILoop_left_out = cost_N_ILoop_left_out_synthesized

let cost_N_ILoop_out = cost_N_ILoop_out_synthesized

let cost_N_ILsl_bytes = cost_N_ILsl_bytes_synthesized

let cost_N_ILsl_nat = cost_N_ILsl_nat_synthesized

let cost_N_ILsr_bytes = cost_N_ILsr_bytes_synthesized

let cost_N_ILsr_nat = cost_N_ILsr_nat_synthesized

let cost_N_ILt = cost_N_ILt_synthesized

let cost_N_IMap_get_and_update = cost_N_IMap_get_and_update_synthesized

let cost_N_IMap_get = cost_N_IMap_get_synthesized

let cost_N_IMap_iter = cost_N_IMap_iter_synthesized

let cost_N_IMap_map = cost_N_IMap_map_synthesized

let cost_N_IMap_mem = cost_N_IMap_mem_synthesized

let cost_N_IMap_size = cost_N_IMap_size_synthesized

let cost_N_IMap_update = cost_N_IMap_update_synthesized

let cost_N_IMin_block_time = cost_N_IMin_block_time_synthesized

let cost_N_IMul_bls12_381_fr = cost_N_IMul_bls12_381_fr_synthesized

let cost_N_IMul_bls12_381_fr_z = cost_N_IMul_bls12_381_fr_z_synthesized

let cost_N_IMul_bls12_381_g1 = cost_N_IMul_bls12_381_g1_synthesized

let cost_N_IMul_bls12_381_g2 = cost_N_IMul_bls12_381_g2_synthesized

let cost_N_IMul_bls12_381_z_fr = cost_N_IMul_bls12_381_z_fr_synthesized

let cost_N_IMul_int = cost_N_IMul_int_synthesized

let cost_N_IMul_nat = cost_N_IMul_nat_synthesized

let cost_N_IMul_nattez = cost_N_IMul_nattez_synthesized

let cost_N_IMul_teznat = cost_N_IMul_teznat_synthesized

let cost_N_INat_bytes = cost_N_INat_bytes_synthesized

let cost_N_INeg_bls12_381_fr = cost_N_INeg_bls12_381_fr_synthesized

let cost_N_INeg_bls12_381_g1 = cost_N_INeg_bls12_381_g1_synthesized

let cost_N_INeg_bls12_381_g2 = cost_N_INeg_bls12_381_g2_synthesized

let cost_N_INeg = cost_N_INeg_synthesized

let cost_N_INeq = cost_N_INeq_synthesized

let cost_N_INil = cost_N_INil_synthesized

let cost_N_INot_bytes = cost_N_INot_bytes_synthesized

let cost_N_INot_int = cost_N_INot_int_synthesized

let cost_N_INot = cost_N_INot_synthesized

let cost_N_INow = cost_N_INow_synthesized

let cost_N_IOpen_chest = cost_N_IOpen_chest_synthesized

let cost_N_IOpt_map_none = cost_N_IOpt_map_none_synthesized

let cost_N_IOpt_map_some = cost_N_IOpt_map_some_synthesized

let cost_N_IOr_bytes = cost_N_IOr_bytes_synthesized

let cost_N_IOr_nat = cost_N_IOr_nat_synthesized

let cost_N_IOr = cost_N_IOr_synthesized

let cost_N_IPairing_check_bls12_381 = cost_N_IPairing_check_bls12_381_synthesized

let cost_N_IPush = cost_N_IPush_synthesized

let cost_N_IRead_ticket = cost_N_IRead_ticket_synthesized

let cost_N_IRight = cost_N_IRight_synthesized

let cost_N_ISapling_empty_state = cost_N_ISapling_empty_state_synthesized

let cost_N_ISapling_verify_update = cost_N_ISapling_verify_update_synthesized

let cost_N_ISelf_address = cost_N_ISelf_address_synthesized

let cost_N_ISelf = cost_N_ISelf_synthesized

let cost_N_ISender = cost_N_ISender_synthesized

let cost_N_ISet_delegate = cost_N_ISet_delegate_synthesized

let cost_N_ISet_iter = cost_N_ISet_iter_synthesized

let cost_N_ISet_mem = cost_N_ISet_mem_synthesized

let cost_N_ISet_size = cost_N_ISet_size_synthesized

let cost_N_ISet_update = cost_N_ISet_update_synthesized

let cost_N_ISha256 = cost_N_ISha256_synthesized

let cost_N_ISha3 = cost_N_ISha3_synthesized

let cost_N_ISha512 = cost_N_ISha512_synthesized

let cost_N_ISlice_bytes = cost_N_ISlice_bytes_synthesized

let cost_N_ISlice_string = cost_N_ISlice_string_synthesized

let cost_N_ISource = cost_N_ISource_synthesized

let cost_N_ISplit_ticket = cost_N_ISplit_ticket_synthesized

let cost_N_IString_size = cost_N_IString_size_synthesized

let cost_N_ISub_int = cost_N_ISub_int_synthesized

let cost_N_ISub_tez_legacy = cost_N_ISub_tez_legacy_synthesized

let cost_N_ISub_tez = cost_N_ISub_tez_synthesized

let cost_N_ISub_timestamp_seconds = cost_N_ISub_timestamp_seconds_synthesized

let cost_N_ISwap = cost_N_ISwap_synthesized

let cost_N_ITicket = cost_N_ITicket_synthesized

let cost_N_ITotal_voting_power = cost_N_ITotal_voting_power_synthesized

let cost_N_IUncomb = cost_N_IUncomb_synthesized

let cost_N_IUnit = cost_N_IUnit_synthesized

let cost_N_IUnpair = cost_N_IUnpair_synthesized

let cost_N_IView = cost_N_IView_synthesized

let cost_N_IVoting_power = cost_N_IVoting_power_synthesized

let cost_N_IXor_bytes = cost_N_IXor_bytes_synthesized

let cost_N_IXor_nat = cost_N_IXor_nat_synthesized

let cost_N_IXor = cost_N_IXor_synthesized

let cost_N_KCons = cost_N_KCons_synthesized

let cost_N_KIter_empty = cost_N_KIter_empty_synthesized

let cost_N_KIter_nonempty = cost_N_KIter_nonempty_synthesized

let cost_N_KList_exit_body = cost_N_KList_exit_body_synthesized

let cost_N_KLoop_in_left = cost_N_KLoop_in_left_synthesized

let cost_N_KLoop_in = cost_N_KLoop_in_synthesized

let cost_N_KMap_exit_body = cost_N_KMap_exit_body_synthesized

let cost_N_KMap_head = cost_N_KMap_head_synthesized

let cost_N_KNil = cost_N_KNil_synthesized

let cost_N_KReturn = cost_N_KReturn_synthesized

let cost_N_KUndip = cost_N_KUndip_synthesized

let cost_N_KView_exit = cost_N_KView_exit_synthesized


(* ------------------------------------------------------------------------ *)

(* N_ISapling_verify_update_with_blake2b
   This function depends on another cost function cost_N_IBlake2b.
   Such code can't be generated by the current Snoop. *)
let cost_N_ISapling_verify_update_with_blake2b size1 size2 bound_data =
  let open S.Syntax in
  cost_N_IBlake2b bound_data + cost_N_ISapling_verify_update size1 size2

(* N_IApply
   The current generated model receives int as a flag,
   but it should receive bool. *)
(* model interpreter/N_IApply_synthesized *)
(* fun size ->
     let time = if size = 0 then 140. else 220. in
     let alloc = if size = 0 then 225.986577181 else 510.013245033 in
     max time alloc *)
let cost_N_IApply rec_flag = if rec_flag then S.safe_int 220 else S.safe_int 510

(* N_KMap_enter_body
   Removed conversion of [size] for optimization *)
(* model interpreter/N_KMap_enter_body_synthesized *)
(* fun size ->
     let time = if size = 0 then 10. else 80. in
     let alloc = if size = 0 then 11. else 0. in max time alloc *)
let cost_N_KMap_enter_body size =
  if Compare.Int.(size = 0) then S.safe_int 15 else S.safe_int 80

(* N_KList_enter_body
   The generated model receives the length of `xs` as the first argument
   and branches on whether it is 0 or not.
   However, calculating the length makes the performance worse.
   The model should be changed to receive `xs_is_nil` as the first argument. *)
(* model interpreter/N_KList_enter_body_synthesized *)
(* fun size_xs ->
     fun size_ys ->
       let time = if size_xs = 0 then 30. + (1.8125 * size_ys) else 30. in
       let alloc =
         if size_xs = 0 then 23. + (12.0014700944 * size_ys) else 0. in
       max time alloc *)
let cost_N_KList_enter_body xs size_ys =
  match xs with
  | [] ->
      let open S.Syntax in
      let size_ys = S.safe_int size_ys in
      let w1 = size_ys lsr 2 in
      S.max
        ((size_ys lsr 1) + w1 + (size_ys lsr 4) + size_ys + S.safe_int 30)
        (w1 + (size_ys * S.safe_int 12) + S.safe_int 25)
  | _ :: _ -> S.safe_int 30

(* model PARSE_TYPE
   This is the cost of one iteration of parse_ty, extracted by hand from the
   parameter fit for the PARSE_TYPE benchmark. *)
let cost_PARSE_TYPE1 = cost_PARSE_TYPE 1

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

(* IDropN and IDupN use non affine models with multiple cases. The inferred
   cost functions are more complex than the following affine functions. *)

(* model N_IDropN *)
(* fun size ->
     let time = 2.625 * size + 30. in
     let alloc = 0. * size + 0. in
     max time alloc *)
let cost_N_IDropN size =
  let open S.Syntax in
  let w3 = S.safe_int size in
  (w3 * S.safe_int 2) + (w3 lsr 1) + (w3 lsr 3)
  + S.safe_int 30

(* model N_IDupN *)
(* fun size ->
     let time =
       let size = sub size 1 in
       (1.25 * size) + 20.
     in
     let alloc =
       let size = sub size 1 in
       0. * size + 12.
     in
     max time alloc *)
let cost_N_IDupN size =
  let open S.Syntax in
  let size = S.safe_int size in
  let w4 = S.sub size (S.safe_int 1) in
  w4 + (w4 lsr 2) + S.safe_int 20

(* ------------------------------------------------------------------------ *)

(* Following functions are partially carbonated: they charge some gas
   by themselves.  Their inferred gas parameters cannot be directly
   used since they should contain the partial carbonation.
*)

(* model N_IContract *)
(* Generated code: let time = 741.243807166 in let alloc = 16. in max time alloc *)
(* Most computation of [741.24] happens in [parse_contract_for_script], which is
   carbonated.

   We estimate the pure runtime cost of the opcode is [30], which changes the code to:
   let time = 30 in let alloc = 16. in max time alloc
*)
let cost_N_IContract = S.safe_int 30

(* model N_ICreate_contract *)
(* Generated code: let time = 864.643807166 in let alloc = 196. in max time alloc *)
(* Most computation of [864.64] happens in [create_contract], which is carbonated.
   We estimate the pure runtime cost of the opcode is [60], which changes the code to:

   let time = 60. in let alloc = 196. in max time alloc
*)
let cost_N_ICreate_contract = S.safe_int 196

(* model N_ITransfer_tokens *)
(* Generated code: let time = 264.8271. in let alloc = 120. in max time alloc *)
(* Most computation of [264.8271] happens in [transfer], which is carbonated.
   We estimate the pure runtime cost of the opcode is [60], which changes the code to:

   let time = 60. in let alloc = 120. in max time alloc
*)
let cost_N_ITransfer_tokens = S.safe_int 120

(* model IEmit *)
(* Generated code: let time = 308.970473833 in let alloc = 124. in max time alloc *)
(* Most computation of [308.97] happens in [emit_event], which is carbonated.
   We estimate the pure runtime cost of the opcode is [30], which changes the code to:

   let time = 30. in let alloc = 124. in max time alloc
*)
let cost_N_IEmit = S.safe_int 124

(* --------------------------------------------------------------------- *)

(* The cost functions below where not benchmarked, a cost model was derived
    from looking at similar instructions. *)
(* Cost for Concat_string is paid in two steps: when entering the interpreter,
    the user pays for the cost of computing the information necessary to compute
    the actual gas (so it's meta-gas): indeed, one needs to run through the
    list of strings to compute the total allocated cost.
    [concat_string_precheck] corresponds to the meta-gas cost of this computation.
*)

let cost_N_IConcat_string_precheck length =
  (* we set the precheck to be slightly more expensive than cost_N_IList_iter *)
  let open S.Syntax in
  let length = S.safe_int length in
  length * S.safe_int 10

(* This is the cost of allocating a string and blitting existing ones into it. *)
let cost_N_IConcat_string total_bytes =
  let open S.Syntax in
  S.safe_int 100 + (total_bytes lsr 1)

(* Same story as Concat_string. *)
let cost_N_IConcat_bytes total_bytes =
  let open S.Syntax in
  S.safe_int 100 + (total_bytes lsr 1)

(* A partially carbonated instruction,
   so its model does not correspond to this function *)
(* Cost of Unpack pays two integer comparisons, and a Bytes slice *)
let cost_N_IUnpack total_bytes =
  let open S.Syntax in
  let total_bytes = S.safe_int total_bytes in
  S.safe_int 260 + (total_bytes lsr 1)
